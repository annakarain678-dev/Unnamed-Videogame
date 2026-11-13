class_name StoneGate
extends AnimatableBody3D
## A heavy stone slab blocking a doorway. When opened, it grinds down into the ground;
## when closed, it rises back up. It blocks bodies and the wisp alike.

@export var size := Vector3(2.0, 3.0, 0.4)
## How long it takes to fully open or close (seconds).
@export var travel_time := 1.2

var is_open := false

var _closed_y := 0.0
var _amount := 0.0  # 0 = shut, 1 = fully open


func _ready() -> void:
	collision_layer = Layers.WORLD
	_closed_y = position.y

	var slab := BoxMesh.new()
	slab.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.36, 0.34, 0.33)
	material.roughness = 1.0
	slab.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = slab
	add_child(visual)

	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)


func set_open(open: bool) -> void:
	is_open = open


func _physics_process(delta: float) -> void:
	var goal := 1.0 if is_open else 0.0
	if is_equal_approx(_amount, goal):
		return
	_amount = move_toward(_amount, goal, delta / travel_time)
	# Sinks all the way below the ground when open.
	position.y = _closed_y - (size.y + 0.1) * smoothstep(0.0, 1.0, _amount)
