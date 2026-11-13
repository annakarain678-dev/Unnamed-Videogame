class_name CameraRig
extends Node3D
## Third-person camera that orbits and follows a target.
## Mouse to look. Esc frees the mouse; click to recapture it.
## (The scroll wheel is saved for switching inventory slots later.)
##
## The camera trails the target slightly, so the wisp can drift a little off-center while
## moving ("wiggle room") and settles back to the middle when it stops.

@export var target_path: NodePath
@export var mouse_sensitivity := 0.0025
@export var min_pitch_degrees := -75.0
@export var max_pitch_degrees := 45.0
## How quickly the camera catches up. Lower = more wiggle room.
@export var follow_speed := 5.5
## The furthest the wisp can drift from the center of the camera, in meters.
@export var max_lag := 2.5
@export var base_fov := 70.0
## Extra field of view while dashing, for a sense of speed.
@export var dash_fov_boost := 7.0

## Horizontal look angle in radians. The player uses it so "forward" means "away from the camera".
var yaw := 0.0
var pitch := deg_to_rad(-8.0)

var _target: Node3D
## How far above the target's origin the camera looks (e.g. a body's head height).
var _height := 0.0

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	# The camera moves every rendered frame itself, so it opts out of physics smoothing.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_to_group("camera_rig")
	_target = get_node(target_path)
	global_position = _target_position()

	var arm_shape := SphereShape3D.new()
	arm_shape.radius = 0.25
	_spring_arm.shape = arm_shape
	# Only big, solid things pull the camera in. It passes through thin things like statues.
	_spring_arm.collision_mask = Layers.WORLD
	_exclude_from_spring_arm(_target)

	_camera.fov = base_fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and captured:
		var motion := event as InputEventMouseMotion
		yaw -= motion.relative.x * mouse_sensitivity
		pitch = clampf(
			pitch - motion.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
	elif event is InputEventMouseButton and event.pressed:
		var button := event as InputEventMouseButton
		if not captured and button.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	var goal := _target_position()
	var weight := 1.0 - exp(-follow_speed * delta)
	var follow := global_position.lerp(goal, weight)
	# Never let the wisp drift too far from center.
	var lag := follow - goal
	if lag.length() > max_lag:
		follow = goal + lag.normalized() * max_lag
	global_position = follow
	rotation = Vector3(pitch, yaw, 0.0)

	var dashing: bool = _target.get("is_dashing") == true
	var goal_fov := base_fov + (dash_fov_boost if dashing else 0.0)
	_camera.fov = lerpf(_camera.fov, goal_fov, 1.0 - exp(-6.0 * delta))


## Jumps straight to the target (after a teleport), instead of gliding over.
func snap_to_target() -> void:
	global_position = _target_position()


## Switches what the camera follows. It glides over rather than jumping.
func set_target(target: Node3D, height: float) -> void:
	_spring_arm.clear_excluded_objects()
	_target = target
	_height = height
	_exclude_from_spring_arm(target)


## The target's smoothed (in-between physics ticks) position, so the camera never stutters.
func _target_position() -> Vector3:
	return _target.get_global_transform_interpolated().origin + Vector3.UP * _height


## Stops the camera from bumping into the thing it's following.
func _exclude_from_spring_arm(target: Node3D) -> void:
	if target is CollisionObject3D:
		_spring_arm.add_excluded_object((target as CollisionObject3D).get_rid())
