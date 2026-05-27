# Architecture — Dialogic Adventure Game Template

This document describes the runtime architecture shared by every game built on this template.  It is aimed at programmers who want to extend the engine layer or understand how data flows at runtime.

---

## High-level overview

```
project.godot
 └─ Autoloads
     ├─ Dialogic          (addons/dialogic — manages timelines, variables, portraits)
     ├─ GlobalScope       (Scripts/global_scope.gd — location enum + definitions)
     └─ CursorManager     (Scripts/cursor_manager.gd — context-sensitive cursor)

Scenes/game.tscn  (main scene)
 └─ Game (Node — Scenes/game.gd)
     ├─ LocationContainer (Node2D — holds the active location scene)
     ├─ MainMenu          (CanvasLayer)
     ├─ NarrationContainer(Node2D — Dialogic renders into this during cutscenes)
     ├─ Vignette          (CanvasLayer — optional post-process overlay)
     └─ TransitionLayer   (CanvasLayer — Scripts/fader.gd — fade in/out)
```

### Active subsystems (instantiated in `game.gd._ready()`)

| Class | File | Role |
|---|---|---|
| `LocationManager` | `Scripts/location_manager.gd` | Swaps the active location scene inside `LocationContainer` |
| `ProgressionManager` | `Scripts/progression_manager.gd` | Watches Dialogic variables and fires the next story action |
| `EndgameResolver` | `Scripts/endgame_resolver.gd` | Selects the correct ending timeline from a rules table |

---

## LocationManager

```
GlobalScope.Location (enum)  →  GlobalScope.LOCATION_DEFINITIONS (dict)
   └─ LocationDefinition.tres (Resources/location_definition.gd)
          └─ .scene  (PackedScene)  →  instantiated into LocationContainer
```

**Adding a new location:**
1. Create `Scenes/Locations/MyRoom.tscn`.
2. Create `LocationDefinitions/MyRoom.tres` (script = `location_definition.gd`, scene = the .tscn).
3. Add `MY_ROOM` to the `Location` enum in `Scripts/global_scope.gd`.
4. Add `Location.MY_ROOM: preload("res://LocationDefinitions/MyRoom.tres")` to `LOCATION_DEFINITIONS`.

---

## ProgressionManager

`ProgressionManager` is initialised with an ordered `Array[Dictionary]` called **progression steps**.

Each step looks like:

```gdscript
{
    "variable_name": "prologue_fini",         # Dialogic VAR path
    "on_complete":   {"type": "location", "value": GlobalScope.Location.KITCHEN},
    "on_incomplete": {"type": "cutscene",  "value": "prologue"}
}
```

**On startup** (`refresh()` + `get_startup_action()`): steps are scanned from first to last.  The first step whose variable is `false` returns its `on_incomplete` action.  If all variables are `true`, `{"type": "endgame"}` is returned.

**On variable change** (`handle_dialogic_signal("variables_changed")`): the manager re-checks each step.  When a variable flips from `false` → `true` for the first time in this session, the step's `on_complete` action is emitted via the `action_requested` signal.

Action types understood by `game.gd._execute_action()`:

| `"type"` | `"value"` | Effect |
|---|---|---|
| `"location"` | `GlobalScope.Location` int | Load the specified location scene |
| `"cutscene"` | Timeline ID string | Fade and start the Dialogic timeline |
| `"endgame"` | *(none)* | Delegate to `EndgameResolver` |

---

## EndgameResolver

`EndgameResolver` takes an `Array[Dictionary]` of **rules** at construction time.

```gdscript
EndgameResolver.new([
    {
        "conditions": [{"var": "test_reussi",     "value": true},
                       {"var": "secret_decouvert", "value": true}],
        "timeline_key": "smash_second"
    },
    {
        "conditions": [{"var": "test_reussi", "value": true}],
        "timeline_key": "smash_capitaine"
    },
    {
        "conditions": [],          # fallback — always matches
        "timeline_key": "devenir_mousse"
    }
])
```

`resolve(ending_timelines: Dictionary) → String`  
Rules are checked in order.  The first rule whose every condition is satisfied returns `ending_timelines[timeline_key]`.  An empty `conditions` array always matches, so put fallbacks last.

---

## Interactable / Door / Conditionner

These three scripts are the building blocks for every location scene.

### `interactable.gd` (extends `Area2D`)

| Export | Type | Description |
|---|---|---|
| `timeline` | `String` | Dialogic timeline to start on click |
| `cursor_type` | `CursorManager.Type` | Cursor shown on hover |

Mouse click → `Dialogic.start(timeline)`.

### `door.gd` (extends `Area2D`)

| Export | Type | Description |
|---|---|---|
| `destination` | `GlobalScope.Location` | Target location on click |

Mouse click → emits `TravelEvent.triggered(destination)` → `game.gd._on_location_requested()` → `LocationManager.set_location()`.

### `conditionner.gd` (extends `Node2D`)

| Export | Type | Description |
|---|---|---|
| `conditions` | `Array[String]` | Dialogic variable paths (all must be true to show) |
| `invert` | `bool` | If `true`, shows when ALL conditions are false |

Re-checks visibility every time Dialogic emits `signal_event("variables_changed")`.  Wrap any sub-tree in a `Conditionner` node to make it appear/disappear based on quest state — no custom code needed.

---

## TravelEvent

`Data/TravelEvent.tres` is a singleton **Resource** (class `TravelEvent`) that carries one signal:

```gdscript
signal triggered(destination: GlobalScope.Location)
```

It is preloaded both in `door.gd` (emitter) and `game.gd` (listener).  Using a shared resource avoids needing a direct node reference between scenes.

---

## Save / Load

Dialogic's built-in save subsystem (`Dialogic.Save`) persists all declared variables.  `game.gd` calls:
- `Dialogic.Save.load()` when "Continue" is pressed.
- Auto-save is enabled (60 s interval, see `project.godot`).

No additional code is required for basic save/load.

---

## CursorManager

Four cursor types are defined (`CursorManager.Type`):

| Enum | Texture | When used |
|---|---|---|
| `NONE` | `cursor.png` | Default; no hovered interactive object |
| `CHARACTER` | `Bulle_Conversation.png` | Hovering a character (NPC with dialogue) |
| `ITEM` | `Loupe.png` | Hovering an interactable object/item |
| `DOOR` | `Porte.png` | Hovering a door / travel area |

To add a new cursor type: add an enum entry, add a `const` for the texture, and add a `match` case in `set_cursor()`.

---

## Fader

`Scripts/fader.gd` (class `Fader`, extends `CanvasLayer`) provides a simple fade-to-black / fade-in transition.

```gdscript
fader.transition()              # start fade-to-black
await fader.on_transition_finished   # emitted at the black frame
# perform scene swap / timeline start here
# fade-to-normal starts automatically after the signal
```

`game.gd` calls `start_cutscene()` which chains the transition with `Dialogic.start()`.

---

## Extending the engine

### New action type

Add a new `match` branch in `game.gd._execute_action()`:

```gdscript
"my_action":
    _handle_my_action(action.get("value"))
```

Emit the action from a custom script by calling `progression_manager.action_requested.emit({"type": "my_action", "value": ...})` or directly from `game.gd`.

### New cursor type

1. Add entry to `CursorManager.Type` enum.
2. Add `const MY_CURSOR = preload(...)`.
3. Add `match` case in `set_cursor()`.
4. Set `cursor_type` on the relevant `interactable.gd` nodes.

### New Conditionner logic

`conditionner.gd` currently supports AND logic (all conditions must be true).  For OR logic, subclass or duplicate the script and override `check_conditions()`.
