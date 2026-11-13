class_name BodyModel
extends Node3D
## A simple low-poly "pill person" built from basic shapes, for any species.
## - Human: the plain version.
## - Tar'ye: a little bigger, with fur, cat ears and a swishing tail.
## Can look like grey stone (a statue) or alive (colored), and animates as it moves.
## Faces -Z (Godot's "forward"). About 1.85 m tall (Tar'ye a little taller).

const STONE := Color(0.63, 0.62, 0.59)

## Colors for each species: skin/fur, top, trousers, eyes.
const PALETTES := {
	"Human": {
		"skin": Color(0.86, 0.68, 0.54), "top": Color(0.38, 0.50, 0.64),
		"trousers": Color(0.32, 0.29, 0.26), "eyes": Color(0.08, 0.07, 0.07),
	},
	"Tar'ye": {
		"skin": Color(0.82, 0.58, 0.32), "top": Color(0.50, 0.25, 0.20),
		"trousers": Color(0.30, 0.24, 0.18), "eyes": Color(0.55, 0.65, 0.12),
	},
}

## What the body is doing, set by its owner: "" (normal), "push" (shoving something heavy),
## or "struggle" (trying to lift something too heavy).
var pose := ""

var species := "Human"
var _parts: Array[Dictionary] = []  # { "material": StandardMaterial3D, "alive": Color }
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _tail: Array[Node3D] = []
var _tail_lag := 0.0
var _tail_lag_speed := 0.0
var _phase := 0.0
var _time := 0.0


func _init(species_name := "Human") -> void:
	species = species_name
	var colors: Dictionary = PALETTES.get(species, PALETTES["Human"])

	# Body and head.
	_add_part(self, _capsule(0.26, 0.80), Vector3(0.0, 1.18, 0.0), colors["top"])
	_add_part(self, _sphere(0.2, 0.4), Vector3(0.0, 1.74, 0.0), colors["skin"])

	# Eyes, so you can tell which way it's facing.
	for side in [-1.0, 1.0]:
		_add_part(self, _sphere(0.035, 0.07), Vector3(0.075 * side, 1.77, -0.175), colors["eyes"])

	# Legs hang from hip pivots; arms from shoulder pivots. Rotating a pivot swings the limb.
	_left_leg = _add_pivot(self, Vector3(-0.12, 0.86, 0.0))
	_right_leg = _add_pivot(self, Vector3(0.12, 0.86, 0.0))
	for leg in [_left_leg, _right_leg]:
		_add_part(leg, _capsule(0.105, 0.86), Vector3(0.0, -0.43, 0.0), colors["trousers"])

	_left_arm = _add_pivot(self, Vector3(-0.36, 1.46, 0.0))
	_right_arm = _add_pivot(self, Vector3(0.36, 1.46, 0.0))
	for arm in [_left_arm, _right_arm]:
		_add_part(arm, _capsule(0.085, 0.72), Vector3(0.0, -0.32, 0.0), colors["top"])
		_add_part(arm, _sphere(0.085, 0.17), Vector3(0.0, -0.66, 0.0), colors["skin"])

	if species == "Tar'ye":
		_add_cat_features(colors["skin"])
		scale = Vector3.ONE * 1.08


## Pointed ears on top of the head, and a long tail curling up from the lower back.
func _add_cat_features(fur: Color) -> void:
	for side in [-1.0, 1.0]:
		var ear := CylinderMesh.new()
		ear.top_radius = 0.0
		ear.bottom_radius = 0.075
		ear.height = 0.17
		ear.radial_segments = 4
		ear.rings = 1
		var holder := _add_pivot(self, Vector3(0.11 * side, 1.88, 0.01))
		holder.rotation.z = -0.3 * side
		_add_part(holder, ear, Vector3(0.0, 0.06, 0.0), fur)

	# The tail is a chain of segments; each bends a little from the one before.
	# It droops down from the lower back, then runs out mostly level, tip lifting slightly.
	var parent: Node3D = _add_pivot(self, Vector3(0.0, 0.92, 0.2))
	for i in 7:
		var segment := _add_pivot(parent, Vector3(0.0, 0.0, 0.0 if i == 0 else 0.13))
		segment.rotation.x = 0.4 if i == 0 else -0.04
		var piece := _capsule(lerpf(0.055, 0.035, i / 6.0), 0.17)
		var holder := _add_pivot(segment, Vector3(0.0, 0.0, 0.065))
		holder.rotation.x = PI / 2.0  # Lay the capsule along the tail.
		_add_part(holder, piece, Vector3.ZERO, fur)
		_tail.append(segment)
		parent = segment


## Turns the model to stone (a statue) or back to life.
## `gloom` (0 to 1) darkens the stone, e.g. when a darkling possesses it.
func set_stone(stone: bool, gloom := 0.0) -> void:
	for part in _parts:
		var material: StandardMaterial3D = part["material"]
		material.albedo_color = STONE.darkened(gloom) if stone else part["alive"]
		material.roughness = 1.0 if stone else 0.8


## Animates arms, legs and tail. `speed` is horizontal speed in m/s; `turn_rate` is how fast the
## body is turning (radians per second), so the tail can swing out behind on turns.
func animate(speed: float, swimming: bool, on_floor: bool, delta: float, alive := true, turn_rate := 0.0) -> void:
	_time += delta
	if alive:
		_animate_tail(speed, turn_rate, delta)
	if swimming and speed > 0.6:
		_animate_crawl(speed, delta)
		return

	var leg_swing := 0.0
	var arm_swing := 0.0
	var arm_spread := 0.0
	var arm_lift := 0.0  # Both arms raised forward together.

	if pose == "struggle":
		# Arms out to heave at it, trembling with effort; legs braced.
		arm_lift = 1.2 + sin(_time * 38.0) * 0.07
		leg_swing = 0.18
	elif pose == "push":
		# Arms braced forward against it, one leg planted behind to drive the shove.
		arm_lift = 1.45
		leg_swing = 0.4
	elif swimming:
		# Treading water: arms sweep gently out to the sides, legs kick slowly.
		_phase += delta * 3.0
		arm_swing = sin(_phase) * 0.35
		arm_spread = 0.7
		leg_swing = sin(_phase * 1.5) * 0.3
	elif not on_floor:
		arm_spread = 0.45
		leg_swing = 0.35
	else:
		_phase += delta * speed * 2.4
		var amount := clampf(speed / 4.5, 0.0, 1.4) * 0.65
		leg_swing = sin(_phase) * amount
		arm_swing = -sin(_phase) * amount * 0.8

	var blend := 1.0 - exp(-12.0 * delta)
	var alternate := on_floor or swimming or pose != ""
	_left_leg.rotation.x = lerpf(_left_leg.rotation.x, leg_swing, blend)
	_right_leg.rotation.x = lerpf(_right_leg.rotation.x, -leg_swing if alternate else leg_swing * 0.4, blend)
	var right_arm := (-arm_swing if not swimming else arm_swing) + arm_lift
	_left_arm.rotation.x = lerpf(_left_arm.rotation.x, arm_swing + arm_lift, blend)
	_right_arm.rotation.x = lerpf(_right_arm.rotation.x, right_arm, blend)
	_left_arm.rotation.z = lerpf(_left_arm.rotation.z, -arm_spread, blend)
	_right_arm.rotation.z = lerpf(_right_arm.rotation.z, arm_spread, blend)


## The tail swishes side to side in a wave that travels down to the tip, with an extra
## flick every few seconds, and swishes faster when moving.
## On top of that, it trails behind on turns: when the body turns, the tail swings out the other
## way, then springs back (like the wisp's tail lagging behind it).
func _animate_tail(speed: float, turn_rate: float, delta: float) -> void:
	if _tail.is_empty() or delta <= 0.0:
		return

	# A soft spring: the tail's lag chases "opposite the turn", overshoots a little, and settles.
	var lag_goal := clampf(-turn_rate * 0.12, -0.9, 0.9)
	_tail_lag_speed += ((lag_goal - _tail_lag) * 45.0 - _tail_lag_speed * 9.0) * delta
	_tail_lag += _tail_lag_speed * delta

	var swish := 2.0 + speed * 0.5
	var flick := pow(maxf(0.0, sin(_time * 0.9)), 12.0) * 0.35  # An occasional extra flick.
	for i in _tail.size():
		var along := float(i) / float(_tail.size() - 1)
		var sway := sin(_time * swish - i * 0.7) * (0.14 + along * 0.1 + flick)
		# The base takes most of the lag; the rest of the tail curves with it.
		var lag := _tail_lag * (0.5 if i == 0 else 0.12)
		_tail[i].rotation.y = sway * (0.6 if i == 0 else 1.0) + lag
		# A slight lift and droop as it swings.
		var lift := sin(_time * swish * 0.5 - i * 0.5) * 0.04
		var rest := 0.4 if i == 0 else -0.04
		_tail[i].rotation.x = rest + lift


## Front crawl, for swimming along lying flat: arms windmill in turn, legs flutter.
func _animate_crawl(speed: float, delta: float) -> void:
	_phase = wrapf(_phase + delta * (2.5 + speed), -PI, PI)
	var blend := 1.0 - exp(-12.0 * delta)
	# Arms circle all the way around the shoulder, half a turn apart: reaching forward over
	# the head, then pulling back under the body (that's what drives a swimmer forward).
	_left_arm.rotation.x = -_phase
	_right_arm.rotation.x = wrapf(-_phase + PI, -PI, PI)
	_left_arm.rotation.z = lerpf(_left_arm.rotation.z, -0.15, blend)
	_right_arm.rotation.z = lerpf(_right_arm.rotation.z, 0.15, blend)
	var kick := sin(_phase * 3.0) * 0.3
	_left_leg.rotation.x = lerpf(_left_leg.rotation.x, kick, blend)
	_right_leg.rotation.x = lerpf(_right_leg.rotation.x, -kick, blend)


func _add_pivot(parent: Node3D, at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	parent.add_child(pivot)
	return pivot


func _add_part(parent: Node3D, mesh: PrimitiveMesh, at: Vector3, alive_color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = alive_color
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	_parts.append({"material": material, "alive": alive_color})


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 3
	return mesh


func _sphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 6
	return mesh
