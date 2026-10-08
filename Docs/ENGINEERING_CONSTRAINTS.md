# ENGINEERING_CONSTRAINTS.md — Locked Engineering Decisions for the Act One Build

**Version:** 2026-08-29. Output of the engineering-constraints session (MOSTLY_ACT1_BUILD_PLAN.md §6, phase 0). All thirteen agenda items were ruled on by Adam in this session; every ruling below is **LOCKED** (authority: user-confirmed — assistant proposed, Adam explicitly chose, including all stated qualifiers). Ledger IDs `[EC-n]` are to be appended to MOSTLY_DECISION_LEDGER.md as a new section K.

**How to read this document.** Claude Code (Fable) designs *within* these constraints; it does not choose them and does not relax them. Where an item says "config," the value lives in `data/config.json` with a flagged placeholder default, never as a literal in a script. Where an item says "validator," it means `tests/validate_data.gd` (§11). Anything marked OPEN is a gap this document cannot close and Fable must not close either — stop and ask.

Existing locked rulings this document depends on and does not reopen: precision smith, buys base gear, crafts mods `[B6]`; party max 3, Camp-only swaps `[E17]`; Fletch/Brace companions `[E18]`; forge network and no portable workbench `[G9]`; anchor-and-fill as hard requirement `[G2]`; Act One scope `[U2-1..U2-9]`; engine/format `[A13]`; build on Windows `[I1]`; docs edited only via docs-only prompts `[I4]`.

---

## 1. Combat model — LOCKED `[EC-1]`

- **Turn-based, strict turns (no ATB), fought in place on the overworld** (Chrono Trigger lineage). No separate battle scene, no transition. Enemies are visible in the world; contact starts a battle. **No random encounters.**
- Menu-driven: Attack / Item / Gadget / Companion ability / Flee. Companions are player-controlled through the menu; **no companion AI.**
- **HP is a single integer per combatant. There is no MP.** Patch's "magic" is crafted gadgets with charges (§4).
- Damage = flat weapon value ± `modifiers` from gear and status. **No stat-growth curves or levels in v1.** A `level` field may exist in data; no system reads it.
- Party of up to 3 per `[E17]`.
- **Flee always succeeds.** No penalty.
- Auto-battle toggle is a config flag (`combat.auto_battle_available`, default true).
- **Mobs are Forge side-effects, not monsters** — an author-level rule that is enforced as *data*: every entry in `data/mobs/*.json` must carry a non-empty `side_effect_of` string and a `modifiers[]` list (same shape as item modifiers, §4). The validator rejects a mob with `side_effect_of` empty. Mob design direction (Adam, this session; ledger `[EC-1a]`, user-authored): tongue-in-cheek naming and design — animated inanimate objects, weird pets, cryptids; each mob carries an *actual* gameplay side-effect modifier; the combinations of modifiers across the roster are what make the population feel diverse. The roster itself is a writing-track deliverable (BUILD_PLAN §4.9); Fable does not invent mobs.
- Battle is a pure state machine (`Battle` autoload) drivable headlessly with no physics or scene, so the walkthrough can fight scripted battles.

## 2. Quest / flag system — LOCKED `[EC-2]`

- One autoload **`GameState`** holding a flat `Dictionary[String, Variant]`. API: `set_flag(key, value)`, `get_flag(key, default)`, `has_flag(key)`, `increment(key, by := 1)`, signal `flag_changed(key, value)`, `reset()`.
- **Key format:** `<scope>.<subject>.<predicate>`, snake_case. v1 scopes: `act1`, `region`, `village`, `weird`, `sys`, `recipe`, `quest`. A mod region uses its package id as scope.
- **Registry is mandatory:** `data/flags.json` declares every key with `type`, `tier` ∈ {`critical`, `normal`}, and a one-line description. The validator fails on any key referenced anywhere in `data/**`, `regions/**`, or `scenes/**` that is not declared. Typos fail the build, not the playtest.
- **`critical` tier** = flags the Act One walkthrough asserts on (region unlocks, chain beats, the letter). Only anchor areas (§7) may set them.
- **Region lock** is exactly `region.<id>.unlocked: bool`. Nothing else represents it. The unlock event is a cutscene whose `set_flag` beats flip five flags.
- **Border crossings** (Adam, this session; ledger `[EC-2a]`, user-authored): each crossing increments `region.<id>.crossing_attempts`; `region.total_crossing_attempts` is the sum. Guard dialogue conditions on both — guards get progressively pissy with Patch's persistence and know his attempt counts at *other* crossings despite the world lacking that technology, hand-waved like everything else they no longer understand. Engineering consequence: these counters exist from Foundations; the dialogue is a writing-track item.
- **Quests are not a separate system.** A quest is a named flag set in `data/quests/<id>.json`: `id`, `start_flag`, `complete_flag`, optional `fail_flag`, `display` (title/body for the future List). The List `[D7]` reads these; module appends `[D8]` remain PROVISIONAL and nothing here precludes or builds them.

## 3. Save system — LOCKED `[EC-3]`

- **Manual slots + autosave.** Slot count is config (`save.slots`, default 3). Autosave to `slot_auto` on every scene transition.
- One JSON file per slot: `user://saves/slot_<n>.json`. Contents: `schema_version` (int), `timestamp`, `playtime_s`, `game_state` (the whole `GameState` dictionary), `inventory`, `party`, `location` `{region, area, spawn, position}`.
- Amendment (L3, 2026-10-08): the `party` section arrives with its owning system (Battle, phase 5); the loader tolerates its absence. SaveManager owns only the envelope; contributors own their sections.
- **`SaveManager` autoload** concatenates `to_save_dict()` from every stateful autoload and restores via `from_save_dict()`. Adding a system never touches `SaveManager`. Every stateful autoload implements both plus `reset()`.
- Save is refused during dialogue, cutscene, or battle — those are never serialized.
- Loader refuses a newer `schema_version`; upgrades an older one through a migration function table (v1→v1 stub exists from day one).
- **`user://` layout is closed:** `saves/`, `seen_cutscenes.json` (cross-run, unchanged from Session 3), `settings.json`. Nothing else.

## 4. Inventory and items — LOCKED `[EC-4]`

- **Definitions** in `data/items/<id>.json`: `id`, `name`, `description`, `type` ∈ {`resource`, `consumable`, `gear`, `gadget`, `key`}, `tags[]`, `stackable`, `max_stack`, `weight` (required on every item, see below), `slot` (gear only: `weapon` / `armor` / `accessory` / `attachment`), `modifiers[]` of `{stat, op, value}`, `charges` (gadgets), `on_use` (effect id).
- **Instances** are dictionaries: `{item_id, count}` for stackables; `{item_id, charges_left, attachments: [instance...]}` for gear/gadgets.
- **`Inventory` autoload**: one shared party bag; equipment is per party member (`equipped: {slot: instance}`). No bag limit in v1 (`inventory.max_bag_slots` config, 0 = unlimited).
- **`on_use` is a registry of named effect functions** (`heal`, `apply_buff`, `set_flag`, …). A new consumable is a JSON file, never a script.
- **Starting gear per village is data:** `data/villages/<id>.json` → `starting_items[]`, `starting_flags{}`, plus the Docs/03 pro/con hooks. No village-specific code anywhere.
- **Realistic weight mode** (Adam, this session; ledger `[EC-4a]`, user-authored): an optional per-game choice at New Game, stored as the per-run flag `sys.realistic_weight`. When on, super-realistic carry limits apply and unlock extra content as enticement (dialogue, possibly quests/equipment — inner-dialogue jokes about who could possibly carry three swords and where they're putting them). Engineering consequence: `weight` is required on every item definition from Foundations even though v1 ignores it when the flag is off; the limit is config (`inventory.realistic_weight_max`). Extra content is writing-track.
- Repair is **not** an item verb (see §9).

## 5. Dialogue JSON schema v2 — LOCKED `[EC-5]`

- **Node graph.** File: `{ "id", "entries": [ { "when": <condition>, "start": <node_id> } ], "nodes": { <node_id>: { "lines": [...], "choices": [...]?, "set": [...]?, "next": <node_id>? } } }`. `entries` is evaluated top-down, first match wins; last entry has `"when": "true"`.
- **Line:** `{ "speaker": <character_id>, "text", "text_f"?, "portrait"? }`. `speaker` is an id resolved through `data/characters.json` (display name, default portrait, gender). A line may override `portrait`.
- **Gender variants** `[U2-7]`: inline tokens resolved by a substitutor — `{he/she}`, `{him/her}`, `{his/her}`, `{his/hers}`, `{himself/herself}` — with `text_f` as the escape hatch for lines tokens cannot carry. Full duplicate lines are *not* the default mechanism.
- **Conditions** are a small grammar, parsed by one function, no `Expression`/eval: `flag`, `!flag`, `flag == value`, `flag != value`, `flag >= n`, `flag <= n`, joined by `&&` and `||`, parentheses allowed.
- **`set[]`**: `{ "flag", "value" }` or `{ "flag", "increment": n }`, applied when the node is entered.
- **`choices[]`**: `{ "text", "text_f"?, "when"?, "next" }`.
- **Stable line keys** `<file>.<node>.<index>` are generated by the validator into `data/i18n/keys.json`; text stays inline in v1. Extraction later is a script, not a rewrite.
- `data/schema/dialogue.schema.json` is committed; the validator checks every dialogue file against it.
- **Migration** of the 11 existing files is a script; the loader also accepts the v1 flat `lines[]` shape as a single node named `start` so nothing breaks mid-transition.
- Writing rules the code cannot enforce (restated for authors, not for Fable): weirdness is never acknowledged by NPCs in Act One; hedged claims are true, confident claims are false `[Rule 3]`.

## 6. Scene architecture — LOCKED `[EC-6]`

- **Connected scenes. No overworld map.** Roads are walked (required by the "road home doesn't go back the way it came" beat).
- **A region is a package:** `regions/<id>/` containing `region.json` (§7), `areas/*.tscn`, `dialogue/`, `cutscenes/`, `items/`, `mobs/`, `quests/`, and optional `forges` data. Replacing the folder replaces the region.
- **Area ids** are `<region>/<area>` strings everywhere (flags, saves, exits). The nine starting villages are nine area sets under `regions/hold/`, not nine regions. `scenes/workshop.tscn` relocates to `regions/hold/areas/<village>_workshop.tscn` in Foundations.
- Amendment (L4): the relocated area is named `workshop` until village selection exists (phase 3), when the `<village>_workshop` pattern applies.
- Every area scene has one root with an `Area` script exposing `spawns: Dictionary[String, Vector2]` and `used_rect() -> Rect2i`.
- **`SceneRouter` autoload** is the single choke point for transitions: `Exit` Area2D nodes carry `target_region`, `target_area`, `target_spawn`; the router fades out, unloads, loads asynchronously, places the player, fades in, autosaves. It enforces the region lock (`region.<id>.unlocked` false → play the region's `locked_message` dialogue and bounce) and calls `Weirdness.set_region()` on region change.
- Camera: one `Camera2D` on the player, limits from `used_rect()`, integer-snapped.
- **Exit randomization** (Adam, this session; ledger `[EC-6a]`, user-authored): extremely rarely — less rarely as the world deteriorates — an exit delivers Patch to the wrong destination. No explanation; a frustration sound from Patch. He accepts it happened but rejects that it should have been possible, and that pisses him off. Engineering rules: `SceneRouter` asks `Weirdness.roll("misroute")` on every transition; the probability lives in the weirdness curve, not the router; a misroute picks only from the current region's **unlocked, already-visited** areas (can never break the region lock or the critical path); the only persisted trace is `weird.misroutes` incremented; it fires an SFX cue and no dialogue.

## 7. Generator contract — LOCKED `[EC-7]`

- The generator is **deferred**; handcrafted regions expose its *output shape* now so it can drive the same scenes later `[U2-4]`.
- `region.json`: `id`, `display_name`, `motto`?, `biome_tags[]`, `weirdness` (float multiplier; Hobb's village area is 0), `locked_message` (dialogue id), `entry_points[]`, `anchors[]`, `fill_slots[]`, `edges[]`, `forges[]`?.
  - **`anchors[]`**: plot-bearing areas that must exist with fixed content — `{ id, area, biome_tags[], required_exits[] }`. Act One anchors: Patch's village, Last Post, Near Enough, Wren's post, Hobb's village, the Turning crossing, North Office, Still Point, the Abbey.
  - **`fill_slots[]`**: `{ id, biome_pool[], length_hint, default_area, spawn_pool[] }`. v1 fills every slot by hand via `default_area`.
  - **`edges[]`**: `{ from, to, via_slot? }`.
- **Only anchors may set `critical`-tier flags** (§2). Fills may set any other flag — side quests, encounter counters, wandering things are all fine. The validator enforces the tier rule.
- **Quests travel with entities, not areas:** a quest-bearing mob or NPC is defined in `data/mobs/` or `data/characters.json` with its own flags and is spawned through a fill slot's `spawn_pool`. A mod region can ship a wandering quest-giver with zero engine changes.
- The July 10 anchor-and-fill spec `[G3]` is superseded in *format* by `region.json`; it remains the design reference for the future generator's validator (1000 seeds, every anchor reachable, no orphan slots).

## 8. Cutscene beats as data — LOCKED `[EC-8]`

- Beat arrays move from GDScript to `data/cutscenes/<id>.json`: `{ id, skippable, once, beats: [...] }`. The existing vocabulary (`wait`, `move`, `animation`, `dialogue`, `end`) is the v1 schema, extended with `set_flag`, `camera` (pan/shake), `fade`, `sfx`, `spawn`, `despawn`, `choice` (delegates to dialogue), and `emit` (fires a named signal a scene may hook — JSON never calls scripts).
- Actors are referenced by scene node name, resolved at play time.
- `opening_cutscene.gd` is replaced by a generic **`CutsceneTrigger`** node with exported `cutscene_id` and `when` condition (§5 grammar). `CutsceneSkip` and `seen_cutscenes.json` are unchanged.
- `data/schema/cutscene.schema.json` is committed.
- **Acceptance test for the loader:** the 30-beat opening migrated to JSON plays identically; `opening_cutscene.gd` is deleted.

## 9. Crafting / resources data model — LOCKED `[EC-9]`

- `data/recipes/<id>.json`: `id`, `output {item_id, count}`, `inputs[]` of `{ "tag:<tag>" | "<item_id>", count, preferred? }`, `substitution_penalty` (modifier list applied to output when a non-preferred input is used), `station_tier` ∈ {`home`, `smith`, `monastery`}, `station_tags[]` (e.g. `order:thrum`).
- **Tag-based inputs** are how non-ideal substitution works `[G9]`. The item-tag taxonomy is a short committed list `data/tags.json`; the validator rejects unknown tags. Populating it is a writing-track item (BUILD_PLAN §4.9).
- **Recipes are discovered by flag** `recipe.<id>.known`; the crafting intro is "set one flag."
- **Stations** are scene nodes with `tier`, `tags[]`, and `modifiers[]` (the forge-tier buffs *and* debuffs, none objectively best `[G9]`). Monastery forge data lives in the region's `region.json → forges[]` so a mod region's forge is data.
- **Repair is an interaction verb, not a recipe.** `Repairable` node: `repair_flag`, `requires` (item id or tag, optional), `dialogue_before`, `dialogue_after`, `sfx`?. No station, no recipe. The mill, the Abbey gate, the ferryman's problem, the clocks are all `Repairable` with no new code each.

## 10. Weirdness autoload — LOCKED `[EC-10]`

- **`Weirdness` autoload** owns one scalar `intensity: float` (0.0–1.0), **derived, never saved** — recomputed from flags on load via `data/weirdness/curve.json` (act progress, region multiplier, `weird.*` counters).
- A scheduler emits `flicker_requested(kind, spot, params)` at intervals derived from intensity. Catalog `data/weirdness/catalog.json`: each kind has `min_intensity`, `weight`, `cooldown`, `regions_excluded[]`, `handler`, `v1: bool`. Scenes place `FlickerSpot` markers with allowed kinds. A short history ring prevents the same kind+spot twice in a row.
- `roll(event_name) -> bool` is the general-purpose hook; `misroute` (§6) is its first consumer, with its probability as a curve entry.
- `set_region(id)` applies the region's `weirdness` multiplier; 0 means nothing fires (Hobb's village).
- Scripted beats (nine days, road home, the mill, the river, the bell tower) are cutscenes and flags, not this autoload.
- Debug ring buffer of fired flickers is readable from the test harness, not persisted. The only persisted weirdness state is the `weird.*` counters the design explicitly wants.
- The curve numbers, catalog contents, and flicker one-liners are the §5 weirdness spec — a separate design session. Fable ships the contract with placeholder values flagged in config.

## 11. Test harness — LOCKED `[EC-11]`

- **Plain GDScript, no framework.** `tests/run_tests.gd` extends `SceneTree`, run as `godot --headless -s tests/run_tests.gd`; discovers `tests/test_*.gd`, each exposing `func run(t: TestContext) -> void` with `assert_eq`, `assert_true`, `fail`; one line per test; non-zero exit on any failure; calls `reset()` on every stateful autoload between tests.
- `tests/validate_data.gd` (cheapest signal, runnable alone): every JSON file under `data/` and `regions/` against its schema in `data/schema/`; flag registry (§2) including tier rule (§7); tag registry (§9); dialogue ids referenced by scenes/cutscenes exist; mob `side_effect_of` non-empty; every art file has a manifest entry (§12); every character id in dialogue exists in `characters.json`.
- `tests/walkthrough_act1.gd` drives `GameState` + `SceneRouter` + `Battle` through the Act One sequence and asserts: the letter cutscene is reachable; the five outer regions are locked before it and unlocked after; every anchor is reachable. Fixtures are save files in `tests/fixtures/` (§3).
- **Single entry point:** `tools/check.bat` (Windows, the build machine) and `tools/check.sh`, running in order `godot --headless --quit` → `validate_data` → `run_tests`, stopping at first failure. **Every Prompt Workshop definition of done from here on is: `tools\check.bat` exits 0 and prints `N passed, 0 failed`.**

## 12. Asset pipeline — LOCKED `[EC-12]`; EULA gate OPEN

- `assets/manifest.json` lists every art file: `path`, `source` ∈ {`mana_seed`, `original`, `ai_generated`, `placeholder`}, `pack` (Mana Seed pack name), `license`, `status` ∈ {`final`, `placeholder`}. The validator fails on any file under `assets/` missing from it.
- **Licensed Mana Seed files are never used as AI input or style reference until the Seliel the Shaper EULA has been read and the ruling recorded here** `[A15]`. Status: **OPEN — pre-launch gate.** Until closed, `ai_generated` assets may be produced only from prompts with no licensed input. Fable never sources art from the web.
- **Placeholders are visibly placeholders:** filename prefix `PH_`, node name suffix `_ph`, and a magenta outline where practical. Current placeholders (verify before trusting): cat sprite (runtime-generated), all portraits (`patch_default` everywhere, including Voices From Outside), the Forge, monks, mobs, Turning tiles.
- Paths by convention, not per-file config: `assets/portraits/<character_id>_<expression>.png`, `assets/sprites/<entity_id>/`, `assets/tiles/<pack>/`, `assets/sfx/`, `assets/music/`.
- `Docs/LICENSES.md` is created now with Mana Seed listed as "terms: to be verified." Free Mana Seed demo assets until the vertical slice, then buy `[A14]`.

## 13. Conventions — LOCKED `[EC-13]`

Restated from CLAUDE.md and `[A13]`: GDScript only, no C#; nearest-neighbor filtering on all sprites; viewport 320×180, stretch mode `canvas_items`, window 1280×720 via `Boot`; Mana Seed 16×16; do not invent names, places, or mechanics not in the docs — stop and ask. Build on Windows (the-rig), never the Ubuntu server `[I1]`. Design docs are edited only through docs-only prompts `[I4]`.

Added this session:

- **Autoload roster is closed:** `Boot`, `GameState`, `SaveManager`, `Inventory`, `DialogueManager`, `CutsceneManager`, `CutsceneSkip`, `SceneRouter`, `Weirdness`, `Battle`. Adding one requires a change to this document first.
- **Folder layout is fixed:** `regions/` (content packages), `data/` (shared JSON: `items/`, `mobs/`, `recipes/`, `quests/`, `cutscenes/`, `dialogue/` for shared/system dialogue, `villages/`, `weirdness/`, `schema/`, `i18n/`, `flags.json`, `tags.json`, `characters.json`, `config.json`), `scenes/` (shared UI only), `scripts/` (shared classes and autoloads), `assets/`, `tests/`, `tools/`, `Docs/`.
- JSON is the only content format under `data/` and `regions/`; no `.tres` for content.
- Every stateful autoload implements `reset()`, `to_save_dict()`, `from_save_dict()`.
- Every JSON content type has a schema in `data/schema/`.
- Tunables live in `data/config.json`, never as script literals; open design values get a flagged placeholder default.
- Pixel positions are integers; no sub-pixel camera.
- Files snake_case; classes PascalCase; autoload names match `class_name`.
- Static typing required on all function signatures. Signals named past-tense (`flag_changed`, `dialogue_ended`).
- Otherwise follow the official Godot GDScript style guide; do not duplicate it here.

---

## Appendix A — New ledger rows (for MOSTLY_DECISION_LEDGER.md §K)

| # | Item | Status | Authority | Notes |
|---|---|---|---|---|
| EC-1 … EC-13 | Engineering constraints §1–§13 above | LOCKED | user-confirmed (assistant proposed; Adam chose with all stated qualifiers) | 2026-08-29 |
| EC-1a | Mobs: tongue-in-cheek — animated objects, weird pets, cryptids; each carries a real side-effect modifier; combinations drive diversity | LOCKED | user-authored | Roster is writing-track. |
| EC-2a | Border guards count crossing attempts per region and in total; get pissy; know other crossings' counts, hand-waved | LOCKED | user-authored | Dialogue is writing-track. |
| EC-4a | Optional realistic-weight mode at New Game; unlocks extra content as enticement | LOCKED | user-authored | Extra content is writing-track. |
| EC-6a | Rare, escalating exit misroute; no explanation; Patch's frustration sound | LOCKED | user-authored | Guarded: unlocked + visited areas only. |
| EC-12a | Mana Seed EULA verification before any AI use | OPEN (pre-launch gate) | user-authored `[A15]` | Cannot be closed by a session; closed by reading the license. |

## Appendix B — Items this document deliberately does not decide

Weirdness curve numbers and flicker catalog (BUILD_PLAN §5 session); mob roster, resource list, item-tag taxonomy, recipes (writing track §4.9); regional-lock reason and unlock event `[U2-2]`; companion timing in Act One (§3 TODO 4); crafting-intro forge location (§3 TODO 6); pronoun convention for authored text `[B9]` — the dialogue token system makes this a per-line authoring choice, but the prose convention is still undecided.

- Act 2 consequence map (quest → world delta) — required before Act 2 content `[L1]`.
