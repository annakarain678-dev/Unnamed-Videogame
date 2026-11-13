class_name KashTail
extends Node3D
## The long serpent tail of a Kash (Sen-Kash: snake; Qoi-Kash: eel).
## It starts at the hips and drags along behind the body like a real tail: every part of it
## follows the exact path the hips took, and always keeps its full length (it never bunches up
## when you stop or turn). A side-to-side wave runs down it as it slithers.
## On land it lies along the ground; in water it trails freely.
## Lives in world space (it doesn't rotate stiffly with the body), like the wisp's comet tail.

## Where the tail joins the body (the hips).
var anchor: Node3D
## The body's "right" direction, for slithering side to side.
var side_reference: Node3D
## The body the tail belongs to, so its own collision isn't mistaken for ground.
var exclude: CollisionObject3D

var segment_count := 14
## Distance between segments, in meters (sets the tail's length).
var spacing := 0.22
var radius_start := 0.24
var radius_end := 0.04
## One color per segment (a pattern of bands); repeats if shorter than the tail.
var colors: Array[Color] = [Color(0.3, 0.5, 0.3)]
## A fin running along the top, down to the tip (Qoi-Kash).
var has_fin := false
var fin_color := Color(0.1, 0.12, 0.15)

## Filled in when built: { "material", "alive" } for each piece, so the owner can turn it to stone.
var parts: Array[Dictionary] = []

var _points := PackedVector3Array()
## Where the hips have been, newest first.
var _path := PackedVector3Array()
var _segments: Array[Node3D] = []
var _time := 0.0
var _wave := 0.0
var _laid_out := false
var _last_anchor := Vector3(INF, INF, INF)
## The tail's shape in water (without the ripple), and whether it was in water last frame.
var _rope := PackedVector3Array()
var _was_in_water := false


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_transform = Transform3D.IDENTITY

	for i in segment_count:
		var along := float(i) / float(segment_count - 1)
		var radius := lerpf(radius_start, radius_end, along)
		var holder := Node3D.new()
		add_child(holder)

		# A stretched sphere, lying along the tail.
		var body := SphereMesh.new()
		body.radius = radius
		body.height = radius * 2.0
		body.radial_segments = 10
		body.rings = 5
		var piece := MeshInstance3D.new()
		piece.mesh = body
		piece.scale = Vector3(1.0, 0.85, maxf(1.0, spacing * 0.75 / radius))
		piece.material_override = _material(colors[i % colors.size()], piece)
		holder.add_child(piece)

		if has_fin:
			var fin := BoxMesh.new()
			fin.size = Vector3(0.025, lerpf(0.22, 0.12, along), spacing * 1.15)
			var fin_piece := MeshInstance3D.new()
			fin_piece.mesh = fin
			fin_piece.position.y = radius * 0.85 + fin.size.y * 0.4
			fin_piece.material_override = _material(fin_color, fin_piece)
			holder.add_child(fin_piece)

		_segments.append(holder)
		_points.append(Vector3.ZERO)


## Lays the tail out straight behind the body (used when a statue is first placed).
func lay_out(ground_y: float) -> void:
	var start := anchor.global_position
	var back := anchor.global_basis.z.normalized()  # The body faces -Z, so behind is +Z.
	back.y = 0.0
	back = back.normalized() if back.length() > 0.01 else Vector3.BACK
	var leader := start
	for i in segment_count:
		# Step back along the ground, draping down over edges (like off a statue's plinth).
		var point := leader + back * spacing
		var floor_y := _ground_at(point, ground_y) + _radius(i) * 0.8
		point.y = lerpf(leader.y, floor_y, 0.6)
		point = leader + (point - leader).normalized() * spacing
		_points[i] = point
		leader = point
	# The path the tail follows starts as this laid-out line.
	_path = PackedVector3Array([start])
	_path.append_array(_points)
	_laid_out = true
	_last_anchor = start
	_place_segments()


## Call every frame while alive. `speed` is how fast the body moves; `ground_y` is the height of
## the ground under it; `on_ground` is true on land (the tail lies along the ground); `in_water`
## makes the tail float freely, waving, only resting on the bottom where it actually touches.
func update(delta: float, speed: float, ground_y: float, on_ground: bool, in_water := false) -> void:
	if not _laid_out:
		lay_out(ground_y)
		return
	_time += delta
	_last_anchor = anchor.global_position
	if in_water:
		if not _was_in_water:
			_rope = _points.duplicate()  # Just entered the water: start from the tail's current shape.
		_was_in_water = true
		_update_in_water(delta, speed, ground_y)
		return
	if _was_in_water:
		# Just climbed out: carry on along the shape the tail had in the water.
		_was_in_water = false
		_path = PackedVector3Array([anchor.global_position])
		_path.append_array(_points)

	# The tail follows the line the hips have drawn. Only real movement is recorded, so standing
	# still never bunches the tail up: it always keeps its full length, lying where the body has been.
	# On land only sideways movement counts, so jumping (even on the spot) never pulls the tail in.
	var hips := anchor.global_position
	var step := hips - _path[0]
	if not in_water:
		step.y = 0.0
	if step.length() > 0.06:
		_path.insert(0, hips)
		_trim_path()
	else:
		_path[0] = hips

	# Points along that line...
	var bases := PackedVector3Array()
	for i in segment_count:
		bases.append(_point_along_path(spacing * (i + 1), not in_water))
	# ...pulled a little taut, like a string: sharp corners and tight loops ease out a bit.
	for pass_count in 2:
		for i in range(1, segment_count - 1):
			var middle := (bases[i - 1] + bases[i + 1]) * 0.5
			bases[i] = bases[i].lerp(middle, 0.3)

	# The slither: a side-to-side wave that runs down the tail, bigger and quicker when moving.
	# In water the tail mostly ripples up and down instead, and never stops entirely.
	var moving := clampf(speed / 5.0, 0.0, 1.0)
	var sway := (0.03 + moving * 0.15) if in_water else (0.03 + moving * 0.3)
	_wave += delta * ((2.4 if in_water else 1.8) + speed * 2.2)

	var ahead := hips
	for i in segment_count:
		var base := bases[i]
		var along := base - ahead
		along.y = 0.0
		var side := along.cross(Vector3.UP).normalized() if along.length() > 0.001 else Vector3.ZERO
		# The wave grows from nothing at the hips to full size a few segments down.
		var reach := clampf((i + 1) / 4.0, 0.0, 1.0)
		var point := base + side * sin(_wave - i * 0.55) * sway * reach
		ahead = base
		var rest := _ground_at(point, ground_y) + _radius(i) * 0.8
		if on_ground:
			# On land, the tail lies along the ground (slopes, steps, ledges). Going downhill it
			# drops quickly rather than hanging in the air.
			var speed_down := 30.0 if _points[i].y > rest else 14.0
			point.y = lerpf(_points[i].y, rest, 1.0 - exp(-speed_down * delta))
			point.y = maxf(point.y, rest - 0.05)
		_points[i] = point
	_place_segments()


## In water the tail behaves like a supple but slightly stiff rope hanging from the hips:
## - every segment keeps exactly one spacing from the one ahead, so the tail always keeps its
##   full length and can't scrunch up, whichever way you move (up, down, sideways, forward);
## - it trails behind wherever the body has gone (below you as you rise, above you as you dive);
## - it resists bending sharply, so it curves smoothly instead of hinging at angles;
## - at rest it droops into a gentle downward curve, with a slow ripple running down it.
func _update_in_water(delta: float, speed: float, ground_y: float) -> void:
	var moving := clampf(speed / 5.0, 0.0, 1.0)
	_wave += delta * (2.4 + speed * 2.2)
	var hips := anchor.global_position
	# Its natural resting shape: leaving the hips heading down, continuing the line of the body,
	# then curving back until it lies level behind (like a mermaid's tail, not a dangling rope).
	var down := -anchor.global_basis.y.normalized()
	var back := anchor.global_basis.z.normalized()
	# The shape holds firmly at rest; while swimming the tail mostly just trails behind.
	var hold := lerpf(0.2, 0.04, moving)

	var leader := hips
	var direction := down
	for i in segment_count:
		var along := float(i + 1) / float(segment_count)
		var p := _rope[i]
		# Hang exactly one spacing behind the segment ahead.
		var offset := p - leader
		if offset.length() < 0.001:
			offset = direction * 0.01
		p = leader + offset.normalized() * spacing
		# Ease toward the resting shape: the first part points down, the rest curves round to back.
		var preferred := down.slerp(back, clampf(along * 1.8, 0.0, 1.0))
		p = p.lerp(leader + preferred * spacing, hold)
		# Stiffness: lean toward carrying straight on from the segment ahead (no sharp hinges).
		var straight := leader + direction * spacing
		p = p.lerp(straight, 0.08)
		p = leader + (p - leader).normalized() * spacing
		# It rests on the bottom only where it would otherwise sink into it...
		p.y = maxf(p.y, _ground_at(p, ground_y) + _radius(i) * 0.8)
		# ...and nothing is allowed to change its length.
		p = leader + (p - leader).normalized() * spacing
		_rope[i] = p
		direction = (p - leader).normalized()
		leader = p

	# What you see: the rope, plus a soft side-to-side and up-and-down ripple running down it.
	leader = hips
	for i in segment_count:
		var p := _rope[i]
		var flat := Vector3(p.x - leader.x, 0.0, p.z - leader.z)
		var side := flat.cross(Vector3.UP).normalized() if flat.length() > 0.001 else Vector3.ZERO
		var reach := clampf((i + 1) / 4.0, 0.0, 1.0)
		var ripple := sin(_wave * 0.8 - i * 0.6) * (0.06 + moving * 0.08) * reach
		var sway := sin(_wave - i * 0.55) * (0.03 + moving * 0.12) * reach
		_points[i] = p + Vector3.UP * ripple + side * sway
		leader = p
	_place_segments()


## Moves the whole tail along with the body without reshaping it: for an empty statue that's
## falling or sinking, so body and tail always stay together.
func carry() -> void:
	var now := anchor.global_position
	if is_finite(_last_anchor.x):
		var shift := now - _last_anchor
		for i in _points.size():
			_points[i] += shift
		for k in _path.size():
			_path[k] += shift
		for k in _rope.size():
			_rope[k] += shift
	_last_anchor = now
	_place_segments()


## The point `distance` meters back along the path the hips have traveled. `flat` measures
## distance across the ground only (on land), so up-and-down movement never uses up tail.
func _point_along_path(distance: float, flat := false) -> Vector3:
	var travelled := 0.0
	for k in range(_path.size() - 1):
		var a := _path[k]
		var b := _path[k + 1]
		var step := Vector2(a.x - b.x, a.z - b.z).length() if flat else a.distance_to(b)
		if travelled + step >= distance:
			return a.lerp(b, (distance - travelled) / step) if step > 0.0001 else a
		travelled += step
	# Path too short (just started): carry on straight back from its end.
	var tail_end := _path[_path.size() - 1]
	var back := (tail_end - _path[0]).normalized() if _path.size() > 1 else Vector3.BACK
	if back.length() < 0.5:
		back = Vector3.BACK
	return tail_end + back * (distance - travelled)


## Keeps only as much path as the tail needs.
func _trim_path() -> void:
	# (A bit extra, since on land up-and-down steps in the path don't count toward the tail's length.)
	var needed := spacing * (segment_count + 2) * 1.6
	var travelled := 0.0
	for k in range(_path.size() - 1):
		travelled += _path[k].distance_to(_path[k + 1])
		if travelled > needed:
			_path.resize(k + 2)
			return


func _place_segments() -> void:
	var leader := anchor.global_position
	for i in segment_count:
		var point := _points[i]
		var holder := _segments[i]
		holder.global_position = (point + leader) * 0.5
		var toward := leader - point
		if toward.length() > 0.001:
			var up := Vector3.UP if absf(toward.normalized().y) < 0.95 else Vector3.FORWARD
			holder.look_at(holder.global_position + toward, up)
		leader = point


## The height of the ground under `point` (looking a little above and below it), or `fallback`.
func _ground_at(point: Vector3, fallback: float) -> float:
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		return fallback
	# Look only a little above the tail, so it goes around rocks and boulders the body went around,
	# rather than hopping up on top of them.
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.35, point + Vector3.DOWN * 3.0)
	ray.collision_mask = Layers.WORLD | Layers.THIN
	if exclude:
		ray.exclude = [exclude.get_rid()]
	var hit := space.intersect_ray(ray)
	return (hit["position"] as Vector3).y if hit else fallback


func _radius(i: int) -> float:
	return lerpf(radius_start, radius_end, float(i) / float(segment_count - 1))


func _material(color: Color, piece: MeshInstance3D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parts.append({"material": material, "alive": color})
	return material
