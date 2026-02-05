extends CharacterBody3D

@export var added_velocity : Vector3 = Vector3.ZERO

@export var movement_allowed : bool = true
## Determines if the player can control the camera, disable when you want to move the camera manually
@export var camera_control_allowed : bool = true
## Determines if the character will face the direction of movement or face the camera point, first-person will override this
@export var body_faces_movement : bool = false
@export var jump_allowed : bool = true
@export var gravity_affected : bool = true
@export var sprint_allowed : bool = true
@export var crouch_allowed : bool = true
##Determines if the player can enter noclip mode
@export var noclip_allowed : bool = true
##Determines if a player can stop their momentum by letting go of movement while midair 
@export var midair_deceleration : bool = true
##If the player can strafe
@export var strafing_allowed : bool = true
##If the player can strafe midair, strafing_allowed being disabled will override this
@export var air_strafing_allowed : bool = true
#If the player will automatically jump upon touching the floor while the jump input is held down
@export var hold_jump : bool = false
@export var toggle_sprint : bool = false
@export var toggle_crouch : bool = false
@export var invert_mouse : bool = false
@export var mouse_lock : bool = true


@onready var moving : bool = false
@onready var jumping : bool = false
@onready var sprinting : bool = false
@onready var noclipping : bool = false
@onready var floating : bool = false
@onready var crouching : bool = false

@export_group("Attributes")
@export var jump_power : float = 4.5
@export var base_speed : float = 7.0
@export var sprint_increase : float = 0.25
@export var crouch_decrease : float = 0.15
@export var crouch_animation_time : float = 0.075
@export var noclip_speed : float = 25.0
#Speed multiplier used internally for things like sprinting, if you want to give the player boosts use the exported multiplier instead.
@onready var base_speed_multiplier : float = 1.0
#Speed modifier to be used externally, for things such as gear and items
@export var speed_multiplier : float = 1.0
@export var friction : float = 25
@export var acceleration : float = 25
@export var air_acceleration : float = 35

## The clamp for the most speed a player can achieve, too low of values may cause players to move faster diagonally for some reason.
@export var max_speed : float = 30
@export var look_sensitivity : float = 0.002
@export var max_vertical_look_angle : float = 85

signal jumped
signal landed

#Used to connect to the input system, uses ui inputs as a fallback
@export_group("Inputs")
@export var mapped_inputs : Dictionary [String, String] = {
	
	"left": "ui_left",
	"right": "ui_right",
	"forward": "ui_up",
	"backward": "ui_down",
	"jump": "ui_accept",
	"sprint": "sprint",
	"noclip": "noclip",
	"crouch": "crouch",
	"look_up": "ui_up",
	"look_down": "ui_down",
	"look_left": "ui_left",
	"look_right": "ui_right",
	"zoom_out": "zoom_out",
	"zoom_in": "zoom_in"
	
}



## Object references
@export_group("Instances")
@export var head: Node3D
@export var perspective_handler : Node
@export var collider: CollisionShape3D



## Debounce vars
@onready var stored_sprint_state : bool = false
@onready var stored_crouch_state : bool = false


func _ready() -> void:

	check_mappings()

func _unhandled_input(_event: InputEvent) -> void:
	# Toggle noclip mode
	if noclip_allowed and Input.is_action_just_pressed(mapped_inputs["noclip"]):
		if not noclipping:
			enable_noclip()
		else:
			disable_noclip()

func _physics_process(delta: float) -> void:

	
	# If noclipping, handle noclip and nothing else
	if floating: #TODO rewrite float
		var dir := Input.get_vector(mapped_inputs["left"], mapped_inputs["right"], mapped_inputs["forward"], mapped_inputs["backward"])
		var motion := (head.global_basis * Vector3(dir.x, 0, dir.y)).normalized()
		motion *= noclip_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if gravity_affected:
		if not is_on_floor():
			velocity += get_gravity() * delta
			
	if is_on_floor():
		jumping = false
		landed.emit()

	# Apply jump velocity
	if jump_allowed:
		if is_on_floor():
			if Input.is_action_just_pressed(mapped_inputs["jump"]):
				velocity.y = jump_power
				jumped.emit()
				jumping = true
			elif Input.is_action_pressed(mapped_inputs["jump"]) and hold_jump == true:
				velocity.y = jump_power
				jumped.emit()
				jumping = true

	# Changes velocity to move the player
	if movement_allowed:

		var input_direction : Vector2 = Input.get_vector(mapped_inputs["left"], mapped_inputs["right"], mapped_inputs["forward"], mapped_inputs["backward"])
		
		if is_on_floor():
			if strafing_allowed == false:
				input_direction.x = 0
		else:
			if air_strafing_allowed == false or strafing_allowed == false:
				input_direction.x = 0
		
		var movement_vector : Vector3
		if perspective_handler.camera_dolly > perspective_handler.first_person_threshold and body_faces_movement == true:
			if input_direction != Vector2.ZERO:
				var new_basis : Basis = head.global_transform.basis
				new_basis.z.y = 0
				new_basis.z = new_basis.z.normalized()
				new_basis.x.y = 0
				new_basis.x = new_basis.x.normalized() #Scrubs some axis off the basis that cause the player to move slower when the camera looks down
				movement_vector = (new_basis * Vector3(input_direction.x, 0, input_direction.y))
				var target_rotation : float = Vector3.FORWARD.signed_angle_to(movement_vector, up_direction)
				rotation.y = lerp_angle(rotation.y, target_rotation, 15 * delta)
		else:
			movement_vector = (transform.basis * Vector3(input_direction.x, 0, input_direction.y))
		
		# Changes acceleration and crouch slow based on being in the air and crouch state
		var current_acceleration : float = acceleration
		var crouch_slow : float = (crouch_decrease * int(crouching))
		if not is_on_floor():
			current_acceleration = air_acceleration
			crouch_slow = 0

		#print(movement_vector)
		if movement_vector:
			velocity.x = move_toward(velocity.x, movement_vector.x * base_speed * (base_speed_multiplier - crouch_slow) * speed_multiplier, current_acceleration * friction * delta)
			velocity.z = move_toward(velocity.z, movement_vector.z * base_speed * (base_speed_multiplier - crouch_slow) * speed_multiplier, current_acceleration * friction * delta)
		elif is_on_floor() or midair_deceleration == true:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)
			
		velocity.x = clamp(velocity.x, -max_speed, max_speed) #(current_friction * delta)
		velocity.z = clamp(velocity.z, -max_speed, max_speed)
		#print(velocity.length())
				
	else:
		velocity.x = 0
		velocity.y = 0

	velocity += added_velocity
	#print(velocity)
	added_velocity = Vector3.ZERO
	move_and_slide()

func enable_noclip() -> void:
	if noclip_allowed:
		collider.disabled = true
		floating = true
		velocity = Vector3.ZERO

func disable_noclip() -> void:
	if noclip_allowed:
		collider.disabled = false
		floating = false

## Chunks for unassigned input actions

func check_mappings() -> void:
	
	if movement_allowed:
		for current_mapping in mapped_inputs:
			if not InputMap.has_action(mapped_inputs[current_mapping]):
				push_warning("No " + str(mapped_inputs[current_mapping]) + " InputAction found, disabling controls")
				movement_allowed = false
