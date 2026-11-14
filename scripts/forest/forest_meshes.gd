class_name ForestMeshes
extends RefCounted
## Builds every tree, bush, fern, grass tuft and rock mesh used by the giant forest, and the materials
## they share. Everything is made from code (no imported art), with a few levels of detail for trees.
##
## Tree meshes are named:
##   giant_a, giant_b  - redwood giants, full detail (two shapes)
##   giant_mid         - the same, simplified for medium distance
##   giant_low         - very simple, for long distance
##   giant_far         - tiny, for the far forest
##   under             - a smaller conifer growing in the giants' shade
##   bush, fern, grass, rock_a, rock_b

const BARK_LOW := Color(0.62, 0.52, 0.48)
## Colors are written the way they should look on screen, and converted to the engine's linear light.
const FROND_BASE := Color(0.10, 0.24, 0.10)
const FROND_TIP := Color(0.30, 0.44, 0.15)

var meshes := {}
var terrain_material: ShaderMaterial
var bark_material: ShaderMaterial
var foliage_material: ShaderMaterial
var grass_material: ShaderMaterial
var rock_material: ShaderMaterial
var noise_texture: ImageTexture


func _init() -> void:
	_build_noise_texture()
	terrain_material = _material("res://shaders/forest_terrain.gdshader")
	bark_material = _material("res://shaders/forest_bark.gdshader")
	foliage_material = _material("res://shaders/forest_foliage.gdshader")
	grass_material = _material("res://shaders/forest_grass.gdshader")
	rock_material = _material("res://shaders/forest_rock.gdshader")

	meshes["giant_a"] = _conifer(11, 140.0, 5.8, 0.40, 17, 12, 1.0)
	meshes["giant_b"] = _conifer(23, 120.0, 5.2, 0.48, 15, 12, 1.0)
	meshes["giant_mid"] = _conifer_lod(140.0, 5.8, 0.40, 5, 8, 6)
	meshes["giant_low"] = _conifer_lod(140.0, 5.8, 0.40, 4, 6, 4)
	meshes["giant_far"] = _conifer_lod(140.0, 5.8, 0.40, 2, 5, 3)
	meshes["under"] = _conifer(37, 34.0, 0.95, 0.16, 9, 8, 0.85)
	meshes["bush"] = _plant(41, 9, 1.5, 0.95, 0.55, 0.45, Color(0.10, 0.22, 0.08), Color(0.30, 0.40, 0.12))
	meshes["fern"] = _plant(43, 12, 1.25, 0.34, 0.95, 0.85, Color(0.16, 0.30, 0.09), Color(0.42, 0.55, 0.20))
	meshes["grass"] = _grass()
	meshes["rock_a"] = _rock(51, 1.0)
	meshes["rock_b"] = _rock(77, 0.8)


func _material(path: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(path)
	material.set_shader_parameter("noise_tex", noise_texture)
	return material


func _build_noise_texture() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 99
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	var image := noise.get_seamless_image(512, 512)
	image.generate_mipmaps()
	noise_texture = ImageTexture.create_from_image(image)


# --- A tiny mesh-building helper ----------------------------------------------

class Builder:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	func vertex(position: Vector3, normal: Vector3, color: Color, uv := Vector2.ZERO) -> int:
		vertices.push_back(position)
		normals.push_back(normal)
		colors.push_back(color)
		uvs.push_back(uv)
		return vertices.size() - 1

	func triangle(a: int, b: int, c: int) -> void:
		indices.push_back(a)
		indices.push_back(b)
		indices.push_back(c)

	func quad(a: int, b: int, c: int, d: int) -> void:
		triangle(a, b, c)
		triangle(a, c, d)

	func add_to(mesh: ArrayMesh, material: Material) -> void:
		if vertices.is_empty():
			return
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, material)


# --- Conifers -----------------------------------------------------------------

## The trunk's radius at a given height: tapering, with a flared, buttressed foot.
static func _trunk_radius(base: float, height: float, y: float) -> float:
	var t := clampf(y / height, 0.0, 1.0)
	var r := base * lerpf(1.0, 0.16, pow(t, 0.75))
	r += base * 0.75 * exp(-y / 3.2)
	return r


func _add_trunk(b: Builder, base: float, height: float, sides: int, rings: int, top_fraction := 1.0) -> void:
	var rows := []
	for k in rings + 1:
		var t := pow(float(k) / rings, 1.5) * top_fraction
		var y := height * t
		var r := _trunk_radius(base, height, y)
		var row := []
		for i in sides + 1:
			var a := float(i) / sides * TAU
			# Gentle lobes, like fluted redwood trunks.
			var lobe := 1.0 + 0.045 * sin(a * 7.0 + y * 0.02)
			var dir := Vector3(cos(a), 0.0, sin(a))
			var shade := lerpf(0.55, 1.0, smoothstep(0.0, 14.0, y))
			var wind := pow(y / height, 2.0)
			row.append(b.vertex(
				dir * r * lobe + Vector3(0.0, y, 0.0), Vector3(dir.x, 0.12, dir.z).normalized(),
				Color(shade, shade, shade, wind), Vector2(float(i) / sides, y)
			))
		rows.append(row)
	for k in rings:
		for i in sides:
			b.quad(rows[k][i], rows[k][i + 1], rows[k + 1][i + 1], rows[k + 1][i])


## One drooping branch, as a curved strip of four cards. `elevation` raises its direction (radians).
func _add_frond(
	b: Builder, origin: Vector3, yaw: float, elevation: float, length: float, width: float,
	droop: float, base_color: Color, tip_color: Color, roll: float, wind: float
) -> void:
	var horizontal := Vector3(cos(yaw), 0.0, sin(yaw))
	var direction := horizontal * cos(elevation) + Vector3.UP * sin(elevation)
	var side := Vector3(-sin(yaw), 0.0, cos(yaw)).rotated(direction, roll)
	var outward_normal := (horizontal * 0.55 + Vector3.UP * 0.85).normalized()
	var previous_left := -1
	var previous_right := -1
	for s in 5:
		var u := s / 4.0
		var p := origin + direction * length * u + Vector3.DOWN * length * droop * u * u
		var half := width * 0.5 * (1.0 - 0.2 * u)
		var color := base_color.lerp(tip_color, u).srgb_to_linear()
		color.a = wind * u
		var left := b.vertex(p - side * half, outward_normal, color, Vector2(u, -1.0))
		var right := b.vertex(p + side * half, outward_normal, color, Vector2(u, 1.0))
		if previous_left >= 0:
			b.quad(previous_left, previous_right, right, left)
		previous_left = left
		previous_right = right


## A full conifer: trunk, bare lower trunk, then tiers of drooping branches up to a pointed top.
func _conifer(
	seed_value: int, height: float, trunk_base: float, crown_start: float,
	tiers: int, trunk_sides: int, spread: float
) -> ArrayMesh:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var bark := Builder.new()
	var leaves := Builder.new()
	_add_trunk(bark, trunk_base, height, trunk_sides, 14)

	var max_reach := height * 0.115 * spread
	for k in tiers:
		var t := float(k) / (tiers - 1)
		var y := lerpf(crown_start * height, height * 0.965, t)
		var reach := max_reach * pow(1.0 - t, 0.85) + height * 0.012
		var count := int(lerpf(10.0, 4.0, t))
		var trunk_r := _trunk_radius(trunk_base, height, y)
		for i in count:
			var yaw := k * 2.4 + float(i) / count * TAU + random.randf_range(-0.2, 0.2)
			var length := reach * random.randf_range(0.8, 1.15)
			var origin := Vector3(cos(yaw) * trunk_r * 0.8, y + random.randf_range(-1.0, 1.0) * height * 0.01, sin(yaw) * trunk_r * 0.8)
			# Lower branches are older: browner and drooping more.
			var old := 1.0 - t
			var base_c := FROND_BASE.lerp(Color(0.20, 0.17, 0.07), old * 0.35)
			var tip_c := FROND_TIP.lerp(Color(0.34, 0.36, 0.14), old * 0.3)
			_add_frond(leaves, origin, yaw, random.randf_range(-0.05, 0.25), length, length * 0.5,
				lerpf(0.55, 0.3, t), base_c, tip_c, random.randf_range(-0.5, 0.5), 1.0)
	# The pointed top.
	for i in 5:
		_add_frond(leaves, Vector3(0.0, height * 0.93, 0.0), i / 5.0 * TAU, 1.0, height * 0.07, height * 0.03,
			0.1, FROND_BASE, FROND_TIP, 0.0, 1.0)

	var mesh := ArrayMesh.new()
	bark.add_to(mesh, bark_material)
	leaves.add_to(mesh, foliage_material)
	return mesh


## A simple conifer for distance: a rough trunk and a few stacked, jagged skirts of branches.
func _conifer_lod(height: float, trunk_base: float, crown_start: float, tiers: int, sides: int, trunk_sides: int) -> ArrayMesh:
	var bark := Builder.new()
	var leaves := Builder.new()
	_add_trunk(bark, trunk_base, height, trunk_sides, 3, 0.92)
	var max_reach := height * 0.12
	for k in tiers:
		var t := float(k) / maxf(tiers - 1, 1)
		var top_y := lerpf(crown_start * height + height * 0.22, height, t)
		var base_y := lerpf(crown_start * height, height * 0.78, t)
		var reach := max_reach * pow(1.0 - t, 0.8) + height * 0.015
		var color := FROND_BASE.lerp(FROND_TIP, 0.25 + t * 0.4).srgb_to_linear()
		var apex := leaves.vertex(Vector3(0.0, top_y, 0.0), Vector3.UP, color.lightened(0.1), Vector2.ZERO)
		var ring := []
		for i in sides:
			var a := float(i) / sides * TAU
			var jag := 1.0 if i % 2 == 0 else 0.7
			var dir := Vector3(cos(a), 0.0, sin(a))
			var drop := reach * 0.18 if i % 2 == 0 else 0.0
			var normal := (dir * 0.7 + Vector3.UP * 0.7).normalized()
			ring.append(leaves.vertex(dir * reach * jag + Vector3(0.0, base_y - drop, 0.0), normal, color.darkened(0.15), Vector2.ZERO))
		for i in sides:
			leaves.triangle(apex, ring[i], ring[(i + 1) % sides])
	var mesh := ArrayMesh.new()
	bark.add_to(mesh, bark_material)
	leaves.add_to(mesh, foliage_material)
	return mesh


# --- Bushes and ferns ----------------------------------------------------------

## A clump of arching fronds from one point: used for bushes and sword ferns.
func _plant(
	seed_value: int, count: int, length: float, width: float, elevation: float, droop: float,
	base_color: Color, tip_color: Color
) -> ArrayMesh:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var b := Builder.new()
	for i in count:
		var yaw := float(i) / count * TAU + random.randf_range(-0.3, 0.3)
		var l := length * random.randf_range(0.75, 1.15)
		_add_frond(b, Vector3(0.0, 0.05, 0.0), yaw, elevation * random.randf_range(0.7, 1.2), l, width * l / length * 1.3,
			droop, base_color, tip_color, random.randf_range(-0.4, 0.4), 0.7)
	var mesh := ArrayMesh.new()
	b.add_to(mesh, foliage_material)
	return mesh


## A tuft of grass: three crossed cards that the shader cuts into blades.
func _grass() -> ArrayMesh:
	var b := Builder.new()
	for i in 3:
		var a := i / 3.0 * PI
		var dir := Vector3(cos(a), 0.0, sin(a)) * 0.5
		var tall := 0.75
		var c := Color.WHITE
		var v0 := b.vertex(-dir, Vector3.UP, c, Vector2(0.0, 0.0))
		var v1 := b.vertex(dir, Vector3.UP, c, Vector2(1.0, 0.0))
		var v2 := b.vertex(dir + Vector3.UP * tall, Vector3.UP, c, Vector2(1.0, 1.0))
		var v3 := b.vertex(-dir + Vector3.UP * tall, Vector3.UP, c, Vector2(0.0, 1.0))
		b.quad(v0, v1, v2, v3)
	var mesh := ArrayMesh.new()
	b.add_to(mesh, grass_material)
	return mesh


# --- Rocks --------------------------------------------------------------------

## A lumpy boulder: a squashed icosphere with its points pushed about, shaded flat.
func _rock(seed_value: int, squash: float) -> ArrayMesh:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var base: Array[Vector3] = [
		Vector3(-1, phi, 0), Vector3(1, phi, 0), Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi), Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 1), Vector3(-phi, 0, -1), Vector3(-phi, 0, 1),
	]
	var faces := [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2],
		[10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5],
		[2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]
	var points: Array[Vector3] = []
	for p in base:
		var q := p.normalized() * random.randf_range(0.82, 1.12)
		q.y *= squash * 0.75
		if q.y < -0.35:
			q.y = -0.35
		points.append(q)
	var b := Builder.new()
	for f in faces:
		# Split each face into four for more lumps.
		var a: Vector3 = points[f[0]]
		var bb: Vector3 = points[f[1]]
		var c: Vector3 = points[f[2]]
		var ab := ((a + bb) * 0.5).normalized() * random.randf_range(0.85, 1.05) * ((a + bb) * 0.5).length()
		var bc := ((bb + c) * 0.5).normalized() * random.randf_range(0.85, 1.05) * ((bb + c) * 0.5).length()
		var ca := ((c + a) * 0.5).normalized() * random.randf_range(0.85, 1.05) * ((c + a) * 0.5).length()
		for tri: Array in [[a, ab, ca], [ab, bb, bc], [ca, bc, c], [ab, bc, ca]]:
			var normal: Vector3 = ((tri[1] - tri[0]) as Vector3).cross(tri[2] - tri[0]).normalized()
			if normal.dot(tri[0] + tri[1] + tri[2]) < 0.0:
				normal = -normal
			var shade := random.randf_range(0.9, 1.1)
			var i0 := b.vertex(tri[0], normal, Color(shade, shade, shade))
			var i1 := b.vertex(tri[1], normal, Color(shade, shade, shade))
			var i2 := b.vertex(tri[2], normal, Color(shade, shade, shade))
			b.triangle(i0, i1, i2)
	var mesh := ArrayMesh.new()
	b.add_to(mesh, rock_material)
	return mesh
