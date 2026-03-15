#THIS REQUIRES THE INTERACTOR3D CLASS TO EXIST 
#Also this should be placed in the projects autoload
extends Node

const max_check_distance : float = 9999
##Determines if interactors can be activated directly using the cursor
const direct_interaction : bool = true
##Determines if prompts will show up in the world to allow you to interact (Not to be confused with the direct interact UI)
const proximity_interaction : bool = true
const max_proximity_angle : float = 130

##If an interactable has been detected
signal interactable_detected(object : Node)
##If an interactable has been detected through a direct raycast specifically
signal interactable_detected_direct(object : Node)
##If no interactable has been detected
signal no_interactable_detected
##If no interactable has been detected through a direct raycast
signal no_interactable_detected_direct



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	# UID for interaction prompt scene
	
	
	
	var active_camera : Camera3D = get_viewport().get_camera_3d()
	var active_interactable : Interactable3D
	#Assumes a camera -> head -> player structure as of now
	var player : Node3D = active_camera.get_parent().get_parent()
	var interactable_flag : bool = false
	var interactable_flag_direct : bool = false
	
	if proximity_interaction:
		for current_node in get_tree().get_nodes_in_group("Interactors"):
			if player.global_position.distance_to(current_node.global_position) <= current_node.max_distance:
				#print("Distance to " + str(player.global_position.distance_to(current_node.global_position)))
				var horizontal_angle : float = rad_to_deg(-player.global_basis.x.normalized().dot((current_node.global_position - player.global_position).normalized()) * PI)
				#print(horizontal_angle)
				
				if abs(horizontal_angle) <= max_proximity_angle and current_node.is_on_screen() == true:
					#print(current_node.is_on_screen())
					interactable_detected.emit(current_node)
					interactable_flag = true
					active_interactable = current_node
	
	if direct_interaction:
		var space_state : PhysicsDirectSpaceState3D = active_camera.get_world_3d().direct_space_state
		var origin : Vector3 = active_camera.project_ray_origin(get_viewport().get_mouse_position())
		var target : Vector3 = origin + active_camera.project_ray_normal(get_viewport().get_mouse_position()) * max_check_distance
	
		var query := PhysicsRayQueryParameters3D.create(origin, target)
		query.collide_with_areas = true
	
	
		var result := space_state.intersect_ray(query)
		#print(result)
		
		if result:
			for current_child : Node in result["collider"].get_children():
				if current_child is Interactable3D:
					#print("Child is Interactable3D")
					#print(active_camera.global_position.distance_to(result["collider"].global_position))
					if active_camera.global_position.distance_to(current_child.global_position) <= current_child.max_distance:
						interactable_flag = true
						interactable_flag_direct = true
						#print("Interactable detected" + str(current_child))
						interactable_detected.emit(current_child)
						interactable_detected_direct.emit(current_child)
						active_interactable = current_child
	
	if Input.is_action_just_pressed("Interact") and active_interactable:
		#print(active_interactable)
		active_interactable.interact.emit(player)
							
	if interactable_flag == false:
		no_interactable_detected.emit()
	if interactable_flag_direct == false:
		no_interactable_detected_direct.emit()
			
