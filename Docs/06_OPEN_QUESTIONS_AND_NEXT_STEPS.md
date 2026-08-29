# MOSTLY — Game Design Document

> **Supersession notice (2026-08-28):** Where this document conflicts with
> `Docs/handoff/MOSTLY_CANON.md` or `Docs/handoff/MOSTLY_DECISION_LEDGER.md`, the
> handoff documents win. Status tags in this file are not authoritative; consult the
> ledger. See `Docs/handoff/MIGRATION_WARNINGS.md` for known errors in this file.

## Document 6: Open Questions & Next Steps

-----

## Decisions Made (Do Not Revisit Without Good Reason)

These are locked. Changing them has downstream consequences across multiple systems.

|Decision                  |Value                                                   |
|--------------------------|--------------------------------------------------------|
|Title                     |Mostly                                                  |
|Tagline                   |It’s mostly fine.                                       |
|Protagonist name          |Patch                                                   |
|Protagonist profession    |Blacksmith                                              |
|The machine               |The Forge (floating gyroscope, defies physics)          |
|Power source              |Spooky Fluid in hollow spheres                          |
|Catastrophe cause         |Botched Spooky Fluid batch — no villain                 |
|World name (folk)         |The Hold                                                |
|World name (official)     |The Principality of the Mostly Peaceful Interior        |
|World name (common)       |The Mostly                                              |
|Capital                   |Margin                                                  |
|Outer regions             |6 named + stub regions                                  |
|Act One                   |Completable vanilla                                     |
|Mod system                |DISCARDED as core mechanic (July 2026) — see below      |
|Endgame modules           |Studio-authored, 4–6 at launch, optional, fill stub regions|
|Story structure           |At least 2–3 acts in the main story. Act One ends when Patch reaches The Forge — that is not the game's ending.|
|Stub region / module tone |Deliberately weirder and sillier than the mainline deadpan story — the tonal release valve|
|Generation                |Anchor-and-fill procedural (map/content variety, independent of modules)|
|Completability guarantee  |Base game is a complete story with zero modules installed|
|Tone                      |Deadpan, not absurdist                                  |
|Starting villages         |9, each with mechanical pro/con from character backstory|
|Monastic naming convention|The [Badass Noun]                                       |
|Thematic throughline      |All orders unknowingly describe Forge maintenance       |
|Act One→Two bridge        |Five locked beats: deliver spheres → unprompted repairs at the abbey (diegetic repair tutorial) → go home → Forge destabilizes post-departure → monks summon Patch back. See Document 2.|
|Summons/culpability rule  |Monks summon Patch as a known fixer, not a suspect; Patch's "I made that part" realization stays private, on-site — no witness overlap|
|Fluid sequencing          |Brack's bad batch is loaded into The Forge only after Patch has already left — locked to prevent any witness overlap|
|The List                  |Complaints forwarded from the Office of Unlikely Events in Margin, filed without recognizing they're connected; structural spine of Act Two; framing + 4 sample entries locked, full 15–20 entries still outstanding|

**On the mod system discard (July 2026):** The original design made in-game modding the mandatory Act Two+ progression mechanic — the world broke procedurally after Act One and the player repaired it via a declarative mod editor. This is permanently discarded. The base game, including Act Two and beyond, is now a complete, fully completable story with no modding required at any point. Replayability instead comes from (1) anchor-and-fill procedural generation of map content per run, and (2) studio-authored endgame modules that add optional post-story content in the stub regions. See Document 3 for full detail. Optional post-launch community modding remains a possible future layer with zero base-game dependency on it happening.

-----

## Open Design Questions

### High Priority (Blocks Further Development)

**1. What is at the true center of The Hold?**
The wilderness at the geographic center is reserved. Whatever is there must recontextualize something the player already knows. The circle drawn by ancient engineers is visible only to certain players (tied to starting village). What is inside the circle? What does being able to see the line mean for the plot?

**2. Who originally built The Forge?**
Someone built it. Named it. The name implies a philosophy: the world is something you maintain with craft and labor, not magic or destiny. That person is long gone. Are they relevant to the plot? Does Patch find any record of them? Patch would respect them enormously and never admit it.

**3. Module interaction matrix**
4–6 launch endgame modules are targeted (Document 3). Every pair needs a defined answer to "what changes when both are installed?" — shared NPCs, route conflicts, outcome changes, or truth-fragment distribution. This matrix doesn't exist yet and is now the hardest open design problem in the game.

**4. What happens in Act Two (and possibly Act Three)?**
Locked, August 2026: reaching The Forge ends Act One, not the game. The main story is at least 2–3 acts. Content is completely open — this is now arguably the single highest-priority open question in the whole design, since everything from Doc 2 onward currently stops at the Forge.

**5. Does any player-visible instability survive into the endgame?**
The mechanical break-and-repair loop is cut, but it's undecided whether stub regions should still *read* as unstable narratively until a module is installed, or whether "unstable" is now purely an Act One atmospheric beat. Affects how module content gets framed. Related to the new stub-region tone lock (Document 4) — "unstable" and "weird/silly" aren't mutually exclusive, but the relationship between them isn't designed yet. *(Engine decision: resolved — Godot 4.6.2, in active build.)*

### Medium Priority (Needed Before Full World Build)

**6. The back-of-box copy**
Two or three sentences describing Mostly to a stranger without spoilers. Identified as a useful next exercise — will reveal whether the concept is communicating cleanly or has gaps.

**7. Folklore vs. reality for each region**
Each outer region has a reason it hasn’t been fully explored (folklore) and a reality (sometimes mundane/hilarious, sometimes genuinely dangerous for wrong reasons). None of the six regions have their folklore/reality defined yet.

**8. Opening scene prose**
Write the opening sequence in prose — no engine, no code. Patch trying to leave the village while people stop them at the door. This will define the game’s voice more precisely than any further concept work.

**9. The guard at the gate**
Who is this person? What’s their relationship with Patch? What errand do they ask Patch to run? This is the first NPC with a speaking role and sets the tone for all NPC interactions.

**10. The casual acquaintance**
The friend of a friend from the outskirts village who placed the sphere order. Name, personality, current state when Patch finds them (confused, frightened, gone?). Their village needs a name.

### Lower Priority (Can Wait)

**11. Additional playable characters**
Noted as a future state. Title chosen to accommodate this. No development needed until Patch’s arc is complete.

**12. Post-launch community modding**
Not discussed in detail. Endgame modules load as data packages, which keeps the door open for community modding using the same format if an audience materializes. Zero base-game or launch-module features depend on this happening. Not a launch requirement.

**13. Monetization model**
Not discussed. Relevant decisions: base game price, whether endgame modules ship free/bundled/as paid DLC, community mod marketplace if that layer ever launches (revenue share?).

**14. The unlabeled key**
What does it open? May be permanently unresolved. Decide intentionally either way.

**15. The Fifth Appendix**
What is in it? Almost certainly should never be revealed. The annual picnic is the point.

-----

## Immediate Next Steps (Recommended Order)

**Step 1: Write the back-of-box copy.**
Two or three sentences. Tests whether the concept communicates. Will surface any gaps in the core pitch.

**Step 2: Write the opening scene in prose.**
Patch, the workshop, the village, the gate. No engine, no code. Defines the voice. Everything else flows from this.

**Step 3: Define the delivery chain.**
How many links? Quick sketches of each person. Characterize the Spooky Fluid botcher.

**Step 4: Define the folklore and reality for each of the six regions.**
One sentence each. Enough to establish tone and surprise factor.

**Step 5: Sketch the module interaction matrix.**
One page. Rows and columns are launch module candidates. Each cell: "what changes when both are installed?" (Engine decision resolved: Godot 4.6.2, in active build.)

**Step 6: Map sketch.**
Rough positions of the six regions, starting villages, the circle, and the center wilderness. Doesn’t need to be final — needs to be workable.

**Step 7: Write The List’s full 15–20 entries.**
Framing and four tone-reference sample entries are locked (Document 2). The remaining entries — the actual structural spine of Act Two — still need to be written. Flagged as outstanding, not resolved by this pass.

-----

## Design Principles to Carry Forward

These emerged from the design process and should inform all future decisions:

**On tone:** The world takes itself seriously. Its inhabitants don’t always. Patch takes themselves seriously. The situation keeps refusing to cooperate.

**On the seams:** The stub regions must read as intentional invitations, not missing content. The map, NPC folklore, and offhand dialogue should all signal: the world was built incomplete on purpose, and something official fills those spaces later.

**On endgame modules:** Combinations over count. A module that doesn't interact with at least one other module isn't finished. The interaction matrix is the design artifact, not the module list.

**On worldbuilding:** Every institution in this world is accidentally managing the consequences of The Forge through bureaucracy and ritual without knowing it. New institutions should follow this pattern.

**On the village names and settlement names:** The humor works through restraint and the addition of a single unexpected detail that implies a whole history. Avoid names that are funny on the surface without depth underneath.

**On Patch:** They fix things because they’re broken and Patch is standing there. Destiny is irrelevant. Obligation is minimal. Irritation is the dominant emotional register. Respect is earned slowly and expressed sideways.

**On the ending:** Different runs reveal different amounts of truth. The ending reflects what Patch knew when they fixed it. Completion is always possible. Full understanding is rare.

-----

## Document Index

|Document                       |Contents                                                                           |
|-------------------------------|-----------------------------------------------------------------------------------|
|01_OVERVIEW.md                 |Title, pitch, pillars, genre, audience, structural overview, key references        |
|02_PROTAGONIST_AND_NARRATIVE.md|Patch, the inciting incident, the plot, Act One structure, themes                  |
|03_MECHANICS.md                |Endgame modules, the world's instability, anchor-and-fill, starting villages, crafting|
|04_WORLD_AND_MAP.md            |The Hold, Margin, six outer regions, stub regions, map generation, biomes          |
|05_MONASTIC_ORDERS.md          |All six orders, core beliefs, rituals, thematic summary                            |
|06_OPEN_QUESTIONS.md           |This document — decisions made, open questions, next steps, design principles      |