extends RefCounted

signal action_requested(action: Dictionary)

var progression_steps: Array[Dictionary]
var progression_state: Dictionary = {}

func _init(steps: Array[Dictionary] = []) -> void:
	progression_steps = steps

func refresh() -> void:
	progression_state.clear()
	for step in progression_steps:
		var variable_name: String = step.get("variable_name", "")
		progression_state[variable_name] = Dialogic.VAR.get_variable(variable_name)

func get_startup_action() -> Dictionary:
	for step in progression_steps:
		var variable_name: String = step.get("variable_name", "")
		if not progression_state.get(variable_name, false):
			return step.get("on_incomplete", {}).duplicate(true)

	return {"type": "endgame"}

func handle_dialogic_signal(_argument : String) -> void:
	for step in progression_steps:
		var variable_name: String = step.get("variable_name", "")
		var current_value: bool = Dialogic.VAR.get_variable(variable_name)
		var previous_value: bool = progression_state.get(variable_name, false)

		if current_value != previous_value:
			progression_state[variable_name] = current_value
			if current_value:
				action_requested.emit(step.get("on_complete", {}).duplicate(true))
