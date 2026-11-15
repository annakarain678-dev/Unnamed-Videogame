class_name CrierModel
extends Node3D
## The Town Crier: a slim young man in a rust-red hood and tabard, a slouch cap, rolled sleeves and cuffed boots,
## holding a scroll in his left hand. Low-poly, built from simple shapes and painted in muted earth colours
## (see docs/art-direction.md).
##
## The rig is a hierarchy of named joints (see `joints`), the same layout a skeleton would have:
##   hips > spine > chest > (neck > head > mouth), shoulder_L/R > elbow_L/R > wrist_L/R, hip_L/R > knee_L/R > ankle_L/R
## He plays two animations by himself: a calm idle (breathing, weight shift, looking about, a loosely hanging
## right arm) and, every so often, a shout: his empty right hand comes up to his mouth, his chest fills, his head
## tips back and his mouth opens in two or three bursts. Call `shout()` to make him do it now.
## Faces -Z like every body model. About 1.78 m tall.

signal shouted

## Shouts on his own every so often. Turn off to control it from code with `shout()`.
@export var auto_shout := true
@export var shout_gap_min := 6.0
@export var shout_gap_max := 11.0

const SHOUT_RAISE := 0.8
const SHOUT_HOLD := 1.9
const SHOUT_LOWER := 0.9

const SKIN := Color(0.84, 0.66, 0.52)
const HAIR := Color(0.30, 0.19, 0.12)
const SHIRT := Color(0.66, 0.55, 0.42)
const RUST := Color(0.50, 0.19, 0.15)
const TROUSERS := Color(0.34, 0.21, 0.14)
const LEATHER := Color(0.46, 0.29, 0.17)
const ROPE := Color(0.60, 0.48, 0.32)
const PAPER := Color(0.82, 0.74, 0.58)

## Every joint by name, for animating or attaching things (a held item, a hat swap, a talking pose).
var joints := {}
var shouting := false

var _time := 0.0
var _shout_time := 0.0
var _next_shout := 4.0
var _blend := 0.0
var _burst_phase := 0.0
var _mouth: Node3D


func _init() -> void:
	_build()


func _ready() -> void:
	_next_shout = randf_range(2.5, shout_gap_max)
	_time = randf() * 10.0


## Starts a shout now (ignored if he is already shouting).
func shout() -> void:
	if shouting:
		return
	shouting = true
	_shout_time = 0.0
	_burst_phase = 0.0
	shouted.emit()


# --- Animation ------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	if auto_shout and not shouting:
		_next_shout -= delta
		if _next_shout <= 0.0:
			shout()
	if shouting:
		_shout_time += delta
		var total := SHOUT_RAISE + SHOUT_HOLD + SHOUT_LOWER
		if _shout_time >= total:
			shouting = false
			_blend = 0.0
			_next_shout = randf_range(shout_gap_min, shout_gap_max)
		elif _shout_time < SHOUT_RAISE:
			_blend = smoothstep(0.0, 1.0, _shout_time / SHOUT_RAISE)
		elif _shout_time < SHOUT_RAISE + SHOUT_HOLD:
			_blend = 1.0
		else:
			_blend = smoothstep(0.0, 1.0, 1.0 - (_shout_time - SHOUT_RAISE - SHOUT_HOLD) / SHOUT_LOWER)
	_pose()


func _pose() -> void:
	var t := _time
	var w := _blend
	var breath := sin(t * 1.5) * 0.5 + 0.5
	var sway := sin(t * 0.45)

	# Weight shifts slowly from one foot to the other.
	var hips: Node3D = joints["hips"]
	hips.position = Vector3(sway * 0.012, 0.93 - absf(sway) * 0.004, 0.0)
	hips.rotation = Vector3(0.0, sway * 0.04, sway * 0.018)
	(joints["hip_L"] as Node3D).rotation.z = -sway * 0.018
	(joints["hip_R"] as Node3D).rotation.z = -sway * 0.018
	(joints["hip_L"] as Node3D).rotation.x = 0.0
	(joints["hip_R"] as Node3D).rotation.x = 0.0
	(joints["knee_L"] as Node3D).rotation.x = 0.03 + maxf(0.0, sway) * 0.05
	(joints["knee_R"] as Node3D).rotation.x = 0.03 + maxf(0.0, -sway) * 0.05

	# Breathing: the chest rises and fills. In a shout it fills right out, then empties.
	var inhale := w * 0.05
	var chest: Node3D = joints["chest"]
	chest.scale = Vector3(1.0 + breath * 0.012 + inhale, 1.0 + breath * 0.02 + inhale * 0.6, 1.0 + breath * 0.012 + inhale)
	(joints["spine"] as Node3D).rotation = Vector3(0.01 + 0.07 * w, -sway * 0.03, 0.0)

	# Head: looks about, and tips back to shout.
	var head: Node3D = joints["head"]
	head.rotation = Vector3(
		sin(t * 0.5) * 0.03 + 0.2 * w,
		(sin(t * 0.33) * 0.2 + sin(t * 0.11) * 0.12) * (1.0 - w),
		sin(t * 0.27) * 0.02)

	# Left arm: the scroll hangs at his side (a little higher while he shouts).
	var arm_sway := sin(t * 0.9) * 0.02
	(joints["shoulder_L"] as Node3D).rotation = Vector3(0.12 + arm_sway + 0.1 * w, 0.0, 0.1)
	(joints["elbow_L"] as Node3D).rotation = Vector3(0.7 + 0.1 * w, 0.0, 0.0)
	(joints["wrist_L"] as Node3D).rotation = Vector3(0.1, 0.0, 0.0)

	# Right arm: hangs loose, then comes up to cup the mouth.
	var idle_shoulder := Vector3(0.05 + arm_sway, 0.0, -0.08)
	var idle_elbow := Vector3(0.18 + breath * 0.02, 0.0, 0.0)
	var idle_wrist := Vector3(0.05, 0.0, 0.0)
	var shout_shoulder := Vector3(0.75, 0.0, -0.28)
	var shout_elbow := Vector3(1.6, 0.0, 0.0)
	var shout_wrist := Vector3(-0.2, 0.0, 0.25)
	(joints["shoulder_R"] as Node3D).rotation = idle_shoulder.lerp(shout_shoulder, w)
	(joints["elbow_R"] as Node3D).rotation = idle_elbow.lerp(shout_elbow, w)
	(joints["wrist_R"] as Node3D).rotation = idle_wrist.lerp(shout_wrist, w)

	# Mouth: shut, or open in bursts while he calls ("Hear ye! Hear ye!").
	var open := 0.0
	if shouting and _shout_time > SHOUT_RAISE and _shout_time < SHOUT_RAISE + SHOUT_HOLD:
		var s := (_shout_time - SHOUT_RAISE) / SHOUT_HOLD
		open = clampf(sin(s * TAU * 1.5 - 0.4) * 1.4, 0.0, 1.0) * 0.5 + 0.5 * smoothstep(0.0, 0.15, s) * (1.0 - smoothstep(0.85, 1.0, s))
	_mouth.scale = Vector3(1.0 + open * 0.15, 0.25 + open * 1.1, 0.5 + open * 0.8)
	_mouth.position.y = -0.052 - open * 0.006


# --- Building the model ---------------------------------------------------------------------------

func _build() -> void:
	var root := self
	var hips := _joint(root, "hips", Vector3(0.0, 0.93, 0.0))
	var spine := _joint(hips, "spine", Vector3.ZERO)
	var chest := _joint(spine, "chest", Vector3(0.0, 0.3, 0.0))
	var neck := _joint(chest, "neck", Vector3(0.0, 0.27, 0.0))
	var head := _joint(neck, "head", Vector3(0.0, 0.07, 0.0))

	# Pelvis and tunic skirt.
	_part(hips, _box(0.32, 0.2, 0.2), Vector3(0.0, 0.0, 0.0), TROUSERS)
	_part(hips, _box(0.34, 0.2, 0.22), Vector3(0.0, -0.06, 0.0), SHIRT)
	# Torso (shirt) with a little waist.
	_part(spine, _capsule(0.135, 0.56), Vector3(0.0, 0.27, 0.0), SHIRT, Vector3(1.0, 1.0, 0.72))
	# Rope belt and a pouch on his right hip.
	_part(spine, _torus(0.12, 0.15), Vector3(0.0, 0.11, 0.0), ROPE, Vector3(1.0, 1.0, 0.72))
	_part(hips, _box(0.085, 0.11, 0.06), Vector3(0.2, 0.0, 0.0), LEATHER)
	_part(hips, _box(0.09, 0.03, 0.065), Vector3(0.2, 0.065, 0.0), Color(0.36, 0.22, 0.13))
	# Rust-red tabard, front and back, with ragged strips along the hem.
	_part(spine, _box(0.2, 0.62, 0.014), Vector3(0.03, -0.0, -0.105), RUST, Vector3.ONE, Vector3(0.05, 0.0, 0.02))
	_part(spine, _box(0.25, 0.55, 0.014), Vector3(0.0, 0.03, 0.105), RUST, Vector3.ONE, Vector3(-0.04, 0.0, 0.0))
	for i in 5:
		var x := -0.07 + i * 0.045
		var drop := 0.05 + (i * 37 % 5) * 0.018
		_part(spine, _box(0.036, drop, 0.012), Vector3(0.03 + x * 0.8, -0.31 - drop * 0.5, -0.11), RUST, Vector3.ONE, Vector3(0.05, 0.0, 0.0))
	# Hood and mantle over the shoulders.
	_part(chest, _sphere(0.2), Vector3(0.0, 0.2, 0.0), RUST, Vector3(1.22, 0.5, 0.95))
	_part(chest, _box(0.3, 0.26, 0.03), Vector3(0.0, 0.12, 0.12), RUST, Vector3.ONE, Vector3(-0.35, 0.0, 0.0))
	_part(chest, _box(0.05, 0.2, 0.025), Vector3(-0.02, 0.1, -0.135), RUST, Vector3.ONE, Vector3(0.1, 0.0, 0.15))
	# A knot of cord at the throat.
	_part(chest, _sphere(0.022), Vector3(0.0, 0.2, -0.125), ROPE)

	# Head: skin, hair, ears, face, cap.
	_part(head, _sphere(0.105), Vector3(0.0, 0.07, 0.0), SKIN, Vector3(0.95, 1.12, 1.0))
	_part(head, _sphere(0.115), Vector3(0.0, 0.1, 0.022), HAIR, Vector3(1.0, 0.95, 1.0))
	for side in [-1.0, 1.0]:
		_part(head, _sphere(0.03), Vector3(0.098 * side, 0.065, 0.0), SKIN, Vector3(0.45, 1.0, 0.8))
		_part(head, _sphere(0.016), Vector3(0.04 * side, 0.085, -0.088), Color(0.06, 0.04, 0.04))
		_part(head, _box(0.045, 0.01, 0.012), Vector3(0.045 * side, 0.112, -0.09), HAIR, Vector3.ONE, Vector3(0.0, 0.0, -0.18 * side))
		_part(head, _box(0.026, 0.07, 0.04), Vector3(0.1 * side, 0.1, -0.02), HAIR)
	_part(head, _sphere(0.02), Vector3(0.0, 0.058, -0.1), Color(0.78, 0.58, 0.45), Vector3(0.9, 1.0, 1.0))
	# Fringe falling over the forehead under the cap.
	for i in 5:
		_part(head, _box(0.03, 0.035, 0.012), Vector3(-0.056 + i * 0.028, 0.135, -0.095), HAIR, Vector3.ONE, Vector3(0.0, 0.0, (i - 2) * 0.12))
	# The mouth: dark, opens wide when he shouts.
	_mouth = Node3D.new()
	_mouth.name = "mouth"
	_mouth.position = Vector3(0.0, -0.052 + 0.07, -0.094)
	head.add_child(_mouth)
	_part(_mouth, _sphere(0.026), Vector3.ZERO, Color(0.17, 0.05, 0.05))
	joints["mouth"] = _mouth
	# Slouch cap, red, with a tan band and a droop at the back.
	_part(head, _sphere(0.125), Vector3(0.0, 0.15, 0.022), RUST, Vector3(1.0, 0.72, 1.12), Vector3(-0.12, 0.0, 0.0))
	_part(head, _cylinder(0.118, 0.118, 0.035), Vector3(0.0, 0.118, 0.012), ROPE, Vector3.ONE, Vector3(-0.1, 0.0, 0.0))
	_part(head, _sphere(0.08), Vector3(0.0, 0.14, 0.14), RUST, Vector3(1.0, 1.1, 0.9), Vector3(0.5, 0.0, 0.0))

	# Arms. His right is +X (he faces -Z).
	for side in ["L", "R"]:
		var sign := 1.0 if side == "R" else -1.0
		var shoulder := _joint(chest, "shoulder_" + side, Vector3(0.205 * sign, 0.22, 0.0))
		var elbow := _joint(shoulder, "elbow_" + side, Vector3(0.0, -0.3, 0.0))
		var wrist := _joint(elbow, "wrist_" + side, Vector3(0.0, -0.27, 0.0))
		_part(shoulder, _capsule(0.052, 0.32), Vector3(0.0, -0.15, 0.0), SHIRT)
		_part(elbow, _cylinder(0.058, 0.058, 0.05), Vector3(0.0, 0.0, 0.0), SHIRT)  # the rolled cuff
		_part(elbow, _capsule(0.04, 0.3), Vector3(0.0, -0.13, 0.0), SKIN)
		_part(wrist, _box(0.05, 0.1, 0.085), Vector3(0.0, -0.05, 0.0), SKIN)
		_part(wrist, _box(0.018, 0.05, 0.03), Vector3(-0.034 * sign, -0.03, -0.02), SKIN, Vector3.ONE, Vector3(0.0, 0.0, 0.4 * sign))
		# Fingers: four little ones along the end of the palm.
		for f in 4:
			_part(wrist, _box(0.012, 0.055, 0.016), Vector3(-0.018 + f * 0.012, -0.12, 0.0), SKIN)
	# The scroll in his left hand.
	var scroll := _cylinder(0.03, 0.03, 0.2)
	_part(joints["wrist_L"], scroll, Vector3(0.0, -0.06, 0.0), PAPER, Vector3.ONE, Vector3(0.0, 0.0, PI * 0.5))
	_part(joints["wrist_L"], _cylinder(0.034, 0.034, 0.03), Vector3(0.0, -0.06, 0.0), RUST, Vector3.ONE, Vector3(0.0, 0.0, PI * 0.5))
	_part(joints["wrist_L"], _sphere(0.03), Vector3(0.1, -0.06, 0.0), Color(0.72, 0.6, 0.44), Vector3(0.5, 1.0, 1.0))
	_part(joints["wrist_L"], _sphere(0.03), Vector3(-0.1, -0.06, 0.0), Color(0.72, 0.6, 0.44), Vector3(0.5, 1.0, 1.0))

	# Legs: baggy brown trousers tucked into cuffed boots.
	for side in ["L", "R"]:
		var sign := 1.0 if side == "R" else -1.0
		var hip := _joint(hips, "hip_" + side, Vector3(0.09 * sign, -0.07, 0.0))
		var knee := _joint(hip, "knee_" + side, Vector3(0.0, -0.4, 0.0))
		var ankle := _joint(knee, "ankle_" + side, Vector3(0.0, -0.37, 0.0))
		_part(hip, _capsule(0.085, 0.46), Vector3(0.0, -0.2, 0.0), TROUSERS, Vector3(1.0, 1.0, 1.0))
		_part(knee, _capsule(0.075, 0.34), Vector3(0.0, -0.12, 0.0), TROUSERS)
		_part(knee, _cylinder(0.088, 0.078, 0.07), Vector3(0.0, -0.27, 0.0), LEATHER)   # folded boot cuff
		_part(knee, _cylinder(0.07, 0.065, 0.15), Vector3(0.0, -0.34, 0.0), Color(0.4, 0.25, 0.14))
		_part(ankle, _box(0.105, 0.09, 0.27), Vector3(0.0, -0.01, -0.06), Color(0.42, 0.26, 0.15))
		_part(ankle, _box(0.108, 0.03, 0.28), Vector3(0.0, -0.06, -0.06), Color(0.22, 0.14, 0.09))


func _joint(parent: Node3D, joint_name: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = joint_name
	node.position = at
	parent.add_child(node)
	joints[joint_name] = node
	return node


func _part(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, mesh_scale := Vector3.ONE, rotation_radians := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	instance.material_override = material
	instance.position = at
	instance.scale = mesh_scale
	instance.rotation = rotation_radians
	parent.add_child(instance)
	return instance


static func _box(x: float, y: float, z: float) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(x, y, z)
	return mesh


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 7
	return mesh


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	return mesh


static func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	return mesh


static func _torus(inner: float, outer: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 14
	mesh.ring_segments = 6
	return mesh
