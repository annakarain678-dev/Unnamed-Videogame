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
## Sent when the game autosaves (at a pillar), with the text to show.
signal saved(text: String)

## The body the wisp is in, or null while it's free.
var current_body: FormBody = null
## True while the wisp is inside a possessed heart, fighting a darkling (see HeartChase).
var in_heart := false

## Where the wisp wakes up when a body is lost (the last form pillar it used).
var respawn_point := Vector3.ZERO
var has_respawn := false
## When and where the last save was, for the pause menu (e.g. "Day 1  ·  10:35 am").
var last_save_text := ""

var _wheel: FormWheel
var _wheel_pillar: FormPillar
var _frozen_body: FormBody
var _talking_body: FormBody
var _prompt: Label
var _energy: ProgressBar
var _breath: ProgressBar
var _notice_text := ""
var _notice_left := 0.0

@onready var _wisp: Wisp = get_node(wisp_path)
@onready var _rig: CameraRig = get_node(camera_rig_path)


func _ready() -> void:
	add_to_group("player_controller")
	_build_prompt()
	_wheel = FormWheel.new()
	add_child(_wheel)
	_wheel.chosen.connect(_on_form_chosen)
	_wheel.closed.connect(_on_wheel_closed)


## Puts the wisp into `body`, bringing it to life.
func enter_body(body: FormBody) -> void:
	_enter_body(body)


## Remembers where the wisp should wake up if a body is lost.
## (Nothing is written to disk yet; this is the one place real saving will hook in later.)
func set_save_point(at: Vector3, announce := true) -> void:
	respawn_point = at
	has_respawn = true
	var atmosphere := get_tree().get_first_node_in_group("atmosphere") as Atmosphere
	last_save_text = atmosphere.cycle.clock_text() if atmosphere else ""
	if announce:
		saved.emit("Autosaved")


func is_wheel_open() -> bool:
	return _wheel != null and _wheel.is_open


## True while a conversation is open.
func is_talking() -> bool:
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	return box != null and box.is_open


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not in_heart and not _wheel.is_open and not is_talking():
		var npc := _nearest_npc()
		if npc and current_body:
			_start_talk(npc)
			get_viewport().set_input_as_handled()
			return
		elif npc:
			_notice("You need a body to talk to %s. Take a form." % npc.display_name)
			return
	# As the wisp, Right Mouse beside a form pillar opens its wheel of forms.
	if event.is_action_pressed("draw") and not in_heart and not _wheel.is_open:
		var pillar := _nearest_pillar()
		if pillar:
			_open_wheel(pillar)
			get_viewport().set_input_as_handled()
			return
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


## A body drowned (while you were in it) or a statue shattered from a fall. Either way the body goes
## back to its plinth; if you were in it, you're thrown out as the wisp. (Later, dying in a body
## restarts the chapter's loop.)
func on_body_lost(body: FormBody, reason: String) -> void:
	if reason == "drowned" and body == current_body:
		_lose_body(body, "You drowned.", "The %s statue is back on its plinth." % body.species)
	elif reason == "crashed" and body == current_body:
		_lose_body(body, "You hit the ground too hard and shattered.", "The %s statue is back on its plinth." % body.species)
	elif reason == "shattered":
		_notice("The %s statue shattered from the fall. It's back on its plinth." % body.species)


## You lose a body for good (the sacrifice has a price): a form made at a pillar is gone, and the wisp
## wakes at the last pillar it used. (A statue from the old test island just goes back to its plinth.)
func _lose_body(body: FormBody, what_happened: String, statue_note: String) -> void:
	_leave_body()
	if body.is_in_group("pillar_forms"):
		body.queue_free()
		if has_respawn:
			_wisp.global_position = respawn_point
			_wisp.velocity = Vector3.ZERO
			_wisp.reset_physics_interpolation()
			_rig.snap_to_target()
		_notice("%s You wake at the last pillar." % what_happened)
	else:
		body.return_home()
		_notice("%s %s" % [what_happened, statue_note])


func _nearest_pillar() -> FormPillar:
	var nearest: FormPillar = null
	var nearest_distance := 4.5
	# (As a body, it's the body that has to be beside the pillar.)
	var here := current_body.global_position if current_body else _wisp.global_position
	for node in get_tree().get_nodes_in_group("form_pillars"):
		var pillar := node as FormPillar
		var distance := here.distance_to(pillar.global_position + Vector3.UP * 1.0)
		if distance < nearest_distance:
			nearest = pillar
			nearest_distance = distance
	return nearest


func _nearest_npc() -> Npc:
	var nearest: Npc = null
	var here := current_body.global_position if current_body else _wisp.global_position
	var best := 1.0e9
	for node in get_tree().get_nodes_in_group("npcs"):
		var npc := node as Npc
		var d := here.distance_to(npc.global_position + Vector3.UP * 1.0)
		if d < npc.talk_range and d < best:
			nearest = npc
			best = d
	return nearest


func _start_talk(npc: Npc) -> void:
	var box := get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box == null:
		return
	# Hold the body still while talking.
	_talking_body = current_body
	_talking_body.velocity = Vector3.ZERO
	_talking_body.set_physics_process(false)
	if not box.closed.is_connected(_on_talk_closed):
		box.closed.connect(_on_talk_closed)
	box.start(npc.npc_id, current_body.species)


func _on_talk_closed() -> void:
	if _talking_body and is_instance_valid(_talking_body):
		_talking_body.set_physics_process(true)
	_talking_body = null


func _open_wheel(pillar: FormPillar) -> void:
	_wheel_pillar = pillar
	# Touching a pillar autosaves.
	set_save_point(pillar.respawn_position())
	# Hold the wisp (or the body you are in) still while the wheel is open.
	_wisp.velocity = Vector3.ZERO
	_wisp.set_physics_process(false)
	_frozen_body = current_body
	if _frozen_body:
		_frozen_body.velocity = Vector3.ZERO
		_frozen_body.set_physics_process(false)
	_wheel.open()


func _on_form_chosen(species: String) -> void:
	if _wheel_pillar == null:
		return
	if current_body:
		if current_body.species == species:
			return  # Already in that form.
		# Step out of the old form (a form made at a pillar just goes away) and into the new one.
		_leave_body()
	_enter_body(_wheel_pillar.spawn_form(species))


func _on_wheel_closed() -> void:
	if _frozen_body and is_instance_valid(_frozen_body):
		_frozen_body.set_physics_process(true)
	_frozen_body = null
	# If no form was chosen, the wisp is free again. (Entering a body keeps it switched off.)
	if current_body == null:
		_wisp.set_physics_process(true)


func _notice(text: String) -> void:
	_notice_text = text
	_notice_left = 4.0


func _process(delta: float) -> void:
	var key := _key_name("toggle_body")
	_notice_left = maxf(0.0, _notice_left - delta)
	if is_talking():
		_prompt.text = ""
	elif _notice_left > 0.0:
		_prompt.text = _notice_text
	elif in_heart:
		_prompt.text = ""  # The heart chase shows its own instructions.
	elif current_body:
		if current_body.is_struggling:
			_prompt.text = "Too heavy for a %s" % current_body.species
		elif current_body.can_fly and current_body.in_deep_water:
			_prompt.text = "Your wings are soaked: you can't swim!"
		elif current_body.at_ceiling:
			_prompt.text = "The air is too thin to fly any higher"
		elif current_body.can_fly and current_body.wings_soaked:
			_prompt.text = "Your wings are still drying"
		elif current_body.can_fly and not current_body.is_flying and not current_body.is_on_floor():
			_prompt.text = "Space  ·  Spread your wings and fly"
		elif _nearest_npc() != null:
			_prompt.text = "%s  ·  Talk to %s        %s  ·  Leave the body" % [_key_name("interact"), _nearest_npc().display_name, key]
		elif _nearest_pillar() != null:
			_prompt.text = "Right Mouse  ·  Change form"
		elif current_body.nearby_boulder() and not current_body.is_busy():
			_prompt.text = "Right Mouse  ·  Push the boulder"
		else:
			_prompt.text = "%s  ·  Leave the %s body" % [key, current_body.species]
	else:
		var statue := _nearest_statue()
		if _wheel.is_open:
			_prompt.text = ""
		elif statue == null and _nearest_npc() != null:
			_prompt.text = "You need a body to talk to %s  ·  Take a form" % _nearest_npc().display_name
		elif statue == null and _nearest_pillar() != null:
			_prompt.text = "Right Mouse  ·  Change form"
		elif statue == null:
			_prompt.text = ""
		elif statue.haunted:
			_prompt.text = "A darkling possesses this statue  ·  Hold Left Mouse to shine"
		else:
			_prompt.text = "%s  ·  Enter the %s statue" % [key, statue.species]
	_prompt.visible = _prompt.text != ""

	# The Fayran's flight energy, shown while it isn't full.
	var flier := current_body != null and current_body.can_fly and not in_heart
	_energy.visible = flier and current_body.flight_energy < 99.5
	if flier:
		_energy.value = current_body.flight_energy

	# Breath, shown while holding it (bodies without gills).
	var holding := current_body != null and not is_inf(current_body.max_breath) \
		and current_body.breath < current_body.max_breath - 0.05
	_breath.visible = holding
	if holding:
		_breath.value = 100.0 * current_body.breath / current_body.max_breath


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
	# A form made at a pillar is only borrowed: leaving it, it simply goes away.
	if body.is_in_group("pillar_forms"):
		body.queue_free()


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

	# A slim bar for a Fayran's flight energy, just above the prompt.
	_energy = ProgressBar.new()
	_energy.show_percentage = false
	_energy.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_energy.offset_left = -110.0
	_energy.offset_right = 110.0
	_energy.offset_top = -112.0
	_energy.offset_bottom = -102.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.98, 0.94, 0.80)
	fill.set_corner_radius_all(4)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	back.set_corner_radius_all(4)
	_energy.add_theme_stylebox_override("fill", fill)
	_energy.add_theme_stylebox_override("background", back)
	_energy.visible = false
	layer.add_child(_energy)

	# A blue bar for breath underwater, just above that.
	_breath = _energy.duplicate() as ProgressBar
	_breath.offset_top = -128.0
	_breath.offset_bottom = -118.0
	var water := StyleBoxFlat.new()
	water.bg_color = Color(0.45, 0.75, 1.0)
	water.set_corner_radius_all(4)
	_breath.add_theme_stylebox_override("fill", water)
	_breath.visible = false
	layer.add_child(_breath)
