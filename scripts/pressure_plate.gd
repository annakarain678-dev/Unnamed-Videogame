class_name PressurePlate
extends Node3D
## A round stone plate set into the ground. Anything heavy resting on it presses it down:
## a body (alive, or turned back to stone) or a boulder. The wisp weighs nothing.
## Glows while pressed, and sends `changed` when it's pressed or released.

signal changed(pressed: bool)

@export var radius := 0.95

var pressed := false

var _area: Area3D
var _material: StandardMaterial3D
var _top: Node3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.42, 0.40, 0.38)
	_material.roughness = 0.9
	_material.emission_enabled = true
	_material.emission = Color(0.0, 0.0, 0.0)

	# The plate itself: a low disc you can stand on. It sinks a little when pressed.
	_top = Node3D.new()
	add_child(_top)
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.16
	disc.radial_segments = 16
	disc.material = _material
	var body := StaticBody3D.new()
	body.collision_layer = Layers.THIN
	body.position.y = 0.08
	_top.add_child(body)
	var visual := MeshInstance3D.new()
	visual.mesh = disc
	body.add_child(visual)
	var shape := CollisionShape3D.new()
	shape.shape = disc.create_convex_shape()
	body.add_child(shape)

	# A ring of darker stone around it, so it reads as a "thing" from a distance.
	var rim := CylinderMesh.new()
	rim.top_radius = radius + 0.25
	rim.bottom_radius = radius + 0.3
	rim.height = 0.06
	rim.radial_segments = 16
	var rim_material := StandardMaterial3D.new()
	rim_material.albedo_color = Color(0.25, 0.24, 0.23)
	rim.material = rim_material
	var rim_visual := MeshInstance3D.new()
	rim_visual.mesh = rim
	rim_visual.position.y = 0.03
	add_child(rim_visual)

	# What counts as "on the plate": a short column above it.
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.WORLD | Layers.THIN
	_area.monitorable = false
	var column := CylinderShape3D.new()
	column.radius = radius
	column.height = 1.4
	var area_shape := CollisionShape3D.new()
	area_shape.shape = column
	area_shape.position.y = 0.8
	_area.add_child(area_shape)
	add_child(_area)


func _physics_process(_delta: float) -> void:
	var weighed_down := false
	for body in _area.get_overlapping_bodies():
		if body is FormBody or body is Boulder:
			weighed_down = true
			break
	if weighed_down == pressed:
		return
	pressed = weighed_down
	_top.position.y = -0.07 if pressed else 0.0
	_material.emission = Color(0.9, 0.7, 0.3) if pressed else Color(0.0, 0.0, 0.0)
	_material.emission_energy_multiplier = 0.6
	changed.emit(pressed)
