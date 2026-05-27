extends GameConfig
class_name PirateLoveGameConfig

func get_progression_steps() -> Array[Dictionary]:
	return [
		{
			"variable_name": "prologue_fini",
			"on_complete": {"type": "location", "value": GlobalScope.Location.INFIRMARY},
			"on_incomplete": {"type": "cutscene", "value": "prologue"}
		},
		{
			"variable_name": "Chapitre_1.RatEtFromage.quete_finie",
			"on_complete": {"type": "cutscene", "value": "chapitre1"},
			"on_incomplete": {"type": "location", "value": GlobalScope.Location.INFIRMARY}
		},
		{
			"variable_name": "chapitre1_fini",
			"on_complete": {"type": "location", "value": GlobalScope.Location.SHIP_HOLD},
			"on_incomplete": {"type": "cutscene", "value": "chapitre1"}
		},
		{
			"variable_name": "Chapitre_1.LaLoucheDeMurlock.quete_finie",
			"on_complete": {"type": "cutscene", "value": "chapitre2"},
			"on_incomplete": {"type": "location", "value": GlobalScope.Location.SHIP_HOLD}
		},
		{
			"variable_name": "chapitre2_fini",
			"on_complete": {"type": "location", "value": GlobalScope.Location.DECK_1},
			"on_incomplete": {"type": "cutscene", "value": "chapitre2"}
		},
		{
			"variable_name": "Chapitre_1.ReparerLeBateau.quete_finie",
			"on_complete": {"type": "cutscene", "value": "test_du_second"},
			"on_incomplete": {"type": "location", "value": GlobalScope.Location.DECK_2}
		},
		{
			"variable_name": "test_du_second_fini",
			"on_complete": {"type": "endgame"},
			"on_incomplete": {"type": "cutscene", "value": "test_du_second"}
		}
	]

func get_endgame_rules() -> Array[Dictionary]:
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

func get_endgame_timelines() -> Dictionary:
	return {
		"smash_capitaine": "smash_capitaine",
		"smash_second": "smash_second",
		"devenir_mousse": "devenir_mousse",
		"fin_depart": "fin_depart"
	}
