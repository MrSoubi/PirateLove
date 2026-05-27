# Migration Guide — PirateLove Layout → Template Layout

This guide is for developers who worked on the original PirateLove project and want to understand what changed in this templated version, or who want to port their own derived fork to the new structure.

---

## What stayed the same

- **All location scenes** (`Scenes/Locations/*.tscn`) — unchanged.
- **All character scenes** (`Characters/*.tscn`) — unchanged.
- **All Dialogic assets** (timelines `.dtl`, characters `.dch`, items `.dch`, styles) — unchanged.
- **Core engine scripts** (`Scripts/*.gd`) — interfaces unchanged, except `endgame_resolver.gd` (see below).
- **Autoload configuration** in `project.godot` — unchanged.
- **`Data/TravelEvent.tres`** — unchanged.
- **`addons/`** — unchanged (Dialogic 2 Alpha-16 and signal_lens remain vendored).

---

## What changed

### `Scripts/endgame_resolver.gd`

**Before (PirateLove-specific):**

```gdscript
func resolve(timelines: Dictionary) -> String:
    if Dialogic.VAR("test_reussi") and Dialogic.VAR("secret_decouvert"):
        return timelines["smash_second"]
    elif Dialogic.VAR("test_reussi"):
        return timelines["smash_capitaine"]
    ...
    return timelines["devenir_mousse"]
```

**After (data-driven):**

```gdscript
func _init(rules: Array[Dictionary]) -> void:
    _rules = rules

func resolve(timelines: Dictionary) -> String:
    for rule in _rules:
        if _all_conditions_met(rule["conditions"]):
            return timelines[rule["timeline_key"]]
    return ""
```

The logic is identical — but the variable names and timeline keys are no longer hardcoded.  They are supplied as a data structure by the caller.

**Impact on existing code:** none — the public interface (`resolve(timelines)`) has the same return type.  If you have a subclass or mock of `EndgameResolver`, update its `_init` signature.

---

### `Scenes/game.gd`

**Removed:**

```gdscript
func _get_endgame_timelines() -> Dictionary: ...    # was inline dict
func handle_endgame() -> void:
    var resolver := EndgameResolver.new()           # was no-arg constructor
```

**Added:**

```gdscript
func _build_endgame_rules() -> Array[Dictionary]: ...   # PirateLove rules as data
func _ready() -> void:
    _endgame_resolver = EndgameResolver.new(_build_endgame_rules())
```

**Why:** `_build_endgame_rules()` contains exactly the same four endings as before, expressed as a list of condition→timeline-key dicts.  The gameplay is unchanged.

---

### New file: `Scripts/game_config.gd`

This is an optional base class for new games that prefer a Resource-based configuration pattern over editing `game.gd` directly.  PirateLove does not use it yet (it is provided for template consumers).

If you want to move PirateLove configuration into a `GameConfig` resource:
1. Create `pirate_love_config.gd` extending `GameConfig`.
2. Override `get_progression_steps()`, `get_endgame_rules()`, `get_endgame_timelines()`.
3. In `game.gd._ready()`, load the resource and call its methods instead of the inline `_build_*` functions.

---

### New directory: `docs/`

Contains this guide, `architecture.md`, and `create-a-new-game.md`.  No functional impact.

---

### New directory: `tools/`

Contains `new_game.py` and `tools/templates/`.  These are development-time tools only — they do not affect the Godot project at runtime and are not imported by the project.

---

## How to adopt the template in a fork

If you forked PirateLove before this templating work was done, here is the minimum change set:

### 1. Replace `Scripts/endgame_resolver.gd`

Copy the new version from this repository.  The file is self-contained — no other files depend on its internals.

### 2. Update `Scenes/game.gd`

Add `_build_endgame_rules()` and update `_ready()` to pass the rules to the constructor:

```gdscript
var _endgame_resolver: EndgameResolver

func _ready() -> void:
    ...
    _endgame_resolver = EndgameResolver.new(_build_endgame_rules())
    ...

func _build_endgame_rules() -> Array[Dictionary]:
    return [
        # your rules here — match your old if/elif chain
        {"conditions": [{"var": "X", "value": true}, {"var": "Y", "value": true}], "timeline_key": "ending_a"},
        {"conditions": [{"var": "X", "value": true}],                               "timeline_key": "ending_b"},
        {"conditions": [],                                                            "timeline_key": "ending_default"}
    ]

func handle_endgame() -> void:
    var timelines := _get_endgame_timelines()
    var tl := _endgame_resolver.resolve(timelines)
    if tl != "":
        start_cutscene(tl)
```

### 3. (Optional) Copy `Scripts/game_config.gd`

Only needed if you want the Resource-based config pattern.

### 4. (Optional) Copy `tools/`

Only needed if you want to use the scaffolding script or validator for a new game based on your fork.

---

## Side-by-side layout comparison

```
Before                               After (template)
──────────────────────────────────   ──────────────────────────────────
Scenes/game.gd                       Scenes/game.gd            (modified)
Scripts/endgame_resolver.gd          Scripts/endgame_resolver.gd (modified)
                                     Scripts/game_config.gd      (new)
                                     tools/new_game.py            (new)
                                     tools/templates/             (new)
                                     docs/architecture.md         (new)
                                     docs/create-a-new-game.md    (new)
                                     docs/migration-guide.md      (new — this file)
                                     README.md                    (new)
```

Everything else is byte-for-byte identical to the original PirateLove project.
