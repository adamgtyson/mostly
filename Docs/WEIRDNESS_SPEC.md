# WEIRDNESS_SPEC.md — The Act One Weirdness System

**Version:** 2026-10-08. Output of the BUILD_PLAN §5 design session. Answers §5 items 1–8 and supplies the §4.12 flicker one-liner pool. Rulings are Adam's (2026-10-08); ledger IDs `[M-n]` are appended to MOSTLY_DECISION_LEDGER.md §M. Fills the Foundations contract in Docs/ENGINEERING_CONSTRAINTS.md §10 `[EC-10]`; it does not redesign it.

**Status key:** LOCKED = Adam ruled. PROPOSED = assistant values awaiting a build-phase reconciliation (flag ids, tuning). Nothing here is tagged LOCKED that Adam did not rule on.

---

## 0. One paragraph

The world is deniable at first and undeniable by the end. Scripted story beats (cutscenes + flags) raise a single derived `intensity` scalar; the `Weirdness` autoload turns that scalar into random, sub-quarter-second, never-acknowledged **flickers** drawn from a data-driven catalog. Flickers are texture. Beats are plot. Nothing random can ever touch the plot.

## 1. Flicker catalog — LOCKED `[M-1]`

Six v1 kinds. Each is ≤ 0.25s visual or ≤ 1.5s audio, touches no gameplay state, and reads as "did I see that?"

| kind | what the player sees | min_intensity | weight | cooldown | regions_excluded |
|---|---|---|---|---|---|
| `sprite_edge` | A figure at the viewport edge for ~6 frames (~0.1s). Gone if the camera moves toward it. | 0.05 | 3 | 120 | — |
| `tile_blink` | One tile swaps to a wrong-but-plausible neighbor (fence post → well, door → wall) for 2 frames, then restores. | 0.10 | 3 | 90 | — |
| `npc_wrong_frame` | An idle NPC shows one frame from a different animation, or faces the wrong way, for 1 frame. | 0.15 | 2 | 90 | — |
| `sound_offstage` | A non-positional one-shot: a bell where there is no bell, a single hammer strike, one chicken. | 0.15 | 2 | 60 | — |
| `light_skip` | Ambient modulate dips 3% for 1 frame, or a cast shadow with no caster for 3 frames. | 0.25 | 2 | 60 | — |
| `npc_line` | An NPC's idle bubble (not the dialogue box) shows one line from the §9 pool. Never logged, never repeated in-run. | 0.35 | 1 | 180 | — |

Deferred, present in the catalog with `v1: false` so the contract is exercised: `cat_elsewhere` (the workshop cat somewhere it cannot be — reserved for the return home), `reflection_lag`, `clock_wrong`, `double_npc`.

`npc_line` is **in v1** (Adam: explicitly). Tuning numbers (min_intensity / weight / cooldown) are PROPOSED starting values; the kind list is LOCKED.

## 2. Interval curve — LOCKED `[M-2]`

**Shape lives in the data, not the code.** `Weirdness.next_interval()` stays `lerp(max, min, intensity)`; the curve's feel comes from the `act_progress` ladder being non-linear.

- **Bounds** (config): `weirdness.flicker_interval_max_s` = **300**, `weirdness.flicker_interval_min_s` = **45**. (Foundations placeholders were 90 / 20.)
- **Jitter** (Adam-authored rule): after computing the interval, add a uniform random offset in **[−10s, +10s]**, then clamp to ≥ 10s. Never a metronome.
- **Clock:** player-time, ticking only while the player has control in an explorable area. Paused during dialogue, cutscene, battle, and menus.
- **Region change:** intensity does **not** reset (it is derived from flags and cannot). Only the countdown resets.
- **Arrival grace:** 8 seconds after entering any area before anything may fire.
- **Global floor:** no two flickers of any kind within 10 seconds of each other.

### 2.1 The Act One ladder — values LOCKED, flag ids PROPOSED

Cumulative `act_progress` entries in `data/weirdness/curve.json`. Flag ids are PROPOSED; the phase that builds each beat owns the real id and must reconcile this table.

| when (PROPOSED flag) | +intensity | running total | ≈ interval before jitter |
|---|---|---|---|
| `act1.nine_days_noted` (opening cutscene complete) | 0.05 | 0.05 | ~287s |
| `act1.last_post.road_seen` | 0.10 | 0.15 | ~262s |
| `act1.mill_fixed` | 0.10 | 0.25 | ~236s |
| `act1.wren.map_received` | 0.10 | 0.35 | ~211s |
| `act1.turning.entered` | 0.15 | 0.50 | ~172s |
| `act1.abbey.arrived` | 0.15 | 0.65 | ~134s |
| `act1.forge_seen` | 0.10 | 0.75 | ~109s |
| `act1.abbey.departed` (return trip) | 0.25 | 1.00 | ~45s |

Note: `Weirdness._on_flag_changed` already recomputes on any key beginning `act`, so `act1.*` ids need no engine change.

### 2.2 Counters and events

- `weird.misroutes`: as built — 0.01 per unit, max 0.10. No other counters. **No "flickers seen" counter** — the design says never logged, and a hidden tally is a temptation to use later.
- `events.misroute`: base **0.04** (× intensity → 0.2% per transition early, 4% at full intensity). PROPOSED tuning; the mechanic is `[EC-6a]`.

## 3. Scripted vs. random — LOCKED `[M-3]`

**Scripted** (cutscenes + flags; never the autoload, per `[EC-10]`): the nine days; the Last Post road home; the backward mill; the missing river; Still Point; the bell tower running fast; the 2–3 return-trip beats; the letter. These are exactly the rungs of the §2.1 ladder — each scripted beat *is* what raises intensity.

**Random**: the §1 catalog.

**Binding rule:** no catalog kind may reproduce a scripted beat's content. No "river flickers out," no backward-mill flicker. Random fill is texture; scripted beats are plot. This is also why scripting wins: plot beats stay deterministic and the critical-path walkthrough (BUILD_PLAN §7) can assert on them.

## 4. Regional intensity — LOCKED `[M-4]`

- `region.json → weirdness`: **The Hold 1.0, The Turning 1.5.** Applied after the ladder, clamped to 1.0 — The Turning reaches ceiling by the Abbey and unlocks higher-`min_intensity` kinds earlier. `npc_line` first appears in The Turning on a typical run.
- **Hobb's village is 0, by area.** `[EC-7]` said "area is 0" but the multiplier is per-region. Resolution (Adam: option B): add an optional **`weirdness_override: float`** to anchor entries in `region.json`; `SceneRouter` applies it on *area* change, not only region change. This also suppresses `misroute` rolls on exits from Hobb's village, which option A (no FlickerSpots) would not. `[EC-7]` amendment.

## 5. Village interaction — LOCKED `[M-5]`

Defines "tell" and "stagger" concretely, and re-grounds the Docs/03 "world-break events" vocabulary flagged in MOSTLY_CANON §4.8: **in Act One, a *world-break event* = a scripted overt beat, or a misroute.** Carry that definition forward.

- **Stagger** (baseline, all villages): on first contact with each scripted overt beat (mill, river, Still Point, Forge sight, each return beat), Patch loses control for **1.2s** with a short "huh" idle. Never on random flickers — those are deniable by definition, so Patch does not react.
- **Seven Chickens:** stagger is **0.3s, no animation**, on an **80% roll** (the Docs/03 RNG component; the other 20% is the normal stagger). The con (missed warning cues) belongs to combat (phase 5); cross-reference only.
- **Tell** (Good Soil (Probably) only): **2–4s before** a scripted overt beat and before every misroute, the ambient bus ducks 6dB for 1.5s and wind/bird loops stop. Nothing visual. The player learns the silence. Tells **never** precede random flickers — a warning before a deniable event makes it undeniable, which inverts the system.

## 6. Deniability rules — LOCKED `[M-6]`

1. No NPC acknowledges a flicker in Act One. Ever.
2. A flicker sets no flag and writes nothing to a save. `weird.misroutes` is the sole exception, already locked `[EC-6a]`.
3. Never the same kind at the same spot twice in a row (built: history ring). `npc_line`: never the same line twice per run — in-memory set, not saved; a reload may repeat one, accepted.
4. Never during dialogue, cutscene, battle, or menu. Never in the 8s after arriving in an area. Never two flickers within 10s of each other, any kind.
5. Visual flickers ≤ 0.25s. Audio flickers ≤ 1.5s.
6. `FlickerSpot`s are placed by hand and never on exits, interactables, or the critical-path walk line. Nothing a flicker does can block, redirect, collide, or damage.
7. No flicker reproduces a scripted beat (§3).

## 7. Replay reveal — LOCKED `[M-7]`

**Nothing mechanical.** Ladder, catalog, and spots are identical on every run; the player just knows what they are looking at. REJECTED: a fixed first flicker (known kind at a known spot in the opening village) as a replayer's wink — it makes the first flicker a known quantity, and the opening is where deniability matters most.

## 8. Implementation contract — delta from the Foundations skeleton

The `[EC-10]` skeleton is correct. These are additions for the phase 3/4 build prompts, **not** a Foundations rework. Fable builds within these; it does not choose them.

- **Handler registry:** catalog `handler` strings resolve through a `FlickerHandlers` registry (same pattern as Inventory's `on_use` registry). v1 handlers: `sprite_edge`, `tile_blink`, `npc_wrong_frame`, `sound_offstage`, `light_skip`, `npc_line`. `log` stays for tests.
- **`FlickerSpot`** gains `params: Dictionary` (tile coords, NPC node path, sprite frames) alongside `allowed_kinds[]`.
- **Scheduler pause:** `set_scheduler_enabled(false)` exists; prefer a single `GameState` "player has control" query that `Weirdness` checks, over four call sites.
- **Jitter** (§2) in `next_interval()`; **arrival grace** and **global 10s floor** in `_reschedule()`.
- **Area-level `weirdness_override`** (§4) in `region.json` anchors and `SceneRouter`.
- **Tell hook:** `Weirdness.tell_requested` signal, emitted by `CutsceneManager` before a beat tagged `overt: true` and by `SceneRouter` before a misroute, only when the starting-village flag resolves to Good Soil (Probably). Flag id is phase 3's to name.
- **Stagger** is a cutscene beat type (`stagger`, duration and animation from config; Seven Chickens reads its own config values). Lives in cutscene data, not in `Weirdness`.
- **`npc_line` pool** ships as `data/weirdness/lines.json`, schema-validated, each entry `{ id, text, min_intensity? }`. Pronoun-free toward Patch, so `[U2-7]` gender variants are not required for this pool.
- **Tests** (plain GDScript, `[EC-11]`): ladder is monotonic non-decreasing; no kind is eligible below its `min_intensity`; Hobb's village fires zero across 1000 forced `fire_one()` calls; `npc_line` never repeats across 500 fires; jittered intervals all fall within [max(10, base−10), base+10].

### 8.1 What does NOT change in this session
`data/weirdness/{curve,catalog}.json` and `data/config.json` keep their placeholder values until the phase 3 build prompt, because the ladder's `when` conditions reference flags that `data/flags.json` does not yet declare and the validator must stay green.

## 9. Flicker one-liner pool (§4.12) — LOCKED `[M-8]`, 19 lines

Rules: deadpan; sayable as mundane; nothing supernatural in the wording; **pronoun-free toward Patch**. The NPC says it and returns to normal idle. The tagline "It's mostly fine." is **excluded** from this pool (Adam).

| id | text | note |
|---|---|---|
| `step` | Mind the step. | there is no step |
| `yesterday` | Same as yesterday, then. | |
| `just_here` | You were just here. | |
| `wind` | Wind's from the wrong way again. | |
| `hear_that` | Did you hear that? No. Neither did I. | |
| `second_time` | Second time today I've said that. | |
| `dark_soon` | It'll be dark soon. | at noon |
| `well` | That's not where the well is. | |
| `six` | Felt like six, didn't it. | min_intensity 0.5; echoes the nine days |
| `bells` | The bells are early. | nowhere with a bell |
| `road` | Road's longer than I remember. | |
| `you_again` | You again. | first meeting |
| `thought_left` | Oh. I thought you'd left. | |
| `mill` | We don't talk about the mill. | no mill here |
| `mind_him` | Don't mind him. | no one else present |
| `which_one` | Which one are you? | |
| `someone_else` | Sorry — thought you were someone else. You're not, are you. | |
| `still_here` | Still here? Good. Good. | |
| `fences` | Someone's been moving the fences. | |

## 10. Ledger entries — §M (append to MOSTLY_DECISION_LEDGER.md)

| id | ruling | status |
|---|---|---|
| M-1 | Six v1 flicker kinds as §1; `npc_line` is v1; four deferred kinds ship `v1:false`. Tuning numbers PROPOSED. | LOCKED (Adam 2026-10-08) |
| M-2 | Interval bounds 300s/45s; ±10s uniform jitter per interval (Adam-authored); player-time clock paused without control; 8s arrival grace; 10s global floor; ladder values as §2.1 with PROPOSED flag ids. | LOCKED |
| M-3 | Scripted beats raise intensity; random catalog fills; no catalog kind may reproduce a scripted beat. | LOCKED |
| M-4 | Region multipliers Hold 1.0 / Turning 1.5; Hobb's village 0 via area-level `weirdness_override` applied by SceneRouter (option B). Amends `[EC-7]`. | LOCKED |
| M-5 | Stagger 1.2s baseline; Seven Chickens 0.3s/no anim on 80%; GSP tell = 6dB ambient duck + loop stop 2–4s before scripted overt beats and misroutes, never before random flickers; "world-break event" in Act One defined as scripted overt beat or misroute. | LOCKED |
| M-6 | Deniability rules 1–7 as §6. | LOCKED |
| M-7 | Replay: nothing mechanical. Fixed first flicker REJECTED. | LOCKED |
| M-8 | 19-line `npc_line` pool as §9; tagline excluded; pool is pronoun-free toward Patch. | LOCKED |

## 11. Open / downstream
- Flag ids in §2.1 reconcile when each phase names its beat flags (phases 3–7).
- `weirdness_override` and the scheduler-pause query are phase 3 engine work; handlers are phase 3 (`sprite_edge`, `tile_blink`, `sound_offstage`, `light_skip`) and phase 4 (`npc_wrong_frame`, `npc_line`, once exterior NPCs exist).
- Which `FlickerSpot`s go where is a per-area placement task inside each content phase, not a design question.
- BUILD_PLAN §3 TODO 7 is closed by this doc; §4.12 "weirdness flicker lines" moves from **none** to **exists**.
