# MOSTLY_CANON.md — The World Bible (Consolidated)

**Version:** 2026-08-28, rebuilt from the repo Docs, eight conversation extracts (June 7 – Aug 11), five character-sheet drafts, the build code, and Adam's rulings of 2026-08-28. Provenance for every row is in **MOSTLY_DECISION_LEDGER.md** (ledger IDs cited as `[A1]`, `[E11]`, etc.).

**Status legend:** LOCKED / PROVISIONAL / OPEN / INFERRED / REJECTED / TODO. **Authoritative wording is quoted, not paraphrased.** Where something is Adam's own words, that is said.

**How to read this document.** The repo Docs (00–06) are the committed canon *for what they cover*, but a large body of locked material from the July 7 session was never written into them. This document merges both. Where the two disagree, the merge rule applied is: Adam's latest explicit ruling > later user-authored text > later user-confirmed text > earlier text > assistant-only proposals. Items pulled *back* from "locked" in the Docs are marked as such.

---

## 1. What the Game Is

**Title:** *Mostly* — **Tagline:** *It's mostly fine.* `[A1]` LOCKED.

**Scope:** "$5–$10 steam game," not AAA. `[A4]` LOCKED (Adam, July 21).

**Aesthetic:** 16-bit top-down RPG in the register of Chrono Trigger, Secret of Mana, FF4–6. Godot 4.6.2, GDScript only, 320×180 viewport, Mana Seed 16×16 assets, nearest-neighbor. `[A12–A13]` LOCKED.

**The thesis (Adam-confirmed, July 7) — LOCKED `[A11]`:**

> "The joke at the heart of Mostly isn't that religion is foolish. It's that if you give ordinary people a machine that saves civilization for fifteen hundred years, they will preserve it with songs, festivals, recipes, village customs, and stories about giants — and somehow, against all odds, that turns out to be enough."

**Back-of-box copy — LOCKED, Adam's Draft 4 verbatim `[A10]`:**

> "You know that feeling when a machine makes a noise it wasn't making yesterday? Patch knows that feeling. The Mostly is a peaceful country of farms, villages, monasteries, and traditions that have worked for longer than anyone can remember. Most people are content to leave well enough alone. Patch isn't most people. A routine commission becomes an investigation. An investigation becomes a journey. A journey becomes a growing suspicion that an awful lot of very important things are being maintained by people who no longer remember why. Explore a world where every custom exists for a reason, every institution is preserving part of a forgotten truth, and every answer leads to another question. A fantasy RPG about craftsmanship, curiosity, and figuring out what's making that noise before it becomes everybody's problem."

Rejected drafts 1–3; specifically struck: "Patch may be the first person in centuries with the skills to recognize it" — chosen-one drift. `[A9]` REJECTED, and flagged as an instinct to watch.

### Design pillars (Docs/01) — LOCKED `[A5–A7]`

1. The writing is the hook (Pratchett-adjacent deadpan).
2. No villain. "Nobody intended this. Nobody is to blame in a satisfying narrative sense. Everyone is implicated."
3. Completable by construction. Base game is a complete story; nothing must be installed or built to finish it.
4. Combinations over count (endgame modules must interact). **Under revisit — see §11.**
5. Deadpan, not absurdist. "Patch does not think anything is funny. The player does. That gap is where the humor lives." Exception: stub-region / module content is "really weird and often silly, tongue-in-cheek" (Adam, Aug 5). `[A6]`

**Humor rule (LOCKED):** "The humor works through restraint and the addition of a single unexpected detail that implies a whole history. Avoid names that are funny on the surface without depth underneath."

**Institution rule (LOCKED):** "Every institution in this world is accidentally managing the consequences of The Forge through bureaucracy and ritual without knowing it. New institutions should follow this pattern."

---

## 2. Core Premise and the Catastrophe

LOCKED `[C1–C5]`. Docs/00 wording:

> Patch made **hollow spheres** for a commission. The spheres power **The Forge** — an ancient floating gyroscope that maintains a barrier (The Hold) keeping paranormal phenomena out of the known world. Someone refueled The Forge with a bad batch of **Spooky Fluid**. The Forge destabilized. The world is unraveling. No villain. A chain of ordinary people making reasonable mistakes. Patch just wants to go home.

- **The spheres were perfect. The Fluid was wrong.** Patch's contribution is the vessel, never the fault.
- The Forge was running low on power before the refuel; Act One's flickers are the barrier weakening. The botched refuel is what destabilizes it — and it is loaded **only after Patch has left the Abbey** `[C12]` LOCKED, reaffirmed by Adam 2026-08-28.
- **Spooky Fluid** is the canonical name. Adam: "I'm apt to even call it Spooky Fluid for realsies." "No further dignification is warranted or appropriate." `[C2]`

---

## 3. Patch

LOCKED `[B1–B8]`.

- Blacksmith. Gender: player's choice. Home: one of nine starting villages.
- Name rationale (assistant proposed, Adam: "HOLY SHIT YUP"): "a blacksmith name, a software term, a verb meaning 'to fix something imperfectly,' and a personality description simultaneously."
- Voice: "competent, unglamorous, and annoyed." Does not dwell, does not catastrophize. "Irritation is the dominant emotional register. Respect is earned slowly and expressed sideways."
- Adam: "I really like the 'fuck this I'll fix it myself' attitude, so I don't want to go too hard into the character feeling obligated to fix the problem. Annoyed, yes, but obligated, no."
- Key lines (Adam's words): *"Oh for the love of — I made that part."* / *"Fuck this. I'll fix it myself."* / *"I have one of those. Mine works."* The last "is the recurring joke for the second half of the game. It never gets old. Patch is never wrong."
- **Precision smith, not a combat smith** `[B6]`: makes parts, mechanisms, hollow spheres. "Like a watchmaker who can't build a bridge." Buys base weapons/armor; crafts modifications, upgrades, attachments, gadgets.
- **Character trait established in the opening** `[B7]`: notices something is wrong, stops until he figures out what, files it, moves on. Build line: *"File that. Keep moving."*
- Has a cat. The cat knocked a cup over the order form. "The cat is not sorry." `[B8]`
- Patch's reaction to the maintenance hatch inscription (§5): *"...well that explains an awful lot."* — "This is the thesis statement of the game." `[C7]`
- **Pronoun convention** OPEN `[B9]`: Docs mostly "they"; Adam's prose and July 7 material "he." Gender is player's choice, so authored text needs a rule.

---

## 4. The World

### 4.1 Names and character — LOCKED `[F1]`

| | |
|---|---|
| Official | The Principality of the Mostly Peaceful Interior |
| Common | The Mostly |
| Folk | The Hold — "origin unknown, predates written record"; accidentally accurate |

In-world etymology of "The Mostly": OPEN `[F2]` (an assistant speculation on Aug 11 was never adopted).

The Hold is "Boring. Safe. Agrarian. Communal by necessity rather than warmth," with "a subtle undercurrent of restlessness." Scale ~one week across. Biome bleed from every outer region. NPC archetypes: the contented majority; the willfully ignorant; the street prophets ("not wrong, just not quite right"); the rare sane few ("not marked, not glowing, found through exploration and exhausted dialogue"). LOCKED.

### 4.2 Structure and map

- Circular world; The Hold at center; six outer regions as irregular wedges; stub regions beyond. LOCKED `[F5]`.
- Margin slightly NE of true center because building at the exact center "seemed suspicious" — in the founding documents. LOCKED `[F3]`.
- True center: untouched wilderness with the engineers' circle. Contents OPEN. LOCKED that it is deferred. `[F4]`
- **Map layout (July 7, LOCKED then; now flagged for review `[F15]`):** "Clockwise from north: The Turning, The Measure, The Flow, The Balance, The Quiet, The Distance. All six outer regions share a direct border with The Mostly. No gaps. Stub regions extend outward from outer regions only — no stubs connect directly to The Hold." Stub positions: N of Turning, E of Measure, SE of Flow, S of Balance, W of Quiet, NW of Distance. Art deferred to Godot buildout.
- **⚠ Contradiction:** Docs/04 says "Place [The Balance and The Turning] adjacent on the map." In the six-wedge clockwise order above they are opposite each other, not adjacent, yet the July 7 text also says "their shared corner is visible on the map." Unreconciled. Falls under the territory review `[F9]` TODO.
- **⚠ Contradiction:** Docs/04 places the circle in the center wilderness *and* says Margin's buildings sit "just outside" it; Docs/00 says "Circle in Margin." Unreconciled.

### 4.3 Margin — LOCKED `[F3]`

Grid slightly rotated from true north ("street signs… require extra reinforcement"). Notable street: East South East Slightly Left of Center Avenue. Neighborhoods: Upper Filing, Lower Filing, East Upper Lower, Records, Temporary Annex (700 years old; contains the Royal Palace), Overflow.

Government: **The Ministry of Normal Things** ("Has never solved a crime. Has accidentally prevented seventeen apocalypses."); **The Office of Unlikely Events** (open 24h; source of The List); **The Department of Acceptable Distances** ("anything that hums"; the measured safe distance from The Forge is in their records, filed without comment); **The Bureau of Rotational Affairs** ("Leave permanently unexplained").

The Archivist (support NPC, PROVISIONAL `[E23]`) is probably based in Records.

### 4.4 The postal service — LOCKED `[F14]`

"Canonically dysfunctional. Exists. Letters take weeks. Forms required in triplicate. Deliveries arrive at the wrong [destination] with reliable frequency. The Department of Deliveries has never explained its routing system. This is why commissions and anything important travel by hand. Nobody trusts the post with anything that matters. Explains the commission chain without contrivance." (The July 7 version tied this to a "Probably" village in every region; that village is REJECTED `[F8]`, the postal dysfunction survives.)

### 4.5 Perfectly normal settlements — LOCKED `[F13]`

"Some settlements in the world are entirely unaffected by the world-breaking. Sky is blue. No glitches. Everything exactly as it always was. Each triggers its own questline to figure out why. The existence of these places is quietly more unsettling than the weirdness itself." Hobb's village is the first.

### 4.6 The six outer regions

Each region: one fixed border city (Margin's outpost, "so civil servants can technically say they've been to the outer lands"); 2–3 generated biomes; smaller settlements from name pools; one monastic order; a folklore and a reality (OPEN `[F20]`). LOCKED structure `[F19]`.

**Regional engineering purposes — LOCKED `[F17]` (July 7):** each region's culture is the residue of an engineering function.

| Region | Engineering purpose | Docs/04 border capital (PROVISIONAL) |
|---|---|---|
| The Turning (contains The Forge, the Abbey) | Dynamic Stabilization | North Office — "The city exists because someone had to file maintenance requests." |
| The Measure | Calibration & Tolerance | Linecross — "Built exactly one foot outside the provincial border. This distance is constitutionally protected." |
| The Distance | Safe Exclusion Zone | Comfortably Far |
| The Quiet | Acoustic Monitoring | Lowvoice — "The loudest building is the bakery." |
| The Flow | Thermal & Fluid Regulation | Drainage — "A beautiful city. Terrible name." |
| The Balance | Countermass & Load Management | Counterweight — "Every statue leans very slightly uphill." |

**Mottos — TODO `[F16]`.** Adam's ruling: one motto per region; each monastic order has its own phrase, related to the region's. Two candidate sets exist from July 7 and must be reduced to one per region:

| Region | Folk motto (J7 settlement list) | Engineering motto (J7) | Order motto (Docs/05) |
|---|---|---|---|
| Turning | "A thing in motion is significantly less haunted." | "If it stops, everything else starts." | "Probably." |
| Measure | "Precision is kindness." | "Measure twice. Measure tomorrow." | "Precision is kindness." |
| Distance | "Far enough is a place." | "Leave room for things you cannot see." | — |
| Quiet | "If you heard it, don't repeat it." | "The machine speaks quietly." | — |
| Flow | "Everything should go somewhere." | "Flow is health." | — |
| Balance | "One more rock than necessary." | "Everything supports something." | — |

**The shared children's story — LOCKED `[F18]`.** "Every region tells the same children's story differently. Nobody realizes these are all fragments of the same story":
- Turning: *"Long ago, six giants held up the world while a seventh turned the handle."*
- Measure: *"The world stays together because someone keeps checking."*
- Distance: *"Leave room for the things carrying tomorrow."*
- Quiet: *"If you listen carefully, the earth is humming."*
- Flow: *"Rivers know where they're going."*
- Balance: *"Never take the last stone."*

Docs/04 institutions per region (Ministry of Predictable Motion, Bureau of Distances, Department of Straight Roads, Office of Appropriate Separation, Ministry of Boundaries, Department of Audible Affairs, Bureau of Night Sounds, Ministry of Water Going Where It Should, Office of Acceptable Dampness, Department of Equal and Opposite Things, Bureau of Small Adjustments) stand as PROVISIONAL `[F6]`. Note: two of North Office's descriptions duplicate Margin's jokes verbatim — probable drafting residue.

### 4.7 Settlements — TODO, thorough review required `[F9]`

Adam, 2026-08-28: the settlements per territory, "and probably the territories themselves," need a thorough review. Current state:

- **Docs/04 village lists** (six per region) and **Docs/05 per-order settlement lists** both exist and only partially overlap. PROVISIONAL `[F7]`.
- **July 7 settlement lists** (nine per region plus mottos) — NOT ADOPTED `[F8]`. A "Probably" village in every region — REJECTED: "that surfaces enough already and I don't want to hit people over the head with it."
- **Plot-bearing places, LOCKED `[F11]`:** **Near Enough** (half a day's walk from Patch's village; Brindle lives here; first chain stop), **Last Post** (outlying settlement just beyond Patch's village; Bell runs the kitchen; Latch's errand; "The road home doesn't go back the way it came" — first soft weirdness; something here needs solving later, OPEN), **Still Point** (village in The Turning; Sedge's posting; "The one spot in the region where nothing rotates. Residents find this deeply unsettling and refuse to leave.").
- **To include, LOCKED `[F10]`** (Adam: "I like those names and would like them included"): **Stable Frequency** (harvest festival always exactly on time), **Nominal** ("everything works. Just, works."), **Acceptable Variance** (every building a slightly different height; no one allowed to explain), **Within Tolerance** (bell rings irregularly; residents anxious when it becomes regular) — these four in The Turning, "residents have absorbed Forge maintenance logic into daily life without knowing it"; and **The Village of Sensible Decisions** (implies the opposite; an outlier in The Hold).
- Hobb's village: unnamed, perfectly normal, near The Turning border; the missing river ran nearby, not through it. PROVISIONAL `[F12]`.
- Available-but-unplaced names from the founding brainstorm: Squint, Overthere, Blink, Roundabout, Axis-on-the-Hill, Bucket's End, The Wet Silence.

### 4.8 The nine starting villages — LOCKED `[G5–G7]`

Again, Revised, Temporary, Good Soil (Probably), Seven Chickens, One More Mile, Fine Now, Hay, Mostly, New Again. Epigraphs and pro/con text: Docs/03 is authoritative. Seven Chickens' pro is obfuscated on the selection screen. Village surroundings reflect the pro/con; a safer route always exists. **⚠** Several pro/con mechanics still reference "world-break events" / "no stagger on breaks" from the cut repair loop — need re-grounding once Act Two's event vocabulary exists. Act One definition (M-5): a world-break event is a scripted overt beat or a misroute. See Docs/WEIRDNESS_SPEC.md §5.

### 4.9 Biomes — LOCKED `[F19]`

Plains, Savanna, Mountain, Cold, Desert, Wetlands/Marsh, Dense Forest, Badlands, Coastal, Volcanic ("Patch finds this refreshing"). Which biomes each region draws from: OPEN `[G4]`.

### 4.10 Stub regions

Docs/04: "Exist on the map as labeled space with no content at launch… The stub region is not missing content — it is an invitation." Must be "legibly empty" — outlines, names, NPC references (July 7). **This concept is now under revisit** — see §11 `[G16]`.

---

## 5. The Forge, the Engineers, and the Sacred Texts

- **The Forge** `[C1]` LOCKED: "an ancient floating gyroscope that defies the laws of physics… It floats. It shouldn't work. It works anyway." Patch: *"A floating gyroscope which defies the laws of physics, which pisses Patch off."*
- **The original engineers** `[C6]` LOCKED: "Not gods, not chosen ones. Boringly competent engineers who wrote maintenance schedules and trusted instruments more than assumptions." Whether any record of individuals survives: OPEN.
- **The maintenance hatch inscription** `[C7]` LOCKED, verbatim:
  > *ROTATIONAL FIELD STABILIZATION ARRAY*
  > *Routine Service Interval: 180 Days*
  > *If unusual vibration persists, contact Central Engineering.*
- **The Er'side** `[C10]` LOCKED: "The order's most sacred text. Originally titled *User's Guide*. Over centuries of handling, most of the cover was lost. Only the letters *er's ide* remain. The order named it accordingly. It is an ancient maintenance manual for The Forge. The order treats it as scripture. They do not know what it is. Patch will know immediately upon seeing it. Patch will not say so right away."
- **The reading device** `[C11]` LOCKED: "Ancient steampunk-aesthetic microscope-like device used to read the Spooky Fluid formula. Requires a specific eyepiece to operate. One eyepiece remaining. There used to be more. Nobody knows where they went. Three apprentices are nearly fully trained but cannot complete training without an eyepiece." Missing-eyepieces questline: OPEN.
- **The Thrum and the Grinding** `[C9]` **PROVISIONAL** (pulled back from "locked" by Adam, 2026-08-28): the Abbey is named for the Thrum, "the sacred sound made by properly balanced Spooky Fluid"; The Grinding is named for "the sound The Forge makes when Spooky Fluid runs low." The idea that these are two physically distinct sounds the monks venerate/dread without connecting was an assistant addition on July 21 and was never confirmed. Docs/05 currently says "(locked)"; that is wrong.
- Forge age: ~1,500 years `[C8]`.

---

## 6. Monastic Orders

**Convention** `[H1]`: "The [Badass-Sounding Noun]." Only The Grinding actually follows it. **Throughline** `[H2]` LOCKED: "every monastic order is accidentally describing The Forge's maintenance requirements through their theology… They are all, unknowingly, monks of The Forge. Patch will figure this out before they do. Patch will not be gentle about telling them."

### The Order of the Most Sacred Mystery / The Grinding — The Turning

**⚠ OPEN `[H6]`:** whether The Grinding and the Order of the Most Sacred Mystery are one order under two names or two bodies. Docs/05 describes both; the summons letter is signed by the Order; July 7 gives *separate rosters* to each (below), which points toward two bodies. Unresolved.

**Settlement:** The Abbey of the Hopefully Infinite Thrum `[H5]` LOCKED. Adam's rationale, verbatim: "Named for the overriding intention of every action taken by its monks. They can't really explain the WHY, but they know that as long as The Thrum continues, everything seems to be OK. Mostly." Former name **Glorp Abbey** REJECTED `[H4]` — Adam: "There's a very popular book series out which uses 'Glurp' as a verb and in a perfect world, there will be a ton of overlap between Dungeon Crawler Carl readers, and players of this game. It's going to break the immersion."

Docs/05 content — LOCKED `[H3]`: motto **"Probably."** (older: "We Shouldn't Rule It Out."); greeting "Are you well?" / "As far as anyone knows."; empirically-derived epistemic humility (confident novices got haunted); virtues; Great Heresy = absolute certainty; the Litany of Unfinished Questions; relics (Empty Box, Unlabeled Key, Fifth Appendix); festivals (Feast of Plausible Outcomes, Day of Tentative Conclusions). The monks are "perpetually drunk on their own beer or high on their own cultivation… This is not dereliction. This is coping." Rule: every hedged thing they say is accurate; every confident claim by any other institution is wrong.

**Named members `[E13–E16]` LOCKED:**
- Order of the Most Sacred Mystery: **Brother Hollis** (Keeper of Questions), **Sister Junia** (Observer of Indicators), **Brother Pike** (Apprentice Archivist, 32 years in), **Sister Elm** (Keeper of the Green Light, 19 years watching one unchanged indicator), **Abbot Rowan** ("That's certainly one possibility."), **Brother Aldous** (memory for precedent; Fifth Appendix believer), **Brack** (older monk; see §7), **Sedge** (see §7).
- The Grinding: Brother Flint, Sister Emery, Brother Moss, Sister Whet, Prior Burr.
- **Brother Edwin:** "Every monastery has one monk named Brother Edwin. He is not the same person. No one can explain this. Every Brother Edwin is: earnest, slightly confused, carrying entirely too many notebooks, and one step away from making a catastrophic but completely understandable mistake. Patch never notices anything unusual about this." Never explained.
- **The sober monk** `[E18–E19]`: Fletch (if Patch is female); Brace (if Patch is male — PROVISIONAL "for now"). Docs/05's "young, anxious" sketch is superseded.

### The other five orders — LOCKED `[H7]`, rosters LOCKED `[E15]`

| Order | Region | Core belief / ritual | Accidentally describes | Roster |
|---|---|---|---|---|
| The Brotherhood of Proper Margins | Measure | "Precision is kindness." One-inch margins; schisms over margin width. | Tolerances | Brother Rule, Sister Tessa, Brother String (was Chalk), Sister Plum, Prior Ells |
| The Monastery of Respectful Separation | Distance | Everything needs room; one polite step backward before greeting. | Safe distances | Brother Alder, Sister Brin, Brother Gap (was Hobb), Sister Vale, Prior Fern |
| The Silent Custodians of Ambient Noise | Quiet | "Silence is not the absence of sound. It is proper sound management." The Listening Stick — **"Do not ever explain the Listening Stick further. Do not give it powers. It is just a stick. That is why it works."** | Maintenance-warning monitoring | Brother Ash, Sister Willow, Brother Reed, Sister Moss, Prior Quiet Tom |
| The Abbey of Continuous Drainage | Flow | Everything should flow; greatest sin standing water; Great Cleaning of Ditches. | Fluid circulation | Brother Brook, Sister Sluice, Brother Weir (was Bucket), Sister Rill, Prior Channel |
| The Order of Counterweights | Balance | "For every stone moved, another should feel appreciated." One rock moved nightly. | Rotational equilibrium | Brother Cairn, Sister Slate, Brother Lever, Sister Pebble, **Prior Balance** |

**Prior Balance** — "LOCKED as best single character in the game": "He once spent four hours adjusting a single brass weight. When he finished, every clock in the monastery resumed ticking at exactly the same moment. No one mentioned it." Never explained. `[E16]`

Rejected order names from the founding brainstorm `[H8]`: The Rule Against Looking Directly Into The Sphere; The Litany of Unpleasant Sloshing; The Doctrine of Respectful Distance (absorbed); The Order of the Sacred Spin; "Et Cetera."

---

## 7. The Delivery Chain and Major Supporting Cast

**Chain — LOCKED `[E1]`:** Patch → **Brindle** → **Wren** → **Hobb** → **Sedge** → The Abbey → **Brack**.

**Direction of travel (important, and mis-stated in the Aug 8 character sheets):** the *request* originated at the Abbey and came down the chain to Patch — Brindle is the one who handed Patch the order form. Patch's *delivery* goes back up the chain, meeting each person in turn. The Aug 8 sheets describe the request traveling from Patch's side toward the Abbey; that is inverted. `[E10]`

July 7 characterization is LOCKED; the Aug 8 sheets are PROVISIONAL proposals layered on top (see MOSTLY_STORY_STATE.md §6 for the selection state).

- **Brindle** `[E2]` — Trader. Based in Near Enough. Delivered the commission order to Patch (so Brindle *is* the "casual acquaintance" of Docs/02). Introduces the shops system. When Patch arrives, "visibly rattled — saw a mill running against the river current on his latest circuit. Sends Patch to investigate. Cheerful baseline, currently rattled. Will be relieved if Patch fixes the mill. Will not ask follow-up questions."
- **Wren** `[E3]` — Cartographer, female. At a trading post halfway between Near Enough and the northwestern border of The Hold. "Was looking for a missing river when she met Hobb." Source of every map. Practical, unsentimental: notes like "road terminates unexpectedly — remeasure recommended." See §9 for her mechanics.
- **Hobb** `[E4]` — Innkeeper, male. Runs the only inn in the perfectly normal settlement near The Turning border. Introduces the rumor mechanic. Outskirts problem: a miller with a stopped mill and a ferryman with no river; Patch can help both.
- **Sedge** `[E5–E6]` — Monk of the Order of the Most Sacred Mystery, female. Stationed at Still Point on a six-month rotation "watching nothing for a purpose nobody remembers." Cannot leave until relieved. "Patch asks what she's watching for. Sedge says she doesn't know. Patch asks why it's stressful. Sedge doesn't have a good answer. This conversation will bother Patch for the rest of the game." She leaves the order — **when** is OPEN (Adam, Aug 8: leave the ambiguity intact). July 7's later beat (Patch meets her again after she's left; "She decided she'd had enough of 'probably'"; "Patch respects this enormously and doesn't say so") is PROVISIONAL pending that timing.
- **Brack** `[E7–E8]` — "Older monk. Order of the Most Sacred Mystery. Final chain link. Botched the Spooky Fluid." Not a villain: "He checked the book. Found an entry. The shade was different. Made a reasonable call with available information." State when Patch finds him (Aug 8, Adam-selected): "panicked into action and [has] been making it worse through well-intentioned tinkering." Full name, age, history: OPEN.
- **Latch** `[E11]` — Gate guard of Patch's village, male, 23 years at the gate. Adam: "it's exactly the sort of practical name that emerges in a civilization built around maintenance." Canonical beat, Adam's words:
  > *"How long have you worked the gate?"* / *"Twenty-three years."* / *"Ever seen anything strange?"* / *"No."* / *(pause)* / *"Which is exactly how I like it."*
  "Which is basically the entire philosophy of The Hold in one conversation."
- **Bell** `[E12]` — Runs the kitchen at Last Post. Her soup, at a discount if Latch's message arrives on time, gives a unique restorative buff.
- **"Voices From Outside"** — speaker label for unnamed neighbors/guards shouting the date back. LOCKED.

### Companions `[E17–E22]` LOCKED
- **Fletch** — primary companion if Patch is female. Ranged; makes arrows and throwables. The sober monk: "new enough to the order to still question things, experienced enough to understand what they're seeing."
- **Brace** — primary companion if Patch is male. Support; deploys shields; unique armor upgrades if their storyline is completed. Also the sober monk for male Patch (PROVISIONAL).
- Companion is always the opposite gender to Patch.
- The companion's first noticing: "the monastery bell tower, which has always rung precisely at 6am, 12pm, and 6pm, has been running slightly fast — and getting faster every day. The older monks filed this under 'probably fine.'"
- **Tine** (rogue; dagger; "observes things others miss"), **Hasp** (thief; lockpicks; "Ministry of Normal Things almost certainly has a file on them"), **Sprig** (young herbalist; "shows up at inconvenient moments"; "most likely to be discovered by accident"). Unlockables found through exploration, no markers; base game completable with the primary companion alone.

### Support team — PROVISIONAL `[E23]`
Alchemist (potions), Archivist (diegetic codex; Margin/Records), Fence (black market). Names and locations TBD. NPC archetypes for later placement `[E24]`: Surveyor, Itinerant repair person, Census taker.

### Villager naming pool — LOCKED `[E25]`
Latch, Boots, Chalk, Nibs, Bucket, Crick, Pockets, Fence, Nails, Ditch, Bell, Post, Brindle, Cobb, Tiller, Hinge, Cooper, Wren, Knott, Pindle, Brack, Sedge, Hobb. Convention: "Practical/maintenance words, old trades, natural materials. Villages may not remember real names anymore." Monk names were de-conflicted against this pool (Hobb→Gap, Chalk→String, Bucket→Weir, Cobb→Burr).

---

## 8. The Supernatural and the Unraveling

- Paranormal phenomena exist outside the barrier; inside, they are regulated bureaucratically (haunted ruins, "calmer ghosts," "anything that hums"). LOCKED/PROVISIONAL.
- **Act One weirdness** LOCKED: deniable flickers at lengthening-then-shortening intervals — "Spooky sprites in the corner of the screen for a split second," glitchy landscape, odd NPCs, environmental wrongness. Undeniable by Act One's end. Reads as atmosphere on first play, as early unraveling on replay.
- **Specific weirdness beats LOCKED (July 7):** the nine days (§Story); the road home from Last Post not going back the way it came; the mill running against the current (fixable; cause never explained); the missing river; the bell tower running fast; Still Point where nothing rotates.
- **Post-botch symptoms** (The List samples, LOCKED): a bridge sometimes not there; a fourth ring from three bells; a well grown deeper; a straight road with a bend.
- Perfectly normal settlements are the inverse symptom (§4.5).
- Walking trees "to get in his way or keep an eye on him" — PROVISIONAL, later game, not the opening `[F21]`.

---

## 9. Narratively Significant Mechanics

- **Starting village pro/con** LOCKED; **village map mechanic** LOCKED; **circle visibility** PROVISIONAL.
- **Anchor-and-fill generation** — LOCKED architecture and a **HARD requirement** (Adam, 2026-08-28: "I'd like the game to be replayable, so some form of procedural generation and the anchor/fill process should be baked in."). Not yet built. `[G1–G4]`
- **Crafting and the forge network** LOCKED `[G9]`: home forge → blacksmith forges (3–5 errands each; unique buffs *and* debuffs; none objectively best) → monastery forges (unlock on order's main quest; components reflect theology). Workbenches only at blacksmiths and monasteries; not portable (REJECTED). Non-ideal substitution is a feature. Repair ≠ crafting.
- **The cart/wagon build** — REJECTED (Adam: "let's forget about building the cart… a holdover from when I wanted to focus more on modding"). Patch owns a horse and wagon in the opening. `[D14–D15]`
- **Bird flipbook maps (Wren)** LOCKED, Adam's idea: "it would be cool as fuck if the player collects all the maps and quickly pages through them, the bird looks like it's flying like a flipbook." Never explained. `[G11]`
- **Map notes** LOCKED: mundane early; as the world breaks, notes about moved roads and wrong landmarks appear; late-game navigational tool; never flagged as a hint system. `[G12]`
- **Rumor network (Hobb)** LOCKED: innkeepers share a loose network; rumors fragmentary, secondhand, occasionally wrong; reference unmarked quests. Hobb's are the most accurate because his village is unaffected. Patch: "that is not useful information." Every time. `[G13]`
- **Party** LOCKED: max 3 including Patch; one Camp per region, costly to reach; swaps only at Camp (the cost is intentional). Camp visuals per character (arrows drying; shield on a tent; lockpicks on a cloth; herbs; "nothing visible, but things have occasionally been moved"). `[E17, E22]`
- **One long Zelda-style fetch quest** exists somewhere; not in the opening. `[G10]`
- **The List** as diegetic quest log — LOCKED. Modules appending to it — PROVISIONAL `[D8]`.
- **Cutscene skip** — built.
- Never designed: inventory, save system, combat model, reputation, potions, the weirdness event system. `[G21]`

---

### 9.1 Act One scope rulings (2026-08-28) — LOCKED
Act One ends with the summons letter arriving at home `[U2-1]`. During Act One only The Hold and The Turning are reachable; the other regions unlock via an in-world event around the letter (reason and event OPEN) `[U2-2]`. Post-delivery, Patch explores The Turning: combat encounters, resources, crafting intro `[U2-3]`. Act One v1 is handcrafted but generator-driveable `[U2-4]`; all nine villages selectable with their Docs/03 pro/cons intact `[U2-5]`; dialogue carries gender variants `[U2-7]`. Full plan: MOSTLY_ACT1_BUILD_PLAN.md.

## 10. Rules of the World (author-level, LOCKED)

1. No villain, ever.
2. Every institution accidentally manages Forge consequences.
3. Hedged claims are true; confident claims are false.
4. No witness overlap: Patch is never present when The Forge fails.
5. Patch's culpability stays private; the monks never learn it.
6. No chosen-one language, ever.
7. Never explained, by design: the Bureau of Rotational Affairs; the Listening Stick; the Empty Box; the Fifth Appendix's contents; Brother Edwin's multiplicity; Prior Balance's clocks; why the mill ran backward; the bird in the maps; the nine days (an explanation exists in-world but is never confirmed to Patch). The Unlabeled Key: "decide intentionally either way."
8. Humor via restraint and one implied-history detail.
9. Stub/module content may be sillier than the mainline.

---

## 11. Endgame, Modules, and Modding — UNDER REVISIT

**History:** modding was the founding premise (in-game declarative mod system as Act Two+ progression; community sharing load-bearing) → cut July 2026 (Adam: "Are we overcomplicating the game with this modding first mentality…?"; later: "I liked the story so much that I didn't want to distract from it") → replaced by 4–6 studio-authored endgame modules filling content-free stub regions, pairwise interactions required (Docs/03).

**Adam, 2026-08-28 `[G16]`:** "I need to revisit the endgame stuff. Obviously, the game should ship complete with modules for each 'outer region,' but I DO want to give the ability to mod the game by replacing those regions. An initial set of mods, sure, we can release on Nexus to give examples of how it works."

What this leaves standing: base game complete without mods (LOCKED); community modding optional with zero base-game dependency (LOCKED); modules/regions loaded as data packages (LOCKED direction); release-valve tone for that content (LOCKED); July 7's "not DLC, open-source files, seeded on Nexus" (PROVISIONAL). What it puts in question: whether stub regions are content-free at launch at all, the 4–6 count, and the interaction-matrix requirement. **TODO: revisit the endgame design as a unit.** Until then, treat Docs/03's endgame section as PROVISIONAL.

---

## 12. Things Characters Believe That Are False

Every order thinks its theology is about virtue; it is maintenance. The Order treats a User's Guide as scripture. The Grinding sound is a maintenance alert, not holy. Nobody connects "The Hold" to holding anything back. The Department of Acceptable Distances doesn't know why it has a Forge distance on file. Latch has never seen anything strange and likes it that way. The monks think Patch is simply a known fixer. Confident institutions believe they understand what they manage.

## 13. Things the Player Initially Believes That Are False

That the delivery is a simple delivery; that the nine days is a slip; that the road home just looks different; that the weirdness is atmosphere; that the monks are useless; that the spheres might be the problem.

## 14. Author-Level Truths the Player Should Not Initially Know

The Forge and what it does; that the request originated at the Abbey; that Patch's spheres are part of a refuel that will go wrong after Patch leaves; that Brack misread a shade; that every order describes one machine; that the Er'side is a manual; what the circle recontextualizes; that the ending reflects how much of this Patch learned.

## 15. Stale or Erroneous Passages in the Repo Docs (mechanical cleanup list)

- Docs/02: "the order must arrive in five days" → superseded by Adam's prose (8 days). Cart decision and "cannot carry all of them" → REJECTED.
- Docs/02 §Inciting Incident: the casual acquaintance is Brindle; Docs/06 #10 resolved.
- Docs/06 #9 (gate guard) resolved: Latch.
- Docs/05: "(locked)" on the two-sounds passage → PROVISIONAL. "identity… of the sober monk" → Fletch/Brace.
- Docs/02 §The List: "Endgame modules append entries" → PROVISIONAL.
- Docs/00: "Confirm engine (Godot 4?)" stale; "Write the back-of-box copy" done; "opening scene in prose" done.
- Docs/04: map positions no longer "Future" (July 7 layout exists) but are under review; Balance/Turning adjacency conflict.
- Cross-references: Docs/02 "see Document 5" → 3; "Document 6 for full monastic detail" → 5; Docs/04's six "Full detail in Document 6" → 5.
- Docs/03: "Modders can add rows… scales with community contribution" — mod-era residue.
- Docs/01 Key References — mod-era; Claude Project description ("modding-as-game-mechanic") — stale.
- Village pro/con text referencing "world-break events."
