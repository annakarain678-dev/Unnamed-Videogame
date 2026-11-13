class_name HeartChase
extends Node3D
## The fight inside a possessed host's heart.
##
## A stubborn darkling won't simply be shone out. When you try, the wisp is drawn into the host's
## heart: a dark, foggy chamber of rough stone threaded with gold veins that pulse red, with the
## corrupted heart burning with black fire at its center.
##
## The darkling keeps trying to get back to the heart, swinging around the wisp if it's in the way.
## Shine (hold Left Mouse, or F) pushes it away. Hold Right Mouse to draw lines of light behind you
## (see LightLines) that it can't cross and keeps clear of, to wall it off. If it's ever completely
## walled in, it hops up over the lines and out, so you can never trap it by accident.
## Drive it out past the glowing border and the heart is cleansed: the veins turn soft
## bluish-white, the heart turns a healthy beating red, and after a few moments you come back
## out, inside the host. Tab gives up (the darkling keeps its hold).
##
## This is tuned easy. Harder darklings can be made faster, or dodge more (see the settings below).

## Where the chamber is built: far away from everything, out of sight.
const ORIGIN := Vector3(4000.0, 20.0, 0.0)
## Drive the darkling past this distance from the heart to win.
const BORDER := 12.0
const FLOOR_RADIUS := 22.0
## How fast the darkling heads back to the heart (m/s).
const HOMING_SPEED := 3.0
## How hard it swings around the wisp when the wisp is in its way, and how wide a berth it gives.
const DODGE_STRENGTH := 3.2
const DODGE_WIDTH := 3.5
## The wisp's shine pushes it within this reach, hardest up close.
const SHINE_REACH := 6.5
const SHINE_PUSH := 6.5
## It starts veering away from a line of light within this distance.
const LINE_WARINESS := 2.2
const LINE_PUSH := 2.5
## If it's completely walled in for this long, it hops over the lines (taking this long, this high).
const TRAPPED_TIME := 1.5
const HOP_TIME := 1.1
const HOP_HEIGHT := 2.8
## Its normal hovering height above the floor.
const HOVER := 1.5
## How long to admire the cleansed heart before leaving.
const CLEANSED_TIME := 4.0
const FADE_TIME := 0.45

enum State { IDLE, CHASE, CLEANSED, BUSY }

var _state := State.IDLE
var _outer_darkling: Darkling
var _host: FormBody
var _return_position := Vector3.ZERO

var _inner_darkling: DarklingShape
var _inner_position := Vector2.ZERO  # Relative to the heart, across the floor.
var _inner_velocity := Vector2.ZERO
var _inner_fade := 1.0
var _trapped_time := 0.0
var _trap_check := 0.0
var _hop_left := 0.0
var _lines: LightLines
var _saved_shine_speed := 0.5
var _cleansed := 0.0
var _cleansed_time := 0.0
var _time := 0.0

var _floor_material: ShaderMaterial
var _ring_material: StandardMaterial3D
var _heart: Node3D
var _heart_material: StandardMaterial3D
var _heart_flame: DarkFlame
var _heart_light: OmniLight3D
var _fade: ColorRect
var _title: Label
var _hint: Label


func _ready() -> void:
	add_to_group("heart_chase")
	# Everything in here moves every frame, not on physics ticks.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	position = ORIGIN
	_build_chamber()
	_build_ui()
	visible = false


## A stubborn darkling resists: draw the wisp into `host`'s heart to fight it.
func begin(darkling: Darkling, host: FormBody) -> void:
	if _state != State.IDLE:
		return
	_state = State.BUSY
	_outer_darkling = darkling
	_host = host
	var wisp := _wisp()
	_return_position = wisp.global_position
	_set_player_inside(true)
	await _fade_to(1.0)

	_reset_chamber()
	visible = true
	wisp.global_position = ORIGIN + Vector3(0.0, 1.6, 9.0)
	wisp.reset_physics_interpolation()
	wisp.set_active(true)
	# In here, shining doesn't slow the wisp down, or it could never keep up.
	_saved_shine_speed = wisp.shine_speed_scale
	wisp.shine_speed_scale = 1.0
	# Facing the heart, looking down a little so the wisp doesn't hide it.
	_camera_rig().yaw = 0.0
	_camera_rig().pitch = deg_to_rad(-24.0)
	_camera_rig().snap_to_target()
	_state = State.CHASE
	await _fade_to(0.0)


## Tab: give up. The darkling keeps its hold, and the wisp is back where it started.
func give_up() -> void:
	if _state != State.CHASE:
		return
	_state = State.BUSY
	await _fade_to(1.0)
	visible = false
	_lines.clear()
	var wisp := _wisp()
	wisp.shine_speed_scale = _saved_shine_speed
	wisp.global_position = _return_position
	wisp.reset_physics_interpolation()
	_camera_rig().snap_to_target()
	_outer_darkling.keep_hold()
	_set_player_inside(false)
	_state = State.IDLE
	await _fade_to(0.0)


func _process(delta: float) -> void:
	_time += delta
	match _state:
		State.CHASE:
			_update_lines(delta, Input.is_action_pressed("draw"))
			_update_darkling(delta)
			if _inner_position.length() > BORDER:
				_begin_cleansing()
		State.CLEANSED:
			_update_lines(delta, false)
			_update_cleansing(delta)
	if visible:
		_animate_heart()
	_title.visible = visible and _state != State.IDLE
	_hint.visible = visible and _state == State.CHASE


# --- The chase ---------------------------------------------------------------

func _update_darkling(delta: float) -> void:
	var wisp := _wisp()
	var p := _inner_position

	# Mid-hop: it flies up over the lines toward the heart, then settles back to its usual hover.
	if _hop_left > 0.0:
		_hop_left -= delta
		var toward := -p.normalized() if p.length() > 0.01 else Vector2.ZERO
		_inner_velocity = toward * HOMING_SPEED * 1.3
		_inner_position += _inner_velocity * delta
		_place_inner_darkling(delta)
		return
	_check_trapped(delta)

	# It always heads back to the heart (circling it once there).
	var desire := Vector2.ZERO
	var to_heart := -p.normalized() if p.length() > 0.01 else Vector2.ZERO
	if p.length() > 0.8:
		desire = to_heart * HOMING_SPEED
	else:
		desire = Vector2(-p.y, p.x).normalized() * 0.6

	# If the wisp is in its way, it swings around it, toward whichever side is clearer.
	var w := _flat(wisp.global_position)
	var to_wisp := w - p
	var ahead := to_wisp.dot(to_heart)
	if ahead > -1.0 and ahead < p.length() + 1.0:
		var beside := to_wisp - to_heart * ahead  # How far the wisp is off to one side of its path.
		var off_path := beside.length()
		if off_path < DODGE_WIDTH:
			var dodge := -beside.normalized() if off_path > 0.05 else Vector2(-to_heart.y, to_heart.x)
			desire += dodge * DODGE_STRENGTH * (1.0 - off_path / DODGE_WIDTH)

	# The wisp's light pushes it away, hardest up close.
	var distance := p.distance_to(w)
	if wisp.is_shining and distance < SHINE_REACH:
		var away := (p - w).normalized() if distance > 0.01 else Vector2.UP
		desire += away * (1.5 + SHINE_PUSH * (1.0 - distance / SHINE_REACH))

	# It's wary of the lines of light, and veers off before it gets close.
	desire += _lines.repel(p, LINE_WARINESS) * LINE_PUSH

	_inner_velocity = _inner_velocity.lerp(desire, 1.0 - exp(-6.0 * delta))
	# It can't cross the wisp's lines of light: it slides along them instead.
	var step := _lines.slide(p, _inner_velocity * delta)
	if delta > 0.0:
		_inner_velocity = step / delta
	_inner_position += step
	_place_inner_darkling(delta)


## Every so often, check whether the lines have it completely walled in. If they have for a
## moment, it hops up and over them.
func _check_trapped(delta: float) -> void:
	_trap_check -= delta
	if _trap_check > 0.0:
		return
	_trap_check = 0.25
	if _lines.encloses(_inner_position):
		_trapped_time += 0.25
		if _trapped_time >= TRAPPED_TIME:
			_trapped_time = 0.0
			_hop_left = HOP_TIME
	else:
		_trapped_time = 0.0


func _update_lines(delta: float, drawing: bool) -> void:
	var wisp := _wisp()
	var pen := wisp.global_position - ORIGIN
	_lines.update(delta, pen, drawing, wisp.light_line_length)


# --- Cleansing ---------------------------------------------------------------

func _begin_cleansing() -> void:
	_state = State.CLEANSED
	_cleansed_time = 0.0
	_heart_flame.emitting = false
	_title.text = "The heart is free"
	_hint.text = ""


func _update_cleansing(delta: float) -> void:
	_cleansed_time += delta
	_cleansed = clampf(_cleansed_time / 1.2, 0.0, 1.0)
	_floor_material.set_shader_parameter("cleansed", _cleansed)
	_ring_material.emission = Color(0.9, 0.15, 0.1).lerp(Color(0.7, 0.85, 1.0), _cleansed)
	_heart_material.albedo_color = Color(0.06, 0.02, 0.03).lerp(Color(0.85, 0.12, 0.16), _cleansed)
	_heart_material.emission = Color(0.3, 0.0, 0.0).lerp(Color(0.9, 0.15, 0.18), _cleansed)
	_heart_light.light_color = Color(1.0, 0.2, 0.15).lerp(Color(0.75, 0.85, 1.0), _cleansed)

	# The darkling keeps drifting off into the dark and fades away.
	_inner_position += _inner_position.normalized() * 2.5 * delta
	_inner_fade = maxf(0.0, _inner_fade - delta / 1.5)
	_place_inner_darkling(delta)

	if _cleansed_time >= CLEANSED_TIME:
		_finish_cleansed()


func _finish_cleansed() -> void:
	_state = State.BUSY
	await _fade_to(1.0)
	visible = false
	_lines.clear()

	# Back out in the world: the darkling is cast out, and you're in the host's body.
	var wisp := _wisp()
	wisp.shine_speed_scale = _saved_shine_speed
	wisp.global_position = _host.get_core_position()
	wisp.reset_physics_interpolation()
	_outer_darkling.cast_out()
	_set_player_inside(false)
	_player().enter_body(_host)
	_camera_rig().snap_to_target()
	_state = State.IDLE
	await _fade_to(0.0)


# --- Building the chamber ----------------------------------------------------

func _reset_chamber() -> void:
	_cleansed = 0.0
	_inner_position = Vector2(0.0, -0.5)
	_inner_velocity = Vector2.ZERO
	_hop_left = 0.0
	_trapped_time = 0.0
	_inner_fade = 1.0
	_inner_darkling.set_fade(1.0)
	_floor_material.set_shader_parameter("cleansed", 0.0)
	_ring_material.emission = Color(0.9, 0.15, 0.1)
	_heart_material.albedo_color = Color(0.06, 0.02, 0.03)
	_heart_material.emission = Color(0.3, 0.0, 0.0)
	_heart_light.light_color = Color(1.0, 0.2, 0.15)
	_heart_flame.emitting = true
	_title.text = "Drive the darkling out of the heart"
	_hint.text = "Left Mouse  ·  Shine to push it away       Hold Right Mouse  ·  Draw light it can't cross       Tab  ·  Give up"
	_lines.clear()
	_place_inner_darkling(0.0)


func _build_chamber() -> void:
	# The floor: rough stone with gold veins (see heart_floor.gdshader).
	_floor_material = ShaderMaterial.new()
	_floor_material.shader = load("res://scripts/heart_floor.gdshader")
	_floor_material.set_shader_parameter("heart_position", ORIGIN)
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = FLOOR_RADIUS
	floor_mesh.bottom_radius = FLOOR_RADIUS
	floor_mesh.height = 1.0
	floor_mesh.radial_segments = 48
	floor_mesh.material = _floor_material
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -0.5
	add_child(floor_body)
	var floor_visual := MeshInstance3D.new()
	floor_visual.mesh = floor_mesh
	floor_body.add_child(floor_visual)
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = floor_mesh.create_convex_shape()
	floor_body.add_child(floor_shape)

	# An invisible round wall and ceiling keep the wisp inside.
	var wall_mesh := CylinderMesh.new()
	wall_mesh.top_radius = FLOOR_RADIUS - 1.0
	wall_mesh.bottom_radius = FLOOR_RADIUS - 1.0
	wall_mesh.height = 30.0
	var wall_shape := wall_mesh.create_trimesh_shape()
	wall_shape.backface_collision = true
	var wall_body := StaticBody3D.new()
	wall_body.position.y = 14.0
	add_child(wall_body)
	var wall_collision := CollisionShape3D.new()
	wall_collision.shape = wall_shape
	wall_body.add_child(wall_collision)

	# Darkness all around, beyond the floor.
	var dome := SphereMesh.new()
	dome.radius = 36.0
	dome.height = 72.0
	var dome_material := StandardMaterial3D.new()
	dome_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dome_material.cull_mode = BaseMaterial3D.CULL_FRONT
	dome_material.albedo_color = Color(0.008, 0.008, 0.02)
	dome.material = dome_material
	var dome_visual := MeshInstance3D.new()
	dome_visual.mesh = dome
	dome_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dome_visual)

	# The border: a faint glowing ring on the floor.
	var ring := TorusMesh.new()
	ring.inner_radius = BORDER - 0.12
	ring.outer_radius = BORDER + 0.12
	ring.rings = 96
	_ring_material = StandardMaterial3D.new()
	_ring_material.albedo_color = Color(0.1, 0.05, 0.05)
	_ring_material.emission_enabled = true
	_ring_material.emission = Color(0.9, 0.15, 0.1)
	_ring_material.emission_energy_multiplier = 1.5
	ring.material = _ring_material
	var ring_visual := MeshInstance3D.new()
	ring_visual.mesh = ring
	ring_visual.scale = Vector3(1.0, 0.2, 1.0)
	ring_visual.position.y = 0.02
	add_child(ring_visual)

	_build_heart()
	_build_pillars()

	_inner_darkling = DarklingShape.new()
	add_child(_inner_darkling)

	_lines = LightLines.new()
	add_child(_lines)


## The heart on its pedestal: two round lobes over a downward point.
func _build_heart() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.09, 0.085, 0.095)
	stone.roughness = 1.0
	var pedestal := CylinderMesh.new()
	pedestal.top_radius = 1.0
	pedestal.bottom_radius = 1.3
	pedestal.height = 0.7
	pedestal.radial_segments = 10
	pedestal.material = stone
	var pedestal_visual := MeshInstance3D.new()
	pedestal_visual.mesh = pedestal
	pedestal_visual.position.y = 0.35
	add_child(pedestal_visual)

	_heart = Node3D.new()
	_heart.position.y = 1.75
	add_child(_heart)
	_heart_material = StandardMaterial3D.new()
	_heart_material.emission_enabled = true
	_heart_material.roughness = 0.4
	for side in [-1.0, 1.0]:
		var lobe := SphereMesh.new()
		lobe.radius = 0.42
		lobe.height = 0.84
		lobe.material = _heart_material
		var lobe_visual := MeshInstance3D.new()
		lobe_visual.mesh = lobe
		lobe_visual.position = Vector3(0.27 * side, 0.18, 0.0)
		_heart.add_child(lobe_visual)
	var point := CylinderMesh.new()
	point.top_radius = 0.66
	point.bottom_radius = 0.0
	point.height = 0.9
	point.radial_segments = 12
	point.material = _heart_material
	var point_visual := MeshInstance3D.new()
	point_visual.mesh = point
	point_visual.position.y = -0.3
	point_visual.scale = Vector3(1.0, 1.0, 0.65)
	_heart.add_child(point_visual)

	# Black fire while the darkling holds it.
	var flame_holder := Node3D.new()
	flame_holder.position.y = 0.7
	add_child(flame_holder)
	_heart_flame = DarkFlame.new()
	_heart_flame.height = 1.9
	_heart_flame.radius = 0.75
	flame_holder.add_child(_heart_flame)

	_heart_light = OmniLight3D.new()
	_heart_light.position.y = 2.2
	_heart_light.light_energy = 2.0
	_heart_light.omni_range = 16.0
	add_child(_heart_light)


## Broken stone pillars standing in the dark around the edge.
func _build_pillars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.08, 0.075, 0.085)
	stone.roughness = 1.0
	for i in 9:
		var angle := TAU * i / 9.0 + rng.randf_range(-0.15, 0.15)
		var distance := rng.randf_range(15.5, 19.0)
		var pillar := CylinderMesh.new()
		pillar.top_radius = rng.randf_range(0.4, 0.6)
		pillar.bottom_radius = pillar.top_radius * 1.15
		pillar.height = rng.randf_range(2.0, 7.0)
		pillar.radial_segments = 6
		pillar.material = stone
		var visual := MeshInstance3D.new()
		visual.mesh = pillar
		visual.position = Vector3(cos(angle) * distance, pillar.height * 0.5, sin(angle) * distance)
		visual.rotation = Vector3(rng.randf_range(-0.12, 0.12), rng.randf(), rng.randf_range(-0.12, 0.12))
		add_child(visual)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	_title = _make_label(28, Color(1.0, 0.92, 0.85))
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.offset_top = 70.0
	layer.add_child(_title)
	_hint = _make_label(17, Color(1.0, 1.0, 1.0, 0.8))
	_hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint.offset_top = 112.0
	layer.add_child(_hint)

	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _make_label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.offset_left = -600.0
	label.offset_right = 600.0
	label.visible = false
	return label


# --- Helpers -----------------------------------------------------------------

func _animate_heart() -> void:
	# A heartbeat: two quick swells, then a rest. Weak and slow while corrupted.
	var rate := lerpf(0.6, 1.1, _cleansed)
	var t := fmod(_time * rate, 1.0)
	var beat := exp(-pow((t - 0.1) * 18.0, 2.0)) + 0.6 * exp(-pow((t - 0.3) * 18.0, 2.0))
	_heart.scale = Vector3.ONE * (1.0 + beat * lerpf(0.04, 0.12, _cleansed))
	_heart_light.light_energy = lerpf(1.6, 2.4, _cleansed) + beat * 0.8


func _place_inner_darkling(delta: float) -> void:
	# Its usual gentle bob, plus an arc up and back down while hopping over lines.
	var hop := sin(PI * (1.0 - _hop_left / HOP_TIME)) * HOP_HEIGHT if _hop_left > 0.0 else 0.0
	var height := HOVER + sin(_time * 1.6) * 0.15 + hop
	_inner_darkling.position = Vector3(_inner_position.x, height, _inner_position.y)
	_inner_darkling.set_fade(_inner_fade)
	if _inner_velocity.length() > 0.1 and delta > 0.0:
		var goal := atan2(-_inner_velocity.x, -_inner_velocity.y)
		_inner_darkling.rotation.y = lerp_angle(_inner_darkling.rotation.y, goal, 1.0 - exp(-6.0 * delta))


## A world position, as a spot on the chamber floor relative to the heart.
func _flat(world: Vector3) -> Vector2:
	return Vector2(world.x - ORIGIN.x, world.z - ORIGIN.z)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await tween.finished


func _set_player_inside(inside: bool) -> void:
	_player().in_heart = inside
	# Inside a heart, spirit view keeps its darkness but not its grey-navy wash,
	# so the red pulse (and later the bluish-white) show true.
	var atmosphere := get_tree().get_first_node_in_group("atmosphere") as Atmosphere
	if atmosphere:
		atmosphere.set_in_heart(inside)


func _wisp() -> Wisp:
	return get_tree().get_first_node_in_group("wisp") as Wisp


func _player() -> PlayerController:
	return get_tree().get_first_node_in_group("player_controller") as PlayerController


func _camera_rig() -> CameraRig:
	return get_tree().get_first_node_in_group("camera_rig") as CameraRig
