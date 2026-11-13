class_name PlayerController
extends Node
## Decides what the player controls: the wisp, or a body it has entered.
## Press Tab near a statue to enter it. Press Tab again to leave; the body turns back to stone where it stands.

@export var wisp_path: NodePath
@export var camera_rig_path: NodePath
## How close (in meters) the wisp must be to a statue's chest to enter it.
@export var interact_range := 2.6

## Sent when the player enters a body (true) or returns to being the wisp (false).
signal form_changed(in_body: bool)

## The body the wisp is in, or null while it's free.
var current_body: FormBody = null
## True while the wisp is inside a possessed heart, fighting a darkling (see HeartChase).
var in_heart := false

var _prompt: Label

@onready var _wisp: Wisp = get_node(wisp_path)
@onready var _rig: CameraRig = get_node(camera_rig_path)


func _ready() -> void:
	add_to_group("player_controller")
	_build_prompt()


## Puts the wisp into `body`, bringing it to life.
func enter_body(body: FormBody) -> void:
	_enter_body(body)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_body"):
		return
	if in_heart:
		# Tab inside a heart: give up the fight.
		var chase := get_tree().get_first_node_in_group("heart_chase") as HeartChase
		if chase:
			chase.give_up()
		return
	if current_body:
		_leave_body()
	else:
		var statue := _nearest_statue()
		if statue and not statue.haunted:
			_enter_body(statue)


func _process(_delta: float) -> void:
	var key := _key_name("toggle_body")
	if in_heart:
		_prompt.text = ""  # The heart chase shows its own instructions.
	elif current_body:
		if current_body.is_struggling:
			_prompt.text = "Too heavy for a %s" % current_body.species
		elif current_body.nearby_boulder() and not current_body.is_busy():
			_prompt.text = "Right Mouse  ·  Push the boulder"
		else:
			_prompt.text = "%s  ·  Leave the %s body" % [key, current_body.species]
	else:
		var statue := _nearest_statue()
		if statue == null:
			_prompt.text = ""
		elif statue.haunted:
			_prompt.text = "A darkling possesses this statue  ·  Hold Left Mouse to shine"
		else:
			_prompt.text = "%s  ·  Enter the %s statue" % [key, statue.species]
	_prompt.visible = _prompt.text != ""


func _enter_body(body: FormBody) -> void:
	current_body = body
	_wisp.set_active(false)
	body.possess(_rig)
	_rig.set_target(body, body.camera_height)
	form_changed.emit(true)


func _leave_body() -> void:
	var body := current_body
	current_body = null
	body.release()
	# The wisp rises out of the body's head.
	_wisp.global_position = body.global_position + Vector3.UP * 2.3
	_wisp.set_active(true)
	_rig.set_target(_wisp, 0.0)
	form_changed.emit(false)


func _nearest_statue() -> FormBody:
	var nearest: FormBody = null
	var nearest_distance := interact_range
	for node in get_tree().get_nodes_in_group("form_bodies"):
		var body := node as FormBody
		if body == null or body.possessed:
			continue
		var distance := _wisp.global_position.distance_to(body.get_core_position())
		if distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest


## The name of the key bound to an action (e.g. "Tab"), so prompts stay right if it's rebound.
func _key_name(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return OS.get_keycode_string((event as InputEventKey).physical_keycode)
	return action


func _build_prompt() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	_prompt.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_prompt.add_theme_constant_override("shadow_offset_x", 2)
	_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -300.0
	_prompt.offset_right = 300.0
	_prompt.offset_top = -90.0
	_prompt.offset_bottom = -50.0
	_prompt.visible = false
	layer.add_child(_prompt)
