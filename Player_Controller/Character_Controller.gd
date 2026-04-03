extends CharacterBody3D

@export var added_velocity : Vector3 = Vector3.ZERO

@export var movement_allowed : bool = true
## Determines if the player can control the camera, disable when you want to move the camera manually
@export var camera_control_allowed : bool = true
## Determines if the character will face the direction of movement or face the camera point, first-person will override this
@export var body_faces_movement : bool = true
@export var jump_allowed : bool = true
@export var gravity_affected : bool = true
@export var sprint_allowed : bool = true
@export var crouch_allowed : bool = true
@export var swimming_allowed : bool = true
@export var sinks_in_water : bool = false
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
@onready var swimming : bool = false
@onready var previous_swimming_state : bool = false
@onready var crouching : bool = false

@export_group("Attributes")
@export var base_speed : float = 7.0
@export var sprint_increase : float = 0.25
@export var crouch_speed_decrease : float = 0.15
@export var crouch_animation_time : float = 0.075
@export var water_speed_decrease : float = 0.25
#Speed multiplier used internally for things like sprinting, if you want to give the player boosts use the exported multiplier instead.
@onready var base_speed_multiplier : float = 1.0
#Speed modifier to be used externally, for things such as gear and items
@export var speed_multiplier : float = 1.0
@export var friction : float = 25
@export var acceleration : float = 25
@export var air_acceleration : float = 35
@export var jump_power : float = 4.5
#Amount of times a player can jump
@export var max_jumps : int = 1
@onready var jumps_remaining : int
##Time where the player is still allowed to jump after leaving a platform
@export var coyote_time : float = 0.1
@onready var coyote_time_timer : float

## Soft clamp for velocity, can be exceeded but counterfources will be applied.
@export var max_speed : float = 30
@export var look_sensitivity : float = 0.002
@export var max_vertical_look_angle : float = 85

signal jumped
signal landed

#Used to connect to the input system, uses ui inputs as a fallback
@export_group("Inputs")
@export var mapped_inputs : Dictionary [String, String] = {
	
	"Left": "Move_Left",
	"Right": "Move_Right",
	"Forward": "Move_Forward",
	"Backward": "Move_Backward",
	"Jump": "Jump",
	"Sprint": "Sprint",
	"Noclip": "Noclip",
	"Crouch": "Crouch",
	"Look_Up": "Look_Up",
	"Look_Down": "Look_Down",
	"Look_Left": "Look_Left",
	"Look_Right": "Look_Right",
	"Zoom_Out": "Zoom_Out",
	"Zoom_In": "Zoom_In"
	
}
## Object references
@onready var head : SpringArm3D = $Head
@onready var perspective_handler : Node = $Head/Camera/Perspective_Handler
@onready var collider : CollisionShape3D = $Collider 



## Debounce vars
@onready var stored_sprint_state : bool = false
@onready var stored_crouch_state : bool = false


func _ready() -> void:
	
	jumps_remaining = max_jumps
	coyote_time_timer = coyote_time
	check_mappings()

func _unhandled_input(_event: InputEvent) -> void:
	# Toggle noclip mode
	if noclip_allowed and Input.is_action_just_pressed(mapped_inputs["Noclip"]):
		if not noclipping:
			enable_noclip()
		else:
			disable_noclip()

func _physics_process(delta: float) -> void:
	
	coyote_time_timer -= delta
		
	if is_on_floor():
		jumping = false
		landed.emit()
		jumps_remaining = max_jumps
		coyote_time_timer = coyote_time
		
	# Changes velocity to move the player
	if movement_allowed:
		
		# Apply jump velocity
		if jump_allowed and (is_on_floor() or coyote_time_timer > 0 or jumps_remaining > 0) and not swimming and not floating:
			if (Input.is_action_just_pressed(mapped_inputs["Jump"]) or (Input.is_action_pressed(mapped_inputs["Jump"]) and hold_jump == true)):
				velocity.y += jump_power
				jumps_remaining -= 1
				jumped.emit()
				jumping = true
		elif swimming or floating:
			if Input.is_action_pressed(mapped_inputs["Jump"]):
				if noclipping:
					velocity.y += (jump_power * 0.05)
				else:
					#Float upwards
					velocity.y += (jump_power * 0.015)
					
		
		#Apply gravity to velocity
		if gravity_affected:
			#Breaks some player velocity relatively when hitting water
			if swimming == true and previous_swimming_state == false:
				#print("Water dampening.")
				velocity -= (-(velocity * get_gravity() * (velocity.length() * 0.75)) * delta)
			if swimming and sinks_in_water and not noclipping:
				#print("Sink")
				#print((get_gravity() * 0.1) * delta)
				velocity += (get_gravity() * 0.1) * delta
			elif not is_on_floor() and not floating:
				#print(get_gravity() * delta)
				velocity += get_gravity() * delta
				
		
		var input_direction : Vector2 = Input.get_vector(mapped_inputs["Left"], mapped_inputs["Right"], mapped_inputs["Forward"], mapped_inputs["Backward"])
		
		if is_on_floor():
			if strafing_allowed == false:
				input_direction.x = 0
		else:
			if air_strafing_allowed == false or strafing_allowed == false:
				input_direction.x = 0
		
		
		var current_acceleration : float = acceleration
		var crouch_slow : float = (crouch_speed_decrease * int(crouching))
		var water_slow : float = (water_speed_decrease * int(swimming))
		var base_slow : float = crouch_slow + water_slow

		# Changes acceleration and crouch slow based on being in the air and crouch state
		if not is_on_floor() and not swimming:
			current_acceleration = air_acceleration
			crouch_slow = 0
		elif noclipping:
			current_acceleration = 1000
			crouch_slow = 0
			friction = 5000

		
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

		#print(movement_vector)
		if movement_vector and (floating or swimming):
			movement_vector = (head.global_basis * Vector3(input_direction.x, 0, input_direction.y))
			#Workaround for moving cancelling y velocity, there is probably a better way to do this.
			var stored_vel_y : float = velocity.y
			velocity = velocity.move_toward(movement_vector * base_speed * (base_speed_multiplier - base_slow) * speed_multiplier, current_acceleration * friction * delta)
			velocity.y = stored_vel_y
		elif movement_vector:
			velocity.x = move_toward(velocity.x, movement_vector.x * base_speed * (base_speed_multiplier - base_slow) * speed_multiplier, current_acceleration * friction * delta)
			velocity.z = move_toward(velocity.z, movement_vector.z * base_speed * (base_speed_multiplier - base_slow) * speed_multiplier, current_acceleration * friction * delta)
		elif is_on_floor() or midair_deceleration == true:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)
		
		#Vertical friction to prevent sliding in noclip
		#velocity.y = move_toward(velocity.y, 0, (friction * 0.01) * delta)
		
		##Hard speed capping
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
		velocity.z = clamp(velocity.z, -max_speed, max_speed)
		velocity.y = clamp(velocity.y, -max_speed, max_speed)
		##Soft speed capping
		if velocity.x > max_speed:
			velocity.x -= (friction * delta)
		if velocity.y > max_speed:
			velocity.y -= (friction * delta)
		elif noclipping:
			velocity.y = move_toward(velocity.y, 0, 11 * delta)
		if velocity.z > max_speed:
			velocity.z -= (friction * delta)
		#print(velocity.length())
				
	else:
		velocity.x = 0
		velocity.y = 0

	velocity += added_velocity
	#print(velocity)
	added_velocity = Vector3.ZERO
	move_and_slide()
	
	#Sets previous state variables
	#print("Setting previous variable states")
	previous_swimming_state = swimming

func enable_noclip() -> void:
	if noclip_allowed:
		noclipping = true
		collider.disabled = true
		floating = true
		velocity = Vector3.ZERO

func disable_noclip() -> void:
	if noclip_allowed:
		noclipping = false
		collider.disabled = false
		floating = false

## Chunks for unassigned input actions

func check_mappings() -> void:
	
	if movement_allowed:
		for current_mapping in mapped_inputs:
			if not InputMap.has_action(mapped_inputs[current_mapping]):
				push_warning("No " + str(mapped_inputs[current_mapping]) + " InputAction found, disabling controls")
				movement_allowed = false
