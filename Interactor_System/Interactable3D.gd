#Do note that this node uses the position of the camera and not the player, this can cause unintended results of the camera is allowed to detatch from the player
##NOTE This is an extremely basic implementation, it may be unoptimized or lack common features.

extends VisibleOnScreenNotifier3D

class_name Interactable3D

##Emitted when an interaction goes through successfully
signal interacted
##Called to attempt an interaction
signal interact(player : Node3D)

##Determines if the parent object can be clicked on pressed on directly
@export var can_click : bool = true;

@onready var main_entity : Node3D = self.get_parent()
	
@export var max_distance : float = 25
@export var enabled : bool = true

func _ready() -> void:
	add_to_group("Interactors")
	if not InputMap.has_action("Interact"):
		enabled = false
		push_warning("No interact input found")
		
	interact.connect(_on_Interact)
	
@rpc("any_peer", "call_local", "reliable")
func _on_Interact(player : Node3D) -> void:
	if self.global_position.distance_to(player.global_position) <= max_distance:
		interacted.emit()
