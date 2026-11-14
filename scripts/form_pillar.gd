class_name FormPillar
extends Node3D
## A ruined stone obelisk where the wisp can change form. Come close as the wisp and press Right Mouse
## to open the form wheel (see FormWheel). It is also a save point: if a body drowns, crashes or dies,
## the wisp wakes up here, at the last pillar it used.
##
## It stands about 2.1 m (7 feet) tall, square, tapering a little, broken off at an angle at the top,
## with a worn glyph (a ring around a diamond) on its front face. That glyph means "change form";
## it's meant to be reused on anything else that offers forms.
##
## Its front faces local +Z. The look is in forest_pillar.gdshader.

const HEIGHT := 2.15
const HALF := 0.4
const SIDES := 5          # points along each side of the square
const LEVELS := 12        # rings up the stone
const SPAWN_DISTANCE := 1.9

## Rubble and moss at the foot come from the forest's own meshes.
var kit: ForestMeshes
## What the bodies made here need to know about the world's water and ground.
var sea_level := 0.0
var water_area := Callable()
var ground_at := Callable()

var _noise := FastNoiseLite.new()


func _ready() -> void:
	add_to_group("form_pillars")
	_noise.seed = 31
	_noise.frequency = 1.0
	_build_stone()
	_build_collision()
	_build_rubble()


## Where the wisp wakes up after a body is lost: in front of the pillar, just above the ground.
func respawn_position() -> Vector3:
	return global_position + global_basis.z * 1.1 + Vector3.UP * 1.4


## Makes a new body of this species standing in front of the pillar. (The caller enters it.)
func spawn_form(species: String) -> FormBody:
	var at := global_position + global_basis.z * SPAWN_DISTANCE
	var ground := at.y
	if ground_at.is_valid():
		ground = ground_at.call(at.x, at.z)
	var body := FormBody.new()
	body.species = species
	body.sea_level = sea_level
	body.water_area = water_area
	# Face away from the pillar (0 degrees faces north, 180 south).
	var outward := global_basis.z
	body.facing_degrees = rad_to_deg(atan2(-outward.x, -outward.z))
	body.position = Vector3(at.x, ground + 0.3, at.z)
	body.add_to_group("pillar_forms")
	get_parent().add_child(body)
	return body


# --- The stone -----------------------------------------------------------------

## The point on the square's outline for ring point `k` (0 to 4*SIDES-1), going round from the front.
func _outline(k: int) -> Vector2:
	var side := (k / SIDES) % 4
	var t := float(k % SIDES) / SIDES
	match side:
		0: return Vector2(lerpf(-HALF, HALF, t), HALF)
		1: return Vector2(HALF, lerpf(HALF, -HALF, t))
		2: return Vector2(lerpf(HALF, -HALF, t), -HALF)
		_: return Vector2(-HALF, lerpf(-HALF, HALF, t))


func _build_stone() -> void:
	var count := SIDES * 4
	# Where the stone broke off at the top: a slanted, uneven fracture, with one corner chipped away.
	var top := PackedFloat32Array()
	for k in count:
		var p := _outline(k)
		var broken := HEIGHT + 0.42 * (p.x / HALF) - 0.22 * (p.y / HALF) + _noise.get_noise_2d(k * 0.9, 40.0) * 0.16
		if k >= SIDES + 1 and k <= SIDES + 4:
			broken -= 0.55
		if k >= 2 * SIDES + 2 and k <= 2 * SIDES + 3:
			broken -= 0.25
		top.push_back(broken)

	var grid := []
	for j in LEVELS + 1:
		var row := []
		var f := float(j) / LEVELS
		for k in count:
			var p := _outline(k)
			var y := top[k] * f
			var taper := 1.0 - 0.16 * (y / HEIGHT)
			# Chipped edges and uneven faces, more toward the top.
			var corner := 1.6 if k % SIDES == 0 else 1.0
			var chip := _noise.get_noise_2d(k * 0.8, j * 0.6) * (0.02 + 0.13 * smoothstep(0.35, 1.0, f)) * corner
			var bulge := _noise.get_noise_2d(k * 0.3 + 11.0, j * 0.25) * 0.035
			var out := p.normalized() * (chip + bulge)
			row.append(Vector3(p.x * taper + out.x, y - 0.12, p.y * taper + out.y))
		grid.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in LEVELS:
		for k in count:
			var k2 := (k + 1) % count
			var a: Vector3 = grid[j][k]
			var b: Vector3 = grid[j + 1][k]
			var c: Vector3 = grid[j + 1][k2]
			var d: Vector3 = grid[j][k2]
			for v in [a, b, c, a, c, d]:
				st.add_vertex(v)
	# The broken top.
	var center := Vector3.ZERO
	for k in count:
		center += grid[LEVELS][k]
	center /= count
	center.y -= 0.05
	for k in count:
		st.add_vertex(center)
		st.add_vertex(grid[LEVELS][(k + 1) % count])
		st.add_vertex(grid[LEVELS][k])
	st.generate_normals()  # Not smoothed, so each facet stays a hard edge, like split stone.

	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/forest_pillar.gdshader")
	material.set_shader_parameter("noise_tex", kit.noise_texture)
	material.set_shader_parameter("glyph_tex", load("res://assets/symbols/form_glyph.png"))
	var instance := MeshInstance3D.new()
	instance.name = "Stone"
	instance.mesh = st.commit()
	instance.material_override = material
	add_child(instance)


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALF * 1.7, HEIGHT - 0.1, HALF * 1.7)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0.0, HEIGHT * 0.5 - 0.1, 0.0)
	body.add_child(collision)
	add_child(body)


## Fallen chips of stone and a few ferns and grass tufts around the foot.
func _build_rubble() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 77
	for i in 7:
		var angle := random.randf() * TAU
		var distance := random.randf_range(0.55, 1.5)
		var rock := MeshInstance3D.new()
		rock.mesh = kit.meshes["rock_a" if i % 2 == 0 else "rock_b"]
		var s := random.randf_range(0.12, 0.34)
		rock.scale = Vector3(s * random.randf_range(0.9, 1.5), s * random.randf_range(0.6, 1.0), s * random.randf_range(0.9, 1.5))
		rock.rotation.y = random.randf() * TAU
		rock.position = Vector3(cos(angle) * distance, s * 0.05 - 0.04, sin(angle) * distance)
		add_child(rock)
	for i in 5:
		var angle := random.randf() * TAU
		var distance := random.randf_range(0.5, 1.2)
		var plant := MeshInstance3D.new()
		plant.mesh = kit.meshes["fern" if i < 2 else "grass"]
		plant.scale = Vector3.ONE * random.randf_range(0.5, 0.9)
		plant.rotation.y = random.randf() * TAU
		plant.position = Vector3(cos(angle) * distance, -0.02, sin(angle) * distance)
		add_child(plant)
