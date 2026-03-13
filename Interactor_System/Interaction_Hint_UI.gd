extends CanvasItem


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InteractionHandler.interactable_detected_direct.connect(func() -> void: self.visible = true)
	InteractionHandler.no_interactable_detected_direct.connect(func() -> void: self.visible = false)
