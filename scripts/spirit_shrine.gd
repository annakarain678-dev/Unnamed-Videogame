class_name SpiritShrine
extends Node3D
## A small glowing orb on a pedestal that only the wisp can take.
## Taking it makes the wisp's home star grow a little, as the wisp learns and grows.

## How much the home star grows (its full range is 0 to 1).
@export var growth := 0.15
@export var message := "Your star grows a little brighter"

var _taken := false
var _time := 0.0
var _orb: MeshInstance3D
var _light: OmniLight3D
var _label: Label
var _message_left := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.40, 0.38, 0.36)
	var pedestal := CylinderMesh.new()
	pedestal.top_radius = 0.3
	pedestal.bottom_radius = 0.4
	pedestal.height = 1.0
	pedestal.radial_segments = 8
	pedestal.material = stone
	var base := MeshInstance3D.new()
	base.mesh = pedestal
	base.position.y = 0.5
	add_child(base)

	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.95, 0.8)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.86, 0.55)
	glow.emission_energy_multiplier = 4.0
	glow.disable_fog = true
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	sphere.material = glow
	_orb = MeshInstance3D.new()
	_orb.mesh = sphere
	_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_orb.position.y = 1.4
	add_child(_orb)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.86, 0.55)
	_light.light_energy = 1.4
	_light.omni_range = 5.0
	_light.position.y = 1.4
	add_child(_light)

	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	_label = Label.new()
	_label.text = message
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.78))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.offset_left = -400.0
	_label.offset_right = 400.0
	_label.offset_top = -120.0
	_label.visible = false
	layer.add_child(_label)


func _process(delta: float) -> void:
	_time += delta
	if _message_left > 0.0:
		_message_left -= delta
		_label.modulate.a = clampf(_message_left, 0.0, 1.0)
		_label.visible = _message_left > 0.0

	if _taken:
		# The orb rises and fades into the wisp.
		_orb.scale = _orb.scale.move_toward(Vector3.ZERO, delta * 1.5)
		_light.light_energy = move_toward(_light.light_energy, 0.0, delta * 2.0)
		return

	_orb.position.y = 1.4 + sin(_time * 2.0) * 0.06
	var wisp := get_tree().get_first_node_in_group("wisp") as Wisp
	if wisp and wisp.visible and wisp.global_position.distance_to(_orb.global_position) < 1.1:
		_take()


func _take() -> void:
	_taken = true
	var atmosphere := get_tree().get_first_node_in_group("atmosphere") as Atmosphere
	if atmosphere:
		atmosphere.grow_star(growth)
	_label.visible = true
	_message_left = 4.0
