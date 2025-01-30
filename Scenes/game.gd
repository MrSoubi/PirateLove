extends Node

@onready var transition_layer: Fader = $TransitionLayer

# timelines narration
@export var prologue_timeline : String
@export var chapitre1_timeline : String
@export var chapitre2_timeline : String
@export var test_du_second_timeline : String
@export var fin_smash_capitaine_timeline : String
@export var fin_smash_second_timeline : String
@export var fin_mousse_timeline : String
@export var fin_depart_timeline : String

var prologue_termine : bool
var rat_et_fromage_termine : bool
var chapitre1_termine : bool
var louche_de_murlock_termine : bool
var chapitre2_termine : bool
var reparer_bateau_termine : bool
var test_du_second_termine : bool

@export var prologue_var : String
@export var rat_et_fromage_var : String
@export var chapitre1_var : String
@export var louche_de_murlock_var : String
@export var chapitre2_var : String
@export var reparer_bateau_var : String
@export var test_du_second_var : String

@onready var main_menu: CanvasLayer = $MainMenu
@onready var location_container: Node2D = $LocationContainer

@export var initial_scene : GlobalScope.Location

const TRAVEL_EVENT = preload("res://Data/TravelEvent.tres")

# locations
const KITCHEN = preload("res://LocationDefinitions/Kitchen.tres")
const CAPTAIN_CABIN = preload("res://LocationDefinitions/CaptainCabin.tres")
const DECK_1 = preload("res://LocationDefinitions/Deck_1.tres")
const DECK_2 = preload("res://LocationDefinitions/Deck_2.tres")
const INFIRMARY = preload("res://LocationDefinitions/Infirmary.tres")
const MAST = preload("res://LocationDefinitions/Mast.tres")
const SHIP_HOLD = preload("res://LocationDefinitions/ShipHold.tres")

func _ready() -> void:
	TRAVEL_EVENT.triggered.connect(set_location)
	Dialogic.signal_event.connect(handle_dialogic_signal)

func handle_dialogic_signal(argument : String):
	print("signal recu")
	# on vient de finir le prologue
	if prologue_termine != Dialogic.VAR.get_variable(prologue_var):
		prologue_termine = true
		set_location(GlobalScope.Location.INFIRMARY)
		Dialogic.VAR.set_variable("Chapitre_1.RatEtFromage.quete_en_cours", true)

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
	set_local_booleans()
	main_menu.visible = false
	
	if not prologue_termine:
		print("lancement du prologue")
		start_cutscene(prologue_timeline)
	elif not rat_et_fromage_termine:
		set_location(GlobalScope.Location.INFIRMARY)
	elif not chapitre1_termine:
		start_cutscene(chapitre1_timeline)
	elif not louche_de_murlock_termine:
		set_location(GlobalScope.Location.SHIP_HOLD)
	elif not chapitre2_termine:
		start_cutscene(chapitre2_timeline)
	elif not reparer_bateau_termine:
		set_location(GlobalScope.Location.DECK_2)
	elif not test_du_second_termine:
		start_cutscene(test_du_second_timeline)
	else:
		handle_endgame()

func _on_button_continuer_pressed() -> void:
	transition_layer.transition()
	await transition_layer.on_transition_finished
	Dialogic.Save.load()
	start_game()

func _on_button_nouvelle_partie_pressed() -> void:
	transition_layer.transition()
	await transition_layer.on_transition_finished
	start_game()

func set_local_booleans():
	prologue_termine = Dialogic.VAR.get_variable(prologue_var)
	rat_et_fromage_termine = Dialogic.VAR.get_variable(rat_et_fromage_var)
	chapitre1_termine = Dialogic.VAR.get_variable(chapitre1_var)
	louche_de_murlock_termine = Dialogic.VAR.get_variable(louche_de_murlock_var)
	chapitre2_termine = Dialogic.VAR.get_variable(chapitre2_var)
	reparer_bateau_termine = Dialogic.VAR.get_variable(reparer_bateau_var)
	test_du_second_termine = Dialogic.VAR.get_variable(test_du_second_var)

func handle_endgame():
	var smash_la_capitaine : bool
	var smash_le_second : bool
	var deviens_un_pirate : bool
	var le_celibat_c_cool : bool
	
	smash_la_capitaine = Dialogic.VAR.get_variable("test_reussi") and not Dialogic.VAR.get_variable("secret_decouvert")
	smash_le_second = Dialogic.VAR.get_variable("test_reussi") and Dialogic.VAR.get_variable("secret_decouvert")
	deviens_un_pirate = not Dialogic.VAR.get_variable("test_reussi") and not Dialogic.VAR.get_variable("secret_decouvert")
	le_celibat_c_cool = not Dialogic.VAR.get_variable("test_reussi") and Dialogic.VAR.get_variable("secret_decouvert")
	
	if smash_la_capitaine:
		start_cutscene(fin_smash_capitaine_timeline)
	elif smash_le_second:
		start_cutscene(fin_smash_second_timeline)
	elif deviens_un_pirate:
		start_cutscene(fin_mousse_timeline)
	elif le_celibat_c_cool:
		start_cutscene(fin_depart_timeline)

func start_cutscene(timeline : String):
	prints("lancement cutscene", timeline)
	transition_layer.transition()
	await transition_layer.on_transition_finished
	Dialogic.start_timeline(timeline)
