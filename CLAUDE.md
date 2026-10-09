# Mostly — Claude Code Project File

## Project Overview
16-bit top-down RPG in Godot 4.6.2. Mana Seed asset collection (16x16 tiles).
Full design documentation in /Docs/. Read 00_QUICK_REFERENCE.md at the start of every session.
Do not invent names, places, or mechanics not found in the docs. Ask first.

## Current Build State
Session 7 complete: **docs only** — no engine, scene, script, or data changes. `Docs/WEIRDNESS_SPEC.md` (the BUILD_PLAN §5 design session output) is now in the doc set, decision-ledger section M carries its eight rulings (M-1…M-8, all LOCKED; tuning values and the §2.1 flag ids stay PROPOSED until each build phase names its beat flags), and the spec is propagated: EC §7 gains the M-4 anchor-level `weirdness_override` amendment, EC §10 points at the spec for curve/catalog/line pool, BUILD_PLAN §3 TODO 7 is RESOLVED and §4.12 flicker lines moved **none → exists** (19 lines), CANON §4.8 carries the Act One world-break definition (M-5), and QUICK_REFERENCE lists the spec among the authoritative documents. `Docs/handoff/MOSTLY_DECISION_LEDGER.md` now ends at section M and remains the standing authority.

`tools\check.bat` was run twice this session — before and after the edits — and exits 0 both times: 15 validator categories clean, **124 tests passing, 0 failed**. Nothing under `data/`, `scripts/`, `scenes/`, `regions/` or `tests/` was touched: WEIRDNESS_SPEC §8.1 holds the weirdness data at its placeholder values until phase 3 so the validator stays green.

Build state is otherwise unchanged from session 5 (Phase 2 Foundations, built to Docs/ENGINEERING_CONSTRAINTS.md). Godot 4.6.2 at C:\Projects\Mostly; engine on this machine is C:\Godot\Godot_v4.6.2-stable_win64_console.exe. Window 1280x720 (4x the 320x180 viewport) via Boot. Remote is https://github.com/adamgtyson/mostly.git (main); session 6 **is** pushed (origin/main was at the session-6 commit when session 7 opened — CLAUDE.md's earlier "not pushed" note was stale). Session 7's three commits are local and unpushed.

**Definition of done is `tools\check.bat` exits 0** (§11). It runs, stopping at first failure: engine import (`--headless --editor --quit`, which also regenerates the global class-name cache typed tests need) then `tests/validate_data.gd` then `tests/run_tests.gd`. Godot is resolved from $GODOT, then PATH, then the default install path.

Autoloads (§13 roster, closed; only Battle remains, phase 5): `Boot`, `GameState`, `SaveManager`, `Inventory`, `DialogueManager`, `CutsceneManager`, `CutsceneSkip`, `SceneRouter`, `Weirdness`.

- `scripts/game_state.gd` - flat flag store (§2); set_flag/get_flag/has_flag/increment, flag_changed. `data/flags.json` is the mandatory registry; the validator rejects any undeclared reference.
- `scripts/save_manager.gd` - manual slots + autosave (§3). Contributors are discovered generically, so adding a system never edits it; SaveManager owns the envelope (schema_version/timestamp/playtime_s), contributors own sections. Refuses to save mid-dialogue/cutscene/battle; refuses a newer schema; migration table with a v1 identity step. The `party` section arrives with Battle in phase 5 (ledger L3, §3 amendment).
- `scripts/inventory.gd` - shared bag + per-member equipment (§4); items load from `data/items/*.json`; `on_use` effect registry (set_flag wired; heal/apply_buff are phase-5 stubs). `weight` required on every item; limits apply only under `sys.realistic_weight` (EC-4a).
- `scripts/dialogue_manager.gd` - dialogue schema v2 (§5): node graph, entries first-match-wins, set[] on entry, conditional choices, gender tokens with `text_f` escape hatch, speakers resolved through `data/characters.json`. Still accepts the v1 flat shape.
- `scripts/condition.gd` - the one condition parser (§5). No Expression, no eval. Also feeds the validator's flag-reference check.
- `scripts/cutscene_manager.gd` - beats as data (§8) from `data/cutscenes/*.json`; vocabulary extended with set_flag, camera, fade, sfx, spawn, despawn, choice, emit. Actors are node paths resolved at play time. Phase 3/4 add a `stagger` beat type and the `overt: true` tag that fires the tell hook (WEIRDNESS_SPEC §8).
- `scripts/cutscene_trigger.gd` - generic replacement for per-cutscene scripts; exported `cutscene_id` and a `when` condition. `scripts/opening_cutscene.gd` is deleted.
- `scripts/scene_router.gd` - the single transition choke point (§6): fade, threaded load, spawn placement, autosave. Enforces `region.<id>.unlocked`; calls `Weirdness.set_region()`; misroute hook guarded to unlocked, already-visited areas (EC-6a). Phase 3 adds the area-level `weirdness_override` (M-4).
- `scripts/weirdness.gd` - skeleton (§10). `intensity` is derived and never saved; scheduler, catalog selection, anti-repeat ring, debug buffer, `roll(event)`. Curve/catalog still ship flagged placeholders and the one catalog kind is `v1: false`, so nothing fires yet; Docs/WEIRDNESS_SPEC.md §8 is the delta phases 3-4 implement.
- `scripts/area.gd` / `scripts/exit.gd` / `scripts/flicker_spot.gd` - area root (spawns, used_rect, self-registration), Exit nodes, flicker markers.
- `scripts/game_config.gd`, `scripts/json_schema.gd` - shared classes (not autoloads): config reader, and a small JSON-Schema subset validator (§11 mandates no framework).
- `regions/hold/` - the first region package: `region.json` in the §7 generator-output shape (workshop as its one anchor, empty fill_slots/edges) and `areas/workshop.tscn`, relocated from `scenes/workshop.tscn`. Camera bounds unchanged.
- `data/` - config.json, flags.json, tags.json, characters.json, items/ (3 PH_ fixtures), dialogue/ (11 files, all v2), cutscenes/opening.json, weirdness/{curve,catalog}.json, schema/ (7 schemas), i18n/keys.json (generated).
- `assets/manifest.json` - covers all 3 art files; all `placeholder` with unverified licence pending EC-12a.
- `tools/` - check.bat, check.sh, and the two one-shot migration scripts (both idempotent/re-runnable).
- `Docs/WEIRDNESS_SPEC.md` - the Act One weirdness system: six v1 flicker kinds, the 8-rung intensity ladder, 300s/45s bounds with ±10s jitter, regional multipliers (Hold 1.0 / Turning 1.5 / Hobb's village 0), stagger and tell definitions, seven deniability rules, the 19-line `npc_line` pool, and the §8 implementation contract. Ledger §M.

Migration parity is enforced by tests, not asserted: 11 dialogue files render identically to a fixture captured from the v1 files before migration (26 lines), and the opening cutscene's 30 beats load back exactly as the deleted script produced them.

## Pending / On the Horizon
- Known issue [L5]: the cat placeholder sprite is not visible in the workshop scene after the session-5 relocation (likely `cat_sprite.gd` node path or `_ready` draw). Fix in the next build prompt. The phase 8 playtest checklist must include "every placeholder is visibly rendered" — invisible-but-loading passes every automated check.
- Manual check still outstanding from session 5: boot the game and watch the opening play as before. Headless boot is clean (400 frames, no errors), but nothing has verified it visually.
- Phase 3 (BUILD_PLAN §8): Patch's village + Last Post - exterior, Latch, Bell, gear reward, nine-village selection screen (data-driven), region lock in place. Needs `data/villages/<id>.json` (§4 starting_items/starting_flags), which Foundations did not build. Phase 3 also owns the first weirdness build slice per WEIRDNESS_SPEC §8/§11: real curve and catalog values, `data/weirdness/lines.json`, the `FlickerHandlers` registry, jitter/arrival-grace/global-floor, area-level `weirdness_override`, the tell hook, and the `stagger` cutscene beat. Phase 4 adds `npc_wrong_frame` and `npc_line` once exterior NPCs exist.
- WEIRDNESS_SPEC §2.1 flag ids are PROPOSED: each phase that builds a beat owns the real flag id and must reconcile the ladder table and `data/flags.json`. The spec's §1 tuning numbers (min_intensity / weight / cooldown) and the 0.04 misroute base are PROPOSED too.
- The relocated area is `regions/hold/areas/workshop.tscn`; §6 names the pattern `<village>_workshop.tscn`. Renaming waits on village selection in phase 3 (ledger L4, now a §6 amendment).
- Pre-build design TODOs (BUILD_PLAN §3) still open: 1-6 and 8-11 - design sessions. TODO 7 (weirdness) is RESOLVED by Docs/WEIRDNESS_SPEC.md.
- Act One writing list (BUILD_PLAN §4), Latch and Brindle first; gates phases 3-7. Includes mob roster, resource list, item-tag taxonomy, recipes (§4.9) - `data/tags.json` holds only PH_ placeholders. §4.12 flicker lines are now done; the rest of §4.12 system text is still **none**.
- Act 2 consequence map (quest → world delta), per ledger L1 and ENGINEERING_CONSTRAINTS Appendix B: a required deliverable before any Act 2 content. Act 1 side quests persist into later acts as world deltas; no counter, no visible timer, no fail state.
- Author The List's full 15-20 entries (Docs/06).
- OPEN, cannot be closed by a session: EC-12a - read the Seliel the Shaper Mana Seed EULA and record the ruling in Docs/ENGINEERING_CONSTRAINTS.md §12. Blocks any AI use of licensed assets.
- Regional-lock reason and unlock event [U2-2] still OPEN; needed before phase 7.
- `sys.patch_gender` defaults to masculine when unset - an engineering fallback, not a canon default. The New Game screen (phase 3) should set it explicitly.
- Battle is the last autoload on the §13 roster and arrives in phase 5; it will also contribute the save envelope's `party` key.
- Ledger L2 is OPEN (future idea, post-ship): a sim-style game set in the same world as a possible second product. No work before Mostly v1 ships.
- Reconcile Docs/00-06 status tags against Docs/handoff/MOSTLY_DECISION_LEDGER.md over time; the ledger remains the standing authority.

## Key Conventions
- GDScript only, no C#
- Nearest neighbor filtering on all sprites
- Viewport: 320x180, stretch mode: canvas_items