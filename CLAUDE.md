# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 2 complete. Godot 4.6.2 project at C:\Projects\Mostly. Window opens at 1280×720 (4× the 320×180 viewport) via Boot autoload.

- `scenes/workshop.tscn` — 20×15 tile room (320×240 px); StaticBody2D walls; 2-tile door opening on south wall; Camera2D clamped to room bounds (0,0)–(320,240)
- `scripts/player.gd` — CharacterBody2D (Patch); WASD + arrow 4-direction movement at 80 px/s; movement locked while dialogue is active; Z or Enter triggers interaction (guarded against double-fire with dialogue). Sprite row order: Down=0, Up=1, Right=2, Left=3.
- `scripts/interactable.gd` — Area2D with @export label and @export dialogue_id; calls DialogueManager.start_dialogue(dialogue_id) on interact()
- `scripts/boot.gd` — Autoload; sets OS window to 1280×720 on startup
- `scripts/dialogue_manager.gd` — Autoload (DialogueManager); loads JSON dialogue by id from res://data/dialogue/; signals dialogue_started / dialogue_ended; tracks current line; advance() and get_current_line(); sets dialogue_active flag
- `scripts/dialogue_box.gd` — Panel script; connected to DialogueManager signals; shows/hides box; handles Z/Enter via _unhandled_input to advance
- `scripts/cat_sprite.gd` — Sprite2D script; generates a 16×16 orange-tan placeholder texture at runtime
- `scenes/dialogue_box.tscn` — CanvasLayer > Panel (320×60, anchored bottom); Portrait TextureRect 32×32; SpeakerName Label; DialogueText RichTextLabel; dark panel with light border; hidden by default
- `data/dialogue/` — JSON dialogue files: workbench_inspect, table_inspect, crate_inspect, cat_interact
- Four interactables in workshop: Workbench (48,64), Table (160,96), Crate (256,160), Cat (180,96 — orange-tan placeholder, no external PNG required)
- `TileMapLayer` has tile_set assigned (workshop_tileset.tres) and room painted

## Pending / On the Horizon
- Session 3: typewriter text effect, portrait textures, inventory
- Village exterior scene
- Road / gate scene
- Assign real portrait textures to dialogue lines (patch_default → actual Patch portrait sprite)

## Key Conventions
- GDScript only, no C#
- Nearest neighbor filtering on all sprites
- Viewport: 320x180, stretch mode: canvas_items