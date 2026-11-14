class_name ForestBuilder
extends RefCounted
## Works out everything one square patch ("leaf") of the world needs: the terrain mesh, and where every
## tree, bush, fern, tuft of grass and rock goes. It only touches plain data, so it is safe to run on a
## background thread. ForestChunks turns the result into real nodes on the main thread.
##
## The world is a quadtree: a leaf at level 0 is 128 m across, and each level up doubles that. Near the
## wisp the leaves are small (lots of detail); far away they are huge (just terrain and a few trees).

const LEAF_MIN := 128.0
const GRID := 32
const ROOT_ORIGIN := -4096.0

const GIANT_CELL := 44.0
const UNDER_CELL := 17.0
const BUSH_CELL := 9.0
const FERN_CELL := 4.5
const GRASS_CELL := 2.6
const ROCK_CELL := 26.0
const BOULDER_CELL := 150.0


## Stores the position, size and tint of many copies of one mesh, ready to hand to a MultiMesh.
class Batch:
	var data := PackedFloat32Array()
	var count := 0

	func add(local: Vector3, yaw: float, width: float, height: float, tint: Color) -> void:
		var c := cos(yaw)
		var s := sin(yaw)
		data.push_back(c * width)
		data.push_back(0.0)
		data.push_back(s * width)
		data.push_back(local.x)
		data.push_back(0.0)
		data.push_back(height)
		data.push_back(0.0)
		data.push_back(local.y)
		data.push_back(-s * width)
		data.push_back(0.0)
		data.push_back(c * width)
		data.push_back(local.z)
		data.push_back(tint.r)
		data.push_back(tint.g)
		data.push_back(tint.b)
		data.push_back(tint.a)
		count += 1


static func leaf_size(level: int) -> float:
	return LEAF_MIN * float(1 << level)


static func leaf_origin(level: int, ix: int, iz: int) -> Vector2:
	var size := leaf_size(level)
	return Vector2(ROOT_ORIGIN + ix * size, ROOT_ORIGIN + iz * size)


## Builds everything for one leaf. Returns a Dictionary of plain data (see ForestChunks._instantiate).
static func build(level: int, ix: int, iz: int) -> Dictionary:
	var size := leaf_size(level)
	var origin := leaf_origin(level, ix, iz)
	var x0 := origin.x
	var z0 := origin.y

	var result := {
		"key": Vector3i(level, ix, iz),
		"level": level,
		"x0": x0,
		"z0": z0,
		"size": size,
	}
	_build_terrain(result, x0, z0, size, level)

	var batches := {}
	var trunks := PackedFloat32Array()
	if level <= 3:
		_scatter_giants(batches, trunks, x0, z0, size, level)
	elif level <= 6:
		_scatter_far(batches, x0, z0, size, level)
	if level <= 1:
		_scatter_understory(batches, trunks, x0, z0, size)
		_scatter_bushes(batches, x0, z0, size)
		_scatter_rocks(batches, x0, z0, size, ROCK_CELL, 0.5, 2.0, 0.12)
	if level == 0:
		_scatter_ferns(batches, x0, z0, size)
		_scatter_grass(batches, x0, z0, size)
	if level <= 2:
		_scatter_rocks(batches, x0, z0, size, BOULDER_CELL, 3.0, 9.0, 0.35)

	var list := []
	for mesh_name in batches:
		var batch: Batch = batches[mesh_name]
		if batch.count > 0:
			list.append({"mesh": mesh_name, "data": batch.data, "count": batch.count})
	result["batches"] = list
	result["trunks"] = trunks
	return result


# --- Terrain ------------------------------------------------------------------

static func _build_terrain(result: Dictionary, x0: float, z0: float, size: float, level: int) -> void:
	var n := GRID + 1
	var step := size / GRID
	var stride := n + 2
	# Heights with a one-cell border, so normals are correct right to the edge.
	var heights := PackedFloat32Array()
	heights.resize(stride * stride)
	for j in range(-1, n + 1):
		for i in range(-1, n + 1):
			heights[(j + 1) * stride + (i + 1)] = ForestTerrain.height(x0 + i * step, z0 + j * step)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	vertices.resize(n * n)
	normals.resize(n * n)
	colors.resize(n * n)
	var normal_step := maxf(step, 4.0)
	for j in n:
		for i in n:
			var h := heights[(j + 1) * stride + (i + 1)]
			var hx := heights[(j + 1) * stride + (i + 2)] - heights[(j + 1) * stride + i]
			var hz := heights[(j + 2) * stride + (i + 1)] - heights[j * stride + (i + 1)]
			var normal := Vector3(-hx, 2.0 * step, -hz).normalized()
			var index := j * n + i
			vertices[index] = Vector3(i * step, h, j * step)
			normals[index] = normal
			var forest := ForestTerrain.forest_density(x0 + i * step, z0 + j * step, h)
			colors[index] = Color(forest, 0.0, 0.0, 1.0)
	var _unused := normal_step

	var indices := PackedInt32Array()
	for j in GRID:
		for i in GRID:
			var a := j * n + i
			var b := a + 1
			var c := a + n
			var d := c + 1
			indices.push_back(a)
			indices.push_back(b)
			indices.push_back(c)
			indices.push_back(b)
			indices.push_back(d)
			indices.push_back(c)

	# Collision only where bodies could walk: the two finest levels.
	if level <= 1:
		var faces := PackedVector3Array()
		faces.resize(indices.size())
		for k in indices.size():
			faces[k] = vertices[indices[k]]
		result["faces"] = faces

	# Skirts: a strip hanging down from every edge, to hide cracks between leaves of different detail.
	var skirt := maxf(step * 1.3, 2.0)
	var edge: Array[int] = []
	for i in n:
		edge.append(i)
	for j in range(1, n):
		edge.append(j * n + n - 1)
	for i in range(n - 2, -1, -1):
		edge.append((n - 1) * n + i)
	for j in range(n - 2, 0, -1):
		edge.append(j * n)
	var skirt_start := vertices.size()
	for index in edge:
		vertices.push_back(vertices[index] - Vector3(0.0, skirt, 0.0))
		normals.push_back(normals[index])
		colors.push_back(colors[index])
	for k in edge.size():
		var a := edge[k]
		var b := edge[(k + 1) % edge.size()]
		var a2 := skirt_start + k
		var b2 := skirt_start + (k + 1) % edge.size()
		indices.push_back(a)
		indices.push_back(b)
		indices.push_back(a2)
		indices.push_back(b)
		indices.push_back(b2)
		indices.push_back(a2)

	result["vertices"] = vertices
	result["normals"] = normals
	result["colors"] = colors
	result["indices"] = indices


# --- Trees --------------------------------------------------------------------

static func _batch(batches: Dictionary, mesh_name: String) -> Batch:
	if not batches.has(mesh_name):
		batches[mesh_name] = Batch.new()
	return batches[mesh_name]


## Is there a giant within `margin` of this spot (beyond the giant's own trunk radius)?
static func _near_giant(x: float, z: float, margin: float) -> bool:
	var ci := int(floor(x / GIANT_CELL))
	var cj := int(floor(z / GIANT_CELL))
	for j in range(cj - 1, cj + 2):
		for i in range(ci - 1, ci + 2):
			var gx := (i + 0.12 + 0.76 * ForestTerrain.rnd(i, j, 1)) * GIANT_CELL
			var gz := (j + 0.12 + 0.76 * ForestTerrain.rnd(i, j, 2)) * GIANT_CELL
			var dx := gx - x
			var dz := gz - z
			if dx * dx + dz * dz > 100.0:
				continue
			var h := ForestTerrain.height(gx, gz)
			if ForestTerrain.forest_density(gx, gz, h) * 0.9 > ForestTerrain.rnd(i, j, 3):
				var radius := 5.0 * _giant_scale(i, j) + margin
				if dx * dx + dz * dz < radius * radius:
					return true
	return false


## How big the giant in this cell is: its height as a fraction of the base mesh's 140 m.
static func _giant_scale(i: int, j: int) -> float:
	var tall := lerpf(95.0, 172.0, pow(ForestTerrain.rnd(i, j, 4), 1.3))
	return tall / 140.0


static func _scatter_giants(batches: Dictionary, trunks: PackedFloat32Array, x0: float, z0: float, size: float, level: int) -> void:
	var i0 := int(floor(x0 / GIANT_CELL))
	var i1 := int(floor((x0 + size) / GIANT_CELL))
	var j0 := int(floor(z0 / GIANT_CELL))
	var j1 := int(floor((z0 + size) / GIANT_CELL))
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var px := (i + 0.12 + 0.76 * ForestTerrain.rnd(i, j, 1)) * GIANT_CELL
			var pz := (j + 0.12 + 0.76 * ForestTerrain.rnd(i, j, 2)) * GIANT_CELL
			if px < x0 or px >= x0 + size or pz < z0 or pz >= z0 + size:
				continue
			var h := ForestTerrain.height(px, pz)
			if ForestTerrain.forest_density(px, pz, h) * 0.9 <= ForestTerrain.rnd(i, j, 3):
				continue
			if ForestTerrain.slope(px, pz) > 0.3:
				continue
			var sy := _giant_scale(i, j)
			var sw := sy * (0.88 + 0.3 * ForestTerrain.rnd(i, j, 5))
			var yaw := ForestTerrain.rnd(i, j, 6) * TAU
			var shade := 0.88 + 0.24 * ForestTerrain.rnd(i, j, 7)
			var tint := Color(shade, shade, shade, 1.0)
			var mesh_name := "giant_mid"
			if level <= 1:
				mesh_name = "giant_a" if ForestTerrain.rnd(i, j, 8) < 0.5 else "giant_b"
			elif level == 3:
				mesh_name = "giant_low"
			# giant_b is a little shorter than giant_a, so stretch it to match.
			if mesh_name == "giant_b":
				sy *= 140.0 / 120.0
			_batch(batches, mesh_name).add(Vector3(px - x0, h - 0.6, pz - z0), yaw, sw, sy, tint)
			if level <= 1:
				trunks.push_back(px - x0)
				trunks.push_back(pz - z0)
				trunks.push_back(5.8 * sw * 1.05)
				trunks.push_back(140.0 * sy * 0.9)
				trunks.push_back(h)


## Smaller conifers growing in the giants' shade.
static func _scatter_understory(batches: Dictionary, trunks: PackedFloat32Array, x0: float, z0: float, size: float) -> void:
	var cell := UNDER_CELL
	var i0 := int(floor(x0 / cell))
	var i1 := int(floor((x0 + size) / cell))
	var j0 := int(floor(z0 / cell))
	var j1 := int(floor((z0 + size) / cell))
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var px := (i + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 11)) * cell
			var pz := (j + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 12)) * cell
			if px < x0 or px >= x0 + size or pz < z0 or pz >= z0 + size:
				continue
			var h := ForestTerrain.height(px, pz)
			var density := ForestTerrain.forest_density(px, pz, h)
			if density * 0.5 <= ForestTerrain.rnd(i, j, 13):
				continue
			if ForestTerrain.slope(px, pz) > 0.3 or _near_giant(px, pz, 2.5):
				continue
			var tall := lerpf(14.0, 40.0, pow(ForestTerrain.rnd(i, j, 14), 1.4))
			var sy := tall / 34.0
			var sw := sy * (0.85 + 0.3 * ForestTerrain.rnd(i, j, 15))
			var shade := 0.85 + 0.3 * ForestTerrain.rnd(i, j, 16)
			_batch(batches, "under").add(Vector3(px - x0, h - 0.3, pz - z0), ForestTerrain.rnd(i, j, 17) * TAU,
				sw, sy, Color(shade, shade, shade, 1.0))
			trunks.push_back(px - x0)
			trunks.push_back(pz - z0)
			trunks.push_back(0.95 * sw * 1.05)
			trunks.push_back(34.0 * sy * 0.9)
			trunks.push_back(h)


## Sparse little trees for the far forest, so the horizon isn't bare.
static func _scatter_far(batches: Dictionary, x0: float, z0: float, size: float, level: int) -> void:
	var per_side := 24
	if level == 5:
		per_side = 28
	elif level == 6:
		per_side = 34
	var cell := size / per_side
	for j in per_side:
		for i in per_side:
			var gi := int(floor(x0 / cell)) + i
			var gj := int(floor(z0 / cell)) + j
			var px := x0 + (i + 0.1 + 0.8 * ForestTerrain.rnd(gi, gj, 21)) * cell
			var pz := z0 + (j + 0.1 + 0.8 * ForestTerrain.rnd(gi, gj, 22)) * cell
			var h := ForestTerrain.height(px, pz)
			if ForestTerrain.forest_density(px, pz, h) * 0.8 <= ForestTerrain.rnd(gi, gj, 23):
				continue
			var sy := lerpf(95.0, 170.0, ForestTerrain.rnd(gi, gj, 24)) / 140.0
			var shade := 0.85 + 0.3 * ForestTerrain.rnd(gi, gj, 25)
			_batch(batches, "giant_far").add(Vector3(px - x0, h - 1.0, pz - z0), ForestTerrain.rnd(gi, gj, 26) * TAU,
				sy * 1.6, sy, Color(shade, shade, shade, 1.0))


# --- Bushes, ferns, grass and rocks --------------------------------------------

static func _scatter_bushes(batches: Dictionary, x0: float, z0: float, size: float) -> void:
	var cell := BUSH_CELL
	for j in range(int(floor(z0 / cell)), int(floor((z0 + size) / cell)) + 1):
		for i in range(int(floor(x0 / cell)), int(floor((x0 + size) / cell)) + 1):
			var px := (i + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 31)) * cell
			var pz := (j + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 32)) * cell
			if px < x0 or px >= x0 + size or pz < z0 or pz >= z0 + size:
				continue
			var h := ForestTerrain.height(px, pz)
			var density := ForestTerrain.forest_density(px, pz, h)
			# More bushes at the forest's edge and in glades than deep under the giants.
			var chance := 0.16 + 0.34 * (1.0 - absf(density - 0.5) * 2.0)
			if h > ForestTerrain.TREE_LINE_HIGH or chance <= ForestTerrain.rnd(i, j, 33):
				continue
			if ForestTerrain.slope(px, pz) > 0.32:
				continue
			var s := lerpf(0.8, 2.0, ForestTerrain.rnd(i, j, 34))
			var shade := 0.8 + 0.4 * ForestTerrain.rnd(i, j, 35)
			_batch(batches, "bush").add(Vector3(px - x0, h - 0.05, pz - z0), ForestTerrain.rnd(i, j, 36) * TAU,
				s, s * 0.85, Color(shade, shade, shade, 1.0))


static func _scatter_ferns(batches: Dictionary, x0: float, z0: float, size: float) -> void:
	var cell := FERN_CELL
	for j in range(int(floor(z0 / cell)), int(floor((z0 + size) / cell)) + 1):
		for i in range(int(floor(x0 / cell)), int(floor((x0 + size) / cell)) + 1):
			var px := (i + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 41)) * cell
			var pz := (j + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 42)) * cell
			if px < x0 or px >= x0 + size or pz < z0 or pz >= z0 + size:
				continue
			var h := ForestTerrain.height(px, pz)
			var density := ForestTerrain.forest_density(px, pz, h)
			if h > ForestTerrain.TREE_LINE_HIGH or density * 0.8 + 0.05 <= ForestTerrain.rnd(i, j, 43):
				continue
			var s := lerpf(0.7, 1.5, ForestTerrain.rnd(i, j, 44))
			var shade := 0.8 + 0.4 * ForestTerrain.rnd(i, j, 45)
			_batch(batches, "fern").add(Vector3(px - x0, h - 0.02, pz - z0), ForestTerrain.rnd(i, j, 46) * TAU,
				s, s, Color(shade, shade, shade, 1.0))


static func _scatter_grass(batches: Dictionary, x0: float, z0: float, size: float) -> void:
	var cell := GRASS_CELL
	for j in range(int(floor(z0 / cell)), int(floor((z0 + size) / cell)) + 1):
		for i in range(int(floor(x0 / cell)), int(floor((x0 + size) / cell)) + 1):
			var px := (i + 0.05 + 0.9 * ForestTerrain.rnd(i, j, 51)) * cell
			var pz := (j + 0.05 + 0.9 * ForestTerrain.rnd(i, j, 52)) * cell
			if px < x0 or px >= x0 + size or pz < z0 or pz >= z0 + size:
				continue
			var h := ForestTerrain.height(px, pz)
			var density := ForestTerrain.forest_density(px, pz, h)
			# Plenty in meadows, a little between the giants.
			var chance := clampf(1.0 - density * 0.9, 0.08, 1.0)
			if h > ForestTerrain.TREE_LINE_HIGH + 40.0 or chance <= ForestTerrain.rnd(i, j, 53):
				continue
			var s := lerpf(0.8, 1.5, ForestTerrain.rnd(i, j, 54))
			var shade := 0.85 + 0.3 * ForestTerrain.rnd(i, j, 55)
			_batch(batches, "grass").add(Vector3(px - x0, h - 0.03, pz - z0), ForestTerrain.rnd(i, j, 56) * TAU,
				s * 1.3, s, Color(shade, shade, shade, 1.0))


static func _scatter_rocks(batches: Dictionary, x0: float, z0: float, size: float, cell: float, min_size: float, max_size: float, base_chance: float) -> void:
	for j in range(int(floor(z0 / cell)), int(floor((z0 + size) / cell)) + 1):
		for i in range(int(floor(x0 / cell)), int(floor((x0 + size) / cell)) + 1):
			var px := (i + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 61)) * cell
			var pz := (j + 0.1 + 0.8 * ForestTerrain.rnd(i, j, 62)) * cell
			if px < x0 or px >= x0 + size or pz < z0 or pz >= z0 + size:
				continue
			var h := ForestTerrain.height(px, pz)
			var chance := base_chance + 0.9 * ForestTerrain.slope(px, pz) + 0.3 * maxf(ForestTerrain.rock_noise(px, pz) - 0.62, 0.0)
			if chance <= ForestTerrain.rnd(i, j, 63):
				continue
			var s := lerpf(min_size, max_size, pow(ForestTerrain.rnd(i, j, 64), 2.0))
			var shade := 0.85 + 0.3 * ForestTerrain.rnd(i, j, 65)
			var mesh_name := "rock_a" if ForestTerrain.rnd(i, j, 66) < 0.5 else "rock_b"
			_batch(batches, mesh_name).add(Vector3(px - x0, h - s * 0.25, pz - z0), ForestTerrain.rnd(i, j, 67) * TAU,
				s * (0.8 + 0.5 * ForestTerrain.rnd(i, j, 68)), s * (0.6 + 0.5 * ForestTerrain.rnd(i, j, 69)),
				Color(shade, shade, shade, 1.0))
