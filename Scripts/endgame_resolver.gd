extends RefCounted

# Each rule is a Dictionary with two keys:
#   "conditions" : Array of Dictionaries, each with "var" (String variable path) and
#                  "value" (bool expected value). All conditions must be true for the
#                  rule to match.  An empty conditions array always matches.
#   "timeline_key": String key into the ending_timelines dictionary passed to resolve().
#
# Rules are evaluated in order; the first matching rule wins.
# Place the most-specific rules first and the fallback (empty conditions) last.
#
# Example rules array:
#   [
#     {
#       "conditions": [{"var": "test_passed", "value": true},
#                      {"var": "secret_found", "value": true}],
#       "timeline_key": "ending_special"
#     },
#     {
#       "conditions": [{"var": "test_passed", "value": true}],
#       "timeline_key": "ending_good"
#     },
#     {
#       "conditions": [],   # fallback — always matches
#       "timeline_key": "ending_default"
#     }
#   ]

var rules: Array[Dictionary]

func _init(endgame_rules: Array[Dictionary] = []) -> void:
	rules = endgame_rules

func resolve(ending_timelines: Dictionary) -> String:
	for rule in rules:
		if _all_conditions_met(rule.get("conditions", [])):
			return ending_timelines.get(rule.get("timeline_key", ""), "")
	return ""

func _all_conditions_met(conditions: Array) -> bool:
	for condition in conditions:
		var current_value = Dialogic.VAR.get_variable(condition.get("var", ""))
		var expected_value = condition.get("value", true)
		if current_value != expected_value:
			return false
	return true
