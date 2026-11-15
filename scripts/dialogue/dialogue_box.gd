class_name DialogueBox
extends CanvasLayer
## The conversation box along the bottom of the screen. Runs one tree from Dialogues at a time.
## E / Space / Enter continue; 1-4 (or a click) pick an answer; Esc walks away.

const CREAM := Color(1.0, 0.95, 0.82)
const BLUE := Color(0.55, 0.82, 1.0)
const INK := Color(0.045, 0.05, 0.065)

signal opened
signal closed

var is_open := false

var _font: SystemFont
var _root: Control
var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _choices: VBoxContainer
var _hint: Label
var _tree: Dictionary = {}
var _player_species := ""
var _options: Array = []
var _typed := 0.0
var _line_length := 0


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Palatino", "Baskerville", "Georgia", "Times New Roman", "serif"])
	_font.font_weight = 600
	_build()
	_root.visible = false


## Starts talking. `player_species` decides whether the two of you share a language.
func start(tree_id: String, player_species: String) -> void:
	_tree = Dialogues.TREES.get(tree_id, {})
	if _tree.is_empty():
		return
	_player_species = player_species
	is_open = true
	_root.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var person_id := tree_id
	GameState.meet(person_id, _tree["name"], _tree["species"], _tree.get("note", ""))
	opened.emit()
	if not Dialogues.can_understand(player_species, _tree["species"]):
		_show_text("You cannot understand each other. Only Human is spoken and understood by everyone.\n(Take the Human form to talk.)", [])
		return
	for entry in _tree["start"]:
		if GameState.check(entry[0], _player_species):
			_goto(entry[1])
			return


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _goto(node_id: String) -> void:
	var node: Dictionary = _tree["nodes"].get(node_id, {})
	for effect in node.get("effects", []):
		GameState.apply(effect)
	var options: Array = []
	for choice in node.get("choices", []):
		if GameState.check(choice.get("if", ""), _player_species):
			options.append(choice)
	_show_text(node.get("text", "..."), options)


func _show_text(text: String, options: Array) -> void:
	_options = options
	_speaker.text = _tree.get("name", "")
	_text.text = text
	_text.visible_characters = 0
	_line_length = text.length()
	_typed = 0.0
	for child in _choices.get_children():
		child.queue_free()
	for i in options.size():
		var button := _button("%d   %s" % [i + 1, options[i]["text"]])
		button.pressed.connect(_pick.bind(i))
		_choices.add_child(button)
	_hint.text = "" if not options.is_empty() else "E  ·  Goodbye"


func _pick(index: int) -> void:
	if index < 0 or index >= _options.size():
		return
	var choice: Dictionary = _options[index]
	for effect in choice.get("effects", []):
		GameState.apply(effect)
	if choice.has("goto"):
		_goto(choice["goto"])
	else:
		close()


func _process(delta: float) -> void:
	if not is_open:
		return
	if _typed < _line_length:
		_typed = minf(_line_length, _typed + delta * 70.0)
		_text.visible_characters = int(_typed)


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("release_mouse"):
		get_viewport().set_input_as_handled()
		close()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode
	get_viewport().set_input_as_handled()
	if _typed < _line_length:
		# First press shows the whole line.
		if key == KEY_E or key == KEY_SPACE or key == KEY_ENTER:
			_typed = _line_length
			_text.visible_characters = -1
			return
	if key >= KEY_1 and key <= KEY_4:
		_pick(key - KEY_1)
	elif _options.is_empty() and (key == KEY_E or key == KEY_SPACE or key == KEY_ENTER):
		close()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_left = -430.0
	_panel.offset_right = 430.0
	_panel.offset_top = -270.0
	_panel.offset_bottom = -34.0
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.94)
	style.border_color = Color(CREAM, 0.85)
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 16.0
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	_speaker = _label("", 24, BLUE)
	box.add_child(_speaker)
	_text = _label("", 22, CREAM)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(780.0, 0.0)
	box.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 2)
	box.add_child(_choices)
	_hint = _label("", 17, Color(CREAM, 0.65))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_hint)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", BLUE)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(BLUE, 0.08)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button
