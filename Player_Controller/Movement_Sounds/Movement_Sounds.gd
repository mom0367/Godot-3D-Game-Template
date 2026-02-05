#BUG Footsteps don't play sometimes, but I have no way to consistently replicate it.

@icon("uid://bnata7fjyrdg7")
class_name Movement_Sounds_3D

extends AudioStreamPlayer3D

signal play_sound

@export var raycast_length : float = 10
@export var time_interval : float = .45
## Determines if sounds are played on a timer (Mainly to simulate the pace of a character walking)
@export var timed_sounds : bool = true
@export var sound_set : MaterialList
##The amount which the parents speed affects the sound interval
@export var speed_time_influence : float = .1
@export var speed_volume_influence : float = 1


@onready var countdown : float = time_interval
@onready var randomizer : AudioStreamRandomizer = AudioStreamRandomizer.new()

@onready var current_material_group : String = "" 
@onready var previous_material_group : String = "" #Stores the previous sound effect so we can avoid unloading and reloading repeat sounds
@onready var starting_db : float = volume_db 


func load_sound_array(desired_group : String) -> void:

	for loop_index in (randomizer.streams_count):

		randomizer.remove_stream(0) #Clears all the streams, actually incrementing with the index doesn't work as it re-sorts on removal.
			
	if sound_set.material_dictionary.has(desired_group):
		for current_object : AudioStream in sound_set.material_dictionary[desired_group]:
			#print(current_object)
			randomizer.add_stream(0, current_object, 1.0)
	else:
		push_warning("No soundset for materialgroup " + desired_group + " doing fallback sound.")
		for current_object : AudioStream in sound_set.material_dictionary[sound_set.fallback_soundgroup]:
			#print(current_object)
			randomizer.add_stream(0, current_object, 1.0)
	
		
	previous_material_group = desired_group

# Called when the node enters the scene tree for the first time.
func sound_effect() -> void:
	
	var space_state : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(self.global_position, (self.global_position  + Vector3(0, -raycast_length, 0)))
	
	var result : Dictionary = space_state.intersect_ray(query)
	
	if result:

		if result.collider is GeometryInstance3D:

			if result.collider.material:
				
				if result.collider.material.has_meta("Material_Group"):
					current_material_group = result.collider.material.get_meta("Material_Group")
			elif result.collider.material_override:

				if result.collider.material_override.has_meta("Material_Group"):
					current_material_group = result.collider.material_override.get_meta("Material_Group")
				
			else:
				
				current_material_group = sound_set.fallback_soundgroup
			

				
			if current_material_group != previous_material_group:
				
				if current_material_group == null:
					load_sound_array(sound_set.fallback_soundgroup)
				else:
					load_sound_array(current_material_group)
		
		
		play()
		
	else:
		#print("No result")
		if timed_sounds:
			countdown = 0
		


func _ready() -> void:
	
	stream = randomizer
	
	if not self.get_parent() is PhysicsBody3D:
		push_warning("Object " + str(self.get_parent) + " does not have a parent that inherits from PhysicsBody3D, meaning it has no velocity to base off of.")
	
	play_sound.connect(sound_effect)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta_time: float) -> void:
	
	countdown -= delta_time
	#print("Velocity: " + str(self.get_parent().velocity.length()))
	volume_db = ((starting_db + (self.get_parent().velocity.length())) * (3.25 * speed_volume_influence))
	#print("Volume: " + str(volume_db))
	
	#print("Current set:")
	#for loop_index in (randomizer.streams_count):
		#
		#print(randomizer.get_stream(loop_index))
	if timed_sounds:
		
		if (countdown <= 0) and (self.get_parent().velocity.length() > 0.5):
			#print(self.get_parent().velocity.length())
		
			countdown = (time_interval / (self.get_parent().velocity.length() * speed_time_influence))
			
			play_sound.emit()
		
	

	
	
	
	#var result = space_state.intersect_ray(query)
	#print(result)
	
