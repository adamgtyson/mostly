# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 3 complete; engine/scene state unchanged this session (docs-only sync). Godot 4.6.2 project at C:\Projects\Mostly. Window opens at 1280×720 (4× the 320×180 viewport) via Boot autoload. Project is under git version control, pushed to https://github.com/adamgtyson/mostly.git (main branch). Docs/handoff/ (9 files: MOSTLY_CANON, MOSTLY_STORY_STATE, MOSTLY_DESIGN_HISTORY, MOSTLY_OPEN_QUESTIONS, MOSTLY_COLLABORATION_GUIDE, PROMPT_WORKSHOP_HANDOFF, MIGRATION_WARNINGS, MOSTLY_DECISION_LEDGER, MOSTLY_ACT1_BUILD_PLAN) is now the authoritative layer over Docs/00–06 — each of Docs/00–06 carries a supersession notice pointing to it. Corrections applied to Docs/00–06: two "(locked)" tags marked PROVISIONAL/unconfirmed (two-sounds irony in Docs/05, List module-append framing in Docs/02); delivery window superseded (five days → eight days on the order form, nine days worked, Docs/02); opening-sequence cart-build beats marked REJECTED — Patch owns a horse and wagon (Docs/02); casual acquaintance resolved to Brindle, trader, of Near Enough (Docs/02, Docs/06); gate guard resolved to Latch (Docs/06); sober monk resolved to Fletch (female Patch) / Brace (male Patch, provisional) (Docs/05); cross-references renumbered (Document 5/6 fixes in Docs/02, Docs/04); Docs/06 decisions table gained a Handoff ledger row; Docs/00 engine-confirmation item resolved to Godot 4.6.2. No engine/scene changes.

- `scenes/workshop.tscn` — 20×15 tile room (320×240 px); StaticBody2D walls; 2-tile door opening on south wall; Camera2D clamped to room bounds (0,0)–(320,240). Player starts at (48,64). OpeningCutscene node triggers cutscene on load.
- `scripts/player.gd` — CharacterBody2D (Patch); WASD + arrow 4-direction movement at 80 px/s; movement and interaction locked while dialogue OR cutscene is active; Z or Enter triggers interaction. Sprite row order: Down=0, Up=1, Right=2, Left=3.
- `scripts/interactable.gd` — Area2D with @export label and @export dialogue_id; calls DialogueManager.start_dialogue(dialogue_id) on interact()
- `scripts/boot.gd` — Autoload; sets OS window to 1280×720 on startup
- `scripts/dialogue_manager.gd` — Autoload (DialogueManager); loads JSON dialogue by id from res://data/dialogue/; signals dialogue_started / dialogue_ended; advance(), get_current_line(), force_end(); force_end() added for cutscene skip support
- `scripts/cutscene_manager.gd` — Autoload (CutsceneManager); data-driven beat sequencer; beat types: wait, move, animation, dialogue, end; play_cutscene(beats, id), skip(); signals cutscene_started(id) / cutscene_ended; sets cutscene_active flag
- `scripts/cutscene_skip.gd` — Autoload (CutsceneSkip); persists seen cutscenes to user://seen_cutscenes.json; has_seen(id), mark_seen(id); shows "[ Z ] Skip" label (CanvasLayer) when cutscene is skippable; Z key triggers CutsceneManager.skip()
- `scripts/opening_cutscene.gd` — Node2D script attached to OpeningCutscene in workshop.tscn; builds beats array and calls CutsceneManager.play_cutscene("opening"); calls CutsceneSkip.mark_seen on completion
- `scripts/dialogue_box.gd` — Panel script; connected to DialogueManager signals; shows/hides box; handles Z/Enter via _unhandled_input to advance
- `scripts/cat_sprite.gd` — Sprite2D script; generates a 16×16 orange-tan placeholder texture at runtime
- `scenes/dialogue_box.tscn` — CanvasLayer > Panel (320×60, anchored bottom); Portrait TextureRect 32×32; SpeakerName Label; DialogueText RichTextLabel; dark panel with light border; hidden by default
- `data/dialogue/` — JSON files: workbench_inspect, table_inspect, crate_inspect, cat_interact, opening_workbench, opening_table, opening_calendar, opening_date_shout, opening_voices, opening_nine_days, opening_depart
- Four interactables in workshop: Workbench (48,64), Table (160,96), Crate (256,160), Cat (180,96 — orange-tan placeholder)
- `TileMapLayer` has tile_set assigned (workshop_tileset.tres) and room painted

## Pending / On the Horizon
- Session 4: typewriter text effect, portrait textures, inventory scaffolding
- Village exterior scene
- Road / gate scene with Latch (gate guard)
- Assign real portrait textures to dialogue lines (patch_default → actual Patch portrait sprite)
- Author The List's full 15–20 entries (Docs/06) — framing + 4 tone-reference samples locked, full list outstanding, needed before Act Two content build-out
- Reconcile Docs/00–06 status tags fully against Docs/handoff/MOSTLY_DECISION_LEDGER.md over time (this session applied the enumerated corrections only; the ledger remains the standing authority for anything not yet folded back into the numbered docs)

## Key Conventions
- GDScript only, no C#
- Nearest neighbor filtering on all sprites
- Viewport: 320x180, stretch mode: canvas_items