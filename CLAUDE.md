# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 4 complete; engine/scene state unchanged this session (docs-only). Godot 4.6.2 project at C:\Projects\Mostly. Window opens at 1280x720 (4x the 320x180 viewport) via Boot autoload. Project is under git version control, pushed to https://github.com/adamgtyson/mostly.git (main branch).

Docs layer: Docs/handoff/ (10 files including README) is the authoritative layer over Docs/00-06. Added this session: Docs/ENGINEERING_CONSTRAINTS.md (dated 2026-08-29) - the locked engineering layer for the Act One build, covering combat model, flag/quest system (GameState), save system (SaveManager), inventory/items, dialogue JSON schema v2, scene architecture (SceneRouter, regions as packages), generator contract (region.json anchors/fill slots), cutscene beats as data, crafting/repair, Weirdness autoload, test harness (tools/check.bat), asset pipeline, and conventions. All thirteen sections LOCKED; EC-12a (Mana Seed EULA verification) is OPEN as a pre-launch gate. Claude Code designs within these constraints and does not choose or relax them. Docs/LICENSES.md created as a stub with Mana Seed terms unverified. Docs/handoff/MOSTLY_DECISION_LEDGER.md gained section K (K0, EC-1..EC-13, EC-1a, EC-2a, EC-4a, EC-6a, EC-12a). Docs/handoff/MOSTLY_ACT1_BUILD_PLAN.md phase 0 (§8) and next-action 2 (§9) marked DONE 2026-08-29. Docs/00_QUICK_REFERENCE.md gained an "Authoritative Documents" section pointing at Docs/handoff/ and Docs/ENGINEERING_CONSTRAINTS.md.

Engine/scene state as of Session 3 (unchanged):

- `scenes/workshop.tscn` - 20x15 tile room (320x240 px); StaticBody2D walls; 2-tile door opening on south wall; Camera2D clamped to room bounds (0,0)-(320,240). Player starts at (48,64). OpeningCutscene node triggers cutscene on load.
- `scripts/player.gd` - CharacterBody2D (Patch); WASD + arrow 4-direction movement at 80 px/s; movement and interaction locked while dialogue OR cutscene is active; Z or Enter triggers interaction. Sprite row order: Down=0, Up=1, Right=2, Left=3.
- `scripts/interactable.gd` - Area2D with @export label and @export dialogue_id; calls DialogueManager.start_dialogue(dialogue_id) on interact()
- `scripts/boot.gd` - Autoload; sets OS window to 1280x720 on startup
- `scripts/dialogue_manager.gd` - Autoload (DialogueManager); loads JSON dialogue by id from res://data/dialogue/; signals dialogue_started / dialogue_ended; advance(), get_current_line(), force_end()
- `scripts/cutscene_manager.gd` - Autoload (CutsceneManager); data-driven beat sequencer; beat types: wait, move, animation, dialogue, end; play_cutscene(beats, id), skip(); signals cutscene_started(id) / cutscene_ended; sets cutscene_active flag
- `scripts/cutscene_skip.gd` - Autoload (CutsceneSkip); persists seen cutscenes to user://seen_cutscenes.json; has_seen(id), mark_seen(id); shows "[ Z ] Skip" label (CanvasLayer) when cutscene is skippable; Z key triggers CutsceneManager.skip()
- `scripts/opening_cutscene.gd` - Node2D script attached to OpeningCutscene in workshop.tscn; builds beats array and calls CutsceneManager.play_cutscene("opening"); calls CutsceneSkip.mark_seen on completion
- `scripts/dialogue_box.gd` - Panel script; connected to DialogueManager signals; shows/hides box; handles Z/Enter via _unhandled_input to advance
- `scripts/cat_sprite.gd` - Sprite2D script; generates a 16x16 orange-tan placeholder texture at runtime
- `scenes/dialogue_box.tscn` - CanvasLayer > Panel (320x60, anchored bottom); Portrait TextureRect 32x32; SpeakerName Label; DialogueText RichTextLabel; dark panel with light border; hidden by default
- `data/dialogue/` - JSON files: workbench_inspect, table_inspect, crate_inspect, cat_interact, opening_workbench, opening_table, opening_calendar, opening_date_shout, opening_voices, opening_nine_days, opening_depart
- Four interactables in workshop: Workbench (48,64), Table (160,96), Crate (256,160), Cat (180,96 - orange-tan placeholder)
- `TileMapLayer` has tile_set assigned (workshop_tileset.tres) and room painted

## Pending / On the Horizon
- Phase 2 Foundations build (BUILD_PLAN §8) - the next code session: GameState flags, SaveManager, Inventory/items, dialogue schema v2 + migration of the 11 existing JSON files, cutscene-beats-as-data, Weirdness autoload skeleton, test harness (tools/check.bat). Built to Docs/ENGINEERING_CONSTRAINTS.md; no content.
- Pre-build design TODOs 1-7 (BUILD_PLAN §3) and the weirdness-system spec (BUILD_PLAN §5) - both are design sessions, not build sessions.
- Act One writing list (BUILD_PLAN §4), Latch and Brindle first; gates phases 3-7. Includes mob roster, resource list, item-tag taxonomy, recipes (§4.9).
- Author The List's full 15-20 entries (Docs/06) - framing + 4 tone-reference samples locked, full list outstanding.
- OPEN, cannot be closed by a session: EC-12a - read the Seliel the Shaper Mana Seed EULA and record the ruling in Docs/ENGINEERING_CONSTRAINTS.md §12. Blocks any AI use of licensed assets as input or style reference.
- Regional-lock reason and unlock event [U2-2] still OPEN; needed before phase 7.
- Reconcile Docs/00-06 status tags fully against Docs/handoff/MOSTLY_DECISION_LEDGER.md over time; the ledger remains the standing authority.

## Key Conventions
- GDScript only, no C#
- Nearest neighbor filtering on all sprites
- Viewport: 320x180, stretch mode: canvas_items