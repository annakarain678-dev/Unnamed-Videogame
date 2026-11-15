class_name Npc
extends Node3D
## A person you can talk to. A stand-in body (the same low-poly model the forms use), solid, who turns to face
## you when you are close. The conversation itself is in Dialogues, keyed by `npc_id`.

@export var npc_id := ""
## How close the player (wisp or body) must be to talk.
@export var talk_range := 4.0

var species := "Human"
var display_name := ""

var _model: Node3D


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

	if npc_id == "crier":
		_model = CrierModel.new()  # his own model, with his own idle and shouting animations
		add_child(_model)
	else:
		var generic := BodyModel.new(species)
		generic.set_owner_body(body)
		add_child(generic)
		generic.set_stone(false)
		_model = generic


func _process(delta: float) -> void:
	var generic := _model as BodyModel
	if generic:
		generic.animate(0.0, false, true, delta)
		generic.update_serpent_tail(delta, 0.0, global_position.y, true, true)
