extends Node2D

@export var conditions : Array[String]
@export var invert : bool = false

func _ready() -> void:
	Dialogic.signal_event.connect(handle_dialogic_signal)
	check_conditions()

func handle_dialogic_signal(argument : String) -> void:
	if argument == "variables_changed":
		check_conditions()

func check_conditions() -> void:
	var show := true

	for condition in conditions:
		var condition_value: bool = Dialogic.VAR.get_variable(condition)
		if invert:
			show = show and not condition_value
		else:
			show = show and condition_value

	visible = show
