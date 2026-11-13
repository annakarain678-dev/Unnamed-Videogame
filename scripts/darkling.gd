class_name Darkling
extends Node3D
## A dark spirit, visible only in the wisp's spirit view.
##
## - Wandering: it drifts around its home. Its territory is the area around its home.
## - Seeking: if an empty statue stands in its territory, it goes and takes it over.
##   (Statues outside its territory are left alone.)
## - Possessing: it hides inside a host. The host burns with black fire in spirit view,
##   and looks gloomy to everyone else.
## - Shine on it long enough and it's driven off: for a while it's afraid, and keeps away from
##   the wisp, but it won't leave its territory (much). Then it forgets its fear and carries on,
##   and will take back an empty statue in its territory, so you have to chase it off again.
##   (It won't move into a statue while the wisp is right beside it.)
## - Stubborn darklings fight back: shining on a host they possess pulls the wisp inside, to the
##   host's heart, where you have to chase the darkling out past the edge (see HeartChase).

## Sent when it's driven out of the host it was possessing.
signal driven_out

## If set when it's added, the darkling starts out possessing this host.
var possess_host: FormBody

@export var wander_radius := 9.0
@export var wander_speed := 1.4
## Its territory: how far from home it roams, and will go to take over an empty statue.
@export var territory_radius := 14.0
## When fleeing, it may stray this much past the edge of its territory, but no further.
@export var territory_slack := 4.0
## How long (seconds) the wisp must shine on it to drive it off.
@export var endurance := 1.6
## Within this distance, the wisp's shine affects it.
@export var shine_reach := 7.0
## How long it stays afraid after being driven off.
@export var fear_time := 6.0
## While afraid, it keeps at least this far from the wisp.
@export var flee_distance := 12.0
@export var flee_speed := 3.0
## It won't take over a statue while the wisp is this close to it.
@export var statue_guard_distance := 8.0
## Chance (0 to 1) that, when shone out of a host, it fights back and you must chase it out of
## the host's heart. Set to 1 (always) for testing; the plan is about 0.3, varying with difficulty.
@export var stubborn_chance := 1.0

enum State { WANDER, SEEK, POSSESS, FLEE, CONTESTED }

## A fleeing darkling is fainter and smaller.
const COWER_FADE := 0.4
const COWER_SIZE := 0.6
## It never flees lower than this, or higher than this, above sea level.
const MIN_HEIGHT := 1.0
const MAX_HEIGHT := 20.0

var _state := State.WANDER
var _home := Vector3.ZERO
var _goal := Vector3.ZERO
var _target_body: FormBody
var _time := 0.0
var _exposure := 0.0
var _fear_left := 0.0
var _look_timer := 0.0
var _fade := 1.0
var _size := 1.0
var _shape: DarklingShape
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rng.randomize()
	_time = _rng.randf_range(0.0, 100.0)
	_home = global_position
	_goal = _home
	_shape = DarklingShape.new()
	add_child(_shape)
	if possess_host:
		var host := possess_host
		possess_host = null
		_possess(host)


func _process(delta: float) -> void:
	_time += delta
	var wisp := _active_wisp()

	match _state:
		State.WANDER:
			_wander(delta)
			_look_for_statue(wisp, delta)
			_react_to_shine(wisp, delta)
		State.SEEK:
			_seek(wisp, delta)
			_react_to_shine(wisp, delta)
		State.POSSESS:
			global_position = possess_host.get_core_position()
			_react_to_shine(wisp, delta)
		State.FLEE:
			_flee(wisp, delta)
		State.CONTESTED:
			# Fighting the wisp inside the host's heart; it stays hidden out here meanwhile.
			global_position = possess_host.get_core_position()

	# Bob gently; shrink and fade while fleeing or being shone on.
	var flinch := clampf(_exposure / endurance, 0.0, 1.0)
	var cowering := _state == State.FLEE
	var settle := 1.0 - exp(-4.0 * delta)
	_fade = lerpf(_fade, COWER_FADE if cowering else lerpf(1.0, 0.55, flinch), settle)
	_size = lerpf(_size, COWER_SIZE if cowering else lerpf(1.0, 0.7, flinch), settle)
	_shape.position.y = sin(_time * 1.6) * 0.15
	_shape.scale = Vector3.ONE * _size
	_shape.set_fade(_fade)


## Thrown out of its host for good (until it comes back for it): it appears, afraid, and flees.
func cast_out() -> void:
	if possess_host == null:
		return
	_shape.visible = true
	# Its territory now centers on the host, so it will come back for it.
	_home = possess_host.global_position + Vector3.UP * 2.0
	possess_host.set_haunted(false)
	possess_host = null
	driven_out.emit()
	_exposure = 0.0
	_fear_left = fear_time
	_target_body = null
	_state = State.FLEE


## The wisp gave up the fight in the heart: the darkling keeps its hold.
func keep_hold() -> void:
	_exposure = 0.0
	_state = State.POSSESS


func _wander(delta: float) -> void:
	if global_position.distance_to(_goal) < 0.5:
		var angle := _rng.randf_range(0.0, TAU)
		var reach := _rng.randf_range(0.0, wander_radius)
		_goal = _home + Vector3(cos(angle) * reach, _rng.randf_range(-1.0, 1.5), sin(angle) * reach)
	_move_toward(_goal, wander_speed, delta)


## Every so often, look for an empty statue inside its territory.
func _look_for_statue(wisp: Wisp, delta: float) -> void:
	_look_timer -= delta
	if _look_timer > 0.0:
		return
	_look_timer = 1.0
	for node in get_tree().get_nodes_in_group("form_bodies"):
		var body := node as FormBody
		if body and _can_take(body, wisp) and body.global_position.distance_to(_home) < territory_radius:
			_target_body = body
			_state = State.SEEK
			return


## An empty statue, with no other darkling in it, and the wisp not standing guard beside it.
func _can_take(body: FormBody, wisp: Wisp) -> bool:
	if body.possessed or body.haunted:
		return false
	return wisp == null or wisp.global_position.distance_to(body.get_core_position()) > statue_guard_distance


func _seek(wisp: Wisp, delta: float) -> void:
	# Give up if it's no longer free (the player got in, another darkling did, or the wisp is guarding it).
	if _target_body == null or not _can_take(_target_body, wisp):
		_target_body = null
		_state = State.WANDER
		return
	var spot := _target_body.get_core_position()
	_move_toward(spot, wander_speed * 1.8, delta)
	if global_position.distance_to(spot) < 0.4:
		_possess(_target_body)


func _possess(host: FormBody) -> void:
	possess_host = host
	_target_body = null
	_shape.visible = false
	host.set_haunted(true)
	_state = State.POSSESS


func _react_to_shine(wisp: Wisp, delta: float) -> void:
	var in_light := wisp != null and wisp.is_shining \
		and wisp.global_position.distance_to(global_position) < shine_reach
	if not in_light:
		_exposure = maxf(0.0, _exposure - delta * 0.5)
		return

	_exposure += delta
	if _state == State.WANDER or _state == State.SEEK:
		var away := (global_position - wisp.global_position).normalized()
		global_position += away * 1.2 * delta  # Recoil from the light.
	if _exposure < endurance:
		return

	if _state != State.POSSESS:
		# A wandering darkling just takes fright.
		_exposure = 0.0
		_fear_left = fear_time
		_target_body = null
		_state = State.FLEE
		return

	# Shone out of its host. A stubborn one fights back: the wisp is drawn into the host's heart.
	var chase := get_tree().get_first_node_in_group("heart_chase") as HeartChase
	if chase and _rng.randf() < stubborn_chance:
		_exposure = 0.0
		_state = State.CONTESTED
		chase.begin(self, possess_host)
	else:
		cast_out()


## While afraid, keep away from the wisp, but stay (mostly) inside its territory.
## When the fear wears off, go back to wandering as usual.
func _flee(wisp: Wisp, delta: float) -> void:
	_fear_left -= delta
	if _fear_left <= 0.0:
		_goal = global_position
		_state = State.WANDER
		return
	if wisp == null:
		return
	var offset := global_position - wisp.global_position
	if offset.length() >= flee_distance:
		return
	var away := Vector3(offset.x, 0.0, offset.z).normalized()
	if away == Vector3.ZERO:
		away = Vector3.FORWARD
	var spot := global_position + away * flee_speed * delta
	# Pinned at the edge of its territory, it slides along the edge instead of leaving.
	var from_home := Vector3(spot.x - _home.x, 0.0, spot.z - _home.z)
	var limit := territory_radius + territory_slack
	if from_home.length() > limit:
		from_home = from_home.normalized() * limit
		spot.x = _home.x + from_home.x
		spot.z = _home.z + from_home.z
	spot.y = clampf(spot.y, MIN_HEIGHT, MAX_HEIGHT)
	global_position = spot


## The wisp, if the player is currently the wisp. (Darklings can't sense bodies.)
func _active_wisp() -> Wisp:
	var wisp := get_tree().get_first_node_in_group("wisp") as Wisp
	return wisp if wisp and wisp.visible else null


func _move_toward(spot: Vector3, speed: float, delta: float) -> void:
	var offset := spot - global_position
	if offset.length() < 0.01:
		return
	global_position += offset.limit_length(speed * delta)
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), 1.0 - exp(-4.0 * delta))
