class_name PlaceTags
extends Control
## Names of places, drawn on the screen at the spot where each place is. They are flat text on top of the
## picture, so fog, the wisp's colors and distance never wash them out. Tags for things underground only
## show while you are underground, and the others only while you are not.

## True while the camera is under the ground.
var underground_view := false

var _tags: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `far` is how far away the tag shows (0 = always). `big` is for the main places.
func add_tag(text: String, at: Vector3, far: float, underground := false, big := false) -> void:
	_tags.append({"text": text, "at": at, "far": far, "underground": underground, "big": big})


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var font := ThemeDB.fallback_font
	var shown: Array = []
	for tag in _tags:
		if tag["underground"] != underground_view:
			continue
		var at: Vector3 = tag["at"]
		if camera.is_position_behind(at):
			continue
		var distance := camera.global_position.distance_to(at)
		var far: float = tag["far"]
		if far > 0.0 and distance > far:
			continue
		shown.append([distance, tag])
	# Far ones first, so near ones are drawn on top.
	shown.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for entry in shown:
		var tag: Dictionary = entry[1]
		var distance: float = entry[0]
		var far: float = tag["far"]
		var fade := 1.0 if far <= 0.0 else clampf((far - distance) / (far * 0.25), 0.0, 1.0)
		var size := 22 if tag["big"] else 16
		var screen := camera.unproject_position(tag["at"])
		var lines: PackedStringArray = (tag["text"] as String).split("\n")
		for i in lines.size():
			var width := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var position := screen + Vector2(-width * 0.5, i * (size + 3))
			draw_string_outline(font, position, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0.0, 0.0, 0.0, 0.85 * fade))
			draw_string(font, position, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1.0, 1.0, 1.0, fade))
