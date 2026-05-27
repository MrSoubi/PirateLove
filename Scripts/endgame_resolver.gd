extends RefCounted

func resolve(ending_timelines: Dictionary) -> String:
	var test_reussi: bool = Dialogic.VAR.get_variable("test_reussi")
	var secret_decouvert: bool = Dialogic.VAR.get_variable("secret_decouvert")

	if test_reussi:
		if secret_decouvert:
			return ending_timelines.get("smash_second", "")
		return ending_timelines.get("smash_capitaine", "")

	if secret_decouvert:
		return ending_timelines.get("fin_depart", "")

	return ending_timelines.get("devenir_mousse", "")
