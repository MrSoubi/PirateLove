extends Node2D

@export var bool_conditions : Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.signal_event.connect(handle_dialogic_signal)
	check_conditions()

func handle_dialogic_signal(argument : String):
	if argument == "variables_changed":
		check_conditions()

func check_conditions():
	var result : bool = true
	for condition in bool_conditions:
		result = result and Dialogic.VAR.get(condition)
	
	visible = result
