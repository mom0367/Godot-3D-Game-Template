extends Node


@export var player_main : PhysicsBody3D
@export var player_mesh : GeometryInstance3D
@export var camera_dolly : float = 0
@export var max_dolly : float = 5
@export var dolly_change_sensitivity : float = 50
@export var hide_model_in_first_person : bool = true
@export var head : Node3D

@onready var camera_spring : SpringArm3D = self.get_parent().get_parent()
@onready var camera : Camera3D = self.get_parent() 

#The amount of zoom when zooming in that will snap the player into first person, to avoid clipping
@onready var first_person_threshold : float = 1
@onready var default_camera_position : Vector3 = self.get_parent().position

@onready var look_rotation : Vector2 
@onready var head_offset : Vector3 = head.position

@onready var mapped_inputs : Dictionary = player_main.mapped_inputs

func _ready() -> void:

	camera_spring.add_excluded_object(player_main)
	
	look_rotation.y = player_main.rotation.y
	look_rotation.x = head.rotation.x

func _input(event: InputEvent) -> void:
	
	if Input.is_key_pressed(KEY_ESCAPE):
		#print("Unlocking mouse")
		player_main.mouse_lock = false
	elif player_main.mouse_lock == false and event is InputEventMouseButton:
		#print("Locking mouse")
		player_main.mouse_lock = true
		
	if player_main.mouse_lock and event is InputEventMouseMotion: # event is InputEventMouseMotion:
		rotate_look(event.relative, player_main.look_sensitivity, 0.01)

func _process(delta: float) -> void:

	head.position = (player_main.position + head_offset)
	
	
	#region Camera in and out
	var current_dolly_sensitvity : float = dolly_change_sensitivity 
	
	if Input.is_action_pressed("zoom_in") or Input.is_action_pressed("zoom_out"): #Lowers dolly sensitivity when a button is pressed, compared to a scroll
		current_dolly_sensitvity *= .1
	
	if not player_main.camera_control_allowed:
		return
	
	var camera_dolly_change : float = 0
	if Input.is_action_just_released("zoom_in") or Input.is_action_pressed("zoom_in"):
		#print("Move camera in")
		camera_dolly_change += (-current_dolly_sensitvity * delta)
			
	if Input.is_action_just_released("zoom_out") or Input.is_action_pressed("zoom_out"):
		#print("Move camera out")
		var additional : float = 0
		if camera_dolly < first_person_threshold:
			additional = first_person_threshold
		#print(additional * current_dolly_sensitvity)
		camera_dolly_change += ((current_dolly_sensitvity + (additional * current_dolly_sensitvity * 3)) * delta)
		
	if camera_dolly <= first_person_threshold or (camera_dolly + camera_dolly_change) <= first_person_threshold:
			#print("Snapping first person")
			camera_dolly = default_camera_position.z
		

	if is_multiplayer_authority() and hide_model_in_first_person and camera_dolly <= first_person_threshold: #Makes the local player main body invisible on the client, to avoid camera clipping
		player_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	else:
		player_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		
	camera_dolly += camera_dolly_change
	camera_dolly = clampf(camera_dolly, default_camera_position.z, max_dolly)
	camera_spring.spring_length = camera_dolly 
	#print(camera_dolly_change)
	#print(camera_dolly)
	#endregion
	
	#region Mouse look and window focus


		
	if player_main.mouse_lock == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Look around

		
	if Input.is_action_pressed(mapped_inputs["look_left"]) or Input.is_action_pressed(mapped_inputs["look_right"]) or Input.is_action_pressed(mapped_inputs["look_up"]) or Input.is_action_pressed(mapped_inputs["look_down"]):
		var look_vector : Vector2 = Input.get_vector(mapped_inputs["look_left"], mapped_inputs["look_right"], mapped_inputs["look_up"], mapped_inputs["look_down"])
		rotate_look(look_vector, player_main.look_sensitivity * 35, delta)
			
			
			
## Rotates the character to change look direction
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2, sensitivity : float, delta : float) -> void:

	#if smoothed == false:
	if player_main.invert_mouse:
		look_rotation.x -= rot_input.y * -1 * (sensitivity * .1) * delta
	else:
		look_rotation.x -= rot_input.y * (sensitivity * .1) * delta
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-player_main.max_vertical_look_angle), deg_to_rad(player_main.max_vertical_look_angle))
	look_rotation.y -= rot_input.x * (sensitivity * .1) * delta
	
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)
	#print(head.rotation)
	
	if camera_dolly < first_person_threshold:
		#print("First person")
		player_main.transform.basis = Basis()
		player_main.rotate_y(look_rotation.y)
		head.rotate_y(look_rotation.y)
	elif player_main.body_faces_movement == true:
		head.rotate_y(look_rotation.y)
	elif player_main.body_faces_movement == false:
		player_main.transform.basis = Basis()
		head.rotate_y(look_rotation.y)
		player_main.rotate_y(look_rotation.y)
		
