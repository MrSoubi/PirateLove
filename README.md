# PirateLove — Dialogic Adventure Game Template

A reusable point-and-click adventure game template built on **Godot 4.3** + **Dialogic 2 (Alpha-16)**.

`PirateLove` is the reference implementation that ships with the template.  Fork this repository to create your own story-driven game with the same engine layer.

---

## Stack

| Component | Version |
|---|---|
| Godot | 4.3 |
| Dialogic | 2 Alpha-16 (vendored in `addons/dialogic`) |
| signal_lens | vendored in `addons/signal_lens` |
| Python (scaffolding only) | 3.8+ |

No plugin installation step is needed — addons are committed directly to the repository.

---

## Quick start — new game

```bash
# Clone the template
git clone https://github.com/MrSoubi/PirateLove.git my-game
cd my-game

# Run the scaffolding wizard
python tools/new_game.py
```

Answer the prompts (game name, locations, characters, quests, endings) and the script will generate a ready-to-open Godot project at the destination you specify.

Then open the generated project in Godot 4.3 and follow the [Create a New Game guide](docs/create-a-new-game.md) for the remaining steps.

---

## Quick start — run PirateLove

1. Open the repository root in **Godot 4.3**.
2. Press **F5** or click **Play**.

---

## Repository layout

```
addons/               Vendored Dialogic 2 + signal_lens
Characters/           In-world character scenes (.tscn)
Data/                 Shared resources (TravelEvent singleton)
Dialogic/
  Characters/         Dialogic character definitions (.dch)
  Items/              Dialogic item definitions (.dch)
  Styles/             Visual novel UI styles
  Timelines/          Story timelines (.dtl)
docs/                 Documentation
  architecture.md     Engine layer explanation
  create-a-new-game.md  Step-by-step new game guide
  migration-guide.md  Porting from old PirateLove layout
Fonts/                Font files
LocationDefinitions/  Location metadata resources (.tres)
Music/                Background music tracks
Scenes/
  Locations/          Location scenes (.tscn)
  game.tscn           Main scene
  game.gd             Game orchestrator (progression, endings, travel)
Scripts/              Reusable engine scripts
  conditionner.gd     Variable-driven node visibility
  cursor_manager.gd   Context-sensitive cursor
  door.gd             Travel area (click → location change)
  endgame_resolver.gd Rules-based ending selector
  fader.gd            Fade-to-black transition
  game_config.gd      Base class for game configuration resources
  global_scope.gd     Location enum + definition registry (autoload)
  interactable.gd     Clickable object → timeline trigger
  location_manager.gd Scene swapper
  progression_manager.gd  Quest/chapter state machine
  travel_event.gd     Signal bridge (door → game.gd)
Textures/             Art assets
tools/
  new_game.py         Scaffolding script (generates new game projects)
  templates/          File templates used by new_game.py
```

---

## Documentation

| Doc | Description |
|---|---|
| [Architecture](docs/architecture.md) | Runtime systems, data flow, extension points |
| [Create a New Game](docs/create-a-new-game.md) | End-to-end guide from scaffolding to export |
| [Migration Guide](docs/migration-guide.md) | What changed from original PirateLove to template |

---

## Validation

After creating or editing a project, run the validator to catch broken cross-references:

```bash
python tools/new_game.py --validate /path/to/your/project
```

Checks performed:
- Every `LocationDefinition.tres` → existing scene file
- Every `timeline = "..."` in `.tscn` → existing `.dtl` file
- Every `Conditionner` condition variable → declared in `project.godot`

---

## License

See `LICENSE` if present in the repository.  Art assets (textures, music) may carry separate licenses.
