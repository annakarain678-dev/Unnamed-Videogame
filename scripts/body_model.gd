class_name BodyModel
extends Node3D
## A simple low-poly "pill person" built from basic shapes, for any species.
## - Human: the plain version.
## - Tar'ye: a little bigger, with fur, cat ears and a swishing tail.
## - Fayran: a Human with a pair of feathered wings from the upper shoulders.
## - Sen-Kash: a human upper body on a long snake tail, in jewel tones (green, gold, red, tan).
## - Qoi-Kash: a human upper body on a dark eel tail, with a dorsal fin down the back to the tip
##   and gills on the sides of the torso. Shark-like skin rather than scales.
## Can look like grey stone (a statue) or alive (colored), and animates as it moves.
## Faces -Z (Godot's "forward"). About 1.85 m tall (Tar'ye a little taller).

const STONE := Color(0.63, 0.62, 0.59)

## Colors for each species: skin/fur, top, trousers, eyes (and, for Kash, the tail's bands).
const PALETTES := {
	"Human": {
		"skin": Color(0.86, 0.68, 0.54), "top": Color(0.38, 0.50, 0.64),
		"trousers": Color(0.32, 0.29, 0.26), "eyes": Color(0.08, 0.07, 0.07),
	},
	"Tar'ye": {
		"skin": Color(0.82, 0.58, 0.32), "top": Color(0.50, 0.25, 0.20),
		"trousers": Color(0.30, 0.24, 0.18), "eyes": Color(0.55, 0.65, 0.12),
	},
	"Fayran": {
		"skin": Color(0.90, 0.74, 0.62), "top": Color(0.88, 0.84, 0.74),
		"trousers": Color(0.62, 0.56, 0.48), "eyes": Color(0.25, 0.35, 0.55),
		"feathers": Color(0.96, 0.95, 0.91), "feather_tips": Color(0.80, 0.78, 0.74),
	},
	"Sen-Kash": {
		"skin": Color(0.78, 0.62, 0.42), "top": Color(0.80, 0.62, 0.20),
		"eyes": Color(0.85, 0.65, 0.10),
		# Jewel-toned scale bands: emerald, gold, emerald, ruby...
		"bands": [Color(0.16, 0.45, 0.30), Color(0.78, 0.60, 0.22), Color(0.16, 0.45, 0.30),
			Color(0.20, 0.52, 0.34), Color(0.62, 0.16, 0.14), Color(0.16, 0.45, 0.30)],
	},
	"Qoi-Kash": {
		"skin": Color(0.22, 0.27, 0.32), "top": Color(0.18, 0.22, 0.27),
		"eyes": Color(0.82, 0.88, 0.92), "fin": Color(0.10, 0.13, 0.17),
		"gills": Color(0.45, 0.12, 0.14),
		# Shark-like: dark slate, a shade lighter in places.
		"bands": [Color(0.20, 0.24, 0.29), Color(0.22, 0.27, 0.32)],
	},
}

## What the body is doing, set by its owner: "" (normal), "push" (shoving something heavy),
## or "struggle" (trying to lift something too heavy).
var pose := ""
## Fayran only: "folded" (at rest), "flap" (flying upward), or "glide" (wings spread).
var wing_mode := "folded"

var species := "Human"
## True for the Kash, who have a serpent tail instead of legs.
var serpent := false
var _serpent_tail: KashTail
var _hips: Node3D
var _wings: Array[Dictionary] = []  # { "shoulder", "elbow", "side" }
var _wing_flap := 0.0
## How far the body is tipped forward (set by the body each frame), so the wings can stay level.
var body_pitch := 0.0
## How far the body is rolled into a turn (set by the body), for the wings and legs to follow.
var bank := 0.0
var _ankle_fins: Array[Dictionary] = []
var _parts: Array[Dictionary] = []  # { "material": StandardMaterial3D, "alive": Color }
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _tail: Array[Node3D] = []
var _tail_lag := 0.0
var _tail_lag_speed := 0.0
var _tail_turn := 0.0
var _phase := 0.0
var _time := 0.0


func _init(species_name := "Human") -> void:
	species = species_name
	var colors: Dictionary = PALETTES.get(species, PALETTES["Human"])
	if species == "Sen-Kash" or species == "Qoi-Kash":
		serpent = true
		_build_kash(colors)
		return

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
	elif species == "Fayran":
		_add_wings(colors["feathers"], colors["feather_tips"])


## A Kash: a human upper body rising from a serpent tail. The upper body sits a little higher than
## a Human's, and the tail starts at the hips and drags along the ground behind.
func _build_kash(colors: Dictionary) -> void:
	var bands: Array = colors["bands"]
	var eel := species == "Qoi-Kash"

	# Where body meets tail: a rounded hip, in the tail's first color.
	_hips = _add_pivot(self, Vector3(0.0, 0.62, 0.05))
	_add_part(_hips, _sphere(0.27, 0.5), Vector3.ZERO, bands[0])

	# Upper body, head and arms.
	_add_part(self, _capsule(0.26, 0.9), Vector3(0.0, 1.15, 0.0), colors["top"])
	var head := _sphere(0.2, 0.4)
	_add_part(self, head, Vector3(0.0, 1.78, 0.0), colors["skin"])
	if eel:
		# A slightly longer, sleeker head, and a crest that runs into the dorsal fin.
		(get_child(get_child_count() - 1) as Node3D).scale = Vector3(0.95, 1.0, 1.15)
		var crest := BoxMesh.new()
		crest.size = Vector3(0.025, 0.16, 0.34)
		_add_part(self, crest, Vector3(0.0, 1.94, 0.04), colors["fin"])
		var back_fin := BoxMesh.new()
		back_fin.size = Vector3(0.025, 0.22, 0.75)
		var fin_holder := _add_pivot(self, Vector3(0.0, 1.2, 0.24))
		fin_holder.rotation.x = -1.35  # Running down the back.
		_add_part(fin_holder, back_fin, Vector3.ZERO, colors["fin"])
		# Gills: three slits on each side of the torso.
		for side in [-1.0, 1.0]:
			for k in 3:
				var slit := BoxMesh.new()
				slit.size = Vector3(0.02, 0.025, 0.16)
				var slit_holder := _add_pivot(self, Vector3(0.25 * side, 1.38 - k * 0.07, -0.02))
				slit_holder.rotation.y = 0.15 * side
				_add_part(slit_holder, slit, Vector3.ZERO, colors["gills"])
	else:
		# A gold collar, jewel-bright against the scales.
		var collar := CylinderMesh.new()
		collar.top_radius = 0.2
		collar.bottom_radius = 0.26
		collar.height = 0.08
		collar.radial_segments = 12
		_add_part(self, collar, Vector3(0.0, 1.55, 0.0), Color(0.85, 0.68, 0.22))

	# Eyes: narrow slits, gold for a snake, pale for an eel.
	for side in [-1.0, 1.0]:
		var eye := _sphere(0.035, 0.07)
		_add_part(self, eye, Vector3(0.075 * side, 1.81, -0.18 if not eel else -0.215), colors["eyes"])
		(get_child(get_child_count() - 1) as Node3D).scale = Vector3(1.0, 0.55, 1.0)

	_left_arm = _add_pivot(self, Vector3(-0.36, 1.5, 0.0))
	_right_arm = _add_pivot(self, Vector3(0.36, 1.5, 0.0))
	for arm in [_left_arm, _right_arm]:
		_add_part(arm, _capsule(0.085, 0.72), Vector3(0.0, -0.32, 0.0), colors["skin"])
		_add_part(arm, _sphere(0.085, 0.17), Vector3(0.0, -0.66, 0.0), colors["skin"])

	# The tail: Sen-Kash are longer; Qoi-Kash have a fin down to the tip.
	_serpent_tail = KashTail.new()
	_serpent_tail.anchor = _hips
	_serpent_tail.side_reference = self
	_serpent_tail.segment_count = 18 if not eel else 15
	_serpent_tail.spacing = 0.22
	_serpent_tail.radius_start = 0.25
	_serpent_tail.radius_end = 0.04
	_serpent_tail.has_fin = eel
	if eel:
		_serpent_tail.fin_color = colors["fin"]
	var tail_colors: Array[Color] = []
	for band in bands:
		tail_colors.append(band)
	_serpent_tail.colors = tail_colors
	add_child(_serpent_tail)


## A pair of feathered wings from the upper shoulders, each with two joints, like a bird's
## (or a chicken's) wing bones: from the shoulder, the upper wing rises to a bend just above the
## head; from that bend, the lower wing (with the long flight feathers) folds back down toward the
## feet. In flight both parts unfold and spread out to the sides.
func _add_wings(feathers: Color, tips: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder := _add_pivot(self, Vector3(0.14 * side, 1.52, 0.2))
		var upper := BoxMesh.new()
		upper.size = Vector3(0.65, 0.12, 0.1)
		_add_part(shoulder, upper, Vector3(0.325 * side, 0.0, 0.0), feathers)
		# Shorter covert feathers along the upper wing.
		for k in 3:
			var covert := BoxMesh.new()
			covert.size = Vector3(0.2, 0.03, 0.35)
			_add_part(shoulder, covert, Vector3((0.12 + k * 0.2) * side, -0.02, 0.17), feathers)

		# The lower wing is long: folded, it reaches from the bend above the head almost down to
		# the feet (stopping just short of the ground). Its flight feathers taper toward the tip.
		var elbow := _add_pivot(shoulder, Vector3(0.65 * side, 0.0, 0.0))
		var lower_length := 1.95
		var lower := BoxMesh.new()
		lower.size = Vector3(lower_length, 0.1, 0.09)
		_add_part(elbow, lower, Vector3(lower_length * 0.5 * side, 0.0, 0.0), feathers)
		var feather_count := 9
		for k in feather_count:
			var along := float(k) / float(feather_count - 1)
			var length := lerpf(0.85, 0.3, along * along)  # Longest near the bend, tapering off.
			var feather := BoxMesh.new()
			feather.size = Vector3(0.21, 0.03, length)
			var x := (0.1 + along * (lower_length - 0.15)) * side
			_add_part(elbow, feather, Vector3(x, -0.02, length * 0.5), tips if k % 2 == 1 else feathers)
		_wings.append({"shoulder": shoulder, "elbow": elbow, "side": side})
	_set_wings(0.0, 0.0, 1.0)

	# No tail feathers (on purpose). Instead, a fan of feathers on the outer side of each ankle.
	# On the ground they lie flat along the lower leg (clear of the ground). In flight they spread
	# out to the side like an airplane's tail fins (or a kite), sweeping a little up the leg, to
	# catch the wind and hold the legs up, keeping the body nearly level.
	for leg_side: float in [-1.0, 1.0]:
		var leg := _left_leg if leg_side < 0.0 else _right_leg
		var fin := _add_pivot(leg, Vector3(0.08 * leg_side, -0.5, 0.02))
		for k in 5:
			var feather := BoxMesh.new()
			feather.size = Vector3(0.07, 0.26, 0.015)
			var fan := _add_pivot(fin, Vector3(0.0, -0.04 * k, 0.0))
			fan.rotation.z = (k - 2) * 0.06 * leg_side  # Nearly parallel: a squarish panel, not a fan.
			_add_part(fan, feather, Vector3(0.0, -0.12, 0.0), tips if k % 2 == 1 else feathers)
		_ankle_fins.append({"pivot": fin, "side": leg_side})


## Fayran ankle fins: 0 = lying flat down the foot; 1 = spread out to the side and a little up the leg.
func _set_ankle_fins(spread: float, blend: float) -> void:
	for fin in _ankle_fins:
		var pivot: Node3D = fin["pivot"]
		var side: float = fin["side"]
		pivot.rotation.z = lerpf(pivot.rotation.z, spread * 1.75 * side, blend)


## Positions the wings: `spread` 0 = folded (upper wing up past the head, lower wing folded back
## down toward the feet), 1 = both parts straight out to the sides. `beat` adds a flap.
## While spread, the wings stay level with the ground however far the body leans into the flight.
func _set_wings(spread: float, beat: float, blend: float) -> void:
	for wing in _wings:
		var side: float = wing["side"]
		var shoulder: Node3D = wing["shoulder"]
		var elbow: Node3D = wing["elbow"]
		# Shoulder: folded, the upper wing points up and a little out, swept back; spread, sideways.
		# Banking into a turn: the inner wing dips, the outer one lifts.
		var turn_tilt := -bank * 0.5 * side * spread
		var shoulder_z := lerpf(1.25, 0.0, spread) * side + beat * side + turn_tilt
		var shoulder_y := lerpf(-0.45, 0.0, spread) * side
		# Lean the wing back against the body's tilt, so it stays level in flight.
		var shoulder_x := -body_pitch * spread
		# Elbow: folded, the lower wing bends right back down toward the feet; spread, straight out.
		var elbow_z := lerpf(-2.75, 0.0, spread) * side - beat * 0.35 * side
		shoulder.rotation.z = lerp_angle(shoulder.rotation.z, shoulder_z, blend)
		shoulder.rotation.y = lerp_angle(shoulder.rotation.y, shoulder_y, blend)
		shoulder.rotation.x = lerp_angle(shoulder.rotation.x, shoulder_x, blend)
		elbow.rotation.z = lerp_angle(elbow.rotation.z, elbow_z, blend)


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
	var all_parts := _parts.duplicate()
	if _serpent_tail:
		all_parts.append_array(_serpent_tail.parts)
	for part in all_parts:
		var material: StandardMaterial3D = part["material"]
		material.albedo_color = STONE.darkened(gloom) if stone else part["alive"]
		material.roughness = 1.0 if stone else 0.8


## Animates arms, legs and tail. `speed` is horizontal speed in m/s; `turn_rate` is how fast the
## body is turning (radians per second), so the tail can swing out behind on turns.
func animate(speed: float, swimming: bool, on_floor: bool, delta: float, alive := true, turn_rate := 0.0) -> void:
	_time += delta
	if alive:
		_animate_tail(speed, turn_rate, delta)
		_animate_wings(delta)
	if serpent:
		_animate_kash_arms(speed, swimming, delta)
		return
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
	elif wing_mode != "folded":
		# Flying: legs held together and trailing straight behind, arms swept slightly back.
		leg_swing = sin(_time * 2.0) * 0.06
		arm_lift = -0.35
		arm_spread = 0.25
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
	# In a banked turn, the legs steer a little too: the inner foot lifts slightly.
	var leg_steer := bank * 0.35 if wing_mode != "folded" else 0.0
	_left_leg.rotation.z = lerpf(_left_leg.rotation.z, leg_steer, blend)
	_right_leg.rotation.z = lerpf(_right_leg.rotation.z, leg_steer, blend)


## Back to the resting pose (e.g. after the statue returns to its plinth): wings folded, ankle
## feathers down, and a Kash's tail laid out fresh.
func reset_tail() -> void:
	if _serpent_tail:
		_serpent_tail._laid_out = false
	wing_mode = "folded"
	body_pitch = 0.0
	bank = 0.0
	if not _wings.is_empty():
		_set_wings(0.0, 0.0, 1.0)
		_set_ankle_fins(0.0, 1.0)


## Kash only: an empty statue is falling or sinking; its tail moves along with it, unchanged.
func carry_serpent_tail() -> void:
	if _serpent_tail and _serpent_tail._laid_out:
		_serpent_tail.carry()


## Kash only: an empty statue has landed after falling or sinking; its tail settles on the ground.
func settle_serpent_tail(ground_y: float) -> void:
	if _serpent_tail:
		_serpent_tail.lay_out(ground_y)


## Kash only: tells the tail which body it belongs to (so it doesn't treat that body as ground).
func set_owner_body(body: CollisionObject3D) -> void:
	if _serpent_tail:
		_serpent_tail.exclude = body


## Kash only: moves the serpent tail. `ground_y` is the ground's height under the body;
## `on_ground` is false while swimming or in the air. A statue's tail is laid out once and then
## stays put.
func update_serpent_tail(delta: float, speed: float, ground_y: float, on_ground: bool, alive: bool, in_water := false) -> void:
	if _serpent_tail == null:
		return
	if alive:
		_serpent_tail.update(delta, speed, ground_y, on_ground and not in_water, in_water)
	elif not _serpent_tail._laid_out:
		_serpent_tail.lay_out(ground_y)


## Kash arms: they slither rather than walk, so the arms just sway a little for balance,
## sweep back when swimming, and brace forward for a shove or a heave.
func _animate_kash_arms(speed: float, swimming: bool, delta: float) -> void:
	var swing := sin(_time * (1.5 + speed * 1.2)) * clampf(speed / 6.0, 0.0, 1.0) * 0.35
	var lift := 0.0
	var spread := 0.15
	if pose == "struggle":
		lift = 1.2 + sin(_time * 38.0) * 0.07
	elif pose == "push":
		lift = 1.45
	elif swimming and speed > 0.6:
		lift = -0.5  # Arms swept back along the body, like a diving eel.
		spread = 0.05
		swing = 0.0
	var blend := 1.0 - exp(-10.0 * delta)
	_left_arm.rotation.x = lerpf(_left_arm.rotation.x, swing + lift, blend)
	_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -swing + lift, blend)
	_left_arm.rotation.z = lerpf(_left_arm.rotation.z, -spread, blend)
	_right_arm.rotation.z = lerpf(_right_arm.rotation.z, spread, blend)


## Fayran wings: folded at rest; spread and gently tilting while gliding; beating while flying up.
func _animate_wings(delta: float) -> void:
	if _wings.is_empty():
		return
	var blend := 1.0 - exp(-8.0 * delta)
	match wing_mode:
		"flap":
			_wing_flap += delta * 9.0
			_set_wings(1.0, sin(_wing_flap) * 0.65, 1.0 - exp(-20.0 * delta))
		"glide":
			# Mostly still, gently tilting; every few seconds, a quick double flap.
			var cycle := fmod(_time, 4.5)
			var flap := sin(cycle / 0.8 * TAU * 2.0) * 0.45 if cycle < 0.8 else 0.0
			_set_wings(1.0, sin(_time * 1.3) * 0.06 + flap, 1.0 - exp(-14.0 * delta))
		"dive":
			_set_wings(0.55, 0.0, blend)  # Half tucked in for speed.
		_:
			_set_wings(0.0, 0.0, blend)
	_set_ankle_fins(0.0 if wing_mode == "folded" else 1.0, blend)


## The tail swishes side to side in a wave that travels down to the tip, with an extra
## flick every few seconds, and swishes faster when moving.
## On top of that, it trails behind on turns: when the body turns, the tail swings out the other
## way, then springs back (like the wisp's tail lagging behind it).
func _animate_tail(speed: float, turn_rate: float, delta: float) -> void:
	if _tail.is_empty() or delta <= 0.0:
		return

	# The turn rate is jumpy from frame to frame, so smooth it first. Then a soft spring: the tail's
	# lag chases "opposite the turn". It is critically damped (no bounce), and eases off smoothly at
	# the limit instead of snapping, so quick turns curve the tail a lot without it twitching back.
	_tail_turn = lerpf(_tail_turn, clampf(turn_rate, -14.0, 14.0), 1.0 - exp(-7.0 * delta))
	var lag_goal := 1.5 * tanh(-_tail_turn * 0.16 / 1.5)
	_tail_lag_speed += ((lag_goal - _tail_lag) * 60.0 - _tail_lag_speed * 15.5) * minf(delta, 0.05)
	_tail_lag += _tail_lag_speed * minf(delta, 0.05)

	var swish := 2.0 + speed * 0.5
	var flick := pow(maxf(0.0, sin(_time * 0.9)), 12.0) * 0.35  # An occasional extra flick.
	for i in _tail.size():
		var along := float(i) / float(_tail.size() - 1)
		var sway := sin(_time * swish - i * 0.7) * (0.14 + along * 0.1 + flick)
		# The base takes most of the lag; the rest of the tail curves with it.
		var lag := _tail_lag * (0.5 if i == 0 else 0.2)
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
