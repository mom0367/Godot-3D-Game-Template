extends Node
#TODO make a subnode instead of a script for the main node
@onready var player_controller : Node = get_parent().get_parent()
@export var animation_tree : AnimationTree

func _process(_delta: float) -> void:
	
	##Scales animation speed with player speed when appropriate
	var increase : float = ((1 * player_controller.velocity.length()) / 6)
	animation_tree.set("parameters/Walk/Character_Speed_Scale/scale", increase)
	animation_tree.set("parameters/Sprint/Character_Speed_Scale/scale", increase)
	animation_tree.set("parameters/Crouch_Walk/Character_Speed_Scale/scale", increase)
