extends Node


@onready var head_drop_distance : float = 0.65
@onready var collider_drop_distance : float = 0.4
@onready var easing_type : Tween.TransitionType = Tween.TRANS_LINEAR



#TODO make these less hardcoded
@onready var player : PhysicsBody3D = self.get_parent()
@export var camera : Camera3D

@onready var collider : CollisionShape3D = player.get_node("Collider")
@onready var raycast_length : float = player.get_node("Collider").get_shape().height

@onready var tween : Tween
@onready var tween_debounce : bool = false

#TODO Make the values dynamically adjust for bigger/smaller characters if possible.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#Debounce to stop crouch from getting slowly offset
	if player.stored_crouch_state == false and tween_debounce == false:
		
		if (Input.is_action_pressed(player.mapped_inputs["crouch"]) and player.toggle_crouch == false) or (Input.is_action_just_pressed(player.mapped_inputs["crouch"]) and player.toggle_crouch == true):
			#print("Crouching enabled")
			tween_debounce = true
			player.crouching = true
			tween = create_tween().set_trans(easing_type)
			tween.tween_property(collider, "position:y", collider.position.y - (collider_drop_distance * 0.5), player.crouch_animation_time)
			tween.tween_property(collider.get_shape(), "height", (collider.get_shape().height - collider_drop_distance), player.crouch_animation_time)
			#Adjusts camera offset as setting the position directly interferes with the perspective script.
			tween.tween_property(camera, "v_offset", camera.v_offset - head_drop_distance, player.crouch_animation_time)


			player.stored_crouch_state = true
			await tween.finished
			tween_debounce = false
	elif tween_debounce == false:
		if (not Input.is_action_pressed(player.mapped_inputs["crouch"]) and player.toggle_crouch == false) or (Input.is_action_just_pressed(player.mapped_inputs["crouch"]) and player.toggle_crouch == true):
			#Raycast setup
			var space_state : PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
			var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(player.global_position, (player.global_position  + Vector3(0, +raycast_length, 0)))
			var result : Dictionary = space_state.intersect_ray(query)
			#Stops player from uncrouching if under an obstacle
			if result:
				if result.collider:
					pass
					#print("Collider found, won't uncrouch.")
			else:
				tween_debounce = true
				player.crouching = false
				if tween:
					tween.kill()
				tween = create_tween().set_trans(easing_type)
				tween.tween_property(collider, "position:y", collider.position.y + (collider_drop_distance * 0.5), player.crouch_animation_time)
				tween.tween_property(collider.get_shape(), "height", (collider.get_shape().height + collider_drop_distance), player.crouch_animation_time)
				tween.tween_property(camera, "v_offset", camera.v_offset + head_drop_distance, player.crouch_animation_time)
				player.stored_crouch_state = false
				await tween.finished
				tween_debounce = false
