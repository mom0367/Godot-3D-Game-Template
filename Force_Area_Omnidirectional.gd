extends Area3D

@onready var affected : Array = []
@export var force : float = 1

func _process(_delta : float) -> void:
	
	for currentItem : Node3D in get_overlapping_bodies():
		
		if affected.has(currentItem):
			continue
		
		if currentItem is CharacterBody3D:
			affected.append(currentItem)
			
			var direction : Vector3 = (currentItem.position - self.position).normalized()
			
			#print(direction)
			currentItem.added_velocity += direction * force
			#print(currentItem.added_velocity)
