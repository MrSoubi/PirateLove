# Create a New Game — Step-by-Step Guide

This guide walks you through creating a brand-new game from this template.  By the end you will have a runnable Godot 4.3 project with your locations, characters, and story outline scaffolded and ready to flesh out.

---

## Prerequisites

| Tool | Version |
|---|---|
| Godot | 4.3 |
| Python | 3.8+ (for the scaffolding script only) |

The `addons/dialogic` and `addons/signal_lens` folders are vendored inside this repository — no separate installation step is needed.

---

## Option A — Automated scaffolding (recommended)

The scaffolding script asks you a series of questions and generates a complete project skeleton.

```bash
# From the root of the template repository:
python tools/new_game.py
```

Answer the prompts:

| Prompt | Example input |
|---|---|
| Game name | `Haunted Manor` |
| Destination folder | `../haunted_manor` |
| Locations | `Foyer, Library, Cellar, Garden` |
| Characters | `Ghost, Butler, Detective` |
| Number of quests | `2` |
| (per quest) Quest name | `FindTheKey` |
| (per quest) Completion variable | `find_the_key_fini` |
| … | … |
| Number of endings | `3` |
| (per ending) Timeline key | `ending_escape` |
| (per ending) Conditions | variable `escaped` = true |

The script creates the destination directory with:
- All vendored addons
- Core engine scripts
- `global_scope.gd` with your `Location` enum
- One `.tscn` scene + `.tres` definition per location
- One `.tscn` scene + `.dch` Dialogic character per character
- One `.dtl` starter timeline per quest + per ending
- A pre-wired `project.godot` with Dialogic variable declarations
- Export presets for Windows and Web

Then open the generated folder in Godot 4.3 and proceed to [Step 3](#step-3--set-inspector-exports-on-the-game-node).

---

## Option B — Manual setup

Use this path if you prefer full control or are adapting an existing project.

### Step 1 — Create the project folder

1. Copy or clone this repository into a new folder.
2. Delete everything inside `Scenes/Locations/`, `Characters/`, `Dialogic/Characters/`, `Dialogic/Timelines/` (keep the `Dialogic/Styles/` folder).
3. Keep all files in `Scripts/`, `Data/`, `addons/`, `Fonts/`.

### Step 2 — Define your locations

**a. Add location entries to `Scripts/global_scope.gd`:**

```gdscript
enum Location {
    FOYER,
    LIBRARY,
    CELLAR,
    GARDEN
}

const LOCATION_DEFINITIONS := {
    Location.FOYER:   preload("res://LocationDefinitions/Foyer.tres"),
    Location.LIBRARY: preload("res://LocationDefinitions/Library.tres"),
    Location.CELLAR:  preload("res://LocationDefinitions/Cellar.tres"),
    Location.GARDEN:  preload("res://LocationDefinitions/Garden.tres"),
}
```

**b. Create a `LocationDefinition` resource for each location:**

Duplicate `LocationDefinitions/Kitchen.tres` (from PirateLove) or use the template at `tools/templates/LocationDefinitions/LocationDefinition.tres.template`.  Set `scene` to `res://Scenes/Locations/<Name>.tscn`.

**c. Create a location scene for each location:**

Use the template at `tools/templates/Scenes/Locations/Location.tscn.template`.  The minimum structure is:

```
Node  (root)
  CanvasLayer
    TextureRect  (background art)
    Area2D + door.gd  (one per exit)
    Area2D + interactable.gd  (one per object/character)
```

See [Location scene anatomy](#location-scene-anatomy) for details.

### Step 3 — Create your characters

For each character you need **two** things:

1. **A Godot scene** (`Characters/<Name>.tscn`) — the clickable in-world sprite.  
   Base it on `tools/templates/Scenes/Character.tscn.template`.  
   Add a `Sprite2D` with your art and a `CollisionPolygon2D` tracing the silhouette.

2. **A Dialogic character definition** (`Dialogic/Characters/<Name>.dch`) — controls portraits and dialogue display name.  
   Create it in the Dialogic editor tab inside Godot, or base it on `tools/templates/Dialogic/Characters/Character.dch.template`.

### Step 4 — Declare your Dialogic variables

Open `project.godot` (or use the Dialogic Settings panel in the editor) and add one boolean variable per quest completion flag, plus any other state variables your timelines need.

Convention used in PirateLove (and recommended):

```
prologue_fini              # top-level booleans
chapitre1_fini

QuestName.sub_quest_fini   # nested under quest group
QuestName.quete_en_cours
QuestName.some_flag
```

### Step 5 — Write your progression steps in `Scenes/game.gd`

Replace (or extend) `_build_progression_steps()` with your own steps:

```gdscript
func _build_progression_steps() -> Array[Dictionary]:
    return [
        {
            "variable_name": "prologue_fini",
            "on_complete":   {"type": "location", "value": GlobalScope.Location.FOYER},
            "on_incomplete": {"type": "cutscene", "value": "prologue"}
        },
        {
            "variable_name": "FindTheKey.quete_finie",
            "on_complete":   {"type": "cutscene", "value": "chapter_2_intro"},
            "on_incomplete": {"type": "location", "value": GlobalScope.Location.LIBRARY}
        },
        # ... more steps ...
        {
            "variable_name": "final_quest_fini",
            "on_complete":   {"type": "endgame"},
            "on_incomplete": {"type": "cutscene", "value": "final_quest_intro"}
        }
    ]
```

### Step 6 — Define your endings

Replace `_build_endgame_rules()` with your ending logic:

```gdscript
func _build_endgame_rules() -> Array[Dictionary]:
    return [
        {
            "conditions": [
                {"var": "escaped",    "value": true},
                {"var": "ghost_free", "value": true}
            ],
            "timeline_key": "ending_good"
        },
        {
            "conditions": [{"var": "escaped", "value": true}],
            "timeline_key": "ending_bittersweet"
        },
        {
            "conditions": [],          # fallback
            "timeline_key": "ending_trapped"
        }
    ]
```

And update `_get_endgame_timelines()` to map those keys to real timeline IDs:

```gdscript
func _get_endgame_timelines() -> Dictionary:
    return {
        "ending_good":        ending_good_timeline,
        "ending_bittersweet": ending_bittersweet_timeline,
        "ending_trapped":     ending_trapped_timeline
    }
```

### Step 7 — Set inspector exports on the Game node

Open `Scenes/game.tscn` in the Godot editor.  Select the root `Game` node.  In the Inspector, fill in each exported `String` field with the matching Dialogic timeline ID or variable path.

### Step 8 — Write your timelines

Create `.dtl` files in `Dialogic/Timelines/`.  Reference the syntax cheat sheet at `tools/templates/Dialogic/Timelines/timeline.dtl.template`.

Key rules:
- Always emit `[signal arg="variables_changed"]` after any `set {variable} = ...` statement that must trigger a location change or item visibility update.
- Use the `Conditionner` node (not timeline conditionals) for toggling scene objects — it reacts to `variables_changed` automatically.

### Step 9 — Add art and audio

| Asset type | Location |
|---|---|
| Background art | `Textures/Locations/<LocationName>/` |
| Character portraits | `Textures/Characters/<CharacterName>/` |
| In-world character sprites | `Textures/Characters/<CharacterName>/` |
| Music | `Music/` |
| Cursor textures | `Textures/Cursors/` |

Reference textures in `.tscn` files via their `res://` paths.  Reference music in `.dtl` timelines with `[music path="res://Music/my_track.mp3" fade="2.0" volume="0.0"]`.

### Step 10 — Test and export

1. Press **F5** (or the Play button) in Godot to run from the main scene.
2. When ready to export: **Project → Export**, select a preset, and click **Export Project**.

---

## Location scene anatomy

Every location scene follows this pattern:

```
Node  (root, named after the location)
  CanvasLayer
    TextureRect          ← full-screen background art
    [optional] QuestName (Node2D + conditionner.gd, conditions=["QuestName.quete_en_cours"])
      Door_To_X         ← Area2D + door.gd, destination = GlobalScope.Location.X
        CollisionPolygon2D
      NpcName           ← instance of Characters/NpcName.tscn, timeline = "quest_npc"
      SomeObject        ← Area2D + interactable.gd, timeline = "quest_object"
        CollisionPolygon2D
      ItemSprite        ← Sprite2D + conditionner.gd (shows/hides based on item flag)
```

- **Wrap quest-specific content in a `Conditionner` node.**  The condition array controls when that sub-tree is visible.  This is how one scene file serves multiple story states without any custom code.
- **Use `invert = true`** on a `Conditionner` to show something _until_ a condition is met (e.g. show the broken door until the player repairs it).
- **Each door area gets one `CollisionPolygon2D`** tracing the clickable region.  Draw it in the editor using **Polygon2D edit mode**.

---

## Naming conventions

Following these conventions ensures the scaffolding tool and validation script work correctly.

| Item | Convention | Example |
|---|---|---|
| Location enum name | `UPPER_SNAKE` | `CAPTAIN_CABIN` |
| LocationDefinition .tres | `PascalCase.tres` | `CaptainCabin.tres` |
| Location scene | `PascalCase.tscn` | `CaptainCabin.tscn` |
| Character scene | `PascalCase.tscn` | `Medecin.tscn` |
| Dialogic character | `PascalCase.dch` | `Medecin.dch` |
| Timeline ID | `snake_case` | `default_medecin` |
| Quest variable group | `QuestName.variable` | `RatEtFromage.quete_finie` |
| Top-level flag | `snake_case` | `prologue_fini` |

---

## Validation

After filling in your content, run the validation pass to catch broken references:

```bash
python tools/new_game.py --validate /path/to/your/project
```

The validator checks:
- Every `LocationDefinition.tres` points to an existing `.tscn`.
- Every `timeline = "..."` in a `.tscn` file has a matching `.dtl` file.
- Every `conditions = Array[String](["..."])` variable appears in `project.godot`.

Fix any reported issues before shipping.
