class_name RegionBuilder
extends RefCounted
## Turns the region's terrain and caves into mesh data. Everything here is a pure function of the chunk's
## index, so it is safe to run on worker threads; the nodes are made on the main thread (RegionWorld).

const TERRAIN_CELL := 6.0
const TERRAIN_CELLS := 32
const TERRAIN_CHUNK := TERRAIN_CELL * TERRAIN_CELLS   # 192 m
const GIANT_CELL := 52.0
const UNDER_CELL := 22.0
const ROCK_CELL := 38.0


## Which terrain chunks (x, z index) are needed to cover the region.
static func terrain_keys() -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	var reach := int(ceil(RegionTerrain.EDGE / TERRAIN_CHUNK)) + 1
	for j in range(-reach, reach):
		for i in range(-reach, reach):
			var center := Vector2((i + 0.5) * TERRAIN_CHUNK, (j + 0.5) * TERRAIN_CHUNK)
			if center.length() < RegionTerrain.EDGE + TERRAIN_CHUNK * 0.5:
				keys.append(Vector2i(i, j))
	return keys


## A square of ground: vertices, normals, path colors, triangle indices (with holes left out) and the
## same triangles as a flat list for the collider.
static func terrain_chunk(ix: int, iz: int) -> Dictionary:
	var n := TERRAIN_CELLS
	var m := n + 3
	var x0 := ix * TERRAIN_CHUNK
	var z0 := iz * TERRAIN_CHUNK
	var heights := PackedFloat32Array()
	heights.resize(m * m)
	for j in m:
		for i in m:
			heights[j * m + i] = RegionTerrain.height(x0 + (i - 1) * TERRAIN_CELL, z0 + (j - 1) * TERRAIN_CELL)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for j in n + 1:
		for i in n + 1:
			var c := (j + 1) * m + (i + 1)
			var h := heights[c]
			var dx := (heights[c - 1] - heights[c + 1]) / (2.0 * TERRAIN_CELL)
			var dz := (heights[c - m] - heights[c + m]) / (2.0 * TERRAIN_CELL)
			vertices.push_back(Vector3(i * TERRAIN_CELL, h, j * TERRAIN_CELL))
			normals.push_back(Vector3(dx, 1.0, dz).normalized())
			var wx := x0 + i * TERRAIN_CELL
			var wz := z0 + j * TERRAIN_CELL
			colors.push_back(Color(
				RegionTerrain.path_factor(wx, wz), 0.0, RegionTerrain.forest_density(wx, wz, h), RegionTerrain.dead_amount(wx, wz)))

	var indices := PackedInt32Array()
	var faces := PackedVector3Array()
	var row := n + 1
	for j in n:
		for i in n:
			var cx := x0 + (i + 0.5) * TERRAIN_CELL
			var cz := z0 + (j + 0.5) * TERRAIN_CELL
			if RegionTerrain.is_hole(cx, cz):
				continue
			var a := j * row + i
			var b := a + 1
			var c := a + row + 1
			var d := a + row
			indices.append_array([a, b, c, a, c, d])
			faces.append_array([vertices[a], vertices[b], vertices[c], vertices[a], vertices[c], vertices[d]])
			# Next to a square the cave mesh builds, add an invisible wall down from the edge, so no crack
			# between the two meshes can ever be fallen through.
			if RegionTerrain.is_hole(cx + TERRAIN_CELL, cz):
				_skirt(faces, vertices[b], vertices[c])
			if RegionTerrain.is_hole(cx - TERRAIN_CELL, cz):
				_skirt(faces, vertices[a], vertices[d])
			if RegionTerrain.is_hole(cx, cz + TERRAIN_CELL):
				_skirt(faces, vertices[d], vertices[c])
			if RegionTerrain.is_hole(cx, cz - TERRAIN_CELL):
				_skirt(faces, vertices[a], vertices[b])
	var scatter := _scatter(x0, z0)
	return {
		"origin": Vector3(x0, 0.0, z0), "vertices": vertices, "normals": normals,
		"colors": colors, "indices": indices, "faces": faces,
		"batches": scatter["batches"], "trunks": scatter["trunks"],
		"center": Vector3(x0 + TERRAIN_CHUNK * 0.5, 0.0, z0 + TERRAIN_CHUNK * 0.5),
	}


static func _skirt(faces: PackedVector3Array, a: Vector3, b: Vector3) -> void:
	var down := Vector3(0.0, -4.0, 0.0)
	faces.append_array([a, b, b + down, a, b + down, a + down])


static func _batch(batches: Dictionary, mesh_name: String) -> ForestBuilder.Batch:
	if not batches.has(mesh_name):
		batches[mesh_name] = ForestBuilder.Batch.new()
	return batches[mesh_name]


## Trees, small conifers and rocks for one square of ground. Positions in the batches are relative to the
## square's center; trunk positions are relative to its corner (for collision).
static func _scatter(x0: float, z0: float) -> Dictionary:
	var cx := x0 + TERRAIN_CHUNK * 0.5
	var cz := z0 + TERRAIN_CHUNK * 0.5
	var batches := {}
	var trunks := PackedFloat32Array()
	var x1 := x0 + TERRAIN_CHUNK
	var z1 := z0 + TERRAIN_CHUNK

	# Giants (about 60 to 120 m): three levels of detail, picked by distance (see RegionWorld).
	for j in range(int(floor(z0 / GIANT_CELL)), int(floor(z1 / GIANT_CELL)) + 1):
		for i in range(int(floor(x0 / GIANT_CELL)), int(floor(x1 / GIANT_CELL)) + 1):
			var px := (i + 0.12 + 0.76 * ForestTerrain.rnd(i, j, 1)) * GIANT_CELL
			var pz := (j + 0.12 + 0.76 * ForestTerrain.rnd(i, j, 2)) * GIANT_CELL
			if px < x0 or px >= x1 or pz < z0 or pz >= z1:
				continue
			var h := RegionTerrain.height(px, pz)
			if RegionTerrain.forest_density(px, pz, h) * 0.85 <= ForestTerrain.rnd(i, j, 3):
				continue
			if RegionTerrain.slope(px, pz) > 0.28:
				continue
			var tall := lerpf(62.0, 118.0, pow(ForestTerrain.rnd(i, j, 4), 1.3))
			var sy := tall / 140.0
			var sw := sy * (0.9 + 0.3 * ForestTerrain.rnd(i, j, 5))
			var yaw := ForestTerrain.rnd(i, j, 6) * TAU
			var shade := 0.88 + 0.24 * ForestTerrain.rnd(i, j, 7)
			var tint := Color(shade, shade, shade, 1.0).lerp(Color(0.5, 0.46, 0.42, 1.0), RegionTerrain.dead_amount(px, pz))
			var local := Vector3(px - cx, h - 0.6, pz - cz)
			var full := "giant_a" if ForestTerrain.rnd(i, j, 8) < 0.5 else "giant_b"
			_batch(batches, full).add(local, yaw, sw, sy * (140.0 / 120.0 if full == "giant_b" else 1.0), tint)
			_batch(batches, "giant_mid").add(local, yaw, sw, sy, tint)
			_batch(batches, "giant_low").add(local, yaw, sw, sy, tint)
			trunks.append_array([px - x0, pz - z0, 5.8 * sw * 1.05, 140.0 * sy * 0.9, h])

	# Smaller conifers in their shade.
	for j in range(int(floor(z0 / UNDER_CELL)), int(floor(z1 / UNDER_CELL)) + 1):
		for i in range(int(floor(x0 / UNDER_CELL)), int(floor(x1 / UNDER_CELL)) + 1):
			var px := (i + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 11)) * UNDER_CELL
			var pz := (j + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 12)) * UNDER_CELL
			if px < x0 or px >= x1 or pz < z0 or pz >= z1:
				continue
			var h := RegionTerrain.height(px, pz)
			if RegionTerrain.forest_density(px, pz, h) * 0.75 <= ForestTerrain.rnd(i, j, 13):
				continue
			if RegionTerrain.slope(px, pz) > 0.3:
				continue
			var s := 0.6 + 0.7 * ForestTerrain.rnd(i, j, 14)
			var shade := 0.85 + 0.25 * ForestTerrain.rnd(i, j, 15)
			_batch(batches, "under").add(Vector3(px - cx, h - 0.3, pz - cz), ForestTerrain.rnd(i, j, 16) * TAU, s, s, Color(shade, shade, shade, 1.0))

	# Loose rocks, more on rough ground.
	for j in range(int(floor(z0 / ROCK_CELL)), int(floor(z1 / ROCK_CELL)) + 1):
		for i in range(int(floor(x0 / ROCK_CELL)), int(floor(x1 / ROCK_CELL)) + 1):
			var px := (i + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 21)) * ROCK_CELL
			var pz := (j + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 22)) * ROCK_CELL
			if px < x0 or px >= x1 or pz < z0 or pz >= z1:
				continue
			if Vector2(px, pz).length() < 120.0 or RegionTerrain.is_hole(px, pz):
				continue
			var h := RegionTerrain.height(px, pz)
			if RegionTerrain.path_factor(px, pz) > 0.2 or (h < RegionTerrain.lake_level() + 0.5 and RegionTerrain.in_water(px, pz)):
				continue
			var steep := RegionTerrain.slope(px, pz)
			if ForestTerrain.rnd(i, j, 23) > 0.35 + steep * 2.0:
				continue
			var s := 0.7 + 2.4 * pow(ForestTerrain.rnd(i, j, 24), 2.0)
			var shade := 0.8 + 0.3 * ForestTerrain.rnd(i, j, 25)
			var rock := "rock_a" if ForestTerrain.rnd(i, j, 26) < 0.5 else "rock_b"
			_batch(batches, rock).add(Vector3(px - cx, h - 0.2 * s, pz - cz), ForestTerrain.rnd(i, j, 27) * TAU, s * 1.3, s, Color(shade, shade, shade, 1.0))

	var list: Array = []
	for mesh_name in batches:
		var b: ForestBuilder.Batch = batches[mesh_name]
		list.append({"mesh": mesh_name, "count": b.count, "data": b.data})
	return {"batches": list, "trunks": trunks}


## One 48 m cube of cave, as a smooth mesh (surface nets) with faces pointing into the open air.
## The cube's samples overlap its neighbours by a cell, so the meshes meet with no cracks.
static func cave_chunk(cx: int, cy: int, cz: int) -> Dictionary:
	var n := RegionCaves.CELLS
	var cell := RegionCaves.CELL
	var origin := Vector3(cx, cy, cz) * RegionCaves.CHUNK
	var prims := RegionCaves.prims_near(origin - Vector3.ONE * 3.0, origin + Vector3.ONE * (RegionCaves.CHUNK + 3.0))
	var with_ground := RegionCaves.has_ground(cx, cz)
	if prims.is_empty() and not with_ground:
		return {}

	# Samples at corners -1..n (index + 1). Where the cube builds the ground too, work out its height once
	# for each column of samples.
	var m := n + 2
	var column_height := PackedFloat32Array()
	# Cubes that reach the surface need the ground's height (to build it, or to stay below it).
	var needs_heights := with_ground or (origin.y + RegionCaves.CHUNK > 18.0 and origin.y < 150.0)
	if needs_heights:
		column_height.resize(m * m)
		for k in m:
			for i in m:
				column_height[k * m + i] = RegionTerrain.height(origin.x + (i - 1) * cell, origin.z + (k - 1) * cell)
	var field := PackedFloat32Array()
	field.resize(m * m * m)
	var any_air := false
	var any_rock := false
	for k in m:
		for j in m:
			for i in m:
				var ground := column_height[k * m + i] if needs_heights else NAN
				var v := RegionCaves.sdf(origin + Vector3(i - 1, j - 1, k - 1) * cell, prims, ground, with_ground)
				field[(k * m + j) * m + i] = v
				if v < 0.0:
					any_air = true
				else:
					any_rock = true
	if not (any_air and any_rock):
		return {}

	# One vertex in each cell the surface crosses: cells -1..n-1 (index + 1).
	var cells := n + 1
	var cell_vertex := PackedInt32Array()
	cell_vertex.resize(cells * cells * cells)
	cell_vertex.fill(-1)
	var vertices := PackedVector3Array()
	var corner_offsets := [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 0),
		Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(0, 1, 1), Vector3i(1, 1, 1),
	]
	var cube_edges := [
		[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7],
	]
	var values := PackedFloat32Array()
	values.resize(8)
	for k in cells:
		for j in cells:
			for i in cells:
				var mask := 0
				for c in 8:
					var o: Vector3i = corner_offsets[c]
					var v := field[((k + o.z) * m + (j + o.y)) * m + (i + o.x)]
					values[c] = v
					if v < 0.0:
						mask |= 1 << c
				if mask == 0 or mask == 255:
					continue
				var sum := Vector3.ZERO
				var count := 0
				for e in cube_edges:
					var a: int = e[0]
					var b: int = e[1]
					if (values[a] < 0.0) != (values[b] < 0.0):
						var t := values[a] / (values[a] - values[b])
						var oa: Vector3i = corner_offsets[a]
						var ob: Vector3i = corner_offsets[b]
						sum += Vector3(oa).lerp(Vector3(ob), t)
						count += 1
				var local := (Vector3(i - 1, j - 1, k - 1) + sum / count) * cell
				cell_vertex[(k * cells + j) * cells + i] = vertices.size()
				vertices.push_back(local)

	# A quad for every edge (owned by this cube) that goes from air to rock.
	var indices := PackedInt32Array()
	for k in n:
		for j in n:
			for i in n:
				var here := field[((k + 1) * m + (j + 1)) * m + (i + 1)]
				for axis in 3:
					var next_i := i + 1 + (1 if axis == 0 else 0)
					var next_j := j + 1 + (1 if axis == 1 else 0)
					var next_k := k + 1 + (1 if axis == 2 else 0)
					var there := field[(next_k * m + next_j) * m + next_i]
					if (here < 0.0) == (there < 0.0):
						continue
					var u := (axis + 1) % 3
					var w := (axis + 2) % 3
					var base := Vector3i(i + 1, j + 1, k + 1)   # cell index of the cell holding this corner as its min
					var quad: Array[int] = []
					for off in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(0, 0), Vector2i(-1, 0)]:
						var cell_index := base
						cell_index[u] += off.x
						cell_index[w] += off.y
						quad.append(cell_vertex[(cell_index.z * cells + cell_index.y) * cells + cell_index.x])
					if quad.has(-1):
						continue
					if here < 0.0:
						indices.append_array([quad[0], quad[1], quad[2], quad[0], quad[2], quad[3]])
					else:
						indices.append_array([quad[0], quad[2], quad[1], quad[0], quad[3], quad[2]])

	if indices.is_empty():
		return {}
	# Normals point into the open air: against the rock's gradient. Colors: how much each vertex is cave
	# (rock walls) rather than ground (the green channel).
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	var colors := PackedColorArray()
	colors.resize(vertices.size())
	var e := cell * 0.5
	for v in vertices.size():
		var p := origin + vertices[v]
		var g_here := NAN
		var g_x1 := NAN
		var g_x0 := NAN
		var g_z1 := NAN
		var g_z0 := NAN
		var cave_amount := 1.0
		if needs_heights:
			g_here = RegionTerrain.height(p.x, p.z)
			# Only vertices near the ground need the ground's shape in their gradient.
			if absf(p.y - g_here) < 4.0:
				g_x1 = RegionTerrain.height(p.x + e, p.z)
				g_x0 = RegionTerrain.height(p.x - e, p.z)
				g_z1 = RegionTerrain.height(p.x, p.z + e)
				g_z0 = RegionTerrain.height(p.x, p.z - e)
			else:
				g_x1 = g_here
				g_x0 = g_here
				g_z1 = g_here
				g_z0 = g_here
			if with_ground:
				cave_amount = clampf((g_here - p.y - 0.8) / 1.2, 0.0, 1.0)
		var gradient := Vector3(
			RegionCaves.sdf(p + Vector3(e, 0, 0), prims, g_x1, with_ground) - RegionCaves.sdf(p - Vector3(e, 0, 0), prims, g_x0, with_ground),
			RegionCaves.sdf(p + Vector3(0, e, 0), prims, g_here, with_ground) - RegionCaves.sdf(p - Vector3(0, e, 0), prims, g_here, with_ground),
			RegionCaves.sdf(p + Vector3(0, 0, e), prims, g_z1, with_ground) - RegionCaves.sdf(p - Vector3(0, 0, e), prims, g_z0, with_ground))
		normals[v] = -gradient.normalized()
		colors[v] = Color(0.0, cave_amount, 0.0, 0.0)
	var faces := PackedVector3Array()
	for index in indices:
		faces.push_back(vertices[index])
	return {"origin": origin, "vertices": vertices, "normals": normals, "colors": colors, "indices": indices, "faces": faces, "ground": with_ground}
