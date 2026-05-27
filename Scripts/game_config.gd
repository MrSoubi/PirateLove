# GameConfig — base class that a new game extends to wire its content into the engine.
#
# Override each method in your own game_config.gd (inside your project's Scripts/ folder)
# and return the game-specific data.  The core loop in game.gd calls these methods so it
# never needs to know anything about your story.
#
# Usage
# -----
# 1. Copy this file into your project as Scripts/game_config.gd.
# 2. Change "extends Resource" if you want a pure-code approach, or keep it as a Resource
#    so it can be saved as a .tres and assigned in the inspector.
# 3. Override the three virtual methods below.
# 4. In game.gd replace the inline _build_progression_steps() / _build_endgame_rules()
#    calls with config.get_progression_steps() / config.get_endgame_rules(), where
#    `config` is an instance of your derived class.

class_name GameConfig
extends Resource

# ---------------------------------------------------------------------------
# Progression steps
# ---------------------------------------------------------------------------
# Return an ordered Array[Dictionary] where each dictionary describes one
# story beat.  Keys:
#
#   "variable_name" : String  — Dialogic variable path (e.g. "prologue_fini").
#                               The step is considered complete when this variable
#                               evaluates to true.
#   "on_complete"   : Dictionary — action to take when the step becomes complete.
#   "on_incomplete" : Dictionary — action to take when the step is not yet complete.
#
# Action dictionaries use the same format as _execute_action() in game.gd:
#   {"type": "location", "value": <GlobalScope.Location int>}
#   {"type": "cutscene", "value": "<timeline_id>"}
#   {"type": "endgame"}
#
# The ProgressionManager evaluates steps in order on startup and re-evaluates
# after each Dialogic `variables_changed` signal, so progression advances
# automatically when a timeline sets the right variable.

func get_progression_steps() -> Array[Dictionary]:
	return []

# ---------------------------------------------------------------------------
# Endgame rules
# ---------------------------------------------------------------------------
# Return an ordered Array[Dictionary] evaluated by EndgameResolver.  Keys:
#
#   "conditions"   : Array[Dictionary] — each entry has "var" (String variable path)
#                    and "value" (bool expected value).  All conditions must match.
#                    An empty array is a fallback that always matches.
#   "timeline_key" : String — key into the ending_timelines dict (see below).
#
# Rules are checked in order; the first fully-matching rule is used.

func get_endgame_rules() -> Array[Dictionary]:
	return []

# ---------------------------------------------------------------------------
# Ending timelines
# ---------------------------------------------------------------------------
# Return a Dictionary mapping the timeline_keys used in get_endgame_rules() to
# actual Dialogic timeline IDs (strings).  Keeping this separate from the rules
# lets designers change timeline names without touching rule logic.

func get_endgame_timelines() -> Dictionary:
	return {}
