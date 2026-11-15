extends Node
## Developer helpers, only active when the game is launched with special options.
##
## Take a screenshot and quit (used for automated checks):
##   Godot --path . -- --screenshot=screenshots/test.png
## Optional extras:
##   --screenshot-delay=2.5          seconds to wait before the shot
##   --wisp-pos=0,-3,70              move the wisp somewhere first
##   --look=yaw,pitch                camera angles in degrees
##   --hour=18.5                     set the time of day (0-24)
##   --hold=move_right,move_forward  hold down these controls (simulated)
##   --hold=move_forward@2.0         ...starting after 2 seconds
##   --press=interact@1.0,interact@4 tap these controls at these times (seconds)
##   --release=move_forward@5        let go of a held control at this time
##   --print-body-height=10          print the controlled body's height each second
##   --zoom=2.5                      camera distance behind the wisp (default 6)
##   --enter=Human@12                become that form at the nearest pillar after this many seconds
##   --menu=journal@3               open the pause menu on a page at that time
##   --talk=crier@14                 open this person's conversation at that time (needs a body)
##   --day                           (forest) see the world in daylight as the wisp

var _screenshot_path := ""
var _delay := 2.5


func _ready() -> void:
	var options := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			options[arg.get_slice("=", 0).trim_prefix("--")] = arg.get_slice("=", 1)
		elif arg == "--day":
			options["day"] = "1"

	if options.is_empty():
		return
	_screenshot_path = options.get("screenshot", "")
	_delay = float(options.get("screenshot-delay", _delay))

	await get_tree().process_frame
	_apply_setup(options)
	if _screenshot_path != "":
		_take_screenshot_later()


func _apply_setup(options: Dictionary) -> void:
	var scene := get_tree().current_scene
	var wisp := scene.find_child("Wisp", true, false) as Node3D
	var rig := scene.find_child("CameraRig", true, false) as Node3D

	if options.has("wisp-pos") and wisp:
		var parts: PackedStringArray = options["wisp-pos"].split(",")
		wisp.global_position = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
		wisp.reset_physics_interpolation()
		if rig:
			rig.global_position = wisp.global_position

	if options.has("zoom"):
		var arm := scene.find_child("SpringArm3D", true, false) as SpringArm3D
		if arm:
			arm.spring_length = float(options["zoom"])

	if options.has("day"):
		if scene.has_method("set_day_preview"):
			scene.call("set_day_preview", true)

	if options.has("hour"):
		var atmosphere := scene.find_child("Atmosphere", true, false) as Atmosphere
		if atmosphere:
			atmosphere.cycle.hour = float(options["hour"])

	if options.has("look") and rig:
		var angles: PackedStringArray = options["look"].split(",")
		rig.set("yaw", deg_to_rad(float(angles[0])))
		rig.set("pitch", deg_to_rad(float(angles[1])))

	if options.has("hold"):
		for entry: String in options["hold"].split(","):
			_hold_later(entry.get_slice("@", 0), float(entry.get_slice("@", 1)) if "@" in entry else 0.0)

	if options.has("release"):
		for entry: String in options["release"].split(","):
			_release_later(entry.get_slice("@", 0), float(entry.get_slice("@", 1)) if "@" in entry else 0.0)

	if options.has("print-body-height"):
		_print_body_height_later(float(options["print-body-height"]))

	if options.has("enter"):
		_enter_later(options["enter"].get_slice("@", 0), float(options["enter"].get_slice("@", 1)) if "@" in options["enter"] else 0.0)

	if options.has("menu"):
		_menu_later(options["menu"].get_slice("@", 0), float(options["menu"].get_slice("@", 1)) if "@" in options["menu"] else 0.0)

	if options.has("talk"):
		_talk_later(options["talk"].get_slice("@", 0), float(options["talk"].get_slice("@", 1)) if "@" in options["talk"] else 0.0)

	if options.has("press"):
		for entry: String in options["press"].split(","):
			_tap_later(entry.get_slice("@", 0), float(entry.get_slice("@", 1)) if "@" in entry else 0.0)


func _enter_later(species: String, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	var controller := get_tree().get_first_node_in_group("player_controller") as PlayerController
	var pillar := get_tree().get_first_node_in_group("form_pillars") as FormPillar
	if controller and pillar:
		controller.enter_body(pillar.spawn_form(species))


func _menu_later(page: String, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	var menu := get_tree().current_scene.find_child("PauseMenu", true, false) as PauseMenu
	if menu:
		menu.open()
		menu._show_page(page)


func _talk_later(npc_id: String, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	var only_go := npc_id.begins_with("near:")
	npc_id = npc_id.trim_prefix("near:")
	var controller := get_tree().get_first_node_in_group("player_controller") as PlayerController
	for node in get_tree().get_nodes_in_group("npcs"):
		if (node as Npc).npc_id == npc_id and controller and controller.current_body:
			controller.current_body.global_position = node.global_position + Vector3(0.0, 0.3, 2.6)
			if not only_go:
				controller._start_talk(node)


func _hold_later(action: String, seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
	Input.action_press(action)


func _release_later(action: String, seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
	Input.action_release(action)


## Prints the height of whichever body is being controlled, every second for this many seconds.
func _print_body_height_later(seconds: float) -> void:
	for i in int(seconds):
		await get_tree().create_timer(1.0).timeout
		var controller := get_tree().current_scene.find_child("PlayerController", true, false)
		var body: Node3D = controller.get("current_body") if controller else null
		if body:
			print("t=%ds body height: %.2f" % [i + 1, body.global_position.y])


func _tap_later(action: String, seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
	_send_action(action, true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_send_action(action, false)


func _send_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _take_screenshot_later() -> void:
	await get_tree().create_timer(_delay).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var absolute := ProjectSettings.globalize_path("res://" + _screenshot_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error := image.save_png(absolute)
	print("Screenshot saved: %s (%s)" % [absolute, error_string(error)])
	get_tree().quit()
