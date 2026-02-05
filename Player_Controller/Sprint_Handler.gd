extends Node

@onready var player : PhysicsBody3D = self.get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if player.stored_sprint_state == false:
		if (Input.is_action_pressed(player.mapped_inputs["sprint"]) and player.toggle_sprint == false) or (Input.is_action_just_pressed(player.mapped_inputs["sprint"]) and player.toggle_sprint == true):
			#print("Sprinting enabled")
			player.sprinting = true
			player.base_speed_multiplier += player.sprint_increase
			player.stored_sprint_state = true
	else:
		if (not Input.is_action_pressed(player.mapped_inputs["sprint"]) and player.toggle_sprint == false) or (Input.is_action_just_pressed(player.mapped_inputs["sprint"]) and player.toggle_sprint == true):
			#print("Sprinting disabled")
			player.sprinting = false
			player.base_speed_multiplier -= player.sprint_increase
			player.stored_sprint_state = false
