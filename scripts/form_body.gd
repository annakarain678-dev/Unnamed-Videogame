class_name FormBody
extends CharacterBody3D
## A statue the wisp can enter and bring to life. When left, it turns back to stone where it stands.
##
## While alive: WASD walk, double-tap W to run, Space to jump.
## In deep water: swims lying flat when moving. Space swims up, Shift dives.
## Underwater you stay at whatever depth you choose; at the surface you float.
##
## Heavy boulders: stand next to one and press Right Mouse to push it.
## A strong body (Tar'ye) braces and shoves it a couple of meters.
## A weaker body (Human) tries to heave it, struggles for a moment, then gives up and steps back.

## Which species this statue is. Sets its look and abilities (see SPECIES below).
@export var species := "Human"
## How high a jump goes, in meters.
@export var jump_height := 1.1
## Gravity multipliers. Falling faster than rising gives the jump weight instead of floatiness.
@export var rise_gravity_scale := 2.0
@export var fall_gravity_scale := 3.0
@export var swim_vertical_speed := 2.0
@export var sea_level := 0.0
## Which way the statue faces at the start, in degrees (0 = facing north, 180 = south).
@export var facing_degrees := 0.0
## Where the camera looks, measured up from the feet.
@export var camera_height := 1.5
@export var double_tap_window := 0.35

## Each species' abilities. `strong` bodies can shove heavy boulders.
const SPECIES := {
	"Human": {"walk": 4.5, "run": 7.0, "jump": 1.1, "swim": 2.6, "strong": false},
	"Tar'ye": {"walk": 5.0, "run": 8.5, "jump": 1.5, "swim": 2.0, "strong": true},
}

## Chest height above the feet. When the chest goes under water, the body swims.
const CHEST := 1.2
## How far the pose pivot (around the hips) sits above the feet. The body tilts around it to swim.
const POSE_PIVOT := 1.0
## Lying flat to swim (radians, tipping forward).
const SWIM_TILT := -1.35
## Leaning into a shove or a heave.
const EFFORT_TILT := -0.3
## How close (beyond the boulder's own size) you must stand to push it.
const PUSH_REACH := 1.0
## A shove: brace, then push at this moment, then recover.
const SHOVE_TIME := 0.9
const SHOVE_HIT := 0.55
## How long a too-weak body heaves at a boulder before giving up.
const STRUGGLE_TIME := 1.4
## The short step back after giving up.
const STEP_BACK_TIME := 0.25

## True while the wisp is inside this body.
var possessed := false
## True while a darkling possesses this statue. It can't be entered until the darkling is driven off.
var haunted := false
## True while running. The camera reads this to widen its view.
var is_dashing := false
## True while trying (and failing) to heave a boulder that's too heavy.
var is_struggling: bool:
	get:
		return _struggle_left > 0.0
var camera_rig: CameraRig

var walk_speed := 4.5
var run_speed := 7.0
var swim_speed := 2.6
var strong := false

var _pose: Node3D
var _model: BodyModel
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _last_forward_tap := -10.0
var _swimming := false
var _dark_flame: DarkFlame
var _shove_left := 0.0
var _shove_boulder: Boulder
var _shove_direction := Vector3.ZERO
var _struggle_left := 0.0
var _step_back_left := 0.0
## True once an empty statue has come to rest. It then stays put until entered.
var _settled := false


func _ready() -> void:
	add_to_group("form_bodies")
	# Bodies are "thin": they block the wisp and each other, but the camera passes through them.
	collision_layer = Layers.THIN
	collision_mask = Layers.WORLD | Layers.THIN | Layers.WISP

	var stats: Dictionary = SPECIES.get(species, SPECIES["Human"])
	walk_speed = stats["walk"]
	run_speed = stats["run"]
	jump_height = stats["jump"]
	swim_speed = stats["swim"]
	strong = stats["strong"]

	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.85
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.925
	add_child(collision)

	# The model hangs from a pivot at hip height, so it can turn to face and tip over to swim.
	_pose = Node3D.new()
	_pose.position.y = POSE_PIVOT
	_pose.rotation.y = deg_to_rad(facing_degrees)
	add_child(_pose)

	_model = BodyModel.new(species)
	_model.position.y = -POSE_PIVOT
	_pose.add_child(_model)
	_model.set_stone(true)


## The wisp enters: the statue comes to life.
func possess(rig: CameraRig) -> void:
	possessed = true
	_settled = false
	camera_rig = rig
	_model.set_stone(false)


## The wisp leaves: the body turns back to stone where it stands.
func release() -> void:
	possessed = false
	is_dashing = false
	_swimming = false
	_shove_left = 0.0
	_struggle_left = 0.0
	_step_back_left = 0.0
	_model.pose = ""
	_model.set_stone(true, 0.45 if haunted else 0.0)


## A darkling possesses this statue, or is driven out of it.
## In spirit view, a possessed statue burns with black fire. To everyone else, its stone just
## looks darker and gloomier: a clue even for bodies that can't see darklings.
func set_haunted(value: bool) -> void:
	haunted = value
	if not possessed:
		_model.set_stone(true, 0.45 if haunted else 0.0)
	if haunted and _dark_flame == null:
		_dark_flame = DarkFlame.new()
		add_child(_dark_flame)
	elif not haunted and _dark_flame:
		_dark_flame.queue_free()
		_dark_flame = null


## Roughly the middle of the chest. Used to check how close the wisp is.
func get_core_position() -> Vector3:
	return global_position + Vector3.UP * 1.15


## True while busy shoving, heaving, or stepping back (movement is paused).
func is_busy() -> bool:
	return _shove_left > 0.0 or _struggle_left > 0.0 or _step_back_left > 0.0


## The closest boulder within pushing reach, or null.
func nearby_boulder() -> Boulder:
	var nearest: Boulder = null
	var nearest_gap := PUSH_REACH
	for node in get_tree().get_nodes_in_group("boulders"):
		var boulder := node as Boulder
		var offset := boulder.global_position - global_position
		offset.y = 0.0
		var gap := offset.length() - boulder.radius - 0.32
		if gap < nearest_gap:
			nearest = boulder
			nearest_gap = gap
	return nearest


func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	var jump := false
	var rise := false
	var dive := false

	if possessed and not is_busy():
		_update_run()
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if camera_rig:
			direction = Basis(Vector3.UP, camera_rig.yaw) * Vector3(input.x, 0.0, input.y)
		jump = Input.is_action_just_pressed("float_up")
		rise = Input.is_action_pressed("float_up")
		dive = Input.is_action_pressed("float_down")
		if Input.is_action_just_pressed("push") and not _swimming:
			_try_push()

	_update_actions(delta)
	_update_swimming()

	# An empty statue that has come to rest stays exactly where it is, so you can always find it
	# again, and nothing (like a rolling boulder) can shove it around. An empty statue left in
	# mid-air or in water still falls or sinks until it lands.
	if _settled:
		velocity = Vector3.ZERO
	else:
		if _swimming:
			_swim(delta, direction, rise, dive)
		else:
			_walk(delta, direction, jump)
		move_and_slide()
		if not possessed and is_on_floor():
			_settled = true

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var yaw_before := _pose.rotation.y
	_update_pose(delta, horizontal_speed)
	var turn_rate := angle_difference(yaw_before, _pose.rotation.y) / delta
	_model.pose = "struggle" if is_struggling else ("push" if _shove_left > 0.0 else "")
	_model.animate(horizontal_speed, _swimming, is_on_floor() or _settled, delta, possessed, turn_rate)


## Push the boulder in front of you: a strong body shoves it; a weak one struggles.
func _try_push() -> void:
	var boulder := nearby_boulder()
	if boulder == null:
		return
	_shove_direction = boulder.global_position - global_position
	_shove_direction.y = 0.0
	_shove_direction = _shove_direction.normalized()
	if strong:
		_shove_boulder = boulder
		_shove_left = SHOVE_TIME
	else:
		_struggle_left = STRUGGLE_TIME


func _update_actions(delta: float) -> void:
	if _shove_left > 0.0:
		var before := _shove_left
		_shove_left -= delta
		# The moment of the shove itself.
		var hit_at := SHOVE_TIME - SHOVE_HIT
		if before > hit_at and _shove_left <= hit_at and _shove_boulder:
			_shove_boulder.shove(_shove_direction)
			_shove_boulder = null
	elif _struggle_left > 0.0:
		_struggle_left -= delta
		if _struggle_left <= 0.0:
			_step_back_left = STEP_BACK_TIME  # Give up, and step back.
	elif _step_back_left > 0.0:
		_step_back_left -= delta


func _walk(delta: float, direction: Vector3, jump: bool) -> void:
	var speed := run_speed if is_dashing else walk_speed
	var grip := 12.0 if is_on_floor() else 2.5
	var weight := 1.0 - exp(-grip * delta)
	velocity.x = lerpf(velocity.x, direction.x * speed, weight)
	velocity.z = lerpf(velocity.z, direction.z * speed, weight)

	if _step_back_left > 0.0:
		velocity.x = -_shove_direction.x * 2.5
		velocity.z = -_shove_direction.z * 2.5

	if is_on_floor():
		if jump:
			# Launch speed that reaches exactly `jump_height` under the rising gravity.
			velocity.y = sqrt(2.0 * _gravity * rise_gravity_scale * jump_height)
	else:
		var heaviness := rise_gravity_scale if velocity.y > 0.0 else fall_gravity_scale
		velocity.y -= _gravity * heaviness * delta


## Starts swimming when the chest goes under; stops once standing in shallow water.
## (The gap between the two stops it flickering back and forth.)
## Stone doesn't swim: an empty statue just sinks.
func _update_swimming() -> void:
	if not possessed:
		_swimming = false
	elif not _swimming and global_position.y + CHEST < sea_level:
		_swimming = true
	elif _swimming and global_position.y + CHEST > sea_level + 0.35:
		_swimming = false


func _swim(delta: float, direction: Vector3, rise: bool, dive: bool) -> void:
	var weight := 1.0 - exp(-4.0 * delta)
	velocity.x = lerpf(velocity.x, direction.x * swim_speed, weight)
	velocity.z = lerpf(velocity.z, direction.z * swim_speed, weight)

	# Underwater you hold your depth unless you swim up or down.
	var vertical := 0.0
	if dive:
		vertical = -swim_vertical_speed
	elif rise:
		vertical = swim_vertical_speed

	# At the surface you float there, and can't swim up out of the water.
	var surface_height := sea_level - CHEST - 0.05
	if global_position.y > surface_height - 0.1 and not dive:
		vertical = clampf((surface_height - global_position.y) * 4.0, -1.5, 1.5)

	velocity.y = lerpf(velocity.y, vertical, weight)


func _update_run() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if Input.is_action_just_pressed("move_forward"):
		if now - _last_forward_tap <= double_tap_window:
			is_dashing = true
		_last_forward_tap = now
	if not Input.is_action_pressed("move_forward"):
		is_dashing = false


## Turns the body to face where it's going (or the boulder it's pushing), lies it flat while
## swimming along, and leans it into a shove or a heave.
func _update_pose(delta: float, horizontal_speed: float) -> void:
	if _shove_left > 0.0 or _struggle_left > 0.0:
		_face(_shove_direction, delta)
	elif _step_back_left <= 0.0:
		var flat := Vector3(velocity.x, 0.0, velocity.z)
		if flat.length() > 0.4:
			_face(flat, delta)

	var goal_tilt := 0.0
	if _swimming and horizontal_speed > 0.6:
		goal_tilt = SWIM_TILT
	elif _struggle_left > 0.0:
		goal_tilt = EFFORT_TILT
	elif _shove_left > 0.0:
		# Lean in, then drive forward hardest at the moment of the shove.
		var progress := 1.0 - _shove_left / SHOVE_TIME
		goal_tilt = EFFORT_TILT * (0.6 + 0.8 * sin(progress * PI))
	_pose.rotation.x = lerpf(_pose.rotation.x, goal_tilt, 1.0 - exp(-8.0 * delta))
	# A strained shudder while heaving.
	_pose.rotation.z = sin(Time.get_ticks_msec() * 0.045) * 0.04 if is_struggling else 0.0


func _face(toward: Vector3, delta: float) -> void:
	var goal_yaw := atan2(-toward.x, -toward.z)
	_pose.rotation.y = lerp_angle(_pose.rotation.y, goal_yaw, 1.0 - exp(-10.0 * delta))
