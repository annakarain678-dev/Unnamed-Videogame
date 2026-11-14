class_name PauseMenu
extends CanvasLayer
## The pause menu (Esc), with a journal and options, plus a small "Autosaved" notice.
##
## The look is dark ink with cream trim and diamond flourishes, to match the species symbols and the
## form glyph. Nothing here saves to disk yet: autosaves only remember where the wisp wakes up
## (see PlayerController.set_save_point). When real saving is added, it should hook in at the same place.

const CREAM := Color(1.0, 0.95, 0.82)
const BLUE := Color(0.55, 0.82, 1.0)
const INK := Color(0.045, 0.05, 0.065)
const PANEL_SIZE := Vector2(640.0, 600.0)

## Things the menu changes. Set by whoever builds the world.
var player: PlayerController
var rig: CameraRig
## Called with true or false when "Show info text" is changed.
var info_text_changed := Callable()

var is_open := false

var _font: SystemFont
var _root: Control
var _panel: Control
var _content: VBoxContainer
var _page := "main"
var _quit_armed := false
var _glyph: Texture2D
var _toast_box: HBoxContainer
var _toast_label: Label
var _toast_tween: Tween


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Palatino", "Baskerville", "Georgia", "Times New Roman", "serif"])
	_font.font_weight = 600
	_glyph = load("res://assets/symbols/form_glyph.png")
	_build_panel()
	_build_toast()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("release_mouse"):
		return
	# The form wheel (and anything else that handled Esc first) gets to close itself first.
	if get_viewport().is_input_handled():
		return
	if player and player.is_wheel_open():
		return
	get_viewport().set_input_as_handled()
	if not is_open:
		open()
	elif _page != "main":
		_show_page("main")
	else:
		close()


func open() -> void:
	is_open = true
	_quit_armed = false
	_root.visible = true
	_show_page("main")
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	is_open = false
	_root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Shows a short notice at the top of the screen, e.g. "Autosaved".
func toast(text: String) -> void:
	_toast_label.text = text
	_toast_box.visible = true
	_toast_box.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_box, "modulate:a", 0.0, 0.8)
	_toast_tween.tween_callback(func() -> void: _toast_box.visible = false)


# --- Building the frame ----------------------------------------------------------

func _build_panel() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_top = -PANEL_SIZE.y * 0.5
	_panel.offset_bottom = PANEL_SIZE.y * 0.5
	_panel.draw.connect(_draw_frame)
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 40)
	_panel.add_child(margin)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	margin.add_child(_content)


## The ink panel, a double cream border, diamond corners and the form glyph on the top edge.
func _draw_frame() -> void:
	var size := _panel.size
	var outer := Rect2(Vector2.ZERO, size)
	_panel.draw_rect(outer, Color(INK, 0.95))
	_panel.draw_rect(outer, Color(CREAM, 0.85), false, 3.0)
	var inner := outer.grow(-12.0)
	_panel.draw_rect(inner, Color(CREAM, 0.4), false, 1.5)
	# Diamonds at the four corners, with short lines running along the edges.
	for corner in [Vector2(0, 0), Vector2(size.x, 0), Vector2(0, size.y), Vector2(size.x, size.y)]:
		var toward_x := -1.0 if corner.x > 0.0 else 1.0
		var toward_y := -1.0 if corner.y > 0.0 else 1.0
		var c: Vector2 = corner + Vector2(toward_x * 12.0, toward_y * 12.0)
		_diamond(_panel, c, 9.0, Color(CREAM, 0.9))
		_panel.draw_line(c + Vector2(toward_x * 14.0, 0), c + Vector2(toward_x * 56.0, 0), Color(CREAM, 0.7), 2.0)
		_panel.draw_line(c + Vector2(0, toward_y * 14.0), c + Vector2(0, toward_y * 56.0), Color(CREAM, 0.7), 2.0)
	# The form glyph, set into the top edge.
	var top := Vector2(size.x * 0.5, 0.0)
	_panel.draw_circle(top, 34.0, INK)
	_panel.draw_arc(top, 34.0, 0.0, TAU, 48, Color(CREAM, 0.85), 2.5, true)
	_panel.draw_texture_rect(_glyph, Rect2(top - Vector2(24.0, 24.0), Vector2(48.0, 48.0)), false, Color(CREAM, 0.95))


static func _diamond(canvas: Control, c: Vector2, r: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r * 0.7, 0), c + Vector2(0, r), c + Vector2(-r * 0.7, 0),
	]), color)


## A thin line with a diamond in the middle.
func _divider() -> Control:
	var line := Control.new()
	line.custom_minimum_size = Vector2(0, 22)
	line.draw.connect(func() -> void:
		var mid := Vector2(line.size.x * 0.5, 11.0)
		line.draw_line(Vector2(0, 11), mid - Vector2(14, 0), Color(CREAM, 0.5), 1.5)
		line.draw_line(mid + Vector2(14, 0), Vector2(line.size.x, 11), Color(CREAM, 0.5), 1.5)
		_diamond(line, mid, 6.0, Color(CREAM, 0.8)))
	return line


# --- Pages ----------------------------------------------------------------------

func _show_page(page: String) -> void:
	_page = page
	_quit_armed = false
	for child in _content.get_children():
		child.queue_free()
	match page:
		"options":
			_build_options()
		"journal":
			_build_journal()
		_:
			_build_main()


func _title(text: String) -> void:
	var label := _label(text, 36, CREAM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(label)
	_content.add_child(_divider())


func _build_main() -> void:
	_title("Paused")
	_content.add_child(_button("Resume", close))
	_content.add_child(_button("Journal", func() -> void: _show_page("journal")))
	_content.add_child(_button("Options", func() -> void: _show_page("options")))
	_content.add_child(_button("Save Game", func() -> void:
		toast("Your game saves itself at the pillars")
		close()))
	var quit := _button("Quit to Desktop", Callable())
	quit.pressed.connect(func() -> void:
		if _quit_armed:
			get_tree().quit()
		else:
			_quit_armed = true
			quit.text = "Click again to quit"
		)
	_content.add_child(quit)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(spacer)
	_content.add_child(_divider())
	var save_text := "Last save:  nowhere yet"
	if player and player.has_respawn:
		save_text = "Last save:  the pillar, %s" % player.last_save_text
	var save := _label(save_text, 17, Color(CREAM, 0.7))
	save.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(save)


func _build_options() -> void:
	_title("Options")
	if rig:
		_content.add_child(_slider("Mouse sensitivity", rig.mouse_sensitivity, 0.001, 0.006, func(v: float) -> void: rig.mouse_sensitivity = v))
		_content.add_child(_slider("Field of view", rig.base_fov, 55.0, 100.0, func(v: float) -> void: rig.base_fov = v))
	var info := CheckButton.new()
	info.text = "Show info text"
	info.button_pressed = true
	info.add_theme_font_override("font", _font)
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", CREAM)
	info.add_theme_color_override("font_hover_color", BLUE)
	info.add_theme_color_override("font_pressed_color", CREAM)
	info.toggled.connect(func(on: bool) -> void:
		if info_text_changed.is_valid():
			info_text_changed.call(on))
	_content.add_child(info)
	var volume := _slider("Volume  (no sound yet)", 0.8, 0.0, 1.0, func(_v: float) -> void: pass)
	volume.modulate.a = 0.45
	_content.add_child(volume)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(spacer)
	_content.add_child(_button("Back", func() -> void: _show_page("main")))


func _build_journal() -> void:
	_title("Journal")
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 6)
	_content.add_child(tabs)
	var body := _label("", 20, Color(CREAM, 0.8))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var notes := {
		"Memories": "Nothing recorded yet.\n\nWhat the people you meet remember will be written here.",
		"People": "Nobody has been met yet.",
		"Places": "No places have been found yet.",
		"Rumours": "No rumours yet.\n\nClues that point from one place to another will be linked here.",
	}
	for tab_name in notes:
		var tab := _button(tab_name, func() -> void: body.text = notes[tab_name])
		tab.add_theme_font_size_override("font_size", 19)
		tab.custom_minimum_size = Vector2(0, 34)
		tabs.add_child(tab)
	body.text = notes["Memories"]
	_content.add_child(body)
	# The five marks, as a row of decoration at the foot of the page.
	var marks := HBoxContainer.new()
	marks.alignment = BoxContainer.ALIGNMENT_CENTER
	marks.add_theme_constant_override("separation", 22)
	for icon_name in ["human", "tarye", "fayran", "sen_kash", "qoi_kash"]:
		var mark := TextureRect.new()
		mark.texture = load("res://assets/symbols/%s.png" % icon_name)
		mark.custom_minimum_size = Vector2(46, 46)
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.modulate = Color(CREAM, 0.4)
		marks.add_child(mark)
	_content.add_child(marks)
	_content.add_child(_button("Back", func() -> void: _show_page("main")))


# --- Small pieces ---------------------------------------------------------------

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 46)
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", BLUE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(BLUE, 0.08)
	hover.border_color = Color(BLUE, 0.6)
	hover.border_width_top = 1
	hover.border_width_bottom = 1
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	if action.is_valid():
		button.pressed.connect(action)
	return button


func _slider(text: String, value: float, low: float, high: float, on_change: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_child(_label(text, 20, CREAM))
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = (high - low) / 100.0
	slider.value = value
	slider.focus_mode = Control.FOCUS_NONE
	slider.custom_minimum_size = Vector2(0, 26)
	slider.modulate = Color(CREAM, 0.95)
	slider.value_changed.connect(on_change)
	box.add_child(slider)
	return box


func _build_toast() -> void:
	_toast_box = HBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_box.offset_left = -170.0
	_toast_box.offset_right = 170.0
	_toast_box.offset_top = 22.0
	_toast_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_toast_box.add_theme_constant_override("separation", 10)
	_toast_box.visible = false
	add_child(_toast_box)
	var icon := TextureRect.new()
	icon.texture = _glyph
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(CREAM, 0.95)
	_toast_box.add_child(icon)
	_toast_label = _label("", 22, CREAM)
	_toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_toast_label.add_theme_constant_override("shadow_offset_x", 2)
	_toast_label.add_theme_constant_override("shadow_offset_y", 2)
	_toast_box.add_child(_toast_label)
