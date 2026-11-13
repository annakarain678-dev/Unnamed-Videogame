extends Node
## Registers the game's keyboard controls at startup.
## Keeping them here (instead of the project settings) makes them easy to read and change.

const KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"float_up": [KEY_SPACE],
	"float_down": [KEY_SHIFT],
	# Enter a statue, or leave the body you're in. Change the key here to rebind it.
	"toggle_body": [KEY_TAB],
	# Reserved for talking to people and picking things up (not used yet).
	"interact": [KEY_E],
	# Wisp: flare brighter to drive darklings away. (Also Left Mouse, below.)
	"shine": [KEY_F],
	"release_mouse": [KEY_ESCAPE],
}

const MOUSE_BUTTONS := {
	# Wisp: shine, so you can steer with WASD and shine at once.
	"shine": [MOUSE_BUTTON_LEFT],
	# Wisp: hold to draw a line of light behind you, like your comet tail stretching out.
	# Inside a possessed heart, darklings can't cross it.
	"draw": [MOUSE_BUTTON_RIGHT],
	# In a body: push a boulder (only a strong body like a Tar'ye can move it).
	"push": [MOUSE_BUTTON_RIGHT],
}


func _ready() -> void:
	for action: String in KEYS:
		_ensure_action(action)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	for action: String in MOUSE_BUTTONS:
		_ensure_action(action)
		for button: MouseButton in MOUSE_BUTTONS[action]:
			var event := InputEventMouseButton.new()
			event.button_index = button
			InputMap.action_add_event(action, event)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
