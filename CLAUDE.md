# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 8 complete: title/continue flow, The Turning's full anchor graph, and the anchor-and-fill generator spike. **Definition of done is `tools\check.bat` exits 0**, now four steps: engine import (regenerates the class-name cache typed tests need), `tests/validate_data.gd` (17 categories), `tests/run_tests.gd`, and `tools/generator_sweep.gd` (1000 seeds per region through the graph validator, ~115 ms). Current verified state: **164 tests passing, 0 failed** (153 at session start); sweep `hold` and `turning` both 1000/1000 valid. Godot resolved from $GODOT, then PATH, then C:\Godot\Godot_v4.6.2-stable_win64_console.exe. Remote https://github.com/adamgtyson/mostly.git (main); all session 7-8 commits local and unpushed.

**Unresolved working-tree note:** `project.godot` carries an uncommitted, out-of-session edit — `config/features` bumped "4.6" → "4.7" by an editor re-save. Left untouched and uncommitted for Adam's decision; the build pipeline still runs 4.6.2 and is green.

Autoloads (§13 roster, closed; only Battle remains, phase 5): `Boot`, `GameState`, `SaveManager`, `Inventory`, `DialogueManager`, `CutsceneManager`, `CutsceneSkip`, `SceneRouter`, `Weirdness`.

New or materially changed this session (sessions 5-7 entries otherwise stand):
- `scenes/title.tscn` + `scripts/title.gd` - title screen (assumed ruling, Adam may veto): Continue shown exactly when a save exists, resumes the newest slot by timestamp through the §3 generic restore, departs through the §6 choke point to the saved area's default spawn; New Game opens the session-7 selection screen. `Boot` routes every windowed boot to the title (session 7's save-sniffing rule removed); script-driven SceneTrees are never routed. Flagged, not special-cased: Continue goes through `go_to`, so the EC-6a misroute hook technically applies to a load at high intensity.
- `regions/turning/` - all four Act One anchors declared (turning_crossing, north_office, still_point, abbey) with placeholder areas (group `placeholder`, Exit back to the crossing) and `edges[]` chaining them, so the generator consumes the real graph. Phases 4-5 replace the placeholder scenes with content.
- `scripts/generator/` - the `[G3]` spike: `MapGraph` (nodes/edges/warnings, reachability, to_json/from_json, `resolve_default_areas()` - the EC-7 v1 bridge, exercised but consumed by nobody), `RegionGenerator.generate(region_json, config, seed)` (anchors first in declared order; via_slot chains clamped to the touchpoint band; endpoint slots materialise as single terminal fill nodes; plain edges direct; one seeded RNG, byte-identical output per seed; fill `name` always null - settlement pools are writing-track), `GraphValidator` (entry reachability, orphan slots, chain bounds, required_exits, connectivity; all errors reported). All `RefCounted`, headless by construction. No scenes, no tiles, no SceneRouter changes.
- `data/generator/config.json` (+schema, validator-registered) - the ten `[F19]` biomes verbatim; touchpoint distance bands; region biome pools carrying all ten biomes rather than inventing a mapping; `chain_link_count` 5 (CANON's five human links; `[G4]` said 4 - cited, not ruled); `village_route_variation` empty, OPEN. Every number PLACEHOLDER `[G4]`.
- `regions/hold/region.json` - edges: workshop→hobbs_village direct (the road is phase-3/4 content) and workshop→dev_weirdness_test (endpoint slot; also keeps the dev slot from being an orphan).
- `tools/generator_sweep.gd` + `tools/check.bat` step 4/4 - 1000 seeds per region, every failing seed reported, assertions never relaxed.
- `Docs/GENERATOR_SPIKE.md` - the build record: algorithm as implemented, config placeholders mapped to `[G4]`, what is deliberately not built, sweep output, three open questions (touchpoint-type wiring vs EC-7's closed shape; pool precedence and where bleed lives; what a fill node becomes at scene level). Ledger G3's Notes cell records "BUILT as spike (session 8) - scene driving not built"; its Status column is untouched.
- `tests/` - test_title (3), test_generator (8, incl. byte-identical determinism and 1000 Hold seeds in 18 ms against a 5s bar).

## Pending / On the Horizon
- Manual windowed check (grew this session): boot → title (Continue hidden on a fresh install) → New Game → gender → village → workshop → opening plays; the cat visibly rendered; then save, reboot, Continue resumes.
- `project.godot` 4.6→4.7 features bump, uncommitted, not this session's edit: Adam decides - commit it (moving the project to 4.7) or discard it (4.6.2 stays the build engine). Mixed-editor churn risk until settled.
- Adam to veto or keep two assumed rulings: the minimal title screen (Block A), and Continue routing through the §6 choke point, which leaves the EC-6a misroute hook technically applicable to a load at high intensity.
- The three GENERATOR_SPIKE.md open questions - design session material, likely alongside the `[G4]` numbers. `[G3]`'s own spec text was not found in Docs/handoff/ (only its ledger/history description); if Adam has it elsewhere, reconcile the spike against it.
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