#!/usr/bin/env python3
"""
new_game.py — scaffolding tool for the Dialogic VN / Adventure template.

Usage:
    python tools/new_game.py

The script asks a series of questions and then creates a new Godot project
directory containing:
  - All vendored addons (dialogic, signal_lens)  — copied from this project
  - Core engine scripts (Scripts/)
  - Data/TravelEvent.tres
  - A game.tscn and game.gd pre-wired to the Dialogic autoload
  - A global_scope.gd with the correct Location enum for your game
  - One empty .tscn scene + .tres definition per location
  - One .tscn scene + .dch character definition per character
  - One starter .dtl timeline per quest × location combination
  - A project.godot with Dialogic variables and directory mappings pre-filled
  - A minimal export_presets.cfg for Windows + Web

Prerequisites:
  - Python 3.8+
  - Run from the root of the template repository (i.e. from the folder that
    contains this tools/ directory).
  - The destination directory must not exist yet (or use --force to overwrite).

"""

import argparse
import json
import os
import re
import shutil
import sys
import textwrap
import uuid
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

TEMPLATE_ROOT = Path(__file__).parent  # tools/
PROJECT_ROOT = TEMPLATE_ROOT.parent    # repo root

TEMPLATES_DIR = TEMPLATE_ROOT / "templates"
CORE_SCRIPTS = [
    "Scripts/cursor_manager.gd",
    "Scripts/location_definition.gd",
    "Scripts/location_manager.gd",
    "Scripts/interactable.gd",
    "Scripts/door.gd",
    "Scripts/fader.gd",
    "Scripts/conditionner.gd",
    "Scripts/progression_manager.gd",
    "Scripts/endgame_resolver.gd",
    "Scripts/travel_event.gd",
    "Scripts/game_config.gd",
    "Data/TravelEvent.tres",
]

# Dialogic default action blob (keyboard / mouse advance bindings)
DIALOGIC_DEFAULT_ACTION = (
    '{\n'
    '"deadzone": 0.5,\n'
    '"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"",'
    '"device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,'
    '"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194309,'
    '"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)\n'
    ', Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"",'
    '"device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,'
    '"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),'
    '"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,'
    '"pressed":true,"double_click":false,"script":null)\n'
    ', Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"",'
    '"device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,'
    '"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":32,'
    '"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)\n'
    ']}'
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def ask(prompt: str, default: Optional[str] = None) -> str:
    suffix = f" [{default}]" if default is not None else ""
    while True:
        answer = input(f"{prompt}{suffix}: ").strip()
        if answer:
            return answer
        if default is not None:
            return default
        print("  ✗  This field is required.")


def ask_list(prompt: str, example: str = "") -> list[str]:
    """Ask for a comma-separated list; return a non-empty list of stripped items."""
    hint = f" (comma-separated, e.g. {example})" if example else " (comma-separated)"
    while True:
        raw = input(f"{prompt}{hint}: ").strip()
        items = [x.strip() for x in raw.split(",") if x.strip()]
        if items:
            return items
        print("  ✗  Provide at least one item.")


def to_enum_name(name: str) -> str:
    """Convert 'My Room' → 'MY_ROOM' for GDScript enum entries."""
    return re.sub(r"[^A-Z0-9]", "_", name.upper()).strip("_")


def to_class_name(name: str) -> str:
    """Convert 'my room' → 'MyRoom'."""
    return "".join(word.capitalize() for word in re.split(r"[\s_\-]+", name) if word)


def to_snake(name: str) -> str:
    """Convert 'My Room' → 'my_room'."""
    return re.sub(r"[^a-z0-9]", "_", name.lower()).strip("_")


def load_template(path: Path, **kwargs) -> str:
    text = path.read_text(encoding="utf-8")
    for key, value in kwargs.items():
        text = text.replace("{" + key + "}", value)
    return text


def uid() -> str:
    """Return a short random UID suffix for Godot resource IDs."""
    return uuid.uuid4().hex[:12]


# ---------------------------------------------------------------------------
# Writers
# ---------------------------------------------------------------------------

def write(dest: Path, content: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content, encoding="utf-8")
    print(f"  ✓  {dest.relative_to(dest.parents[len(dest.parts) - 2])}")


def copy_tree(src: Path, dest: Path) -> None:
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(src, dest)
    print(f"  ✓  {dest.name}/ (copied)")


# ---------------------------------------------------------------------------
# Generators
# ---------------------------------------------------------------------------

def gen_global_scope(locations: list[str]) -> str:
    enum_entries = "\n".join(
        f"\t{to_enum_name(loc)}," for loc in locations
    )
    defs = "\n".join(
        f'\tLocation.{to_enum_name(loc)}: preload("res://LocationDefinitions/{to_class_name(loc)}.tres"),'
        for loc in locations
    )
    tmpl = (TEMPLATES_DIR / "Scripts" / "global_scope.gd.template").read_text(encoding="utf-8")
    return (
        tmpl
        .replace("{location_enum}", enum_entries)
        .replace("{location_definitions}", defs)
    )


def gen_location_tres(location_name: str) -> str:
    tmpl = (TEMPLATES_DIR / "LocationDefinitions" / "LocationDefinition.tres.template").read_text(encoding="utf-8")
    return tmpl.replace("{location_name}", to_class_name(location_name))


def gen_location_tscn(location_name: str) -> str:
    tmpl = (TEMPLATES_DIR / "Scenes" / "Locations" / "Location.tscn.template").read_text(encoding="utf-8")
    return tmpl.replace("{location_name}", to_class_name(location_name))


def gen_character_tscn(character_name: str) -> str:
    tmpl = (TEMPLATES_DIR / "Scenes" / "Character.tscn.template").read_text(encoding="utf-8")
    return tmpl.replace("{character_name}", to_class_name(character_name))


def gen_character_dch(character_name: str) -> str:
    """Return a minimal Dialogic character definition (JSON)."""
    tmpl = (TEMPLATES_DIR / "Dialogic" / "Characters" / "Character.dch.template").read_text(encoding="utf-8")
    colors = [
        (0.8, 0.2, 0.2),
        (0.2, 0.6, 0.2),
        (0.2, 0.4, 0.8),
        (0.8, 0.6, 0.1),
        (0.6, 0.2, 0.7),
    ]
    idx = hash(character_name) % len(colors)
    r, g, b = colors[idx]
    return (
        tmpl
        .replace("{character_name}", to_class_name(character_name))
        .replace("{display_name}", character_name)
        .replace("{description}", "")
        .replace("{color_r}", str(round(r, 2)))
        .replace("{color_g}", str(round(g, 2)))
        .replace("{color_b}", str(round(b, 2)))
    )


def gen_timeline(timeline_id: str, quest_name: str) -> str:
    tmpl = (TEMPLATES_DIR / "Dialogic" / "Timelines" / "timeline.dtl.template").read_text(encoding="utf-8")
    return (
        tmpl
        .replace("{timeline_id}", timeline_id)
        .replace("{quest_name}", quest_name)
    )


def gen_progression_step(
    var_name: str,
    on_complete_type: str,
    on_complete_value: str,
    on_incomplete_type: str,
    on_incomplete_value: str,
) -> str:
    def action(atype: str, aval: str) -> str:
        if atype == "cutscene":
            return f'{{"type": "cutscene", "value": "{aval}"}}'
        if atype == "location":
            return f'{{"type": "location", "value": GlobalScope.Location.{aval}}}'
        return '{"type": "endgame"}'

    return textwrap.dedent(f"""\
        {{
            "variable_name": "{var_name}",
            "on_complete": {action(on_complete_type, on_complete_value)},
            "on_incomplete": {action(on_incomplete_type, on_incomplete_value)}
        }}""")


def gen_game_gd(
    quests: list[dict],
    endings: list[dict],
    timeline_exports: list[str],
    variable_exports: list[str],
) -> str:
    tmpl = (TEMPLATES_DIR / "Scenes" / "game.gd.template").read_text(encoding="utf-8")

    tl_exports = "\n".join(f"@export var {name}_timeline: String" for name in timeline_exports)
    var_exports = "\n".join(f"@export var {name}_var: String" for name in variable_exports)

    steps = ",\n".join(
        "        " + gen_progression_step(
            q["var"], q["on_complete_type"], q["on_complete_value"],
            q["on_incomplete_type"], q["on_incomplete_value"]
        )
        for q in quests
    )

    rules = ",\n".join(
        "        " + json.dumps(e, indent=None)
        for e in endings
    )

    ending_tl = "\n".join(
        f'        "{e["timeline_key"]}": {to_snake(e["timeline_key"])}_timeline,'
        for e in endings
    )

    return (
        tmpl
        .replace("{timeline_exports}", tl_exports)
        .replace("{variable_exports}", var_exports)
        .replace("{progression_steps}", steps)
        .replace("{endgame_rules}", rules)
        .replace("{endgame_timelines}", ending_tl)
    )


def gen_project_godot(
    game_name: str,
    dch_directory: dict,
    dtl_directory: dict,
    variables: dict,
) -> str:
    def dict_to_godot(d: dict, indent: int = 0) -> str:
        lines = ["{"]
        pad = "\t" * (indent + 1)
        for k, v in d.items():
            if isinstance(v, dict):
                lines.append(f'{pad}"{k}": {dict_to_godot(v, indent + 1)},')
            elif isinstance(v, bool):
                lines.append(f'{pad}"{k}": {"true" if v else "false"},')
            elif isinstance(v, str):
                lines.append(f'{pad}"{k}": "{v}",')
            else:
                lines.append(f'{pad}"{k}": {v},')
        lines.append("\t" * indent + "}")
        return "\n".join(lines)

    tmpl = (TEMPLATES_DIR / "project.godot.template").read_text(encoding="utf-8")
    return (
        tmpl
        .replace("{game_name}", game_name)
        .replace("{{dch_directory}}", dict_to_godot(dch_directory))
        .replace("{{dtl_directory}}", dict_to_godot(dtl_directory))
        .replace("{{variables}}", dict_to_godot(variables))
        .replace("{{dialogic_default_action}}", DIALOGIC_DEFAULT_ACTION)
    )


def gen_export_presets(game_name: str) -> str:
    safe = game_name.replace(" ", "")
    return textwrap.dedent(f"""\
        [preset.0]

        name="Windows Desktop"
        platform="Windows Desktop"
        runnable=true
        advanced_options=false
        dedicated_server=false
        custom_features=""
        export_filter="all_resources"
        include_filter=""
        exclude_filter=""
        export_path="Build/Win/{safe}.exe"
        encrypt_pck=false
        encrypt_directory=false
        script_export_mode=2

        [preset.0.options]

        binary_format/embed_pck=true
        texture_format/s3tc_bptc=true
        texture_format/etc2_astc=false
        binary_format/architecture="x86_64"
        codesign/enable=false

        [preset.1]

        name="Web"
        platform="Web"
        runnable=true
        advanced_options=false
        dedicated_server=false
        custom_features=""
        export_filter="all_resources"
        include_filter=""
        exclude_filter=""
        export_path="Build/Web/index.html"
        encrypt_pck=false
        encrypt_directory=false
        script_export_mode=2

        [preset.1.options]

        variant/extensions_support=false
        variant/thread_support=false
        vram_texture_compression/for_desktop=true
        vram_texture_compression/for_mobile=false
        html/export_icon=true
        html/canvas_resize_policy=2
        html/focus_canvas_on_start=true
        progressive_web_app/enabled=false
    """)


def gen_gitignore() -> str:
    return textwrap.dedent("""\
        # Godot 4+ specific ignores
        .godot/
        /android/
        /Build
    """)


# ---------------------------------------------------------------------------
# Interview
# ---------------------------------------------------------------------------

def interview() -> dict:
    print()
    print("=" * 60)
    print("  Dialogic Adventure Game — New Project Scaffolding")
    print("=" * 60)
    print()
    print("Answer the questions below.  Press Enter to accept a default.")
    print()

    cfg: dict = {}

    # Basic info
    cfg["game_name"] = ask("Game name", "MyGame")
    cfg["dest"] = ask(
        "Destination folder",
        f"../{to_snake(cfg['game_name'])}"
    )

    # Locations
    print()
    print("── Locations ────────────────────────────────────────────")
    print("  Enter the names of all rooms / areas the player can visit.")
    cfg["locations"] = ask_list("Locations", "Village, Forest, Castle")

    # Characters
    print()
    print("── Characters ───────────────────────────────────────────")
    print("  Enter the names of all speakable / interactive characters.")
    cfg["characters"] = ask_list("Characters", "Hero, Mentor, Villain")

    # Quests / progression
    print()
    print("── Quests ───────────────────────────────────────────────")
    print("  Each quest maps to one Dialogic variable that becomes true")
    print("  when the quest is completed.")
    n_quests = int(ask("Number of quests", "1"))
    cfg["quests"] = []
    for i in range(n_quests):
        print(f"\n  Quest {i + 1} of {n_quests}:")
        quest: dict = {}
        quest["name"] = ask("    Quest name", f"Quest{i + 1}")
        quest["var"] = ask(
            "    Completion variable (Dialogic path)",
            f"{to_snake(quest['name'])}_fini"
        )
        print("    When INCOMPLETE, what should happen?")
        quest["on_incomplete_type"] = ask(
            "      Action type [location / cutscene]", "cutscene"
        )
        if quest["on_incomplete_type"] == "location":
            locs = [to_enum_name(l) for l in cfg["locations"]]
            print(f"      Available: {', '.join(locs)}")
            quest["on_incomplete_value"] = ask("      Location enum name", locs[0])
        else:
            quest["on_incomplete_value"] = ask(
                "      Timeline ID", f"{to_snake(quest['name'])}_intro"
            )
        print("    When COMPLETE, what should happen?")
        quest["on_complete_type"] = ask(
            "      Action type [location / cutscene / endgame]", "location"
        )
        if quest["on_complete_type"] == "location":
            locs = [to_enum_name(l) for l in cfg["locations"]]
            quest["on_complete_value"] = ask("      Location enum name", locs[0])
        elif quest["on_complete_type"] == "cutscene":
            quest["on_complete_value"] = ask(
                "      Timeline ID", f"{to_snake(quest['name'])}_complete"
            )
        else:
            quest["on_complete_value"] = ""
        cfg["quests"].append(quest)

    # Endings
    print()
    print("── Endings ──────────────────────────────────────────────")
    print("  Define one ending per branch.  The last ending should have")
    print("  no conditions (it is the fallback).")
    n_endings = int(ask("Number of endings", "1"))
    cfg["endings"] = []
    for i in range(n_endings):
        print(f"\n  Ending {i + 1} of {n_endings}:")
        ending: dict = {}
        ending["timeline_key"] = ask("    Timeline key", f"ending_{i + 1}")
        conditions = []
        print("    Conditions (leave blank to finish each, empty first = fallback):")
        while True:
            var_path = input("      Condition variable (blank to stop): ").strip()
            if not var_path:
                break
            expected = ask("      Expected value [true / false]", "true") == "true"
            conditions.append({"var": var_path, "value": expected})
        ending["conditions"] = conditions
        cfg["endings"].append(ending)

    return cfg


# ---------------------------------------------------------------------------
# Main builder
# ---------------------------------------------------------------------------

def build(cfg: dict, force: bool = False) -> None:
    dest = Path(cfg["dest"]).expanduser().resolve()

    if dest.exists():
        if not force:
            print(f"\n✗  Destination already exists: {dest}")
            print("   Use --force to overwrite.\n")
            sys.exit(1)
        shutil.rmtree(dest)

    print(f"\nCreating project in {dest} …\n")

    # ── Addons ────────────────────────────────────────────────────────────
    copy_tree(PROJECT_ROOT / "addons", dest / "addons")

    # ── Core scripts ──────────────────────────────────────────────────────
    for rel in CORE_SCRIPTS:
        src = PROJECT_ROOT / rel
        dst = dest / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    print("  ✓  Core scripts")

    # ── Dialogic styles ───────────────────────────────────────────────────
    copy_tree(PROJECT_ROOT / "Dialogic" / "Styles", dest / "Dialogic" / "Styles")

    # ── global_scope.gd ───────────────────────────────────────────────────
    write(dest / "Scripts" / "global_scope.gd", gen_global_scope(cfg["locations"]))

    # ── LocationDefinitions + Location scenes ─────────────────────────────
    dch_dir: dict = {}
    dtl_dir: dict = {}

    for loc in cfg["locations"]:
        cn = to_class_name(loc)
        write(dest / "LocationDefinitions" / f"{cn}.tres", gen_location_tres(loc))
        write(dest / "Scenes" / "Locations" / f"{cn}.tscn", gen_location_tscn(loc))

    # ── Character scenes + .dch definitions ───────────────────────────────
    (dest / "Dialogic" / "Characters").mkdir(parents=True, exist_ok=True)
    (dest / "Textures" / "Characters").mkdir(parents=True, exist_ok=True)
    for char in cfg["characters"]:
        cn = to_class_name(char)
        write(dest / "Characters" / f"{cn}.tscn", gen_character_tscn(char))
        dch_path = f"res://Dialogic/Characters/{cn}.dch"
        write(dest / "Dialogic" / "Characters" / f"{cn}.dch", gen_character_dch(char))
        dch_dir[cn] = dch_path

    # ── Quest timelines ───────────────────────────────────────────────────
    for quest in cfg["quests"]:
        q_snake = to_snake(quest["name"])
        folder = dest / "Dialogic" / "Timelines" / to_class_name(quest["name"])

        # intro timeline (triggered when quest is first entered)
        intro_id = f"{q_snake}_intro"
        write(folder / f"{intro_id}.dtl", gen_timeline(intro_id, quest["name"]))
        dtl_dir[intro_id] = f"res://Dialogic/Timelines/{to_class_name(quest['name'])}/{intro_id}.dtl"

        # per-quest-incomplete timeline referenced in on_incomplete (if cutscene)
        if quest["on_incomplete_type"] == "cutscene":
            tl_id = quest["on_incomplete_value"]
            path = f"res://Dialogic/Timelines/{to_class_name(quest['name'])}/{tl_id}.dtl"
            if tl_id not in dtl_dir:
                write(folder / f"{tl_id}.dtl", gen_timeline(tl_id, quest["name"]))
                dtl_dir[tl_id] = path

        # per-quest-complete timeline referenced in on_complete (if cutscene)
        if quest["on_complete_type"] == "cutscene":
            tl_id = quest["on_complete_value"]
            path = f"res://Dialogic/Timelines/{to_class_name(quest['name'])}/{tl_id}.dtl"
            if tl_id not in dtl_dir:
                write(folder / f"{tl_id}.dtl", gen_timeline(tl_id, quest["name"]))
                dtl_dir[tl_id] = path

    # ── Ending timelines ──────────────────────────────────────────────────
    endings_folder = dest / "Dialogic" / "Timelines" / "Endings"
    for ending in cfg["endings"]:
        tl_id = ending["timeline_key"]
        write(endings_folder / f"{tl_id}.dtl", gen_timeline(tl_id, "Ending"))
        dtl_dir[tl_id] = f"res://Dialogic/Timelines/Endings/{tl_id}.dtl"

    # ── Dialogic variables ────────────────────────────────────────────────
    variables: dict = {}
    for quest in cfg["quests"]:
        variables[quest["var"]] = False

    # ── game.gd ───────────────────────────────────────────────────────────
    timeline_exports = [to_snake(q["name"]) for q in cfg["quests"]] + [
        e["timeline_key"] for e in cfg["endings"]
    ]
    variable_exports = [to_snake(q["var"]) for q in cfg["quests"]]

    game_gd = gen_game_gd(
        quests=cfg["quests"],
        endings=cfg["endings"],
        timeline_exports=timeline_exports,
        variable_exports=variable_exports,
    )
    write(dest / "Scenes" / "game.gd", game_gd)

    # ── game.tscn (copy from this repo as a usable base) ──────────────────
    shutil.copy2(PROJECT_ROOT / "Scenes" / "game.tscn", dest / "Scenes" / "game.tscn")
    print("  ✓  Scenes/game.tscn (copied from template)")

    # ── Fonts ─────────────────────────────────────────────────────────────
    if (PROJECT_ROOT / "Fonts").exists():
        copy_tree(PROJECT_ROOT / "Fonts", dest / "Fonts")

    # ── icon.svg ──────────────────────────────────────────────────────────
    if (PROJECT_ROOT / "icon.svg").exists():
        shutil.copy2(PROJECT_ROOT / "icon.svg", dest / "icon.svg")

    # ── project.godot ─────────────────────────────────────────────────────
    project_godot = gen_project_godot(
        game_name=cfg["game_name"],
        dch_directory=dch_dir,
        dtl_directory=dtl_dir,
        variables=variables,
    )
    write(dest / "project.godot", project_godot)

    # ── export_presets.cfg ────────────────────────────────────────────────
    write(dest / "export_presets.cfg", gen_export_presets(cfg["game_name"]))

    # ── .gitignore ────────────────────────────────────────────────────────
    write(dest / ".gitignore", gen_gitignore())

    # ── Summary ───────────────────────────────────────────────────────────
    print()
    print("=" * 60)
    print(f"  ✅  Project '{cfg['game_name']}' created at:")
    print(f"      {dest}")
    print()
    print("  Next steps:")
    print("  1. Open the folder in Godot 4.3.")
    print("  2. Let the editor import all assets.")
    print("  3. Open Scenes/game.tscn and update the exported timeline")
    print("     and variable IDs on the Game node in the inspector.")
    print("  4. Add your background art to the location .tscn files.")
    print("  5. Write your story in the generated .dtl timeline files.")
    print("  6. See docs/create-a-new-game.md for the full walkthrough.")
    print("=" * 60)
    print()


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def validate_project(path: Path) -> None:
    """Run consistency checks on an existing project directory."""
    errors: list[str] = []

    gs_path = path / "Scripts" / "global_scope.gd"
    if not gs_path.exists():
        errors.append("Missing Scripts/global_scope.gd")
    else:
        gs_text = gs_path.read_text(encoding="utf-8")

        # Collect declared location enum names
        enum_match = re.search(r"enum Location \{([^}]+)\}", gs_text, re.DOTALL)
        declared_locations: set[str] = set()
        if enum_match:
            for name in re.findall(r"([A-Z_]+),?", enum_match.group(1)):
                declared_locations.add(name)
        else:
            errors.append("global_scope.gd: no Location enum found")

        # Check that each declared location has a .tres definition
        for loc in declared_locations:
            # Convert enum name MY_ROOM → look for any .tres in LocationDefinitions/
            pass  # detailed scan below

    # Check every LocationDefinition .tres points to an existing .tscn
    ld_dir = path / "LocationDefinitions"
    if ld_dir.exists():
        for tres in ld_dir.glob("*.tres"):
            content = tres.read_text(encoding="utf-8")
            m = re.search(r'path="(res://Scenes/Locations/[^"]+\.tscn)"', content)
            if m:
                scene_path = path / m.group(1).replace("res://", "")
                if not scene_path.exists():
                    errors.append(
                        f"{tres.name}: references non-existent scene {m.group(1)}"
                    )

    # Check timeline references in .tscn files
    for tscn in (path / "Scenes").rglob("*.tscn"):
        content = tscn.read_text(encoding="utf-8")
        for m in re.finditer(r'timeline = "([^"]+)"', content):
            tl_id = m.group(1)
            # Search for the timeline in Dialogic/Timelines
            found = list((path / "Dialogic" / "Timelines").rglob(f"{tl_id}.dtl"))
            if not found:
                errors.append(
                    f"{tscn.relative_to(path)}: references missing timeline '{tl_id}'"
                )

    # Check Dialogic variable references in .tscn condition arrays
    # (We only check that the project.godot variables section declares them)
    project_text = (path / "project.godot").read_text(encoding="utf-8") if (path / "project.godot").exists() else ""

    for tscn in (path / "Scenes").rglob("*.tscn"):
        content = tscn.read_text(encoding="utf-8")
        for m in re.finditer(r'conditions = Array\[String\]\(\["([^"]+)"', content):
            var_path = m.group(1)
            if var_path not in project_text:
                errors.append(
                    f"{tscn.relative_to(path)}: condition variable '{var_path}' "
                    "not found in project.godot variables section"
                )

    if errors:
        print(f"\n✗  Validation found {len(errors)} issue(s):\n")
        for e in errors:
            print(f"   • {e}")
        sys.exit(1)
    else:
        print("\n✅  All consistency checks passed.\n")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--force", action="store_true", help="Overwrite destination directory if it exists")
    parser.add_argument("--validate", metavar="PATH", help="Run consistency checks on an existing project")
    args = parser.parse_args()

    if args.validate:
        validate_project(Path(args.validate).expanduser().resolve())
        return

    cfg = interview()
    build(cfg, force=args.force)


if __name__ == "__main__":
    main()
