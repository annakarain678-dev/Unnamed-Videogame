class_name ForestWorld
extends Node3D
## The giant forest: an uneven basin about 4 to 5 km across, ringed by cliffs and mountains, covered in
## redwood-sized trees, with open clearings kept free for buildings. You start as the wisp, in daylight,
## in the main clearing.
##
## Keys:  1-5 fly faster (1 = normal, 5 = about 50x, for crossing the map)    M map (click to fly there)
##        V daylight preview (see the world as a body does)    [ and ] change the hour
##        T time-lapse on/off    H hide this text
## As the wisp, go to the stone pillar and press Right Mouse to pick a form.

const START_HOUR := 10.0
const WISP_CEILING := 520.0
const SPEEDS: Array[float] = [1.0, 3.0, 8.0, 20.0, 50.0]
const MAP_RADIUS := 3500.0
const MAP_SIZE := 512
const FOG_DENSITY := 0.00045
const NO_SEA := -100000.0
const FEET := 3.28084
## Where the form pillar stands: in the main clearing, a short walk from the lake, facing it.
const PILLAR_AT := Vector2(-20.0, 85.0)
const PILLAR_YAW := 225.0

var atmosphere: Atmosphere
var chunks: ForestChunks
var kit: ForestMeshes

var _wisp: Wisp
var _rig: CameraRig
var _base_speed := 7.0
var _base_dash := 10.5
var _base_vertical := 4.5
var _speed_index := 0
var _day_preview := false
var _player: PlayerController
var _timelapse := false

var _hud: Label
var _help: Label
var _hud_timer := 0.0
var _map_root: Control
var _map_rect: TextureRect
var _map_marker: ColorRect
var _map_image: Image
var _map_task := -1
var _map_open := false


func _ready() -> void:
	# Run after the wisp each physics tick, so keeping it above the ground is the last word.
	process_physics_priority = 100
	ForestTerrain.setup()
	kit = ForestMeshes.new()

	_wisp = $Wisp
	_rig = $CameraRig
	_base_speed = _wisp.speed
	_base_dash = _wisp.dash_speed
	_base_vertical = _wisp.vertical_speed
	_wisp.max_height = WISP_CEILING
	_wisp.sea_level = NO_SEA

	_player = $PlayerController
	_wisp.sea_level = ForestTerrain.lake_level()
	_build_environment()
	_place_wisp()
	_build_lake()
	_build_pillar()

	chunks = ForestChunks.new()
	chunks.name = "Chunks"
	chunks.kit = kit
	chunks.target = _wisp
	add_child(chunks)
	var started := Time.get_ticks_msec()
	chunks.prebuild_blocking()
	print("Forest: far terrain built in %d ms (%s)" % [Time.get_ticks_msec() - started, chunks.stats()])

	_build_hud()
	_build_menu()
	_build_map()
	_map_task = WorkerThreadPool.add_task(_generate_map)


func _build_environment() -> void:
	var environment := Environment.new()
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.9
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.72, 0.80, 0.90)
	environment.fog_density = FOG_DENSITY
	environment.fog_sky_affect = 0.3
	environment.fog_aerial_perspective = 0.2
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	atmosphere = Atmosphere.new()
	atmosphere.name = "Atmosphere"
	atmosphere.environment = environment
	atmosphere.sea_level = ForestTerrain.lake_level()
	atmosphere.water_area = ForestTerrain.in_lake
	atmosphere.normal_fog_density = FOG_DENSITY
	add_child(atmosphere)
	atmosphere.cycle.hour = START_HOUR
	# The wisp sees in spirit view; bodies see the everyday world. (V previews daylight as the wisp.)
	atmosphere.spirit_amount = 1.0
	atmosphere.set_spirit(true)
	var sun := atmosphere.get_node("Sun") as DirectionalLight3D
	sun.directional_shadow_max_distance = 450.0

	_player.form_changed.connect(func(_in_body: bool) -> void: _update_spirit())

	# Far mountains need a far camera.
	var camera := _rig.get_node("SpringArm3D/Camera3D") as Camera3D
	camera.far = 300000.0
	camera.near = 0.08


## The pillar where the wisp changes form (and wakes up if a body is lost).
func _build_pillar() -> void:
	var pillar := FormPillar.new()
	pillar.name = "FormPillar"
	pillar.kit = kit
	pillar.sea_level = ForestTerrain.lake_level()
	pillar.water_area = ForestTerrain.in_lake
	pillar.ground_at = ForestTerrain.height
	pillar.position = Vector3(PILLAR_AT.x, ForestTerrain.height(PILLAR_AT.x, PILLAR_AT.y), PILLAR_AT.y)
	pillar.rotation_degrees.y = PILLAR_YAW
	add_child(pillar)
	_player.set_save_point(pillar.respawn_position(), false)


## The surface of the lake in the main clearing. (The bowl itself is carved into the terrain.)
func _build_lake() -> void:
	var plane := PlaneMesh.new()
	var side := ForestTerrain.LAKE.z * 3.2
	plane.size = Vector2(side, side)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/forest_water.gdshader")
	material.set_shader_parameter("noise_tex", kit.noise_texture)
	var water := MeshInstance3D.new()
	water.name = "Lake"
	water.mesh = plane
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.position = Vector3(ForestTerrain.LAKE.x, ForestTerrain.lake_level(), ForestTerrain.LAKE.y)
	add_child(water)


func _place_wisp() -> void:
	# Start a few steps in front of the pillar, looking at it.
	var front := Vector2(sin(deg_to_rad(PILLAR_YAW)), cos(deg_to_rad(PILLAR_YAW)))
	var start := PILLAR_AT + front * 3.6
	var ground := ForestTerrain.height(start.x, start.y)
	_wisp.global_position = Vector3(start.x, ground + 3.0, start.y)
	_wisp.reset_physics_interpolation()
	_rig.yaw = deg_to_rad(PILLAR_YAW)
	_rig.pitch = deg_to_rad(8.0)
	_rig.snap_to_target()


func _physics_process(_delta: float) -> void:
	if _wisp == null or not _wisp.visible:
		return
	var p := _wisp.global_position
	var limit := ForestTerrain.WORLD_RADIUS + 200.0
	var r := Vector2(p.x, p.z).length()
	if r > limit:
		p.x *= limit / r
		p.z *= limit / r
		_wisp.velocity = Vector3.ZERO
	# Never dip into the ground, whatever the speed (the terrain's own colliders only exist nearby).
	var floor_y := ForestTerrain.height(p.x, p.z) + 1.4
	if p.y < floor_y:
		p.y = floor_y
		_wisp.velocity.y = maxf(_wisp.velocity.y, 0.0)
	if not p.is_equal_approx(_wisp.global_position):
		_wisp.global_position = p


func _process(delta: float) -> void:
	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.2
		_update_hud()
	_update_map()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_5:
		_set_speed(key - KEY_1)
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
	elif key == KEY_H:
		_hud.visible = not _hud.visible
		_help.visible = _hud.visible


func set_day_preview(on: bool) -> void:
	_day_preview = on
	_update_spirit()


func _update_spirit() -> void:
	atmosphere.set_spirit(_player.current_body == null and not _day_preview)


func _set_speed(index: int) -> void:
	_speed_index = index
	var multiplier := SPEEDS[index]
	_wisp.speed = _base_speed * multiplier
	_wisp.dash_speed = _base_dash * multiplier
	_wisp.vertical_speed = _base_vertical * multiplier


# --- Text on screen -----------------------------------------------------------

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
	_help = _label(layer, Vector2(16.0, 12.0))
	_help.text = "1-5 speed   M map   V daylight preview   [ ] hour   T time-lapse   H hide"
	_hud = _label(layer, Vector2(16.0, 38.0))


func _label(parent: Node, at: Vector2) -> Label:
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
	var p := _wisp.global_position
	var ground := ForestTerrain.height(p.x, p.z)
	var from_center := Vector2(p.x, p.z).length()
	# Feet and miles (the world is built in meters underneath).
	_hud.text = "x %d ft   z %d ft   %d ft above ground   %.2f miles from the center\nspeed x%d (%d mph)   %d fps\n%s" % [
		int(p.x * FEET), int(p.z * FEET), int((p.y - ground) * FEET), from_center / 1609.34,
		int(SPEEDS[_speed_index]), int(_wisp.speed * 2.23694), Engine.get_frames_per_second(), chunks.stats()
	]


# --- The map ------------------------------------------------------------------

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
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_root.add_child(dim)

	_map_rect = TextureRect.new()
	_map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_map_rect.set_anchors_preset(Control.PRESET_CENTER)
	_map_rect.offset_left = -300.0
	_map_rect.offset_right = 300.0
	_map_rect.offset_top = -300.0
	_map_rect.offset_bottom = 300.0
	_map_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_rect.gui_input.connect(_on_map_input)
	_map_root.add_child(_map_rect)

	_map_marker = ColorRect.new()
	_map_marker.color = Color(1.0, 0.9, 0.4)
	_map_marker.size = Vector2(9.0, 9.0)
	_map_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_rect.add_child(_map_marker)

	var caption := Label.new()
	caption.text = "The giant forest, about 3 miles across. Click anywhere to fly there. M closes the map."
	caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caption.offset_top = -80.0
	caption.offset_left = -300.0
	caption.offset_right = 300.0
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_root.add_child(caption)


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
		var u := p.x / (2.0 * MAP_RADIUS) + 0.5
		var v := p.z / (2.0 * MAP_RADIUS) + 0.5
		_map_marker.position = Vector2(u, v) * _map_rect.size - _map_marker.size * 0.5


func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := (event as InputEventMouseButton).position / _map_rect.size
		var x := (local.x - 0.5) * 2.0 * MAP_RADIUS
		var z := (local.y - 0.5) * 2.0 * MAP_RADIUS
		_teleport(x, z)
		_toggle_map()


func _teleport(x: float, z: float) -> void:
	var r := Vector2(x, z).length()
	if r > ForestTerrain.WORLD_RADIUS:
		x *= ForestTerrain.WORLD_RADIUS / r
		z *= ForestTerrain.WORLD_RADIUS / r
	var ground := ForestTerrain.height(x, z)
	_wisp.global_position = Vector3(x, ground + 40.0, z)
	_wisp.velocity = Vector3.ZERO
	_wisp.reset_physics_interpolation()
	_rig.snap_to_target()
	chunks.prebuild_blocking()


## Draws a shaded-relief picture of the whole world. Runs on a background thread.
func _generate_map() -> void:
	var n := MAP_SIZE
	var heights := PackedFloat32Array()
	heights.resize(n * n)
	for j in n:
		for i in n:
			var x := (float(i) / (n - 1) - 0.5) * 2.0 * MAP_RADIUS
			var z := (float(j) / (n - 1) - 0.5) * 2.0 * MAP_RADIUS
			heights[j * n + i] = ForestTerrain.height(x, z)
	var image := Image.create(n, n, false, Image.FORMAT_RGB8)
	for j in n:
		for i in n:
			var x := (float(i) / (n - 1) - 0.5) * 2.0 * MAP_RADIUS
			var z := (float(j) / (n - 1) - 0.5) * 2.0 * MAP_RADIUS
			if Vector2(x, z).length() > ForestChunks.WORLD_EDGE:
				image.set_pixel(i, j, Color(0.03, 0.03, 0.04))
				continue
			var h := heights[j * n + i]
			var left := heights[j * n + maxi(i - 1, 0)]
			var right := heights[j * n + mini(i + 1, n - 1)]
			var up := heights[maxi(j - 1, 0) * n + i]
			var down := heights[mini(j + 1, n - 1) * n + i]
			var shade := clampf(0.8 + ((left - right) + (up - down)) * 0.05, 0.35, 1.25)
			var color: Color
			if h < 90.0:
				color = Color(0.17, 0.30, 0.13).lerp(Color(0.30, 0.38, 0.15), clampf((h - 30.0) / 60.0, 0.0, 1.0))
			elif h < 200.0:
				color = Color(0.30, 0.38, 0.15).lerp(Color(0.52, 0.42, 0.28), clampf((h - 90.0) / 110.0, 0.0, 1.0))
			else:
				color = Color(0.52, 0.42, 0.28).lerp(Color(0.92, 0.90, 0.86), clampf((h - 200.0) / 400.0, 0.0, 1.0))
			image.set_pixel(i, j, Color(color.r * shade, color.g * shade, color.b * shade))
	# Mark the clearings.
	for c in ForestTerrain.CLEARINGS:
		var px := int((c.x / (2.0 * MAP_RADIUS) + 0.5) * (n - 1))
		var py := int((c.y / (2.0 * MAP_RADIUS) + 0.5) * (n - 1))
		for dj in range(-3, 4):
			for di in range(-3, 4):
				if di * di + dj * dj <= 9:
					image.set_pixel(clampi(px + di, 0, n - 1), clampi(py + dj, 0, n - 1), Color(1.0, 0.95, 0.55))
	_map_image = image
