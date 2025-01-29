extends Area2D

@export var destination : GlobalScope.Location
const TRAVEL_EVENT = preload("res://Data/TravelEvent.tres")

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			TRAVEL_EVENT.triggered.emit(destination)

func _on_mouse_entered() -> void:
	CursorManager.set_cursor(CursorManager.Type.DOOR)

func _on_mouse_exited() -> void:
	CursorManager.set_cursor(CursorManager.Type.NONE)
