extends Node2D

@export var hide_if_one_is_false : Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dialogic.signal_event.connect(handle_dialogic_signal)
	check_conditions()

func handle_dialogic_signal(argument : String):
	print("signal")
	if argument == "variables_changed":
		print("signal ok")
		check_conditions()

func check_conditions():
	var show : bool = true
	
	for condition in hide_if_one_is_false:
		show = show and Dialogic.VAR.get_variable(condition)
	
	visible = show
