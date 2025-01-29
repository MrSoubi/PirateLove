extends Node

@onready var location_container: Node = $LocationContainer
const TRAVEL_EVENT = preload("res://Data/TravelEvent.tres")
@export var initial_scene : LocationDefinition

func _ready() -> void:
	TRAVEL_EVENT.triggered.connect(set_location)
	set_location(initial_scene)

func set_location(destination : LocationDefinition):
	empty_location_container()
	var new_location = destination.scene.instantiate()
	location_container.add_child(new_location)

func empty_location_container():
	for child in location_container.get_children():
		location_container.remove_child(child)
