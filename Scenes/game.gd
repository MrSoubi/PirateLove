extends Node

@onready var transition_layer: Fader = $TransitionLayer
@onready var main_menu: CanvasLayer = $MainMenu
@onready var location_container: Node2D = $LocationContainer

# timelines narration
@export var prologue_timeline : String
@export var chapitre1_timeline : String
@export var chapitre2_timeline : String
@export var test_du_second_timeline : String
@export var fin_smash_capitaine_timeline : String
@export var fin_smash_second_timeline : String
@export var fin_mousse_timeline : String
@export var fin_depart_timeline : String

@export var prologue_var : String
@export var rat_et_fromage_var : String
@export var chapitre1_var : String
@export var louche_de_murlock_var : String
@export var chapitre2_var : String
@export var reparer_bateau_var : String
@export var test_du_second_var : String

const TRAVEL_EVENT = preload("res://Data/TravelEvent.tres")
const ProgressionManager = preload("res://Scripts/progression_manager.gd")
const EndgameResolver = preload("res://Scripts/endgame_resolver.gd")
const LocationManager = preload("res://Scripts/location_manager.gd")

var progression_manager
var endgame_resolver
var location_manager

func _ready() -> void:
	location_manager = LocationManager.new(location_container)
	progression_manager = ProgressionManager.new(_build_progression_steps())
	endgame_resolver = EndgameResolver.new(_build_endgame_rules())
	TRAVEL_EVENT.triggered.connect(_on_location_requested)
	Dialogic.signal_event.connect(progression_manager.handle_dialogic_signal)
	progression_manager.action_requested.connect(_execute_action)

func _build_progression_steps() -> Array[Dictionary]:
	return [
		{
			"variable_name": prologue_var,
			"on_complete": {"type": "location", "value": GlobalScope.Location.INFIRMARY},
			"on_incomplete": {"type": "cutscene", "value": prologue_timeline}
		},
		{
			"variable_name": rat_et_fromage_var,
			"on_complete": {"type": "cutscene", "value": chapitre1_timeline},
			"on_incomplete": {"type": "location", "value": GlobalScope.Location.INFIRMARY}
		},
		{
			"variable_name": chapitre1_var,
			"on_complete": {"type": "location", "value": GlobalScope.Location.SHIP_HOLD},
			"on_incomplete": {"type": "cutscene", "value": chapitre1_timeline}
		},
		{
			"variable_name": louche_de_murlock_var,
			"on_complete": {"type": "cutscene", "value": chapitre2_timeline},
			"on_incomplete": {"type": "location", "value": GlobalScope.Location.SHIP_HOLD}
		},
		{
			"variable_name": chapitre2_var,
			"on_complete": {"type": "location", "value": GlobalScope.Location.DECK_1},
			"on_incomplete": {"type": "cutscene", "value": chapitre2_timeline}
		},
		{
			"variable_name": reparer_bateau_var,
			"on_complete": {"type": "cutscene", "value": test_du_second_timeline},
			"on_incomplete": {"type": "location", "value": GlobalScope.Location.DECK_2}
		},
		{
			"variable_name": test_du_second_var,
			"on_complete": {"type": "endgame"},
			"on_incomplete": {"type": "cutscene", "value": test_du_second_timeline}
		}
	]

# Endgame rules for PirateLove — evaluated in order, first match wins.
# Each rule lists the Dialogic variable conditions that must ALL be true, plus
# the key into the ending_timelines dictionary to return on a match.
# An empty "conditions" array acts as a fallback and always matches.
func _build_endgame_rules() -> Array[Dictionary]:
	return [
		{
			"conditions": [
				{"var": "test_reussi", "value": true},
				{"var": "secret_decouvert", "value": true}
			],
			"timeline_key": "smash_second"
		},
		{
			"conditions": [
				{"var": "test_reussi", "value": true}
			],
			"timeline_key": "smash_capitaine"
		},
		{
			"conditions": [
				{"var": "secret_decouvert", "value": true}
			],
			"timeline_key": "fin_depart"
		},
		{
			"conditions": [],
			"timeline_key": "devenir_mousse"
		}
	]

func _on_location_requested(destination : GlobalScope.Location) -> void:
	location_manager.set_location(destination)

func _execute_action(action: Dictionary) -> void:
	match action.get("type", ""):
		"location":
			_on_location_requested(action.get("value"))
		"cutscene":
			start_cutscene(action.get("value", ""))
		"endgame":
			handle_endgame()

func start_game():
	progression_manager.refresh()
	main_menu.visible = false
	_execute_action(progression_manager.get_startup_action())

func _on_button_continuer_pressed() -> void:
	transition_layer.transition()
	await transition_layer.on_transition_finished
	Dialogic.Save.load()
	start_game()

func _on_button_nouvelle_partie_pressed() -> void:
	transition_layer.transition()
	await transition_layer.on_transition_finished
	start_game()

func handle_endgame():
	var ending_timelines := {
		"smash_capitaine": fin_smash_capitaine_timeline,
		"smash_second": fin_smash_second_timeline,
		"devenir_mousse": fin_mousse_timeline,
		"fin_depart": fin_depart_timeline
	}
	var timeline := endgame_resolver.resolve(ending_timelines)
	if timeline != "":
		start_cutscene(timeline)

func start_cutscene(timeline : String):
	transition_layer.transition()
	Dialogic.start(timeline)
