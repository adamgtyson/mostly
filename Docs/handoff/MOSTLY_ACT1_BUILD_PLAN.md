# MOSTLY_ACT1_BUILD_PLAN.md — Scope, Decisions, Writing List, and Pre-Build Sessions for an Act One v1

**Version:** 2026-08-28. Records Adam's rulings from this session on Act One scope and lists everything that must exist before a Claude Code (Fable) build of Act One can be attempted. Ledger IDs `[U2-n]` are appended to MOSTLY_DECISION_LEDGER.md §J.

---

## 1. Act One scope — LOCKED (Adam, 2026-08-28)

**Act One ends when Patch, back home after the delivery, receives the summons letter.** `[U2-1]` Not at the Forge, not at the repair attempt. The bridge beats 1–5 (deliver → odd jobs → go home → Forge fails post-departure → letter) are *inside* Act One; the return journey opens Act Two.

**Regional lock during Act One — LOCKED as a rule, reason OPEN `[U2-2]`:** during Act One Patch can travel only in The Mostly (The Hold) and The Turning. All other regions are blocked. Around the time the letter arrives, something in-world happens that unlocks them.
- **Canonical reason for the block: OPEN.** Must be invented and locked. Candidate seeds, all PROVISIONAL assistant proposals, none adopted: (a) travel across regional borders requires paperwork from a Margin ministry that is issued only for stated business — the commission is Patch's only stated business, so only The Turning's border city will stamp it; (b) the outer border crossings are physically closed by The Department of Acceptable Distances "until further notice" for an unrelated-sounding reason; (c) the roads simply don't go there yet — border crossings other than The Turning's have "not been there" for weeks and nobody has filed it (ties to The List's tone).
- **Canonical unlock event: OPEN.** Whatever it is, it coincides with the letter and must read as the world coming apart, not as a gate opening.

**After the delivery, Patch is free to explore The Turning** `[U2-3]`: battle encounters, resource gathering, and the crafting-system introduction happen here, before going home. Consequences: **combat is in Act One** and **the crafting intro lives in The Turning**, not the opening.

## 2. Build-shape decisions — LOCKED (Adam, 2026-08-28)

| Decision | Ruling | Ledger |
|---|---|---|
| Handcrafted vs. generated | Handcraft Act One v1; architecture must let the anchor-and-fill generator drive the same scenes later. | `[U2-4]` |
| Starting villages | All nine selectable. The Docs/03 mechanical pro/cons stand as designed (Adam: keep them, don't downgrade). Residual: re-ground the ones phrased in cut "world-break" vocabulary. | `[U2-5]` |
| Map scope | v1 proof-of-concept may use only the plot-bearing places; the *shipped* Act One needs The Hold and The Turning fully built and explorable. | `[U2-6]` |
| Gender | Dialogue variants per Patch's gender (not a neutral default). | `[U2-7]` |
| Definition of done | Adam adopts the recommendations in §7. | `[U2-8]` |
| Phasing | Multi-phase build, one workshop prompt per phase (§8). | `[U2-9]` |

## 3. Pre-build design TODOs (must be resolved before scene/dialogue build)

1. **Restage Brack's ceremony** so Patch never witnesses the failure and does not see the misread in a way that pre-empts "I made that part." (From ruling 1 of the first round.)
2. **Finish the delivery-chain character composite** (Brindle, Wren, Hobb, Sedge, Brack) — fix the sheets' inverted chain direction; reconcile Brindle (cheerful/rattled by the mill) and Brack (older monk) with July 7 canon.
3. **Invent and lock the regional-lock reason and the unlock event** (§1).
4. **Decide whether the companion (Fletch/Brace) joins in Act One** at the Abbey, or only on the return in Act Two. The bell-tower observation is theirs; timing matters for the party system's scope in v1.
5. **Decide the combat model** (see §6 agenda) — real-time action (Secret of Mana lineage) vs. turn-based (Chrono Trigger lineage). Nothing in the record chooses.
6. **Define the Act One crafting intro** in The Turning — which forge (a blacksmith forge in North Office? a monastery forge unlocked by the odd jobs?), what Patch first crafts, and how "repair" is introduced without the cart.
7. **Weirdness system decisions** (§5).
8. **The Act One map**: rough positions of Patch's village, Last Post, Near Enough, Wren's trading post, Hobb's village, the Turning border crossing, North Office, Still Point, Stable Frequency / Nominal / Acceptable Variance / Within Tolerance, the Abbey. Note: Wren's post is "halfway between Near Enough and the northwestern border of The Hold" but The Turning is north in the July 7 layout — reconcile during the territory review.
9. **Mob roster for The Turning** — none exists anywhere. Must follow the institution rule (creatures as Forge side-effects, not generic monsters) and the tone rule.
10. **Resource list** for The Turning gathering.
11. **Docs cleanup and July 7 propagation** (docs-only prompt already drafted).

## 4. Act One writing list — everything that must be written before it can be built

Status: **exists** = in repo or locked verbatim; **partial** = concept locked, text missing; **none** = nothing written. Gender variants (`[U2-7]`) apply to every Patch-addressed line.

### 4.1 Opening (Patch's village — workshop)
- Cutscene dialogue — **exists** (11 JSON files). Missing beats: the 8-days-left line, the express-courier math, hitching the horse, departure. **partial**
- Optional crawl — **none**; undecided whether it exists.
- Workshop interactables (workbench, table, crate, cat) — **exists**; more as needed.

### 4.2 Patch's village
- Village exterior NPCs (from the naming pool: Boots, Nibs, Crick, Pockets, Nails, Ditch, Post, Tiller, Hinge, Cooper, Knott, Pindle) — one or two lines each, "contented majority" / "willfully ignorant" archetypes. **none**
- "Voices From Outside" — **exists** (3 lines).
- **Latch**: canonical four-line exchange **exists**; the where-are-you-going / when-back exchange; the errand ask (soup salt ratio to Bell); the gear-reward choice; return dialogue with on-time / late variants; idle lines. **partial**
- Village selection screen: nine epigraphs **exist**; pro/con presentation text (Seven Chickens obfuscated) — Docs/03 text usable; starting gear/ability descriptions **none**.

### 4.3 Last Post
- **Bell**: receiving the message; soup offer (discount / full price variants); buff flavor. **none**
- The road-home-isn't-the-same beat — environmental, plus one or two NPC lines that don't acknowledge it. **none**
- "Something here needs solving" — **undesigned**; either design a small self-contained problem or cut it from v1.
- Last Post NPCs. **none**

### 4.4 Near Enough
- **Brindle**: arrival / recognition; recalling where the order came from (points to Wren); the backward-mill worry; sending Patch; post-fix relief, no follow-up questions; shop intro lines. **partial** (July 7 characterization; Aug 8 sheets provisional)
- **The mill**: the miller (or whoever), the fix interaction, the unexplained-cause non-answer. **none**
- Near Enough NPCs; shop inventory names/descriptions. **none**

### 4.5 Wren's trading post
- **Wren**: map handoff; the missing river; pointing to Hobb; bird-in-the-corner non-explanation; practical/resigned register. **partial**
- Map notes: first map's mundane notes; the note pool that appears as the world breaks (at least 6–10 entries, e.g. "road terminates unexpectedly — remeasure recommended"). **none**
- Trading post NPCs. **none**

### 4.6 Hobb's village (perfectly normal; name TBD)
- **Hobb**: greeting; the rumor pool (at least 8–12 rumors; some accurate, some not; several pointing at unmarked content); pointing to Sedge/Still Point; oversharing register. **partial**
- Outskirts: the miller with the stopped mill; the ferryman with no river — both helpable; their fix interactions. **none**
- The "why is this place fine" questline hook — one seed line only in Act One. **none**
- Village NPCs — deliberately, aggressively normal. **none**

### 4.7 The Turning — border and North Office
- Border crossing anchor: the Ministry of Normal Things satellite office; administrators on two-week postings; the paperwork that lets Patch through (ties to the regional-lock reason). **none**
- North Office: Ministry of Predictable Motion, Office of Slight Vibrations — clerk lines; Bearing Ward / Rotation Square / The Lower Notes / Form District flavor. **none**
- Blacksmith forge (if the crafting intro is here): smith NPC; 3–5 errand seeds (only the first needs to be in v1). **none**

### 4.8 The Turning — villages
- Still Point: residents who won't leave; **Sedge**'s watching-for-what conversation (locked beats, no text); Sedge pointing to the Abbey. **partial**
- Stable Frequency, Nominal, Acceptable Variance, Within Tolerance: one-line epigraphs **exist** (founding session); NPC lines that express each village's absorbed maintenance logic. **none**
- Hobb's village is *not* in The Turning; the perfectly-normal contrast plays against these.

### 4.9 The Turning — encounters and resources
- Mob roster: names, one-line "what this is a side-effect of," behavior notes. **none**
- Resource nodes: names, descriptions. **none**
- Crafting intro: the first recipe(s); the repair verb's first use. **none**

### 4.10 The Abbey of the Hopefully Infinite Thrum
- Arrival: gate; greeting ritual ("Are you well?" / "As far as anyone knows.") **exists**; Litany of Unfinished Questions **exists**.
- **Abbot Rowan** ("That's certainly one possibility."), **Brother Hollis**, **Sister Junia**, **Brother Pike**, **Sister Elm** (the Green Light), **Brother Edwin**, **Brother Aldous** — each needs a small set of lines in the hedged register; every hedged claim must be true. **none** beyond the roster tags.
- **Brack**: the restaged ceremony (TODO 1); apprentices; the Er'side on view; Patch's private recognition (no line, or one internal line). **none**
- **The Forge**: sight cutscene; *"I have one of those. Mine works."* **exists** as a line; framing beats **none**.
- **Odd jobs** (the diegetic repair tutorial): the gate ("the gate no longer makes the sound" — so it *did* make a sound Patch fixed or altered); at least 2–3 more (candidates from canon: the bell tower running fast — noticed but not fixed; something in Sister Elm's indicator room; a clock; a door). Each: request-or-no-request setup, fix interaction, monk reaction. **none**
- **Fletch / Brace** (if present in Act One): introduction; the bell-tower line; whether they leave with Patch. **none**
- Monastery forge (if the crafting intro is here). **none**

### 4.11 Going home and the letter
- Return-trip beats (weirdness now undeniable): 2–3 scripted environmental beats. **none**
- Arrival home; the letter's delivery (who brings it, given the postal service is useless — a monk? a courier? the Ministry?). **none**
- **The letter** — **exists**, verbatim.
- The region-unlock event — cutscene or environmental. **none** (TODO 3)

### 4.12 System text
- Item names/descriptions (gear from Latch's reward, resources, crafted items, Bell's soup). **none**
- Weirdness flicker lines (NPCs "behaving very strangely" — a pool of 10–20 one-liners). **none**
- Quest-log/List-style entries for Act One tasks (if the UI uses the List's register before The List exists). **none**
- Pause/menu/settings copy. **none**

## 5. The weirdness system — a documented need

**Why it's blocking:** it's the through-line of Act One and the thing that makes replay land, and nothing about it is specified beyond "deniable at first, undeniable by the end."

**Decisions needed:**
1. **Flicker catalog** — the finite set of deniable events (corner-of-screen sprite; tile glitch; NPC one-frame wrongness; sound; light) and which are v1.
2. **Interval curve** — actual numbers: starting interval, floor, shape (linear/exponential), whether measured in game-time or player-time, and whether it resets on region change.
3. **Scripted vs. random** — which beats are fixed (nine days; Last Post road; backward mill; missing river; Still Point; bell tower; the return-trip beats) and which are random fill.
4. **Regional intensity** — does The Turning flicker more than The Hold? Does Hobb's village flicker zero (yes, by canon)?
5. **Village interaction** — Good Soil (Probably) gets an early tell; Seven Chickens skips the stagger. Define what "tell" and "stagger" are concretely.
6. **Deniability rules** — never acknowledged by NPCs in Act One; never logged; never repeated identically.
7. **Replay reveal** — what changes on a second playthrough (nothing mechanically; the player just knows).
8. **Implementation contract** — a single autoload that owns the curve and emits events; scenes subscribe; data-driven catalog so modules can add flicker types later.

**What to write about it:** a one-page spec answering 1–8, plus the flicker one-liner pool (§4.12).

## 6. Planned pre-build session: Engineering constraints — agenda

A dedicated design conversation (claude.ai, not Claude Code) whose output is a short "Engineering Constraints" doc committed to `Docs/`. Fable may design *within* these; it may not choose them.

1. **Combat model** — real-time action vs. turn-based; party or solo in Act One; damage/health model; how "mobs as Forge side-effects" constrains design.
2. **Quest/flag system** — how state is stored (a flags autoload? a dictionary saved to disk?); how The List will later append; how the region lock/unlock is represented.
3. **Save system** — slots; what is saved; when; `user://` layout (seen_cutscenes.json is the precedent).
4. **Inventory and items** — data format for items; stacking; gear slots; how the nine villages' starting-gear variations are expressed (data, not code).
5. **Dialogue JSON schema v2** — choices; conditions on flags; gender variants (`text_m` / `text_f` or a token system); portraits per line; speaker ids vs. display names; localization-readiness.
6. **Scene architecture** — world map vs. connected scenes; how a "region" is a package (folder + manifest) so it can be replaced by a mod and driven by the generator; scene transition and camera conventions.
7. **Generator contract** — what a handcrafted region must expose (anchor nodes, fill slots, biome tags) so anchor-and-fill can later place/replace fill without rewriting scenes.
8. **Cutscene beats as data** — move beat arrays from GDScript to JSON so regions/modules can ship cutscenes.
9. **Crafting/resources data model** — recipes as data; repair as a verb on flagged objects; forge tiers.
10. **Weirdness autoload** — per §5 item 8.
11. **Test harness** — GUT vs. a plain GDScript headless runner; JSON schema validation; a scripted critical-path walkthrough.
12. **Asset pipeline** — which Mana Seed packs are in use; what is placeholder (portraits, cat, Forge, monks, mobs); naming conventions; the EULA rule for AI-generated assets.
13. **Conventions to restate** — GDScript only; nearest-neighbor; 320×180; autoload naming; folder layout.

## 7. Definition of done — recommendations adopted

Cheap signal first, expensive check last, per Prompt Workshop rules.

- **Static:** `godot --headless --quit` (import + script parse errors → non-zero) after every change; a JSON validator script over `data/**/*.json` against the dialogue/item/recipe schemas; a name-collision check of NPC ids against the villager naming pool.
- **Scene load:** a headless GDScript runner that instantiates every scene under `scenes/` and asserts no errors.
- **Critical path:** a scripted walkthrough that drives flags through the Act One sequence (village → Latch errand → Near Enough → mill → Wren → Hobb → border → Still Point → Abbey → odd jobs → home → letter) and asserts the letter cutscene is reachable and the other regions are locked before it and unlocked after.
- **Content completeness:** a script that lists every dialogue id referenced by scenes and fails on any missing file; lists every §4 item still marked **none**.
- **Expensive check:** a manual playtest checklist per phase (Adam), run only once the above pass.

## 8. Phasing (one workshop prompt each)

0. **Engineering constraints session** (§6) → `Docs/ENGINEERING_CONSTRAINTS.md`.
1. **Docs-only sync** (prompt already drafted).
2. **Foundations:** flags, save, inventory/items, dialogue schema v2 + migration of existing JSON, cutscene-beats-as-data, weirdness autoload skeleton, test harness. No content.
3. **Patch's village + Last Post:** exterior, Latch, Bell, gear reward, village selection screen with nine villages (data-driven variations), region lock in place.
4. **The route:** Near Enough + mill, Wren's post + maps, Hobb's village + rumors + outskirts.
5. **The Turning:** border crossing, North Office, Still Point + Sedge, the four maintenance-logic villages, mobs, resources, crafting intro.
6. **The Abbey:** monks, Brack (restaged), the Forge, odd jobs, companion (if in Act One).
7. **Home and the letter:** return beats, letter delivery, unlock event, Act One end state; full critical-path test green.
8. **Playtest fixes** and v1 tag.

Writing (§4) is a parallel track and gates phases 3–7; Fable does not author lore.

## 9. Next actions, in order

1. Run the docs-only prompt; push; Sync now.
2. Hold the engineering-constraints session (§6).
3. Resolve pre-build TODOs 1–7 (§3) in design sessions; write the weirdness spec (§5).
4. Start the writing list (§4), Latch and Brindle first — they set the voice for everything after.
5. Workshop the Foundations prompt (phase 2).
