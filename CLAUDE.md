# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 1 complete. Godot 4.6.2 project at C:\Projects\Mostly.

- `scenes/workshop.tscn` — 20×15 tile room (320×240 px); StaticBody2D walls; door opening 2 tiles wide on south wall
- `scripts/player.gd` — CharacterBody2D (Patch); WASD + arrow 4-direction movement at 80 px/s; AnimatedSprite2D with idle+walk per direction built at runtime from char_a_p1_0bas_humn_v00.png; Z or Enter triggers interaction
- `scripts/interactable.gd` — Area2D component; @export label printed to console on interact()
- Three interactables placed: Workbench (48,64), Table (160,96), Crate (256,160)
- Camera2D follows Player, clamped to room bounds (0,0)–(320,240)
- `TileMapLayer` in scene has NO tile_set assigned — must be configured in Godot editor using `assets/tilesets/home_interiors_timber_roof.png`

## Pending / On the Horizon
- Configure TileMapLayer TileSet in Godot editor and paint the workshop room
- Session 2: dialogue system, inventory, UI
- Village exterior scene
- Road / gate scene

## Key Conventions
- GDScript only, no C#
- Nearest neighbor filtering on all sprites
- Viewport: 320x180, stretch mode: canvas_items