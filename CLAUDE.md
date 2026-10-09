# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 10 complete: the menu screens render correctly in the 320×180 canvas. **Definition of done is `tools\check.bat` exits 0**, five steps: engine import, `tests/validate_data.gd` (17 categories), `tests/run_tests.gd`, `tools/generator_sweep.gd` (1000 seeds/region), `tools/smoke.bat` (real headless boot). Current verified state: **174 tests passing, 0 failed**; sweep 1000/1000 both regions; smoke verdict healthy. Godot 4.6.2. Remote https://github.com/adamgtyson/mostly.git (main); sessions 1-9 pushed, session 10's commits local and unpushed.

**L5 is CLOSED:** the cat placeholder is confirmed visible windowed (Adam, 2026-10-09), and the placeholder-visibility test keeps it that way. Session 9's boot fix is likewise windowed-confirmed — the remaining windowed bug session 10 fixed was the menu screens laying out in window coordinates with the default 16px font inside the 320×180 canvas (title in a corner, New Game ~4x too large and clipped).

Autoloads (§13 roster, closed; only Battle remains, phase 5): `Boot`, `GameState`, `SaveManager`, `Inventory`, `DialogueManager`, `CutsceneManager`, `CutsceneSkip`, `SceneRouter`, `Weirdness`.

New or materially changed this session (sessions 5-9 entries otherwise stand):
- `ui/ui_theme.tres` - the shared UI theme: default font at size 8 (the dialogue box's size; no font files while EC-12a is OPEN), buttons ~13px tall with 4/2 padding, a bright-border focus style legible at 4x window scale, dialogue-box palette. Applied on both menu scene roots.
- `scenes/title.tscn` + `scripts/title.gd` - pure container layout inside Rect2(0,0,320,180): CenterContainer → VBox (title, tagline, Continue, New Game). The old one-shot PRESET_CENTER ran before the children existed, which is why "Mostly" drifted to a corner.
- `scenes/new_game.tscn` + `scripts/new_game.gd` - step 1 CenterContainer → VBox; step 2 MarginContainer → HBox of a **scrolling village list** (ScrollContainer, `follow_focus`: arrowing through the nine buttons scrolls the list — gamepad-reachable with zero custom input code; chosen over pagination) and a PanelContainer detail panel whose RichTextLabel scrolls long pro/con text instead of growing past 180px. No absolute positions anywhere.
- `tests/test_title.gd` / `tests/test_new_game.gd` - the canvas-discipline sweep: both screens instantiate in a real 320×180 SubViewport; every visible content Control sits fully inside the canvas (clip-aware for the scroll list), fonts ≤ 8, a Container parent owns every placement; the New Game sweep runs both steps plus the list focused to its last entry (85 asserts). The old layout fails both the font and bounds rules.
- `Docs/ENGINEERING_CONSTRAINTS.md` §13 - one unnumbered line (Adam numbers constraints): UI scenes lay out in 320×180 canvas coordinates with the shared theme; containers, not absolute positions; the bounds test enforces it.

## Pending / On the Horizon
- **Adam's windowed confirmation for session 10:** Run Project — the title centered in a small pixel-sized font, Continue only with a save; New Game fits on screen, all nine villages reachable by arrowing down the scrolling list, epigraph/pro/con readable in the side panel. (Session 9's boot fix and L5 are already confirmed.)
- Adam to veto or keep three assumed rulings: the minimal title screen (session 8), Continue through the choke point, and "loads and new-game starts never misroute" (session 9).
- The three GENERATOR_SPIKE.md open questions (touchpoint-type wiring vs EC-7's closed shape; pool precedence and where bleed lives; what a fill node becomes at scene level) - design session material alongside the [G4] numbers. [G3]'s own spec text was not found in Docs/handoff/; if Adam has it elsewhere, reconcile the spike against it.
- The session-10 UI constraint line in EC §13 is unnumbered, awaiting Adam's numbering.
- No pause menu yet; when one lands it must hold `sys.player_has_control` false (WEIRDNESS_SPEC §2) and use `ui/ui_theme.tres`.
- Phase 3 remainder (BUILD_PLAN §8), writing-gated: Patch's village + Last Post exteriors, Latch, Bell, gear reward; `data/villages/*: starting_items` empty until the Act One writing list lands.
- Phase 4: exterior NPCs (then `npc_wrong_frame`/`npc_line` fire in real areas), content for The Turning's placeholder anchors, Hobb's village real area + its actual name (BUILD_PLAN §4.6, TBD).
- PROPOSED ids and tuning (WEIRDNESS_SPEC §2.1/§1, `events.misroute` 0.04): each phase that builds a beat owns its real flag id and reconciles curve.json + flags.json + test_act1_walkthrough.
- OPEN, cannot be closed by a session: EC-12a - read the Seliel the Shaper Mana Seed EULA, record in EC §12. Blocks any AI use of licensed assets; placeholders (and the default-font UI) stay programmatic until then.
- Regional-lock reason and unlock event [U2-2] still OPEN - `PH_turning_locked` is the refusal line; the walkthrough's post-letter assertion is PENDING on it. Needed before phase 7.
- Act One writing list (BUILD_PLAN §4), Latch and Brindle first; gates phases 3-7. Includes mob roster, resource list, item-tag taxonomy, recipes (§4.9) - `data/tags.json` holds only PH_ placeholders. §4.12: flicker lines done; item names, quest-log entries, pause/menu copy still **none** (title and New Game chrome is placeholder text pending §4.12).
- Act 2 consequence map (quest → world delta), per ledger L1 and EC Appendix B: required before any Act 2 content.
- Author The List's full 15-20 entries (Docs/06).
- The relocated area is still `regions/hold/areas/workshop.tscn`; the §6 `<village>_workshop` pattern (L4) waits on the per-village exterior work.
- Battle is the last §13 autoload, phase 5; contributes the save envelope's `party` key (ledger L3).
- Ledger L2 OPEN (future idea, post-ship): the sim-style second product. No work before Mostly v1 ships.
- Reconcile Docs/00-06 status tags against the ledger over time; the ledger remains the standing authority.

## Key Conventions
- GDScript only, no C#
- Nearest neighbor filtering on all sprites
- Viewport: 320x180, stretch mode: canvas_items