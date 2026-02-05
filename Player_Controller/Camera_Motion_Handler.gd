extends Node
@onready var camera_offset : Vector3 = Vector3.ZERO
@onready var camera : Camera3D = self.get_parent()
@export var physics_body : PhysicsBody3D

@export var bobbing_enabled : bool = true
@export var horizontal_intensity : float = .20
@export var vertical_intensity : float = .35
@export var rotational_intensity : float = .05
@export var bob_speed : float = 45

@onready var headbob_time : float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:


	if bobbing_enabled == false:
		return
	#TODO add something to set offsets outside of bobbing (For example camera lean when leaning/wallrunning), and have it run before the enabled check
	var length : float = physics_body.velocity.length()
	headbob_time += (delta * length / 25) 
	#print(sin(headbob_time * bob_speed))
	camera_offset.x = (sin(headbob_time * bob_speed) * length * vertical_intensity / 200)
	camera_offset.y = (cos(headbob_time * bob_speed/2) * length * horizontal_intensity / 200)
	camera_offset.z = (cos(headbob_time * bob_speed) * length * rotational_intensity / 200)
	
	camera.rotation = Vector3(camera_offset.x, camera_offset.y, camera_offset.z)
	
