#Do note that this node uses the position of the camera and not the player, this can cause unintended results of the camera is allowed to detatch from the player
##NOTE This is an extremely basic implementation, it may be unoptimized or lack common features.

extends Node

class_name Interactor3D

signal Interacted

##Determines if the parent object can be clicked on pressed on directly
@export var can_click : bool = true;

@onready var main_entity : Node3D = self.get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta):
	#pass
	
	
@export var Max_Distance : float = 25
@export var Enabled : bool = true

func _ready() -> void:
	if not InputMap.has_action("Interact"):
		Enabled = false
		push_warning("No interact input found")
	
func _input(event : InputEvent) -> void:
	var space_state : PhysicsDirectSpaceState3D = main_entity.get_world_3d().direct_space_state
	
	if Input.is_action_pressed("Interact") :
		
		var active_camera : Camera3D = get_viewport().get_camera_3d()
		var origin : Vector3 = active_camera.project_ray_origin(event.position)
		var target : Vector3 = origin + active_camera.project_ray_normal(event.position) * Max_Distance
		#print(to)
		
		var query := PhysicsRayQueryParameters3D.create(origin, target)
		query.collide_with_areas = true
		
		var result := space_state.intersect_ray(query)
		
		
		if result:
			#print(result)
			if result["collider"] == main_entity:
				
				Interacted.emit()
