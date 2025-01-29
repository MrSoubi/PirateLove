extends Area2D

@export var destination : LocationDefinition
const TRAVEL_EVENT = preload("res://Data/TravelEvent.tres")

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			TRAVEL_EVENT.triggered.emit(destination)
