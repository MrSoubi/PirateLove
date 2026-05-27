extends Node

enum Location {
	KITCHEN,
	INFIRMARY,
	SHIP_HOLD,
	DECK_1,
	DECK_2,
	CAPTAIN_CABIN,
	MAST
}

const LOCATION_DEFINITIONS := {
	Location.KITCHEN: preload("res://LocationDefinitions/Kitchen.tres"),
	Location.INFIRMARY: preload("res://LocationDefinitions/Infirmary.tres"),
	Location.SHIP_HOLD: preload("res://LocationDefinitions/ShipHold.tres"),
	Location.DECK_1: preload("res://LocationDefinitions/Deck_1.tres"),
	Location.DECK_2: preload("res://LocationDefinitions/Deck_2.tres"),
	Location.CAPTAIN_CABIN: preload("res://LocationDefinitions/CaptainCabin.tres"),
	Location.MAST: preload("res://LocationDefinitions/Mast.tres")
}

func get_location_definition(location: Location) -> LocationDefinition:
	return LOCATION_DEFINITIONS[location]
