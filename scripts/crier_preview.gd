extends Node3D
## A tiny stage for looking at the Town Crier on his own (scenes/crier_preview.tscn).
## Space makes him shout. Left and right arrows turn him. Add `--shout` after `--` to start with a shout.

var _crier: CrierModel
var _camera: Camera3D


func _ready() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.11)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.58, 0.55)
	environment.ambient_light_energy = 0.7
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var ground := MeshInstance3D.new()
	var plane := CylinderMesh.new()
	plane.top_radius = 1.6
	plane.bottom_radius = 1.6
	plane.height = 0.04
	ground.mesh = plane
	ground.position.y = -0.02
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.32, 0.26, 0.19)
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	add_child(ground)

	_crier = CrierModel.new()
	_crier.auto_shout = not OS.get_cmdline_user_args().has("--still")
	add_child(_crier)
	if OS.get_cmdline_user_args().has("--shout"):
		_crier.shout()

	_camera = Camera3D.new()
	_camera.position = Vector3(0.7, 1.25, -3.3)
	_camera.fov = 38.0
	add_child(_camera)
	_camera.look_at(Vector3(0.0, 1.0, 0.0))


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		_crier.shout()
	if Input.is_key_pressed(KEY_LEFT):
		_crier.rotation.y += delta * 1.5
	if Input.is_key_pressed(KEY_RIGHT):
		_crier.rotation.y -= delta * 1.5
