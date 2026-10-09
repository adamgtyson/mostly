# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 9 complete: the real-boot gray-box bug is diagnosed, fixed and regression-proofed. **Definition of done is `tools\check.bat` exits 0**, now five steps: engine import, `tests/validate_data.gd` (17 categories), `tests/run_tests.gd`, `tools/generator_sweep.gd` (1000 seeds/region), and `tools/smoke.bat` — a real headless boot (autoloads, main scene, no hand-instantiated scenes) that prints a `[smoke]` state block and fails on a null/area/invisible current_scene. Current verified state: **172 tests passing, 0 failed** (164 at session start); sweep 1000/1000 both regions; smoke verdict healthy. Godot 4.6.2 (an external editor's 4.7 features bump was discarded per instruction; the project stays 4.6.2). Remote https://github.com/adamgtyson/mostly.git (main); sessions 1-8 pushed, session 9's commits local and unpushed.

The bug, proven by the smoke harness before fixing: `run/main_scene` was the workshop area; the engine instantiated it, Boot swapped to the title one deferred call later, and the freed workshop's queued `CutsceneTrigger.play()` ran off-tree — the null-tree crash. Headless the title still landed, so the windowed gray box was not a tree-state failure; **Adam confirms the windowed leg** (expected on Run Project in the 4.6.2 editor: the title screen, no red in Output).

Autoloads (§13 roster, closed; only Battle remains, phase 5): `Boot`, `GameState`, `SaveManager`, `Inventory`, `DialogueManager`, `CutsceneManager`, `CutsceneSkip`, `SceneRouter`, `Weirdness`.

New or materially changed this session (sessions 5-8 entries otherwise stand):
- `project.godot` - `run/main_scene` is `scenes/title.tscn` (the only change to the file). Boot's swap is deleted: no pre-route frame exists, areas are reached only through SceneRouter, and an F6-run of an area scene is left alone.
- `scripts/boot.gd` - window setup plus the smoke mode: `--smoke` user arg only, `--smoke-frames=N` override, prints main_scene/current_scene/root children/per-autoload `debug_summary()`/visible-CanvasItem count/tree, exits 0 healthy or 2 on a null, area, or invisible current_scene; internal 25s deadline. `tools/smoke.bat` wraps it with a 30s PowerShell watchdog (124 on hang).
- `scripts/cutscene_trigger.gd` - safe off-tree: `play()` returns quietly without a tree, and `_condition_holds()` resolves flags through the GameState singleton, never `get_tree().root` (§5: conditions resolve flags, not nodes). `data/cutscenes/PH_smoke_blip.json` is a one-beat harness cutscene so tests can prove a trigger starts without playing the opening.
- `scripts/scene_router.gd` - `go_to(..., misroute_eligible := true)` (session 9 assumed ruling, Adam may veto): a misroute is a property of walking through an Exit — the Continue path passes false, and `new_game()` arms a one-shot exemption consumed by the next transition, so the New Game departure is covered with no selection-screen coupling. `Weirdness.roll()` counts consultations per event (debug state, reset-cleared) and the test proves zero rolls on loads and new-game starts under a rigged 100% misroute chance.
- `debug_summary()` on Boot, SceneRouter, CutsceneManager, DialogueManager, Weirdness - one state line each for the smoke block.
- Warnings: boot.gd integer division annotated (whole-pixel centring is the intent); flicker_handlers.gd:90 ternary branches now both String. Remaining cosmetic warnings (inventory, dialogue_manager, scene_router shadowing) deliberately left.
- `tests/` - test_boot (3: main scene never an area, smoke-arg parsing, no swap on scripted trees), test_cutscene_trigger (4, incl. the off-tree crash state), the no-misroute-on-load test in test_scene_router (real travels through the choke point, trigger gated off, scratch saves dir).

## Pending / On the Horizon
- **Adam's windowed confirmation:** Run Project in the 4.6.2 editor should show the title screen with no red in Output; then the full manual pass (New Game → gender → village → workshop → opening plays; cat visible; save; reboot; Continue resumes — now guaranteed misroute-free).
- Adam to veto or keep three assumed rulings: the minimal title screen (session 8), Continue through the choke point, and session 9's "loads and new-game starts never misroute" (`misroute_eligible` + the one-shot new_game exemption).
- If the gray box persists windowed after this fix, the remaining suspect is the embedded Game-tab window vs Boot's `window_set_size/position` - headless cannot test that interaction; diagnose in the editor with the smoke block's tree as the known-good reference.
- The three GENERATOR_SPIKE.md open questions (touchpoint-type wiring vs EC-7's closed shape; pool precedence and where bleed lives; what a fill node becomes at scene level) - design session material alongside the [G4] numbers. [G3]'s own spec text was not found in Docs/handoff/; if Adam has it elsewhere, reconcile the spike against it.
- No pause menu yet; when one lands it must hold `sys.player_has_control` false (WEIRDNESS_SPEC §2) like dialogue and cutscenes do.
- Phase 3 remainder (BUILD_PLAN §8), writing-gated: Patch's village + Last Post exteriors, Latch, Bell, gear reward; `data/villages/*: starting_items` empty until the Act One writing list lands.
- Phase 4: exterior NPCs (then `npc_wrong_frame`/`npc_line` fire in real areas), content for The Turning's placeholder anchors, Hobb's village real area + its actual name (BUILD_PLAN §4.6, TBD).
- PROPOSED ids and tuning (WEIRDNESS_SPEC §2.1/§1, `events.misroute` 0.04): each phase that builds a beat owns its real flag id and reconciles curve.json + flags.json + test_act1_walkthrough.
- OPEN, cannot be closed by a session: EC-12a - read the Seliel the Shaper Mana Seed EULA, record in EC §12. Blocks any AI use of licensed assets; placeholders stay programmatic until then.
- Regional-lock reason and unlock event [U2-2] still OPEN - `PH_turning_locked` is the refusal line; the walkthrough's post-letter assertion is PENDING on it. Needed before phase 7.
- Act One writing list (BUILD_PLAN §4), Latch and Brindle first; gates phases 3-7. Includes mob roster, resource list, item-tag taxonomy, recipes (§4.9) - `data/tags.json` holds only PH_ placeholders. §4.12: flicker lines done; item names, quest-log entries, pause/menu copy still **none** (title and New Game screens carry placeholder chrome pending §4.12).
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