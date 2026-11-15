class_name RegionWorld
extends Node3D
## The first region, as a grey-box: a mostly round basin about 2.9 km across, with every important place
## marked, roads between them, a deep lake, a mesa with flowers on top, and caves you can walk into
## with no loading (see RegionCaves). All grey; markers are plain boxes with name tags.
##
## Keys:  1-5 fly faster    M map (click to fly there)    V daylight preview    [ ] hour    H hide text
## As the wisp, go to a stone pillar and press Right Mouse to pick a form. (Qoi-Kash can dive the
## drowned tunnel from the lake to the village cavern; the others will drown.)

const START_HOUR := 10.0
const WISP_CEILING := 520.0
const SPEEDS: Array[float] = [1.0, 3.0, 8.0, 20.0, 50.0]
const MAP_RADIUS := 1400.0
const MAP_SIZE := 512
const FOG_DENSITY := 0.0004
const FEET := 3.28084
const MAX_TASKS := 4
const PER_FRAME := 2

var atmosphere: Atmosphere
var kit: ForestMeshes

var _wisp: Wisp
var _rig: CameraRig
var _player: PlayerController
var _base_speed := 7.0
var _base_dash := 10.5
var _base_vertical := 4.5
var _speed_index := 0
var _day_preview := false
var _timelapse := false

var _ground_material: ShaderMaterial
var _tags: PlaceTags
var _queue: Array = []
var _results: Array = []
var _mutex := Mutex.new()
var _running := 0
var _total := 0
var _done := 0
var _cave_amount := 0.0
var _lines_on := false
var _started_ms := 0
var _reported := false

var _places: Array = []     # [name, Vector3] for the "nearest" readout and the map
var _hud: Label
var _help: Label
var _hud_timer := 0.0
var _loading: Label
var _map_root: Control
var _map_rect: TextureRect
var _map_marker: ColorRect
var _map_image: Image
var _map_task := -1
var _map_open := false
var _marker_material: StandardMaterial3D
var _dark_material: StandardMaterial3D


func _ready() -> void:
	process_physics_priority = 100
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	RegionTerrain.setup()
	RegionCaves.setup()
	kit = ForestMeshes.new()

	_wisp = $Wisp
	_rig = $CameraRig
	_player = $PlayerController
	_base_speed = _wisp.speed
	_base_dash = _wisp.dash_speed
	_base_vertical = _wisp.vertical_speed
	_wisp.max_height = WISP_CEILING
	_wisp.sea_level = RegionTerrain.lake_level()

	_build_environment()
	_make_materials()
	_build_water()
	var tag_layer := CanvasLayer.new()
	tag_layer.layer = 1
	add_child(tag_layer)
	_tags = PlaceTags.new()
	tag_layer.add_child(_tags)
	_build_places()
	_start_streaming()
	_build_hud()
	_build_menu()
	_build_map()
	_map_task = WorkerThreadPool.add_task(_generate_map)


# --- Terrain and caves, streamed in ------------------------------------------------

func _make_materials() -> void:
	var shader := load("res://shaders/region_ground.gdshader") as Shader
	_ground_material = ShaderMaterial.new()
	_ground_material.shader = shader
	_ground_material.set_shader_parameter("noise_tex", kit.noise_texture)
	_ground_material.set_shader_parameter("lake_level", RegionTerrain.lake_level())
	_ground_material.set_shader_parameter("lake_center", Vector2(RegionTerrain.LAKE.x, RegionTerrain.LAKE.y))
	_ground_material.set_shader_parameter("lake_radius", RegionTerrain.LAKE.z)
	_ground_material.set_shader_parameter("quarry_center", RegionTerrain.BANDIT)


func _start_streaming() -> void:
	var start := Vector2(_wisp.global_position.x, _wisp.global_position.z)
	var terrain := RegionBuilder.terrain_keys()
	terrain.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _chunk_distance(a, start) < _chunk_distance(b, start))
	for key in terrain:
		_queue.append(["t", key])
	for key in RegionCaves.chunk_keys():
		_queue.append(["c", key])
	_total = _queue.size()
	_started_ms = Time.get_ticks_msec()


func _chunk_distance(key: Vector2i, from: Vector2) -> float:
	return Vector2((key.x + 0.5) * RegionBuilder.TERRAIN_CHUNK, (key.y + 0.5) * RegionBuilder.TERRAIN_CHUNK).distance_to(from)


func _work(entry: Array) -> void:
	var result := {}
	if entry[0] == "t":
		var key: Vector2i = entry[1]
		result = RegionBuilder.terrain_chunk(key.x, key.y)
	else:
		var key: Vector3i = entry[1]
		result = RegionBuilder.cave_chunk(key.x, key.y, key.z)
	_mutex.lock()
	_results.append([entry[0], result])
	_running -= 1
	_mutex.unlock()


func _pump_streaming() -> void:
	while not _queue.is_empty():
		_mutex.lock()
		var busy := _running >= MAX_TASKS
		if not busy:
			_running += 1
		_mutex.unlock()
		if busy:
			break
		var entry: Array = _queue.pop_front()
		WorkerThreadPool.add_task(_work.bind(entry))
	var made := 0
	while made < PER_FRAME:
		_mutex.lock()
		var item: Array = _results.pop_front() if not _results.is_empty() else []
		_mutex.unlock()
		if item.is_empty():
			break
		_instantiate(item[0], item[1])
		made += 1
	if not _reported and _done >= _total and _total > 0:
		_reported = true
		print("Region: %d terrain and cave pieces built in %d ms" % [_total, Time.get_ticks_msec() - _started_ms])


func _instantiate(kind: String, data: Dictionary) -> void:
	_done += 1
	if data.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = data["normals"]
	arrays[Mesh.ARRAY_INDEX] = data["indices"]
	var terrain := kind == "t"
	arrays[Mesh.ARRAY_COLOR] = data["colors"]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _ground_material
	node.position = data["origin"]
	if not terrain and not data["ground"]:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(data["faces"])
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	node.add_child(body)
	add_child(node)
	if terrain:
		_add_trees(node, body, data)


## Trees, small conifers and rocks for a square of ground, with a solid trunk for each giant. Each giant is
## drawn three ways (full, middle, simple) and the distance picks which one shows.
func _add_trees(node: Node3D, body: StaticBody3D, data: Dictionary) -> void:
	var trunks: PackedFloat32Array = data["trunks"]
	for t in trunks.size() / 5:
		var cylinder := CylinderShape3D.new()
		cylinder.radius = trunks[t * 5 + 2]
		cylinder.height = trunks[t * 5 + 3]
		var trunk := CollisionShape3D.new()
		trunk.shape = cylinder
		trunk.position = Vector3(trunks[t * 5], trunks[t * 5 + 4] + trunks[t * 5 + 3] * 0.5, trunks[t * 5 + 1])
		body.add_child(trunk)
	var center: Vector3 = data["center"]
	for batch in data["batches"]:
		var mesh_name: String = batch["mesh"]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = kit.meshes[mesh_name]
		multimesh.instance_count = batch["count"]
		multimesh.buffer = batch["data"]
		multimesh.custom_aabb = AABB(Vector3(-130.0, -80.0, -130.0), Vector3(260.0, 460.0, 260.0))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.position = center
		instance.top_level = true
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		match mesh_name:
			"giant_a", "giant_b":
				instance.visibility_range_end = 450.0
				instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			"giant_mid":
				instance.visibility_range_begin = 400.0
				instance.visibility_range_end = 1000.0
			"giant_low":
				instance.visibility_range_begin = 950.0
			"under":
				instance.visibility_range_end = 550.0
			_:
				instance.visibility_range_end = 700.0
		add_child(instance)


# --- Sky, water, atmosphere ------------------------------------------------------------

func _build_environment() -> void:
	var environment := Environment.new()
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.9
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.72, 0.80, 0.90)
	environment.fog_density = FOG_DENSITY
	environment.fog_sky_affect = 0.3
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	atmosphere = Atmosphere.new()
	atmosphere.name = "Atmosphere"
	atmosphere.environment = environment
	atmosphere.sea_level = RegionTerrain.lake_level()
	atmosphere.water_area = RegionTerrain.in_water
	atmosphere.normal_fog_density = FOG_DENSITY
	add_child(atmosphere)
	atmosphere.cycle.hour = START_HOUR
	atmosphere.spirit_amount = 1.0
	atmosphere.set_spirit(true)
	(atmosphere.get_node("Sun") as DirectionalLight3D).directional_shadow_max_distance = 450.0
	_player.form_changed.connect(func(_in_body: bool) -> void: _update_spirit())

	var camera := _rig.get_node("SpringArm3D/Camera3D") as Camera3D
	camera.far = 12000.0
	camera.near = 0.08


func _build_water() -> void:
	var level := RegionTerrain.lake_level()
	_water_plane("Lake", Vector3(RegionTerrain.LAKE.x, level, RegionTerrain.LAKE.y), RegionTerrain.LAKE.z * 2.7)
	# The pool inside the village cavern, at the same level as the lake.
	_water_plane("Pool", Vector3(RegionCaves.pool.x, level, RegionCaves.pool.y), 34.0)


func _water_plane(plane_name: String, at: Vector3, side: float) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(side, side)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/forest_water.gdshader")
	material.set_shader_parameter("noise_tex", kit.noise_texture)
	var water := MeshInstance3D.new()
	water.name = plane_name
	water.mesh = plane
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.position = at
	add_child(water)


func set_day_preview(on: bool) -> void:
	_day_preview = on
	_update_spirit()


func _update_spirit() -> void:
	atmosphere.set_spirit(_player.current_body == null and not _day_preview)


# --- The places ------------------------------------------------------------------------------

func _build_places() -> void:
	_marker_material = StandardMaterial3D.new()
	_marker_material.albedo_color = Color(0.62, 0.62, 0.62)
	_marker_material.roughness = 1.0
	_dark_material = StandardMaterial3D.new()
	_dark_material.albedo_color = Color(0.1, 0.1, 0.11)
	_dark_material.roughness = 1.0
	var level := RegionTerrain.lake_level()
	var base := RegionTerrain.BASE
	var village := RegionTerrain.VILLAGE
	var village_floor := RegionCaves.village_floor

	# --- The starting town: a pillar, the tavern, the library, the market, the crier. ---
	var town_pillar := _pillar(Vector2(-18.0, 52.0), base, Vector2(0.0, 0.0))
	_player.set_save_point(town_pillar.respawn_position(), false)
	_start_wisp(town_pillar)
	_main("Starting Town", Vector2(0.0, 0.0), 0.0)
	_building("Tavern\nKnight · Florist · Darkling Mayor", Vector2(-45.0, -35.0), Vector3(16.0, 7.0, 12.0))
	_building("Library\nScholar", Vector2(-45.0, -12.0), Vector3(12.0, 6.0, 9.0))
	_tag("Market", Vector3(35.0, base + 11.0, 25.0), 300.0)
	_building("Blacksmith (Human)", Vector2(22.0, 14.0), Vector3(5.0, 3.0, 4.0))
	_building("Cartographer (Fayran)", Vector2(46.0, 12.0), Vector3(5.0, 3.0, 4.0))
	_building("Visitor (Sen-Kash)", Vector2(50.0, 34.0), Vector3(5.0, 3.0, 4.0))
	_building("Meat stand (Tar'ye)", Vector2(24.0, 38.0), Vector3(5.0, 3.0, 4.0))
	_building("Duel ground (Tar'ye)", Vector2(75.0, 62.0), Vector3(14.0, 0.3, 14.0))
	_building("Town Crier\n(lost child)", Vector2(-6.0, 24.0), Vector3(3.0, 3.0, 3.0))
	_small("Form pillar", Vector3(-18.0, base + 5.0, 52.0), 150.0)

	# --- North: the forest, the flower mesa, the fork. ---
	_tag("Forest", Vector3(-10.0, base + 14.0, -250.0), 600.0)
	var mesa := RegionTerrain.MESA
	var mesa_top := RegionTerrain.height(mesa.x, mesa.y)
	_main("Flowers (fly up)", mesa, mesa_top + 6.0)
	for i in 9:
		var a := TAU * i / 9.0
		var flower := _box(Vector3(mesa.x + cos(a) * 18.0, mesa_top + 0.6, mesa.y + sin(a) * 18.0), Vector3(1.2, 1.2, 1.2), false)
		flower.get_child(0).material_override = _marker_material
	var fork := RegionTerrain.FORK
	_box(Vector3(fork.x, RegionTerrain.height(fork.x, fork.y) + 1.6, fork.y), Vector3(0.6, 3.2, 0.6), false)
	_tag("Road fork\nFootprints", Vector3(fork.x, base + 7.0, fork.y), 700.0)

	# --- The darklings' clearing: a wide ring of stones, and a save point in the trees nearby. ---
	var darkling := RegionTerrain.DARKLING
	var dark_ground := RegionTerrain.height(darkling.x, darkling.y)
	_main("Darkling Corruption Area\nLucifer (B'nuo Puxarorna)", darkling, dark_ground)
	for i in 14:
		var a := TAU * i / 14.0
		var stone := _box(Vector3(darkling.x + cos(a) * 30.0, dark_ground + 2.5, darkling.y + sin(a) * 30.0), Vector3(2.0, 5.0, 2.0), true)
		stone.rotation.y = a
	_building("Mural: dragon egg", Vector2(darkling.x + 48.0, darkling.y + 30.0), Vector3(9.0, 4.0, 1.0))
	_pillar(Vector2(darkling.x - 8.0, darkling.y + 62.0), RegionTerrain.height(darkling.x - 8.0, darkling.y + 62.0), darkling)
	_small("Form pillar (save point)", Vector3(darkling.x - 8.0, dark_ground + 5.0, darkling.y + 62.0), 150.0)

	# --- The bandit camp, in its quarry. ---
	var bandit := RegionTerrain.BANDIT
	var quarry := base - RegionTerrain.QUARRY_FLOOR
	_main("Bandit Camp", bandit, quarry)
	for tent in [Vector2(-25.0, -20.0), Vector2(-10.0, 25.0), Vector2(-40.0, 5.0), Vector2(15.0, -15.0)]:
		_box(Vector3(bandit.x + tent.x, quarry + 1.5, bandit.y + tent.y), Vector3(6.0, 3.0, 6.0), true)
	_small("Gold & Loot (puzzle)", Vector3(bandit.x + 38.0, quarry + 4.0, bandit.y - 18.0), 400.0)
	_box(Vector3(bandit.x + 38.0, quarry + 1.0, bandit.y - 18.0), Vector3(3.0, 2.0, 3.0), true)
	_small("Captives: Lost Child · Kidnapped Qoi-Kash", Vector3(bandit.x - 20.0, quarry + 6.0, bandit.y - 38.0), 400.0)
	_box(Vector3(bandit.x - 20.0, quarry + 1.5, bandit.y - 38.0), Vector3(4.0, 3.0, 4.0), true)
	_pillar(Vector2(bandit.x - 50.0, bandit.y), quarry, bandit)
	var ramp := RegionCaves.quarry_ramp
	_small("Smugglers' Way ↓ (to the village)", Vector3(ramp.x, quarry + 7.0, ramp.y), 400.0)

	# --- The ancient ruins on their hill, and the hatchery below. ---
	var ruins := RegionTerrain.RUINS
	var ruins_top := RegionTerrain.height(ruins.x, ruins.y)
	_main("Ancient Ruins", ruins, ruins_top + 6.0)
	for i in 6:
		var a := TAU * i / 6.0
		_box(Vector3(ruins.x + cos(a) * 22.0, ruins_top + 3.5, ruins.y + sin(a) * 22.0), Vector3(1.6, 7.0, 1.6), true)
	var egg := _box(Vector3(ruins.x, ruins_top + 1.5, ruins.y), Vector3(2.6, 3.0, 2.6), true)
	egg.get_child(0).material_override = _marker_material
	_small("Dragon Egg", Vector3(ruins.x, ruins_top + 6.0, ruins.y + 3.0), 500.0)
	_tag("Hidden Hatchery", RegionCaves.hatchery + Vector3(0.0, 8.0, 0.0), 150.0, true)
	var mouth := RegionCaves.hatchery_mouth
	_small("Hatchery slope ↓", Vector3(mouth.x, RegionTerrain.height(mouth.x, mouth.y) + 8.0, mouth.y), 400.0)
	var path_mid := Vector2(-330.0, 390.0)
	_small("Ruin stone path", Vector3(path_mid.x, RegionTerrain.height(path_mid.x, path_mid.y) + 5.0, path_mid.y), 500.0)

	# --- The lake: a ruined colonnade on the north shore, and the way down. ---
	var lake := RegionTerrain.LAKE
	var shore_z := lake.y - (lake.z + 14.0)
	_main("Lake Statues\n(Qoi-Kash form)", Vector2(lake.x, shore_z), base + 4.0)
	for i in 5:
		var column := _box(Vector3(lake.x - 16.0 + i * 8.0, base + 2.2, shore_z), Vector3(1.4, 4.4, 1.4), true)
		column.rotation_degrees.z = [0.0, 6.0, -4.0, 0.0, 9.0][i]
	_pillar(Vector2(lake.x + 42.0, shore_z + 6.0), base, Vector2(lake.x, lake.y))
	_tag("Underwater cave ↓\n(drowned tunnel, 24 m down)", Vector3(RegionCaves.shaft.x, level + 5.0, RegionCaves.shaft.y), 500.0)

	# --- The Qoi-Kash village, in the cavern under the hollow hill; the Black far below. ---
	var hill_top := RegionTerrain.height(village.x, village.y)
	_tag("Qoi-Kash Village\n(in the cavern below)", Vector3(village.x, hill_top + 12.0, village.y), 0.0, false, true)
	_pillar(village + Vector2(-15.0, 10.0), village_floor, RegionCaves.pool)
	for house in [Vector2(20.0, -20.0), Vector2(45.0, 5.0), Vector2(15.0, 30.0), Vector2(50.0, -20.0), Vector2(-25.0, 30.0)]:
		_box(Vector3(village.x + house.x, village_floor + 2.5, village.y + house.y), Vector3(8.0, 5.0, 8.0), true)
	_tag("Qoi-Kash village", Vector3(village.x + 25.0, village_floor + 14.0, village.y), 200.0, true)
	_tag("Pool (the drowned tunnel comes up here)", Vector3(RegionCaves.pool.x, level + 5.0, RegionCaves.pool.y), 200.0, true)
	_tag("The Black ↓ (a long way down)", Vector3(village.x + 45.0, village_floor + 8.0, village.y + 20.0), 200.0, true)
	var pit := RegionCaves.pit
	var pit_disc := _box(Vector3(pit.x, pit.y + 0.1, pit.z), Vector3(14.0, 0.2, 14.0), false)
	pit_disc.get_child(0).material_override = _dark_material
	_tag("The Black (pit)", Vector3(pit.x, pit.y + 6.0, pit.z), 200.0, true)
	_tag("Mural of the King", Vector3(pit.x + 20.0, pit.y + 6.0, pit.z), 200.0, true)


func _pillar(at: Vector2, ground: float, facing: Vector2) -> FormPillar:
	var pillar := FormPillar.new()
	pillar.name = "FormPillar"
	pillar.kit = kit
	pillar.sea_level = RegionTerrain.lake_level()
	pillar.water_area = RegionTerrain.in_water
	pillar.ground_at = func(_x: float, _z: float) -> float: return ground
	pillar.position = Vector3(at.x, ground, at.y)
	var toward := facing - at
	pillar.rotation_degrees.y = rad_to_deg(atan2(toward.x, toward.y))
	add_child(pillar)
	return pillar


func _start_wisp(pillar: FormPillar) -> void:
	var front := pillar.global_basis.z
	var start := pillar.global_position + front * 3.6
	_wisp.global_position = Vector3(start.x, start.y + 3.0, start.z)
	_wisp.reset_physics_interpolation()
	_rig.yaw = pillar.rotation.y
	_rig.pitch = deg_to_rad(8.0)
	_rig.snap_to_target()


## A main place: a tall pale beacon with a big name that shows from anywhere.
func _main(place_name: String, at: Vector2, y: float) -> void:
	var ground := RegionTerrain.height(at.x, at.y) if y == 0.0 else y
	_box(Vector3(at.x, ground + 20.0, at.y), Vector3(1.6, 40.0, 1.6), false)
	_tags.add_tag(place_name, Vector3(at.x, ground + 46.0, at.y), 0.0, false, true)
	_places.append([place_name.get_slice("\n", 0), Vector3(at.x, ground, at.y)])


func _tag(text: String, at: Vector3, far: float, underground := false, big := false) -> void:
	_tags.add_tag(text, at, far, underground, big)


func _small(text: String, at: Vector3, far: float) -> void:
	_tags.add_tag(text, at, far)
	_places.append([text.get_slice("\n", 0), at])


func _building(text: String, at: Vector2, size: Vector3) -> void:
	var ground := RegionTerrain.height(at.x, at.y)
	_box(Vector3(at.x, ground + size.y * 0.5, at.y), size, true)
	_tags.add_tag(text, Vector3(at.x, ground + size.y + 3.0, at.y), 170.0)
	_places.append([text.get_slice("\n", 0), Vector3(at.x, ground, at.y)])


## A grey box, optionally solid. (The mesh is its first child.)
func _box(center: Vector3, size: Vector3, solid: bool) -> Node3D:
	var node: Node3D
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _marker_material
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = Layers.WORLD
		body.collision_mask = 0
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(instance)
		body.add_child(collision)
		node = body
	else:
		var holder := Node3D.new()
		holder.add_child(instance)
		node = holder
	node.position = center
	add_child(node)
	return node


# --- Running ----------------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if _wisp == null or not _wisp.visible:
		return
	var p := _wisp.global_position
	var limit := RegionTerrain.EDGE - 80.0
	var r := Vector2(p.x, p.z).length()
	if r > limit:
		p.x *= limit / r
		p.z *= limit / r
		_wisp.velocity = Vector3.ZERO
		_wisp.global_position = p


func _process(delta: float) -> void:
	_pump_streaming()
	_update_cave_light(delta)
	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.2
		_update_hud()
	_update_map()


## Under the ground there is no sun or sky light (the Atmosphere dims everything).
func _update_cave_light(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var p := camera.global_position
	var under := p.y < RegionTerrain.height(p.x, p.z) - 1.5 and Vector2(p.x, p.z).length() < RegionTerrain.EDGE
	_cave_amount = move_toward(_cave_amount, 1.0 if under else 0.0, delta * 3.0)
	atmosphere.cave_amount = _cave_amount
	_tags.underground_view = _cave_amount > 0.5


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_5:
		_speed_index = key - KEY_1
		var multiplier := SPEEDS[_speed_index]
		_wisp.speed = _base_speed * multiplier
		_wisp.dash_speed = _base_dash * multiplier
		_wisp.vertical_speed = _base_vertical * multiplier
	elif key == KEY_M:
		_toggle_map()
	elif key == KEY_V:
		_day_preview = not _day_preview
		_update_spirit()
	elif key == KEY_BRACKETLEFT:
		atmosphere.cycle.hour = fposmod(atmosphere.cycle.hour - 1.0, 24.0)
	elif key == KEY_BRACKETRIGHT:
		atmosphere.cycle.hour = fposmod(atmosphere.cycle.hour + 1.0, 24.0)
	elif key == KEY_T:
		_timelapse = not _timelapse
		atmosphere.cycle.day_length_minutes = 0.5 if _timelapse else 10.0
	elif key == KEY_G:
		_lines_on = not _lines_on
		_ground_material.set_shader_parameter("map_lines", 1.0 if _lines_on else 0.0)
	elif key == KEY_H:
		_hud.visible = not _hud.visible
		_help.visible = _hud.visible


# --- Text on screen -------------------------------------------------------------------------

func _build_menu() -> void:
	var menu := PauseMenu.new()
	menu.name = "PauseMenu"
	menu.player = _player
	menu.rig = _rig
	menu.info_text_changed = func(on: bool) -> void:
		_hud.visible = on
		_help.visible = on
	add_child(menu)
	_player.saved.connect(menu.toast)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	_help = _label2(layer, Vector2(16.0, 12.0))
	_help.text = "1-5 speed   M map   V daylight preview   [ ] hour   T time-lapse   G grid lines   H hide"
	_hud = _label2(layer, Vector2(16.0, 38.0))
	_loading = _label2(layer, Vector2(16.0, 100.0))


func _label2(parent: Node, at: Vector2) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)
	return label


func _update_hud() -> void:
	if _wisp == null:
		return
	if _done < _total:
		_loading.text = "Building the land... %d%%" % int(100.0 * _done / maxf(_total, 1.0))
	else:
		_loading.text = ""
	var p := _wisp.global_position
	var ground := RegionTerrain.height(p.x, p.z)
	var nearest := ""
	var nearest_distance := 1.0e9
	for place in _places:
		var d := p.distance_to(place[1])
		if d < nearest_distance:
			nearest_distance = d
			nearest = place[0]
	var above := "%d ft above ground" % int((p.y - ground) * FEET) if p.y >= ground - 1.5 else "underground (%d ft down)" % int((ground - p.y) * FEET)
	_hud.text = "x %d ft   z %d ft   %s\nNearest: %s (%d ft)\nspeed x%d (%d mph)   %d fps" % [
		int(p.x * FEET), int(p.z * FEET), above, nearest, int(nearest_distance * FEET),
		int(SPEEDS[_speed_index]), int(_wisp.speed * 2.23694), Engine.get_frames_per_second(),
	]


# --- The map ----------------------------------------------------------------------------------

func _build_map() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_map_root = Control.new()
	_map_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.visible = false
	layer.add_child(_map_root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.add_child(dim)

	_map_rect = TextureRect.new()
	_map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_map_rect.set_anchors_preset(Control.PRESET_CENTER)
	_map_rect.offset_left = -310.0
	_map_rect.offset_right = 310.0
	_map_rect.offset_top = -310.0
	_map_rect.offset_bottom = 310.0
	_map_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_rect.gui_input.connect(_on_map_input)
	_map_root.add_child(_map_rect)

	for place in _main_places():
		var tag := Label.new()
		tag.text = place[0]
		tag.add_theme_font_size_override("font_size", 13)
		tag.add_theme_color_override("font_outline_color", Color.BLACK)
		tag.add_theme_constant_override("outline_size", 5)
		var uv := Vector2(place[1].x, place[1].y) / (2.0 * MAP_RADIUS) + Vector2(0.5, 0.5)
		tag.position = uv * 620.0 + Vector2(7.0, -8.0)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map_rect.add_child(tag)

	_map_marker = ColorRect.new()
	_map_marker.color = Color(1.0, 0.9, 0.4)
	_map_marker.size = Vector2(9.0, 9.0)
	_map_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_rect.add_child(_map_marker)

	var caption := Label.new()
	caption.text = "The first region (grey-box), about 1.8 miles across. Click anywhere to fly there. M closes the map."
	caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caption.offset_top = -50.0
	caption.offset_left = -400.0
	caption.offset_right = 400.0
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_root.add_child(caption)


## The names that go on the map: [name, Vector2 position].
func _main_places() -> Array:
	return [
		["Starting Town", RegionTerrain.TOWN], ["Flowers", RegionTerrain.MESA], ["Fork", RegionTerrain.FORK],
		["Darkling area", RegionTerrain.DARKLING], ["Bandit camp", RegionTerrain.BANDIT], ["Ancient ruins", RegionTerrain.RUINS],
		["Lake statues", Vector2(RegionTerrain.LAKE.x, RegionTerrain.LAKE.y)], ["Qoi-Kash village", RegionTerrain.VILLAGE],
	]


func _toggle_map() -> void:
	_map_open = not _map_open
	_map_root.visible = _map_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _map_open else Input.MOUSE_MODE_CAPTURED


func _update_map() -> void:
	if _map_task >= 0 and WorkerThreadPool.is_task_completed(_map_task):
		WorkerThreadPool.wait_for_task_completion(_map_task)
		_map_task = -1
		_map_rect.texture = ImageTexture.create_from_image(_map_image)
	if _map_open and _wisp:
		var p := _wisp.global_position
		var uv := Vector2(p.x, p.z) / (2.0 * MAP_RADIUS) + Vector2(0.5, 0.5)
		_map_marker.position = uv * _map_rect.size - _map_marker.size * 0.5


func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := (event as InputEventMouseButton).position / _map_rect.size
		var x := (local.x - 0.5) * 2.0 * MAP_RADIUS
		var z := (local.y - 0.5) * 2.0 * MAP_RADIUS
		var r := Vector2(x, z).length()
		var limit := RegionTerrain.EDGE - 100.0
		if r > limit:
			x *= limit / r
			z *= limit / r
		_wisp.global_position = Vector3(x, RegionTerrain.height(x, z) + 40.0, z)
		_wisp.velocity = Vector3.ZERO
		_wisp.reset_physics_interpolation()
		_rig.snap_to_target()
		_toggle_map()


## A grey relief picture of the whole region with contour lines. Runs on a background thread.
func _generate_map() -> void:
	var n := MAP_SIZE
	var heights := PackedFloat32Array()
	heights.resize(n * n)
	for j in n:
		for i in n:
			var x := (float(i) / (n - 1) - 0.5) * 2.0 * MAP_RADIUS
			var z := (float(j) / (n - 1) - 0.5) * 2.0 * MAP_RADIUS
			heights[j * n + i] = RegionTerrain.height(x, z)
	var image := Image.create(n, n, false, Image.FORMAT_RGB8)
	for j in n:
		for i in n:
			var x := (float(i) / (n - 1) - 0.5) * 2.0 * MAP_RADIUS
			var z := (float(j) / (n - 1) - 0.5) * 2.0 * MAP_RADIUS
			if Vector2(x, z).length() > RegionTerrain.EDGE:
				image.set_pixel(i, j, Color(0.03, 0.03, 0.04))
				continue
			var h := heights[j * n + i]
			var left := heights[j * n + maxi(i - 1, 0)]
			var right := heights[j * n + mini(i + 1, n - 1)]
			var up := heights[maxi(j - 1, 0) * n + i]
			var down := heights[mini(j + 1, n - 1) * n + i]
			var shade := clampf(0.75 + ((left - right) + (up - down)) * 0.05, 0.3, 1.2)
			var tone := lerpf(0.38, 0.82, clampf((h - 25.0) / 170.0, 0.0, 1.0)) * shade
			if fposmod(h, 20.0) < 1.6:
				tone *= 0.8
			if RegionTerrain.in_water(x, z) and h < RegionTerrain.lake_level():
				image.set_pixel(i, j, Color(0.25, 0.4, 0.5) * clampf(1.0 - (RegionTerrain.lake_level() - h) / 40.0, 0.4, 1.0))
			else:
				image.set_pixel(i, j, Color(tone, tone, tone))
	for place in _main_places():
		var px := int((place[1].x / (2.0 * MAP_RADIUS) + 0.5) * (n - 1))
		var py := int((place[1].y / (2.0 * MAP_RADIUS) + 0.5) * (n - 1))
		for dj in range(-3, 4):
			for di in range(-3, 4):
				if di * di + dj * dj <= 9:
					image.set_pixel(clampi(px + di, 0, n - 1), clampi(py + dj, 0, n - 1), Color(1.0, 0.95, 0.55))
	_map_image = image
