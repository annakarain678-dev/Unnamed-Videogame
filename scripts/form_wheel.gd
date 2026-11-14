class_name FormWheel
extends CanvasLayer
## The wheel of forms. A mostly see-through ring with one simple symbol for each species. A highlight
## travels clockwise or counter-clockwise around it (it is not a free mouse):
##   - move the mouse right / left, or scroll, or press D / A (or E / Q, or the arrow keys) to turn it
##   - Left Mouse (or Enter) picks the highlighted form
##   - Right Mouse or Esc closes the wheel without choosing

## Sent when a form is picked.
signal chosen(species: String)
## Sent whenever the wheel closes, whether or not a form was picked.
signal closed

## Clockwise from the top.
const SPECIES: Array[String] = ["Human", "Tar'ye", "Fayran", "Sen-Kash", "Qoi-Kash"]
const ICONS := {
	"Human": "res://assets/symbols/human.png",
	"Tar'ye": "res://assets/symbols/tarye.png",
	"Fayran": "res://assets/symbols/fayran.png",
	"Sen-Kash": "res://assets/symbols/sen_kash.png",
	"Qoi-Kash": "res://assets/symbols/qoi_kash.png",
}
## How far the mouse must travel to move the highlight one place. While you travel, an arrow grows
## toward the place it is about to jump to.
const MOUSE_STEP := 170.0
## After each jump the wheel rests for this long, ignoring the mouse, so it can't race round.
const PAUSE := 0.4

var is_open := false

var _index := 0
var _angle := 0.0  # Where the highlight is drawn now (radians, 0 = top, clockwise).
var _mouse_travel := 0.0
var _pause := 0.0
var _textures := {}
var _glyph: Texture2D
var _canvas: Control


func _ready() -> void:
	layer = 6
	visible = false
	for species in ICONS:
		_textures[species] = load(ICONS[species])
	_glyph = load("res://assets/symbols/form_glyph.png")
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_wheel)
	add_child(_canvas)


func open() -> void:
	is_open = true
	visible = true
	_mouse_travel = 0.0
	_pause = 0.0
	_angle = _slot_angle(_index)


func _close() -> void:
	is_open = false
	visible = false
	closed.emit()


func _process(delta: float) -> void:
	if not is_open:
		return
	_pause = maxf(0.0, _pause - delta)
	# If you stop moving the mouse, the arrow slowly fades back.
	_mouse_travel = move_toward(_mouse_travel, 0.0, 90.0 * delta)
	# Glide the highlight round the short way.
	var goal := _slot_angle(_index)
	_angle += wrapf(goal - _angle, -PI, PI) * (1.0 - exp(-14.0 * delta))
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion:
		if _pause <= 0.0:
			_mouse_travel += (event as InputEventMouseMotion).relative.x
			if absf(_mouse_travel) >= MOUSE_STEP:
				_step(1 if _mouse_travel > 0.0 else -1)
				_mouse_travel = 0.0
	elif event.is_action_pressed("shine"):
		_choose()  # Left Mouse (the shine control), or F.
	elif event.is_action_pressed("move_right"):
		_step(1)
	elif event.is_action_pressed("move_left"):
		_step(-1)
	elif event is InputEventMouseButton and event.pressed:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_RIGHT:
				_close()
			MOUSE_BUTTON_WHEEL_UP:
				_step(-1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_step(1)
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_E:
				_step(1)
			KEY_Q:
				_step(-1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_choose()
			KEY_ESCAPE, KEY_TAB:
				_close()


func _step(direction: int) -> void:
	_index = posmod(_index + direction, SPECIES.size())
	_pause = PAUSE
	_mouse_travel = 0.0


func _choose() -> void:
	chosen.emit(SPECIES[_index])
	_close()


func _slot_angle(index: int) -> float:
	return float(index) * TAU / SPECIES.size()


# --- Drawing -------------------------------------------------------------------

func _draw_wheel() -> void:
	var size := _canvas.size
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.27
	var cream := Color(1.0, 0.95, 0.82)
	var gold := Color(1.0, 0.80, 0.38)

	# A very faint disc and rings: mostly see-through.
	_canvas.draw_circle(center, radius * 1.32, Color(0.04, 0.06, 0.10, 0.22))
	_canvas.draw_arc(center, radius * 1.32, 0.0, TAU, 96, Color(cream, 0.22), 2.0, true)
	_canvas.draw_arc(center, radius * 0.5, 0.0, TAU, 64, Color(cream, 0.12), 1.5, true)
	_canvas.draw_texture_rect(_glyph, Rect2(center - Vector2(34.0, 34.0), Vector2(68.0, 68.0)), false, Color(cream, 0.16))

	# The highlight: a soft arc that glides round the ring, under the chosen symbol.
	var arc_center := _angle - PI * 0.5
	_canvas.draw_arc(center, radius * 1.0, arc_center - 0.62, arc_center + 0.62, 28, Color(gold, 0.16), 46.0, true)
	_canvas.draw_arc(center, radius * 1.0, arc_center - 0.5, arc_center + 0.5, 28, Color(gold, 0.55), 3.0, true)

	# The arrow: as the mouse travels, it grows from the highlight toward the next place.
	var pull := clampf(_mouse_travel / MOUSE_STEP, -1.0, 1.0)
	if absf(pull) > 0.05 and _pause <= 0.0:
		var span := TAU / SPECIES.size() * absf(pull)
		var from_angle := arc_center + (0.0 if pull > 0.0 else -span)
		var tip_angle := arc_center + span * signf(pull)
		var arrow_radius := radius * 1.17
		_canvas.draw_arc(center, arrow_radius, from_angle, from_angle + span, 24, Color(gold, 0.3 + 0.6 * absf(pull)), 5.0, true)
		var radial := Vector2(cos(tip_angle), sin(tip_angle))
		var tangent := Vector2(-radial.y, radial.x) * signf(pull)
		var tip := center + radial * arrow_radius
		_canvas.draw_colored_polygon(PackedVector2Array([
			tip + tangent * 16.0,
			tip - tangent * 3.0 + radial * 10.0,
			tip - tangent * 3.0 - radial * 10.0,
		]), Color(gold, 0.45 + 0.5 * absf(pull)))

	for i in SPECIES.size():
		var slot := _slot_angle(i)
		var direction := Vector2(sin(slot), -cos(slot))
		var near := clampf(1.0 - absf(wrapf(slot - _angle, -PI, PI)) / (TAU / SPECIES.size()), 0.0, 1.0)
		var icon_height := radius * 0.5 * (1.0 + 0.42 * near)
		var icon: Texture2D = _textures[SPECIES[i]]
		var icon_size := Vector2(icon_height, icon_height)
		var tint := cream.lerp(gold, near)
		tint.a = 0.42 + 0.58 * near
		_canvas.draw_texture_rect(icon, Rect2(center + direction * radius - icon_size * 0.5, icon_size), false, tint)

	# The chosen form's name, and how to use the wheel.
	var font := ThemeDB.fallback_font
	var name_text := SPECIES[_index]
	var name_size := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	_canvas.draw_string(font, center + Vector2(-name_size.x * 0.5, radius * 1.55), name_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(cream, 0.92))
	var hint := "Mouse or A / D  ·  turn        Left Click  ·  choose        Right Click  ·  close"
	var hint_size := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	_canvas.draw_string(font, center + Vector2(-hint_size.x * 0.5, radius * 1.55 + 28.0), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(cream, 0.6))
