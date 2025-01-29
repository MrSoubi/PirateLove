extends Node

@onready var location_container: Node = $LocationContainer
const TRAVEL_EVENT = preload("res://Data/TravelEvent.tres")
@export var initial_scene : GlobalScope.Location
@onready var main_menu: CanvasLayer = $MainMenu

const KITCHEN = preload("res://LocationDefinitions/Kitchen.tres")
const CAPTAIN_CABIN = preload("res://LocationDefinitions/CaptainCabin.tres")
const DECK_1 = preload("res://LocationDefinitions/Deck_1.tres")
const DECK_2 = preload("res://LocationDefinitions/Deck_2.tres")
const INFIRMARY = preload("res://LocationDefinitions/Infirmary.tres")
const MAST = preload("res://LocationDefinitions/Mast.tres")
const SHIP_HOLD = preload("res://LocationDefinitions/ShipHold.tres")

func _ready() -> void:
	TRAVEL_EVENT.triggered.connect(set_location)

func set_location(destination : GlobalScope.Location):
	var destination_definition
	match destination:
		GlobalScope.Location.KITCHEN : 
			destination_definition = KITCHEN
		GlobalScope.Location.CAPTAIN_CABIN : 
			destination_definition = CAPTAIN_CABIN
		GlobalScope.Location.DECK_1 : 
			destination_definition = DECK_1
		GlobalScope.Location.DECK_2 : 
			destination_definition = DECK_2
		GlobalScope.Location.INFIRMARY : 
			destination_definition = INFIRMARY
		GlobalScope.Location.MAST : 
			destination_definition = MAST
		GlobalScope.Location.SHIP_HOLD :
			destination_definition = SHIP_HOLD
	
	empty_location_container()
	var new_location = destination_definition.scene.instantiate()
	location_container.add_child(new_location)

func empty_location_container():
	for child in location_container.get_children():
		location_container.remove_child(child)

func start_game():
	set_location(initial_scene)

func _on_button_continuer_pressed() -> void:
	Dialogic.Save.load()
	main_menu.visible = false
	set_location(initial_scene)

func _on_button_nouvelle_partie_pressed() -> void:
	main_menu.visible = false
	set_location(initial_scene)
