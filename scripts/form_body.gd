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
##
## Fayran fly: jump, then press Space again in mid-air to take off. Hold Space to beat your wings
## and climb (it tires you out), let go to glide slowly down, hold Shift to dive. You land when you
## touch the ground. The air is too thin to climb past a ceiling. Fayran can't swim: in deep water
## their wings soak through and they sink, and they can't fly again until their wings dry off.
##
## Kash (Sen-Kash and Qoi-Kash) slither on a serpent tail instead of walking, and jump only a little.
## Qoi-Kash are slow on land, but have gills: in water they're fast and can stay under as long as
## they like.

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

## Each species' abilities. `strong` bodies can shove heavy boulders; `fly` bodies can take off;
## bodies that can't `swim` sink in deep water; `gills` bodies are at home underwater.
const SPECIES := {
	"Human": {"walk": 4.5, "run": 7.0, "jump": 1.1, "swim": 2.6, "strong": false},
	"Tar'ye": {"walk": 5.0, "run": 8.5, "jump": 1.5, "swim": 2.0, "strong": true},
	"Fayran": {"walk": 4.6, "run": 7.2, "jump": 1.2, "swim": 0.0, "fly": true},
	"Sen-Kash": {"walk": 4.0, "run": 6.5, "jump": 0.6, "swim": 3.2},
	# On land, both Kash slither exactly alike; the Qoi-Kash's gift is the water.
	"Qoi-Kash": {"walk": 4.0, "run": 6.5, "jump": 0.6, "swim": 5.5, "gills": true},
}

## Flight (Fayran).
const FLY_SPEED := 8.5
const FLAP_CLIMB := 4.5
const GLIDE_SINK := 1.2
## The world's height limit: above this the air is too thin to climb. It's set high; the real
## limit on flying is energy.
const FLIGHT_CEILING := 120.0
## Flight energy (0-100): beating your wings uses it; it comes back
## on the ground. (Later this becomes hunger.) Enough to climb well above the giant trees.
const FLAP_COST := 6.0
## Gliding low (below the thin air), energy slowly comes back, so a Fayran can glide a long way.
## Up in the thin air it doesn't.
const GLIDE_RECOVERY := 3.0
const THIN_AIR := 40.0
## Kash: how fast the head can swing round (radians per second). Sets how tight a U-turn is.
const SERPENT_TURN_RATE := 3.5
## Kash float lower than walkers at the surface: just the shoulders and head out of the water.
const SERPENT_FLOAT_DEPTH := 1.5
## In flight the body lies nearly level (but not quite), legs trailing behind.
const FLIGHT_TILT := -1.2
## In flight the body pivots on the point between the wings (higher, and toward the back, compared
## with the hips it pivots on when walking).
const FLIGHT_PIVOT_RAISE := 0.52
const FLIGHT_PIVOT_BACK := 0.2
## Elytra-style flight. The camera's aim is nudged up slightly, so the camera's usual slight
## downward look gives a gentle, speed-keeping glide.
const FLIGHT_AIM_OFFSET := 0.035
## Shift (wings tucked) pitches you this much further down.
const DIVE_AIM_EXTRA := 0.5
## How strongly heading down speeds you up (and heading up slows you).
const FLIGHT_GRAVITY := 9.0
## Air resistance: sets cruising speed with W (~17 m/s level) and how fast a dive can get.
const FLIGHT_DRAG := 0.02
const FLIGHT_THRUST := 6.0
## In flight, Space only gives lift this close to the ground (meters): for short hops, not flying.
const SPACE_LIFT_HEIGHT := 1.0
const FLIGHT_TOP_SPEED := 40.0
## Below this speed you stall and start to sink.
const STALL_SPEED := 5.0

## Crashing: how much speed a collision has to knock off to break the body, depending on which
## way the body hits. Feet first is about a ~9 m drop; head first about half that; side-on or
## flat needs a really hard slam.
const CRASH_HEAD_FIRST := 12.0
const CRASH_FEET_FIRST := 23.0
const CRASH_SIDE_ON := 32.0

## Breath: seconds a body can stay with its head underwater. Gills never run out.
const BREATH := {"Human": 15.0, "Tar'ye": 12.0, "Fayran": 8.0, "Sen-Kash": 15.0}
const BREATH_RECOVERY := 4.0
## A statue falling further than this (meters) shatters when it lands. (For now it simply
## reappears on its plinth.)
const SHATTER_FALL := 10.0
const REST_RECOVERY := 35.0
## How long soaked wings take to dry after leaving deep water.
const SOAKED_TIME := 4.0

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
var can_fly := false
var can_swim := true
var has_gills := false

## Fayran: flying right now; flight energy (0-100); bumping the thin-air ceiling; wings soaked.
var is_flying := false
## Fayran: beating the wings right now (holding W in flight).
var is_flapping := false
var flight_energy := 100.0
var at_ceiling := false
var wings_soaked := false
## True while in water too deep to stand in (swimming, or for a Fayran, sinking).
var in_deep_water: bool:
	get:
		return _swimming
## Breath left (seconds), and how much this body has. Gills: infinite.
var breath := 15.0
var max_breath := 15.0

## Sent when this body drowns, or shatters from a fall; it then returns to its plinth.
signal lost(reason: String)

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
var _soaked_left := 0.0
## Where the statue started (its plinth), to return to after drowning or shattering.
var _home := Transform3D.IDENTITY
var _home_facing := 0.0
## Kash only: which way the head is heading. It turns toward where you want to go at a limited
## rate, so a Kash curves around in an arc (a U-turn) rather than spinning on the spot.
var _heading := 0.0
var serpent := false
var _tail_carried := false
## Fayran: current flying speed along the way you're heading.
var _flight_speed := 0.0
var _bank: Node3D
var _turn_rate := 0.0
## 0 on the ground, 1 in flight: in flight the body turns and tips around the chest (where the
## wings are) rather than the hips.
var _flight_pivot := 0.0
## While an empty statue is falling: the height it started falling from.
var _fall_from := NAN


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
	strong = stats.get("strong", false)
	can_fly = stats.get("fly", false)
	can_swim = swim_speed > 0.0
	has_gills = stats.get("gills", false)
	if has_gills:
		swim_vertical_speed = 3.5
	max_breath = INF if has_gills else BREATH.get(species, 15.0)
	breath = max_breath
	# Kash slither up steep slopes and steps that walkers can't.
	serpent = species == "Sen-Kash" or species == "Qoi-Kash"
	if serpent:
		floor_max_angle = deg_to_rad(70.0)
	_home = global_transform
	_home_facing = deg_to_rad(facing_degrees)
	_heading = _home_facing

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

	# Between the pose and the model: a joint that rolls the body along its spine (banking into a
	# turn in flight).
	_bank = Node3D.new()
	_pose.add_child(_bank)

	_model = BodyModel.new(species)
	_model.position.y = -POSE_PIVOT
	_bank.add_child(_model)
	_model.set_owner_body(self)
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
	is_flying = false
	is_flapping = false
	_swimming = false
	_fall_from = NAN if is_on_floor() else global_position.y
	_shove_left = 0.0
	_struggle_left = 0.0
	_step_back_left = 0.0
	_model.pose = ""
	_model.set_stone(true, 0.45 if haunted else 0.0)


## Puts the statue back on its plinth, as it started (after drowning or shattering).
func return_home() -> void:
	global_transform = _home
	velocity = Vector3.ZERO
	_pose.rotation = Vector3(0.0, _home_facing, 0.0)
	_pose.position = Vector3(0.0, POSE_PIVOT, 0.0)
	_model.position = Vector3(0.0, -POSE_PIVOT, 0.0)
	_bank.rotation = Vector3.ZERO
	_flight_pivot = 0.0
	_turn_rate = 0.0
	_heading = _home_facing
	_swimming = false
	is_flying = false
	breath = max_breath
	flight_energy = 100.0
	_soaked_left = 0.0
	_fall_from = NAN
	_settled = true
	reset_physics_interpolation()
	_model.reset_tail()


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

	at_ceiling = false
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
	_update_wings(delta, jump)
	if serpent:
		direction = _steer(direction, delta)

	# An empty statue that has come to rest stays exactly where it is, so you can always find it
	# again, and nothing (like a rolling boulder) can shove it around. An empty statue left in
	# mid-air or in water still falls or sinks until it lands.
	if _settled:
		velocity = Vector3.ZERO
	else:
		if _swimming and can_swim:
			_swim(delta, direction, rise, dive)
		elif _swimming:
			_sink(delta, direction)
		elif is_flying:
			_fly(delta, direction, rise, dive)
		else:
			_walk(delta, direction, jump)
		if not possessed and is_nan(_fall_from) and not is_on_floor() and velocity.y < 0.0:
			_fall_from = global_position.y  # An empty statue has started to fall.
		var before_hit := velocity
		move_and_slide()
		# Slamming into anything (the ground, a tree, a wall) can break the body: see _check_crash.
		if possessed and _check_crash(before_hit, velocity):
			_report_lost("crashed")
			return
		if not possessed and is_on_floor():
			_settled = true
			# A statue that fell a long way shatters. (For now, it just returns to its plinth.)
			if not is_nan(_fall_from) and _fall_from - global_position.y > SHATTER_FALL:
				return_home()
				_report_lost("shattered")
				return
			_fall_from = NAN
		if is_flying and is_on_floor():
			is_flying = false  # Landed.

	_update_breath(delta)

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var yaw_before := _pose.rotation.y
	_update_pose(delta, horizontal_speed)
	var turn_rate := angle_difference(yaw_before, _pose.rotation.y) / delta
	_turn_rate = lerpf(_turn_rate, turn_rate, 1.0 - exp(-8.0 * delta))
	_model.pose = "struggle" if is_struggling else ("push" if _shove_left > 0.0 else "")
	if is_flying:
		if dive:
			_model.wing_mode = "dive"
		else:
			_model.wing_mode = "flap" if is_flapping else "glide"
	else:
		_model.wing_mode = "folded"
	var standing := is_on_floor() or _settled
	# A body that can't swim just flails (treads water) rather than doing a swimming stroke.
	var stroke_speed := horizontal_speed if can_swim or not _swimming else 0.0
	_model.body_pitch = _pose.rotation.x
	_model.animate(stroke_speed, _swimming, standing, delta, possessed, turn_rate)
	if possessed:
		# On land the tail always lies along the ground, even mid-jump: only the torso lifts.
		# (In water, the tail responds to all movement, up and down included.)
		var tail_speed := velocity.length() if _swimming else horizontal_speed
		_model.update_serpent_tail(delta, tail_speed, _ground_height(), not _swimming, true, _swimming)
	elif not _settled:
		# An empty statue falling or sinking: the tail comes along with it, in one piece.
		_model.carry_serpent_tail()
		_tail_carried = _tail_carried or velocity.length() > 0.3
	elif _tail_carried:
		# ...and once it lands, the tail settles on the ground beside it.
		_model.settle_serpent_tail(global_position.y)
		_tail_carried = false
	else:
		_model.update_serpent_tail(delta, 0.0, global_position.y, true, false)


## Does a collision this frame break the body? It depends on how hard you hit (how much speed the
## collision took away) and which way the body was pointing into it:
## - head first: breaks at a fairly low speed;
## - feet first: in between (you'd break your legs, but landing that way slows you);
## - side-on or flat, like skidding along the ground: takes a really hard slam (and skidding along
##   barely loses any speed, so you usually just slide and survive).
func _check_crash(before: Vector3, after: Vector3) -> bool:
	var lost := before - after
	var impact := lost.length()
	if impact < CRASH_HEAD_FIRST:
		return false
	# Which way the head points (along the spine), versus the direction of the blow.
	var head := (_bank.global_basis.y).normalized()
	var into := head.dot(lost.normalized())  # 1 = head first, -1 = feet first, 0 = side-on / flat.
	var limit := lerpf(CRASH_SIDE_ON, CRASH_HEAD_FIRST, into) if into > 0.0 \
		else lerpf(CRASH_SIDE_ON, CRASH_FEET_FIRST, -into)
	return impact > limit


## Kash: the head swings round toward where you want to go at a limited rate, and the body always
## moves the way the head points. So turning around is a U-turn: the front curves round and heads
## back past the tail, and the tail follows the arc.
func _steer(wanted: Vector3, delta: float) -> Vector3:
	if wanted.length() < 0.1 or is_busy():
		return wanted
	var goal := atan2(-wanted.x, -wanted.z)
	_heading = rotate_toward(_heading, goal, SERPENT_TURN_RATE * delta)
	return Vector3(-sin(_heading), 0.0, -cos(_heading)) * wanted.length()


## How high the feet are above the ground below (a large number if there's no ground near).
func _height_above_ground() -> float:
	if is_on_floor():
		return 0.0
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.2, global_position + Vector3.DOWN * 3.0)
	ray.collision_mask = Layers.WORLD | Layers.THIN
	ray.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return global_position.y - (hit["position"] as Vector3).y if hit else INF


## The height of the ground under the body (even mid-jump), so a Kash's tail stays down.
func _ground_height() -> float:
	if is_on_floor():
		return global_position.y
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.2, global_position + Vector3.DOWN * 5.0)
	ray.collision_mask = Layers.WORLD | Layers.THIN
	ray.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return (hit["position"] as Vector3).y if hit else global_position.y


## How deep the body floats at the surface: walkers float with their chest at the surface; Kash
## sink lower, with only the shoulders and head out.
func _float_height() -> float:
	return sea_level - (SERPENT_FLOAT_DEPTH if serpent else CHEST + 0.05)


func _report_lost(reason: String) -> void:
	lost.emit(reason)
	get_tree().call_group("player_controller", "on_body_lost", self, reason)


## Holding your breath while your head is underwater; drowning when it runs out.
## Floating at the surface counts as breathing (even lying flat for a swimming stroke).
func _update_breath(delta: float) -> void:
	if not possessed or is_inf(max_breath):
		return
	var head_under := _swimming and global_position.y < _float_height() - 0.25
	if head_under:
		breath = maxf(0.0, breath - delta)
		if breath <= 0.0:
			_report_lost("drowned")
	else:
		breath = minf(max_breath, breath + BREATH_RECOVERY * delta)


## Fayran: taking off (Space in mid-air), and flight energy coming back on the ground.
func _update_wings(delta: float, jump: bool) -> void:
	if not can_fly:
		return
	if _swimming:
		_soaked_left = SOAKED_TIME
		is_flying = false
	else:
		_soaked_left = maxf(0.0, _soaked_left - delta)
	wings_soaked = _soaked_left > 0.0
	if is_on_floor() and not is_flying:
		flight_energy = minf(100.0, flight_energy + REST_RECOVERY * delta)
	if possessed and jump and not is_on_floor() and not is_flying and not _swimming \
			and not wings_soaked and flight_energy > 5.0:
		is_flying = true
		velocity.y = maxf(velocity.y, 2.0)
		_flight_speed = maxf(Vector2(velocity.x, velocity.z).length(), 6.0)


func _fly(delta: float, _direction: Vector3, rise: bool, dive: bool) -> void:
	# Elytra-style flight, steered entirely by the camera (mouse): you fly the way it points, up
	# and down as well as left and right. Look down to dive and pick up speed; look up to climb,
	# trading speed for height (climb too steeply and you slow, stall and sink).
	# W beats the wings: a push forward along wherever the camera points (up, down, any way),
	# using energy. Flapping in a dive drives you down even faster (a near-certain crash!).
	# S brakes, Shift tucks the wings for a faster, steeper dive, A/D drift a little to the side.
	# Space doesn't fly: it's only for jumping and taking off (and a little lift right near the
	# ground, for hopping a gap).
	var yaw := camera_rig.yaw if camera_rig else _pose.rotation.y
	var aim := (camera_rig.pitch if camera_rig else 0.0) + FLIGHT_AIM_OFFSET
	if dive:
		aim -= DIVE_AIM_EXTRA  # Tucking the wings pitches you down further.
	aim = clampf(aim, -1.45, 1.0)
	var look := Vector3(-sin(yaw) * cos(aim), sin(aim), -cos(yaw) * cos(aim))

	var throttle := 0.0
	var drift := 0.0
	if possessed:
		throttle = Input.get_axis("move_back", "move_forward")
		drift = Input.get_axis("move_left", "move_right")
	is_flapping = throttle > 0.1 and flight_energy > 0.0

	# Speed: heading down gains speed, heading up loses it; air resistance holds it back
	# (less with wings tucked; much more with S braking). Flapping pushes you on.
	_flight_speed += -look.y * FLIGHT_GRAVITY * delta
	var drag := FLIGHT_DRAG * (0.35 if dive else 1.0) * (4.0 if throttle < -0.1 else 1.0)
	_flight_speed -= drag * _flight_speed * _flight_speed * delta
	if is_flapping:
		_flight_speed += FLIGHT_THRUST * (1.5 if is_dashing else 1.0) * delta
		flight_energy = maxf(0.0, flight_energy - FLAP_COST * delta)
	elif global_position.y < sea_level + THIN_AIR:
		# Gliding low, energy slowly comes back (but never fully while airborne).
		flight_energy = minf(80.0, flight_energy + GLIDE_RECOVERY * delta)
	# (Gliding up in the thin air, it neither drains nor comes back.)
	_flight_speed = clampf(_flight_speed, 0.0, FLIGHT_TOP_SPEED)

	var goal := (look + look.cross(Vector3.UP).normalized() * drift * 0.3).normalized() * _flight_speed
	# Too slow to stay up: you stall and sink. (Flapping keeps you up.)
	var stall := clampf((STALL_SPEED - _flight_speed) / STALL_SPEED, 0.0, 1.0)
	if not is_flapping:
		goal.y -= GLIDE_SINK + stall * 5.0
	# Space: a little lift, only right near the ground (for hopping a gap or a step).
	if rise and _height_above_ground() < SPACE_LIFT_HEIGHT and flight_energy > 0.0:
		goal.y = maxf(goal.y, FLAP_CLIMB)
		flight_energy = maxf(0.0, flight_energy - FLAP_COST * delta)

	# Too high, and the air is too thin to climb any further.
	at_ceiling = global_position.y >= sea_level + FLIGHT_CEILING
	if at_ceiling and goal.y > 0.0:
		goal.y = 0.0
	velocity = velocity.lerp(goal, 1.0 - exp(-4.0 * delta))


## For bodies that can't swim (Fayran): in deep water they flounder and slowly sink.
func _sink(delta: float, direction: Vector3) -> void:
	var weight := 1.0 - exp(-3.0 * delta)
	velocity.x = lerpf(velocity.x, direction.x * 1.0, weight)
	velocity.z = lerpf(velocity.z, direction.z * 1.0, weight)
	velocity.y = lerpf(velocity.y, -1.4, weight)


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
	elif _swimming and is_on_floor() and global_position.y + CHEST > sea_level + 0.35:
		# Only once you're standing in the shallows (bobbing up at the surface doesn't count).
		_swimming = false


func _swim(delta: float, direction: Vector3, rise: bool, dive: bool) -> void:
	var weight := 1.0 - exp(-4.0 * delta)
	if serpent:
		# A Kash swims the way its head points (like slithering): it curves round to turn, and
		# never slides sideways through the water.
		var flat_speed := Vector2(velocity.x, velocity.z).length()
		flat_speed = lerpf(flat_speed, direction.length() * swim_speed, weight)
		var ahead := Vector3(-sin(_heading), 0.0, -cos(_heading))
		velocity.x = ahead.x * flat_speed
		velocity.z = ahead.z * flat_speed
	else:
		velocity.x = lerpf(velocity.x, direction.x * swim_speed, weight)
		velocity.z = lerpf(velocity.z, direction.z * swim_speed, weight)

	# Underwater you hold your depth unless you swim up or down.
	var vertical := 0.0
	if dive:
		vertical = -swim_vertical_speed
	elif rise:
		vertical = swim_vertical_speed

	# At the surface you float there, and can't swim up out of the water.
	var surface_height := _float_height()
	if global_position.y > surface_height - 0.1 and not dive:
		vertical = clampf((surface_height - global_position.y) * 4.0, -1.5, 1.5)

	velocity.y = lerpf(velocity.y, vertical, weight)
	# Don't shoot up out of the water when swimming up to the surface.
	if global_position.y > surface_height and velocity.y > 0.0:
		velocity.y = 0.0


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
		_heading = _pose.rotation.y
	elif serpent:
		# A Kash faces the way its head is heading (see _steer).
		_pose.rotation.y = lerp_angle(_pose.rotation.y, _heading, 1.0 - exp(-14.0 * delta))
	elif is_flying:
		# Birds swing round in wide, banked curves rather than snapping to a new heading.
		var flat := Vector3(velocity.x, 0.0, velocity.z)
		if flat.length() > 0.4:
			var goal_yaw := atan2(-flat.x, -flat.z)
			_pose.rotation.y = lerp_angle(_pose.rotation.y, goal_yaw, 1.0 - exp(-4.0 * delta))
	elif _step_back_left <= 0.0:
		var flat := Vector3(velocity.x, 0.0, velocity.z)
		if flat.length() > 0.4:
			_face(flat, delta)

	# Kash swim upright at the surface, driven by their tails like they slither on land; they only
	# stretch out flat once they dive below it.
	var serpent_at_surface := serpent and global_position.y > _float_height() - 0.4

	var goal_tilt := 0.0
	if _swimming and horizontal_speed > 0.6 and can_swim and not serpent_at_surface:
		goal_tilt = SWIM_TILT
	elif is_flying:
		# The body follows the flight path: nearly level when cruising, head down when diving,
		# more upright when climbing or hovering slowly.
		var flat_speed := Vector2(velocity.x, velocity.z).length()
		var path_pitch := atan2(velocity.y, maxf(flat_speed, 0.01))
		var cruising := clampf(velocity.length() / FLY_SPEED, 0.0, 1.0)
		goal_tilt = clampf(lerpf(-0.35, FLIGHT_TILT, cruising) + path_pitch * 0.9, -2.6, -0.2)
	elif _struggle_left > 0.0:
		goal_tilt = EFFORT_TILT
	elif _shove_left > 0.0:
		# Lean in, then drive forward hardest at the moment of the shove.
		var progress := 1.0 - _shove_left / SHOVE_TIME
		goal_tilt = EFFORT_TILT * (0.6 + 0.8 * sin(progress * PI))
	_pose.rotation.x = lerpf(_pose.rotation.x, goal_tilt, 1.0 - exp(-8.0 * delta))
	# A strained shudder while heaving.
	_pose.rotation.z = sin(Time.get_ticks_msec() * 0.045) * 0.04 if is_struggling else 0.0

	# In flight, turn around the chest (where the wings are), not the hips: raise the pivot to
	# chest height while flying, keeping the body exactly where it is when upright.
	_flight_pivot = lerpf(_flight_pivot, 1.0 if is_flying else 0.0, 1.0 - exp(-6.0 * delta))
	var pivot := POSE_PIVOT + FLIGHT_PIVOT_RAISE * _flight_pivot
	var back := FLIGHT_PIVOT_BACK * _flight_pivot
	_pose.position = Vector3(0.0, pivot, back)
	_model.position = Vector3(0.0, -pivot, -back)
	# ...and roll into turns like a bird: bank along the spine, more the sharper the turn.
	var goal_bank := clampf(-_turn_rate * 0.8, -0.8, 0.8) if is_flying else 0.0
	_bank.rotation.y = lerpf(_bank.rotation.y, goal_bank, 1.0 - exp(-5.0 * delta))
	_model.bank = _bank.rotation.y


func _face(toward: Vector3, delta: float) -> void:
	var goal_yaw := atan2(-toward.x, -toward.z)
	_pose.rotation.y = lerp_angle(_pose.rotation.y, goal_yaw, 1.0 - exp(-10.0 * delta))
