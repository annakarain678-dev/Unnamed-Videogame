class_name Boulder
extends RigidBody3D
## A big, heavy boulder. Only a strong body (like a Tar'ye) can shove it; each shove rolls it
## a couple of meters, then it settles. Weaker bodies can't budge it.

@export var radius := 1.3
@export var color := Color(0.50, 0.48, 0.46)
## How fast it rolls during a shove (m/s), and for how long (s).
@export var shove_speed := 2.6
@export var shove_time := 0.8

var _push := Vector3.ZERO
var _push_left := 0.0


func _ready() -> void:
	add_to_group("boulders")
	mass = 600.0
	collision_layer = Layers.WORLD
	collision_mask = Layers.WORLD | Layers.THIN
	linear_damp = 1.5
	angular_damp = 2.0
	var surface := PhysicsMaterial.new()
	surface.friction = 1.0
	surface.rough = true
	physics_material_override = surface

	# A lumpy, faceted rock shape.
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.75
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	add_child(visual)

	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_convex_shape()
	add_child(collision)


## One strong shove: it rolls along in `direction` for a moment, then settles.
func shove(direction: Vector3) -> void:
	_push = Vector3(direction.x, 0.0, direction.z).normalized()
	_push_left = shove_time
	sleeping = false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _push_left <= 0.0:
		return
	_push_left -= state.step
	# Ease toward the shove speed, and roll to match.
	var velocity := state.linear_velocity
	var goal := _push * shove_speed
	velocity.x = lerpf(velocity.x, goal.x, 0.2)
	velocity.z = lerpf(velocity.z, goal.z, 0.2)
	state.linear_velocity = velocity
	var rolling := Vector3.UP.cross(goal) / radius
	state.angular_velocity = state.angular_velocity.lerp(rolling, 0.2)
