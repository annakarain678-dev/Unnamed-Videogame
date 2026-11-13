class_name LightLines
extends MeshInstance3D
## Lines of light the wisp draws by holding Left Mouse, like its comet tail stretching out behind it.
## Letting go ends the line; earlier lines stay. The wisp only has so much line: draw past its
## length and the oldest part fades away first. Old lines also fade on their own after a while.
## Inside a possessed heart, darklings can't cross these lines (they slide along them instead).
##
## Points are kept in this node's local space; walls are checked across the floor (x/z),
## whatever height they were drawn at.

## Drop a new point every this many meters while drawing.
const POINT_SPACING := 0.25
## Each part of a line lasts this long (seconds), then fades away.
const POINT_LIFE := 10.0
## How close a darkling can come to a line.
const WALL_GAP := 1.0
## Half the thickness of the glowing ribbon.
const RIBBON := 0.2
const COLOR := Color(1.0, 0.86, 0.55)

var _strokes: Array = []  # Each stroke is an Array of { "at": Vector3, "born": float }
var _drawing := false
var _time := 0.0
var _mesh := ImmediateMesh.new()
var _material := StandardMaterial3D.new()


func _ready() -> void:
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 50.0
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.vertex_color_use_as_albedo = true
	_material.disable_fog = true


func clear() -> void:
	_strokes.clear()
	_drawing = false
	_mesh.clear_surfaces()


## Call every frame. `pen` is the wisp's position (in this node's space); `drawing` is whether the
## draw button is held; `length` is how much line the wisp has.
func update(delta: float, pen: Vector3, drawing: bool, length: float) -> void:
	_time += delta
	if drawing:
		if not _drawing:
			_strokes.append([])  # A new line; the old ones stay.
		var stroke: Array = _strokes.back()
		if stroke.is_empty() or (stroke.back()["at"] as Vector3).distance_to(pen) > POINT_SPACING:
			stroke.append({"at": pen, "born": _time})
	_drawing = drawing

	# Old parts fade away on their own...
	for stroke: Array in _strokes:
		while not stroke.is_empty() and _time - float(stroke[0]["born"]) > POINT_LIFE:
			stroke.pop_front()
	# ...and if there's more line than the wisp has, the oldest part goes first.
	while _total_length() > length:
		_trim_oldest_point()
	# Drop finished lines that have faded to nothing.
	for i in range(_strokes.size() - 1, -1, -1):
		var is_active := _drawing and i == _strokes.size() - 1
		if (_strokes[i] as Array).size() < 2 and not is_active:
			_strokes.remove_at(i)

	_rebuild()


## How far something at `from` (across the floor) can actually move by `step` without crossing a
## line. Movement into a line is cancelled; movement along it is kept, so things slide around.
func slide(from: Vector2, step: Vector2) -> Vector2:
	for stroke: Array in _strokes:
		for i in range(stroke.size() - 1):
			var a := _flat(stroke[i]["at"])
			var b := _flat(stroke[i + 1]["at"])
			var to := from + step
			if not (_crosses(from, to, a, b) or _distance_to_segment(to, a, b) < WALL_GAP):
				continue
			var along := (b - a).normalized()
			var normal := Vector2(-along.y, along.x)
			var side := signf((from - a).dot(normal))
			if side == 0.0:
				side = 1.0
			var into := -normal * side
			var push := step.dot(into)
			if push > 0.0:
				step -= into * push
	# Still stuck against a corner? Then don't move.
	for stroke: Array in _strokes:
		for i in range(stroke.size() - 1):
			if _crosses(from, from + step, _flat(stroke[i]["at"]), _flat(stroke[i + 1]["at"])):
				return Vector2.ZERO
	return step


## A gentle push away from any line within `reach` of `p`, so things veer off before touching.
func repel(p: Vector2, reach: float) -> Vector2:
	var push := Vector2.ZERO
	for stroke: Array in _strokes:
		for i in range(stroke.size() - 1):
			var a := _flat(stroke[i]["at"])
			var b := _flat(stroke[i + 1]["at"])
			var nearest := _nearest_on_segment(p, a, b)
			var gap := p.distance_to(nearest)
			if gap < reach and gap > 0.001:
				push += (p - nearest) / gap * (1.0 - gap / reach)
	return push


## True if `p` is completely walled in: every direction out runs into a line.
func encloses(p: Vector2) -> bool:
	if _strokes.is_empty():
		return false
	var directions := 16
	for k in directions:
		var angle := TAU * k / directions
		var far := p + Vector2(cos(angle), sin(angle)) * 60.0
		var blocked := false
		for stroke: Array in _strokes:
			for i in range(stroke.size() - 1):
				if _crosses(p, far, _flat(stroke[i]["at"]), _flat(stroke[i + 1]["at"])):
					blocked = true
					break
			if blocked:
				break
		if not blocked:
			return false
	return true


func total_length() -> float:
	return _total_length()


func _total_length() -> float:
	var total := 0.0
	for stroke: Array in _strokes:
		for i in range(stroke.size() - 1):
			total += (stroke[i]["at"] as Vector3).distance_to(stroke[i + 1]["at"])
	return total


func _trim_oldest_point() -> void:
	for stroke: Array in _strokes:
		if not stroke.is_empty():
			stroke.pop_front()
			return


## Draws each line as a glowing ribbon (a cross of two strips, so it reads from any angle).
## Each part fades in its last few seconds, and the oldest end of the whole line tapers off.
func _rebuild() -> void:
	_mesh.clear_surfaces()
	var any := false
	for stroke: Array in _strokes:
		if stroke.size() >= 2:
			any = true
	if not any:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _material)
	for stroke: Array in _strokes:
		for i in range(stroke.size() - 1):
			var a: Vector3 = stroke[i]["at"]
			var b: Vector3 = stroke[i + 1]["at"]
			var alpha_a := _alpha(stroke, i)
			var alpha_b := _alpha(stroke, i + 1)
			var across := (b - a).cross(Vector3.UP).normalized() * RIBBON
			_strip(a, b, Vector3.UP * RIBBON, alpha_a, alpha_b)
			_strip(a, b, across, alpha_a, alpha_b)
	_mesh.surface_end()


func _alpha(stroke: Array, i: int) -> float:
	var age := _time - float(stroke[i]["born"])
	var fade := clampf((POINT_LIFE - age) / 3.0, 0.0, 1.0)
	var tail := clampf(float(i) / 6.0, 0.15, 1.0)  # The oldest end tapers off.
	return 0.55 * fade * tail


func _strip(a: Vector3, b: Vector3, offset: Vector3, alpha_a: float, alpha_b: float) -> void:
	var color_a := Color(COLOR, alpha_a)
	var color_b := Color(COLOR, alpha_b)
	var corners := [a - offset, a + offset, b + offset, a - offset, b + offset, b - offset]
	var colors := [color_a, color_a, color_b, color_a, color_b, color_b]
	for k in 6:
		_mesh.surface_set_color(colors[k])
		_mesh.surface_add_vertex(corners[k])


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


static func _crosses(p1: Vector2, p2: Vector2, q1: Vector2, q2: Vector2) -> bool:
	var d1 := (p2 - p1).cross(q1 - p1)
	var d2 := (p2 - p1).cross(q2 - p1)
	var d3 := (q2 - q1).cross(p1 - q1)
	var d4 := (q2 - q1).cross(p2 - q1)
	# (Touching counts as crossing, so nothing slips through exactly at a point of the line.)
	return d1 * d2 <= 0.0 and d3 * d4 <= 0.0 and not (d1 == 0.0 and d2 == 0.0)


static func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(_nearest_on_segment(p, a, b))


static func _nearest_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared < 0.0001:
		return a
	var t := clampf((p - a).dot(ab) / length_squared, 0.0, 1.0)
	return a + ab * t
