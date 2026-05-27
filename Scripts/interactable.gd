extends Area2D

@export var timeline : String
@export var cursor_type : CursorManager.Type = CursorManager.Type.ITEM

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		Dialogic.start(timeline)

func _on_mouse_entered() -> void:
	CursorManager.set_cursor(cursor_type)

func _on_mouse_exited() -> void:
	CursorManager.set_cursor(CursorManager.Type.NONE)
