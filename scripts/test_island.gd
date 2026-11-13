extends Node3D
## A greybox test island for trying out movement: sky, sun, sea, beach, hills, rocks and giant trees.
## Everything is built from simple shapes. Real art comes much later.

const SEED := 2026
const ISLAND_TOP := 1.5
const SEA_LEVEL := 0.0
## Where the stone-weight puzzle (hut, gate and pressure plate) stands.
const WEIGHT_PUZZLE := Vector3(-22.0, ISLAND_TOP, 38.0)

const GRASS := Color(0.42, 0.56, 0.30)
const SAND := Color(0.86, 0.78, 0.58)
const ROCK := Color(0.52, 0.50, 0.48)
const BARK := Color(0.40, 0.29, 0.20)
const LEAVES := Color(0.22, 0.40, 0.22)
const LEAVES_LIGHT := Color(0.32, 0.50, 0.26)
const SEABED := Color(0.55, 0.52, 0.42)
const WATER := Color(0.16, 0.42, 0.58, 0.78)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = SEED
	_build_environment()
	_build_ground()
	_build_hills()
	_build_giant_trees()
	_build_rocks()
	_build_statues()
	_build_weight_puzzle()
	_build_controls_hint()


# --- Stone-weight puzzle -----------------------------------------------------

## A small stone hut with a spirit shrine inside, shut by a gate. A pressure plate in front opens
## the gate while something heavy rests on it: a body (alive or stone) or a boulder.
## The wisp weighs nothing. Solutions: leave a body on the plate as stone and float in as the wisp,
## or, as the Tar'ye, shove the nearby boulder onto the plate and walk in.
func _build_weight_puzzle() -> void:
	var c := WEIGHT_PUZZLE
	var stone := ROCK.darkened(0.25)
	var half := 3.0       # Half the hut's width.
	var height := 3.2
	var wall := 0.4

	var back := BoxMesh.new()
	back.size = Vector3(half * 2.0, height, wall)
	_add_solid(back, c + Vector3(0.0, height * 0.5, -half), Vector3.ZERO, stone)
	for side in [-1.0, 1.0]:
		var side_wall := BoxMesh.new()
		side_wall.size = Vector3(wall, height, half * 2.0)
		_add_solid(side_wall, c + Vector3(half * side, height * 0.5, 0.0), Vector3.ZERO, stone)
		# The front wall, either side of a 2 m doorway.
		var front := BoxMesh.new()
		front.size = Vector3(half - 1.0, height, wall)
		_add_solid(front, c + Vector3((1.0 + (half - 1.0) * 0.5) * side, height * 0.5, half), Vector3.ZERO, stone)
	var roof := BoxMesh.new()
	roof.size = Vector3(half * 2.0 + 0.8, 0.5, half * 2.0 + 0.8)
	_add_solid(roof, c + Vector3(0.0, height + 0.25, 0.0), Vector3.ZERO, stone)

	var gate := StoneGate.new()
	gate.size = Vector3(2.0, height, wall * 0.9)
	gate.position = c + Vector3(0.0, height * 0.5, half)
	add_child(gate)

	var plate := PressurePlate.new()
	plate.position = c + Vector3(0.0, 0.0, half + 4.5)
	add_child(plate)
	plate.changed.connect(gate.set_open)

	var shrine := SpiritShrine.new()
	shrine.position = c + Vector3(0.0, 0.0, -1.2)
	add_child(shrine)

	# A boulder nearby, for the Tar'ye way of solving it.
	_add_boulder(c + Vector3(6.0, 1.2, half + 6.0), 1.1)


# --- Sky, sun and atmosphere -------------------------------------------------

func _build_environment() -> void:
	# (The sky itself, with sun, moon and stars, is set up by the Atmosphere below.)
	var environment := Environment.new()
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.9
	environment.ssao_enabled = true
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.72, 0.80, 0.90)
	environment.fog_density = 0.0012
	environment.fog_sky_affect = 0.3

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	# Sun, moon and the day-night cycle, blended with the wisp's spirit view and underwater.
	var atmosphere := Atmosphere.new()
	atmosphere.name = "Atmosphere"
	atmosphere.environment = environment
	atmosphere.sea_level = SEA_LEVEL
	add_child(atmosphere)
	var player: PlayerController = $PlayerController
	player.form_changed.connect(func(in_body: bool) -> void: atmosphere.set_spirit(not in_body))


# --- Sea, seabed, beach and grass --------------------------------------------

func _build_ground() -> void:
	# Seabed, so there's something solid below the water.
	var seabed := BoxMesh.new()
	seabed.size = Vector3(800.0, 2.0, 800.0)
	_add_solid(seabed, Vector3(0.0, -9.0, 0.0), Vector3.ZERO, SEABED)

	# Beach: a wide, gently sloped ring of sand.
	var beach := CylinderMesh.new()
	beach.top_radius = 62.0
	beach.bottom_radius = 85.0
	beach.height = 9.0
	beach.radial_segments = 28
	_add_solid(beach, Vector3(0.0, 0.6 - 4.5, 0.0), Vector3.ZERO, SAND)

	# Grassy island top.
	var island := CylinderMesh.new()
	island.top_radius = 54.0
	island.bottom_radius = 60.0
	island.height = 9.0
	island.radial_segments = 24
	_add_solid(island, Vector3(0.0, ISLAND_TOP - 4.5, 0.0), Vector3.ZERO, GRASS)

	# Sea surface (visual only for now; swimming comes later).
	var sea := PlaneMesh.new()
	sea.size = Vector2(800.0, 800.0)
	var sea_material := _material(WATER)
	sea_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sea_material.roughness = 0.15
	sea_material.metallic_specular = 0.8
	# Draw both sides, so the surface can be seen from underwater too.
	sea_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sea.material = sea_material
	var sea_instance := MeshInstance3D.new()
	sea_instance.name = "Sea"
	sea_instance.mesh = sea
	sea_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea_instance)


# --- Hills -------------------------------------------------------------------

func _build_hills() -> void:
	var hills := [
		[Vector3(-22.0, ISLAND_TOP - 3.0, -18.0), 16.0, 14.0],
		[Vector3(18.0, ISLAND_TOP - 2.0, -28.0), 12.0, 10.0],
		[Vector3(30.0, ISLAND_TOP - 4.0, 8.0), 14.0, 12.0],
	]
	for hill: Array in hills:
		var mesh := SphereMesh.new()
		mesh.radius = hill[1]
		mesh.height = hill[2]
		mesh.radial_segments = 14
		mesh.rings = 7
		_add_solid(mesh, hill[0], Vector3(0.0, _rng.randf_range(0.0, TAU), 0.0), GRASS.darkened(0.06))


# --- Giant trees -------------------------------------------------------------

func _build_giant_trees() -> void:
	var placed := 0
	var attempts := 0
	var positions: Array[Vector3] = []
	while placed < 9 and attempts < 200:
		attempts += 1
		# Trees grow on the far (north-west) half, leaving the south beach open for the start.
		var angle := _rng.randf_range(PI * 0.55, PI * 1.6)
		var distance := _rng.randf_range(8.0, 44.0)
		var spot := Vector3(cos(angle) * distance, ISLAND_TOP, -absf(sin(angle)) * distance)
		var too_close := false
		for other in positions:
			if other.distance_to(spot) < 15.0:
				too_close = true
				break
		if too_close:
			continue
		positions.append(spot)
		_build_tree(spot, _rng.randf_range(0.8, 1.25))
		placed += 1


func _build_tree(base: Vector3, size: float) -> void:
	var trunk_height := 30.0 * size
	var trunk := CylinderMesh.new()
	trunk.top_radius = 1.1 * size
	trunk.bottom_radius = 2.1 * size
	trunk.height = trunk_height
	trunk.radial_segments = 8
	_add_solid(trunk, base + Vector3(0.0, trunk_height * 0.5, 0.0), Vector3(0.0, _rng.randf_range(0.0, TAU), 0.0), BARK)

	# A few overlapping blobs of canopy.
	for i in 3:
		var canopy := SphereMesh.new()
		canopy.radius = _rng.randf_range(6.5, 9.0) * size
		canopy.height = canopy.radius * 1.3
		canopy.radial_segments = 9
		canopy.rings = 5
		var offset := Vector3(_rng.randf_range(-4.0, 4.0), trunk_height + _rng.randf_range(-3.0, 3.0), _rng.randf_range(-4.0, 4.0)) * Vector3(size, 1.0, size)
		var color := LEAVES if i % 2 == 0 else LEAVES_LIGHT
		_add_solid(canopy, base + offset, Vector3(0.0, _rng.randf_range(0.0, TAU), 0.0), color)


# --- Rocks -------------------------------------------------------------------

func _build_rocks() -> void:
	for i in 26:
		var angle := _rng.randf_range(0.0, TAU)
		var distance := _rng.randf_range(10.0, 66.0)
		var radius := _rng.randf_range(0.6, 2.6)
		var rock := SphereMesh.new()
		rock.radius = radius
		rock.height = radius * _rng.randf_range(1.0, 1.6)
		rock.radial_segments = 6
		rock.rings = 3
		var ground := ISLAND_TOP if distance < 54.0 else 0.4
		var spot := Vector3(cos(angle) * distance, ground + radius * 0.3, sin(angle) * distance)
		var tilt := Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.3, 0.3))
		var shade := _rng.randf_range(-0.08, 0.08)
		# Keep the puzzle area clear.
		if Vector2(spot.x - WEIGHT_PUZZLE.x, spot.z - WEIGHT_PUZZLE.z).length() < 10.0:
			continue
		_add_solid(rock, spot, tilt, ROCK.lightened(shade), radius < 1.3)


# --- Statues -----------------------------------------------------------------

func _build_statues() -> void:
	# On the beach right by the start: a Human and a Tar'ye, with a heavy boulder between them.
	# Only the Tar'ye is strong enough to push it.
	_build_statue(Vector3(4.0, 0.6, 57.0), 180.0)
	_build_statue(Vector3(-4.0, 0.6, 57.0), 180.0, "Tar'ye")
	_add_boulder(Vector3(0.0, 0.6 + 1.15, 58.0), 1.3)
	_add_boulder(Vector3(9.0, ISLAND_TOP + 1.4, 46.0), 1.6)

	# One up on the grass near the forest, possessed by a darkling. In spirit view it burns
	# with black fire; only the wisp's shine can drive the darkling out.
	var haunted := _build_statue(Vector3(-12.0, ISLAND_TOP, 30.0), 160.0)
	var possessor := Darkling.new()
	possessor.possess_host = haunted
	possessor.position = haunted.get_core_position()
	add_child(possessor)

	# Where you fight stubborn darklings for a possessed heart (built far off, out of sight).
	add_child(HeartChase.new())

	# A couple more drifting about the forest, just haunting the place.
	_add_darkling(Vector3(-25.0, 6.0, -10.0))
	_add_darkling(Vector3(10.0, 5.0, -30.0))


func _add_boulder(at: Vector3, radius: float) -> Boulder:
	var boulder := Boulder.new()
	boulder.radius = radius
	boulder.position = at
	add_child(boulder)
	return boulder


func _add_darkling(at: Vector3) -> Darkling:
	var darkling := Darkling.new()
	darkling.position = at
	add_child(darkling)
	return darkling


func _build_statue(ground: Vector3, facing_degrees: float, species := "Human") -> FormBody:
	var plinth := CylinderMesh.new()
	plinth.top_radius = 0.7
	plinth.bottom_radius = 0.8
	plinth.height = 0.5
	plinth.radial_segments = 8
	_add_solid(plinth, ground + Vector3(0.0, 0.25, 0.0), Vector3.ZERO, ROCK.darkened(0.1), true)

	var statue := FormBody.new()
	statue.species = species
	statue.sea_level = SEA_LEVEL
	statue.facing_degrees = facing_degrees
	statue.position = ground + Vector3(0.0, 0.5, 0.0)
	add_child(statue)
	return statue


# --- On-screen controls hint --------------------------------------------------

func _build_controls_hint() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "WASD move  ·  Double-tap W dash/run  ·  Space rise/jump/swim up  ·  Shift sink/dive  ·  Tab enter/leave body  ·  Esc free mouse\nWisp: hold Left Mouse to shine, Right Mouse to draw light  ·  Body: Right Mouse to push"
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.75))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.position = Vector2(16.0, 16.0)
	layer.add_child(label)


# --- Helpers -----------------------------------------------------------------

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


## Adds a static, solid object made from a simple mesh, with matching collision.
## `thin` objects (small rocks, plinths) still block movement, but the camera passes through them
## instead of snapping in close.
func _add_solid(mesh: PrimitiveMesh, at: Vector3, rotation_radians: Vector3, color: Color, thin := false) -> StaticBody3D:
	mesh.material = _material(color)

	var body := StaticBody3D.new()
	body.position = at
	body.rotation = rotation_radians
	if thin:
		body.collision_layer = Layers.THIN
	add_child(body)

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	body.add_child(visual)

	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_convex_shape()
	body.add_child(collision)
	return body
