#This should be placed in the projects autoload

extends Node

@onready var interaction_prompt : MeshInstance3D = preload("uid://cwv3i276eharx").instantiate()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().get_root().add_child.call_deferred(interaction_prompt)
	InteractionHandler.interactable_detected.connect(showHint)
	InteractionHandler.interactable_detected_direct.connect(showHint)
	InteractionHandler.no_interactable_detected.connect(hideHint)
	
func showHint(object : Node) -> void:
	interaction_prompt.global_position = object.global_position
	interaction_prompt.visible = true

func hideHint() -> void:
	interaction_prompt.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
