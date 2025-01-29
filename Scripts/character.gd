extends Area2D

@export var timeline : String

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			Dialogic.start(timeline)


func _on_mouse_entered() -> void:
	CursorManager.set_cursor(CursorManager.Type.CHARACTER)


func _on_mouse_exited() -> void:
	CursorManager.set_cursor(CursorManager.Type.NONE)
