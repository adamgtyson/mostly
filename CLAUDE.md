# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 1 complete. Godot 4.6.2 project at C:\Projects\Mostly. Window opens at 1280×720 (4× the 320×180 viewport) via Boot autoload.

- `scenes/workshop.tscn` — 20×15 tile room (320×240 px); StaticBody2D walls; 2-tile door opening on south wall; Camera2D clamped to room bounds (0,0)–(320,240)
- `scripts/player.gd` — CharacterBody2D (Patch); WASD + arrow 4-direction movement at 80 px/s; AnimatedSprite2D idle+walk built at runtime from char_a_p1_0bas_humn_v00.png; Z or Enter triggers interaction. Sprite row order: Down=0, Up=1, Right=2, Left=3.
- `scripts/interactable.gd` — Area2D with @export label; prints label to console on interact()
- `scripts/boot.gd` — Autoload; sets OS window to 1280×720 on startup
- Three interactables placed with sprites from cozy_furnishings_sampler.png and StaticBody2D physics blockers: Workbench (48,64), Table (160,96), Crate (256,160)
- `TileMapLayer` present but NO tile_set assigned — configure in Godot editor using `assets/tilesets/home_interiors_timber_roof.png`

## Pending / On the Horizon
- Configure TileMapLayer TileSet in Godot editor and paint the workshop room
- Test Z/Enter interaction on all three objects (prints label to Output panel)
- Session 2: dialogue system, inventory, UI
- Village exterior scene
- Road / gate scene

## Key Conventions
- GDScript only, no C#
- Nearest neighbor filtering on all sprites
- Viewport: 320x180, stretch mode: canvas_items