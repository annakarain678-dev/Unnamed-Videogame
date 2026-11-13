class_name WispTail
extends Node3D
## A thin comet tail that streams behind the wisp while it moves.
## It stretches out with speed and fades away completely when the wisp stops.

## The node the tail hangs from (the wisp's glowing core).
var anchor: Node3D

@export var segment_count := 26
## Largest gap allowed between neighboring segments, in meters. Sets the tail's full length.
@export var spacing := 0.07
## How quickly the tail draws back into the wisp when it slows down.
@export var settle_speed := 2.0
@export var head_radius := 0.085
@export var color := Color(1.0, 0.86, 0.55)
## Below this speed (m/s) the tail is invisible; at `full_speed` it's fully visible.
@export var fade_start_speed := 0.4
@export var full_speed := 3.0
## How quickly the tail fades in or out.
@export var fade_speed := 6.0

var _points := PackedVector3Array()
var _segments: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _base_alphas := PackedFloat32Array()
var _last_anchor := Vector3.ZERO
var _speed := 0.0
var _fade := 0.0


func _ready() -> void:
	# The tail places itself in world space each frame rather than moving with its parent.
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_transform = Transform3D.IDENTITY

	for i in segment_count:
		var along := float(i + 1) / float(segment_count)  # 0 at the head, 1 at the tip

		var mesh := SphereMesh.new()
		mesh.radius = lerpf(head_radius, head_radius * 0.15, along)
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 8
		mesh.rings = 4

		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.disable_fog = true
		material.albedo_color = Color(color, 0.0)
		mesh.material = material

		var segment := MeshInstance3D.new()
		segment.mesh = mesh
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		segment.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(segment)

		_segments.append(segment)
		_materials.append(material)
		_base_alphas.append(lerpf(0.4, 0.02, along))
		_points.append(Vector3.ZERO)

	reset()


## Draw order relative to other see-through things like water (higher = drawn later, on top).
func set_draw_order(order: int) -> void:
	for material in _materials:
		material.render_priority = order


## Snaps the whole tail back into the wisp (e.g. when it appears somewhere new).
func reset() -> void:
	var start := _anchor_position()
	for i in _points.size():
		_points[i] = start
		_segments[i].global_position = start
	_last_anchor = start
	_speed = 0.0
	_fade = 0.0


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var head := _anchor_position()

	# How fast the wisp is moving decides how visible the tail is.
	var instant_speed := head.distance_to(_last_anchor) / delta
	_last_anchor = head
	_speed = lerpf(_speed, instant_speed, 1.0 - exp(-10.0 * delta))
	var goal := smoothstep(fade_start_speed, full_speed, _speed)
	_fade = lerpf(_fade, goal, 1.0 - exp(-fade_speed * delta))
	visible = _fade > 0.01

	var leader := head
	var settle := 1.0 - exp(-settle_speed * delta)
	for i in _segments.size():
		# Each segment drifts toward the one ahead of it, but never falls more than `spacing` behind.
		var point := _points[i].lerp(leader, settle)
		var offset := point - leader
		if offset.length() > spacing:
			point = leader + offset.normalized() * spacing
		_points[i] = point
		_segments[i].global_position = point
		_materials[i].albedo_color.a = _base_alphas[i] * _fade
		leader = point


func _anchor_position() -> Vector3:
	if anchor == null:
		return global_position
	return anchor.get_global_transform_interpolated().origin
