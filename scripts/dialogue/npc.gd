class_name Npc
extends Node3D
## A person you can talk to. A stand-in body (the same low-poly model the forms use), solid, who turns to face
## you when you are close. The conversation itself is in Dialogues, keyed by `npc_id`.

@export var npc_id := ""
## How close the player (wisp or body) must be to talk.
@export var talk_range := 4.0

var species := "Human"
var display_name := ""

var _model: BodyModel


func _ready() -> void:
	add_to_group("npcs")
	var tree: Dictionary = Dialogues.TREES.get(npc_id, {})
	species = tree.get("species", "Human")
	display_name = tree.get("name", npc_id)

	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.85
	shape.shape = capsule
	shape.position.y = 0.93
	body.add_child(shape)
	add_child(body)

	_model = BodyModel.new(species)
	_model.set_owner_body(body)
	add_child(_model)
	_model.set_stone(false)


func _process(delta: float) -> void:
	if _model:
		_model.animate(0.0, false, true, delta)
		_model.update_serpent_tail(delta, 0.0, global_position.y, true, true)
