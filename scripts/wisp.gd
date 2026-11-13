class_name Wisp
extends CharacterBody3D
## The player's true form: a small, glowing speck of light that floats freely.
## WASD to drift, Space to rise, Shift to sink. Movement is relative to the camera.
## Double-tap W to dash (like sprinting in Minecraft); the dash lasts while W is held.

@export var camera_rig_path: NodePath
@export var speed := 7.0
@export var dash_speed := 10.5
## Two W presses within this many seconds start a dash (Minecraft uses 7 ticks = 0.35 s).
@export var double_tap_window := 0.35
@export var vertical_speed := 4.5
## How quickly the wisp reaches full speed or drifts to a stop (higher = snappier).
@export var responsiveness := 5.0
## The wisp can't rise above this height.
@export var max_height := 70.0
@export var glow_color := Color(1.0, 0.86, 0.55)

## True while dashing. The camera reads this to widen its view.
var is_dashing := false
## True while flaring bright (hold F). Darklings in reach are driven back.
var is_shining := false

@export var shine_speed_scale := 0.5
## How much line of light the wisp can draw (hold Left Mouse), in meters. Draw past it and the
## oldest part fades away. Meant to grow as the wisp grows (e.g. with darklings chased out),
## like a scarf that lengthens on a long journey.
@export var light_line_length := 12.0
## Height of the water's surface, so the glow is drawn correctly through it.
@export var sea_level := 0.0

var _time := 0.0
var _draw_order := 0
var _halo_material: StandardMaterial3D
var _last_forward_tap := -10.0
var _shine := 0.0  # 0..1, eases in and out
var _visual: Node3D
var _halo: MeshInstance3D
var _light: OmniLight3D
var _tail: WispTail
var _collision: CollisionShape3D

@onready var _camera_rig: CameraRig = get_node(camera_rig_path)


func _ready() -> void:
	add_to_group("wisp")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = Layers.WISP
	collision_mask = Layers.WORLD | Layers.THIN
	_build_collision()
	_build_visual()
	_build_tail()


func _physics_process(delta: float) -> void:
	_update_dash()

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var facing := Basis(Vector3.UP, _camera_rig.yaw)
	var horizontal := facing * Vector3(input.x, 0.0, input.y)
	var vertical := Input.get_axis("float_down", "float_up")

	is_shining = Input.is_action_pressed("shine")
	var current_speed := dash_speed if is_dashing else speed
	if is_shining:
		current_speed *= shine_speed_scale
	var desired := horizontal * current_speed + Vector3.UP * vertical * vertical_speed
	if global_position.y >= max_height and desired.y > 0.0:
		desired.y = 0.0

	velocity = velocity.lerp(desired, 1.0 - exp(-responsiveness * delta))
	move_and_slide()


func _process(delta: float) -> void:
	# A gentle bob and flicker so the light feels alive.
	_time += delta
	_visual.position.y = sin(_time * 2.0) * 0.12
	var flicker := sin(_time * 7.3) * 0.08 + sin(_time * 3.1) * 0.06

	# Shining: the halo swells, and the light grows brighter and reaches further.
	_shine = lerpf(_shine, 1.0 if is_shining else 0.0, 1.0 - exp(-8.0 * delta))
	_halo.scale = Vector3.ONE * lerpf(1.0, 2.4, _shine)
	_light.light_energy = lerpf(1.6, 5.0, _shine) + flicker
	_light.omni_range = lerpf(7.0, 14.0, _shine)
	_update_draw_order()


## See-through things are drawn back to front, and the huge sea surface can end up drawn first.
## When the wisp and camera are on opposite sides of the surface, draw the glow first so the
## water tints all of it (core, halo and tail alike), not just the solid core.
func _update_draw_order() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var camera_under := camera.global_position.y < sea_level
	var wisp_under := _visual.global_position.y < sea_level
	var order := -1 if camera_under != wisp_under else 1
	if order != _draw_order:
		_draw_order = order
		_halo_material.render_priority = order
		_tail.set_draw_order(order)


## Hides the wisp while it's inside a body, and brings it back when it leaves.
func set_active(active: bool) -> void:
	visible = active
	set_physics_process(active)
	_collision.disabled = not active
	velocity = Vector3.ZERO
	is_dashing = false
	is_shining = false
	reset_physics_interpolation()
	if active:
		_tail.reset()


func _update_dash() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if Input.is_action_just_pressed("move_forward"):
		if now - _last_forward_tap <= double_tap_window:
			is_dashing = true
		_last_forward_tap = now
	if not Input.is_action_pressed("move_forward"):
		is_dashing = false


func _build_collision() -> void:
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	_collision = CollisionShape3D.new()
	_collision.shape = shape
	add_child(_collision)


func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)

	# Bright core.
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.16
	core_mesh.height = 0.32
	var core_material := StandardMaterial3D.new()
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.albedo_color = Color.WHITE
	core_material.emission_enabled = true
	core_material.emission = glow_color
	core_material.emission_energy_multiplier = 6.0
	core_material.disable_fog = true  # The wisp's light cuts through haze and murky water.
	core_mesh.material = core_material
	var core := MeshInstance3D.new()
	core.mesh = core_mesh
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(core)

	# Soft halo around it.
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 0.38
	halo_mesh.height = 0.76
	var halo_material := StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.albedo_color = Color(glow_color, 0.22)
	halo_material.disable_fog = true
	_halo_material = halo_material
	halo_mesh.material = halo_material
	_halo = MeshInstance3D.new()
	_halo.mesh = halo_mesh
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(_halo)

	# The light it casts on the world around it.
	_light = OmniLight3D.new()
	_light.light_color = glow_color
	_light.omni_range = 7.0
	_light.shadow_enabled = false
	_visual.add_child(_light)


func _build_tail() -> void:
	_tail = WispTail.new()
	_tail.name = "Tail"
	_tail.anchor = _visual
	_tail.color = glow_color
	add_child(_tail)
