# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 7 complete, in two halves. Docs: `Docs/WEIRDNESS_SPEC.md` is in the doc set, decision-ledger §M carries its eight rulings (M-1…M-8 LOCKED; tuning values and the §2.1 flag ids stay PROPOSED), and the spec is propagated into EC §7/§10/Appendix B, BUILD_PLAN §3/§4.12/§5, CANON §4.8 and QUICK_REFERENCE. Build: the weirdness system is implemented to WEIRDNESS_SPEC §8, the invisible cat (L5) is fixed with a permanent placeholder-visibility test, the nine-village data and New Game screen exist (mechanics deferred), the Act One walkthrough skeleton holds the region locks, and The Turning region package skeleton is in place behind its lock. All commits local and unpushed; Adam pushes and runs Sync manually.

**Definition of done is `tools\check.bat` exits 0** (§11): engine import (regenerates the class-name cache typed tests need), then `tests/validate_data.gd`, then `tests/run_tests.gd`. Current verified state: **17 validator categories clean, 153 tests passing, 0 failed** (124 at session start). Godot resolved from $GODOT, then PATH, then C:\Godot\Godot_v4.6.2-stable_win64_console.exe. Window 1280x720 (4x the 320x180 viewport) via Boot. Remote https://github.com/adamgtyson/mostly.git (main).

Autoloads (§13 roster, closed; only Battle remains, phase 5): `Boot`, `GameState`, `SaveManager`, `Inventory`, `DialogueManager`, `CutsceneManager`, `CutsceneSkip`, `SceneRouter`, `Weirdness`.

New or materially changed this session (Foundations entries from session 5 otherwise stand):
- `scripts/weirdness.gd` - full WEIRDNESS_SPEC §8 scheduler: player-time clock gated on `sys.player_has_control`, ±10s jitter floored at 10s, 8s arrival grace, 10s global floor, area-level `weirdness_override` (M-4), `request_tell()`/`tell_requested` (Ambient-bus duck + `ambient_loop` pause; bus created at runtime), the 19-line no-repeat `take_line()` pool, and `params_for()` merging catalog entry with spot params.
- `scripts/flicker_handlers.gd` - `FlickerHandlers` registry (Inventory `on_use` pattern, not an autoload): six v1 handlers + `log`; programmatic placeholders only (in-memory ImageTexture / generated AudioStreamWAV) while EC-12a is OPEN; every spawned placeholder joins group `placeholder`; a handler that cannot draw warns and returns.
- `scripts/flicker_spot.gd` - `class_name FlickerSpot`, exported `params` documented per kind.
- `scripts/cutscene_manager.gd` / `scripts/dialogue_manager.gd` - own `sys.player_has_control` (transient, `persist: false`, never saved); `stagger` beat type with Seven Chickens' 0.3s/no-anim 80% variant and the GSP tell before `overt: true` beats.
- `scripts/scene_router.gd` - `on_area_entered` + anchor `weirdness_override` application after every transition and on boot registration; tell before a misroute.
- `scripts/game_state.gd` - `to_save_dict()` honours `persist: false`; `is_persistent()`.
- `scripts/cat_sprite.gd` - L5 fixed: `Image.create_empty` + RGBA8 (the deprecated `Image.create`+RGB8 upload was the last suspect standing after diagnosis eliminated scene data, lifecycle, cutscene and contrast), bordered-with-ears placeholder, group `placeholder`. Needs one windowed visual confirmation.
- `scripts/new_game.gd` + `scenes/new_game.tscn` - two-step New Game (gender -> village), data-driven from `data/villages/`, keyboard/gamepad only, writes `sys.patch_gender` and the village's `starting_flags`, unlocks the starting region, departs via config-named start. `Boot` routes a fresh launch (no save, no `sys.village`) to it; script-driven SceneTrees are never routed. The workshop's opening trigger is gated `when = "sys.village"` so the opening plays when a run begins, not during the pre-route frame.
- `data/` - `villages/` (nine canonical files, text verbatim from Docs/03; Seven Chickens obfuscated with `pro_text_hidden`), `weirdness/lines.json` (19 lines, M-8), curve.json (the eight-rung ladder totalling 1.0), catalog.json (six v1 kinds + four `v1:false`), `dialogue/PH_turning_locked.json`, schema/ now 9 schemas, flags.json 23 flags (8 critical; `act1.*` ladder + letter PROPOSED ids, six `region.<id>.unlocked`).
- `regions/hold/` - anchors: workshop + `hobbs_village` (`weirdness_override: 0.0`, placeholder scene); fill slot `dev_weirdness_test` -> `areas/weirdness_test.tscn` (one FlickerSpot per v1 kind, dev scene). `regions/turning/` - package skeleton, locked, `turning_crossing` anchor only (north_office/still_point/abbey arrive with phases 4-5).
- `tests/` - validate_data.gd has 17 categories (weirdness spec, villages, handler-name check, `persist` rule, curve flags as references); new suites: test_weirdness_spec (15), test_placeholders_visible (3 — the "every placeholder is visibly rendered" check), test_new_game (6), test_act1_walkthrough (4, post-letter assertion PENDING citing [U2-2] OPEN).

Deliberately-advanced test expectations this session (each reported, none silent): hold fill_slots 0→1 (dev area), hold anchors 1→2 (hobbs_village), dialogue file count frozen-11 → "the eleven migrated files all present by name".

## Pending / On the Horizon
- Manual visual check at next windowed boot: the new flow (fresh boot → New Game → gender → village → workshop → opening cutscene plays) and the cat visibly rendered. The L5 fix is verified headless from every angle; the windowed-renderer leg is the one thing only eyes can close.
- No title/continue flow exists: a boot with an existing save shows the workshop without loading the save (pre-existing gap, now more visible since fresh boots route to New Game). Phase 3/4 decision.
- Phase 3 remainder (BUILD_PLAN §8), writing-gated: Patch's village + Last Post exteriors, Latch, Bell, gear reward. `data/villages/*: starting_items` are empty until the Act One writing list lands. The nine-village selection screen itself is done (content-free slice).
- Phase 4: exterior NPCs (then `npc_wrong_frame`/`npc_line` fire in real areas), The Turning's remaining anchors (north_office, still_point, abbey), Hobb's village real area + its actual name (BUILD_PLAN §4.6, TBD).
- PROPOSED ids and tuning (WEIRDNESS_SPEC §2.1/§1, `events.misroute` 0.04): each phase that builds a beat owns its real flag id and reconciles curve.json + flags.json + test_act1_walkthrough (the ladder is asserted identical in both).
- OPEN, cannot be closed by a session: EC-12a — read the Seliel the Shaper Mana Seed EULA, record in EC §12. Blocks any AI use of licensed assets; placeholders stay programmatic until then.
- Regional-lock reason and unlock event [U2-2] still OPEN — now concretely load-bearing: `PH_turning_locked` is the refusal line, and the walkthrough's post-letter assertion is PENDING on it. Needed before phase 7.
- Act One writing list (BUILD_PLAN §4), Latch and Brindle first; gates phases 3-7. Includes mob roster, resource list, item-tag taxonomy, recipes (§4.9) — `data/tags.json` holds only PH_ placeholders. §4.12: flicker lines done; item names, quest-log entries, pause/menu copy still **none** (the New Game screen's chrome is placeholder text pending §4.12).
- Act 2 consequence map (quest → world delta), per ledger L1 and EC Appendix B: required before any Act 2 content.
- Author The List's full 15-20 entries (Docs/06).
- The relocated area is still `regions/hold/areas/workshop.tscn`; the §6 `<village>_workshop` pattern (L4) now waits on the per-village exterior work, since all nine starts currently share one workshop.
- `sys.patch_gender` is now set explicitly by the New Game screen; the masculine fallback remains only for runs that never passed through it.
- Battle is the last §13 autoload, phase 5; contributes the save envelope's `party` key (ledger L3).
- Ledger L2 OPEN (future idea, post-ship): the sim-style second product. No work before Mostly v1 ships.
- Reconcile Docs/00-06 status tags against the ledger over time; the ledger remains the standing authority.

## Key Conventions
- GDScript only, no C#
- Nearest neighbor filtering on all sprites
- Viewport: 320x180, stretch mode: canvas_items