# MOSTLY — Game Design Document

## Document 3: Core Mechanics

-----

## Endgame Modules

*(Revision note, July 2026: this replaces the original declarative in-game mod system, which made modding the mandatory Act Two+ progression mechanic. That mechanic is permanently discarded. Story-first won.)*

### Philosophy

The base game is fully completable with zero modules installed. Modules change **outcomes, routes, and endgame content**. They never gate completion.

The diegetic framing survives the cut: the world was built incomplete on purpose, and the seams are visible. The player just no longer patches those seams with an editor — they choose which official patches to apply, and the combinations produce different runs.

### Design Requirement: Combinations Over Count

Replayability lives in module *interactions*, not module quantity. If module A and module B don't change each other's outcomes, share NPCs, or create route conflicts, mix-and-match is just a content menu and players will notice.

Every pair of launch modules must answer: **"What changes when both are installed?"** This is tracked in the module interaction matrix (see Document 6). Empty cells in the matrix are unfinished design work, not acceptable gaps.

Minimum interaction types to design for:

- **Shared NPCs** — a character introduced in one module has a role or changed fate in another
- **Route conflicts** — enabling both makes a previously optimal path unavailable or contested
- **Outcome modification** — module B's ending content reads differently depending on what the player did in module A
- **Truth distribution** — different combinations reveal different fragments of what actually happened

### Delivery Mechanism

Modules load as data packages (target: mostly JSON + scenes, consistent with existing dialogue architecture). This keeps the door open for post-launch community modding without committing to any tooling: if an audience materializes, the module format itself becomes the de facto mod spec. Zero base-game features depend on this happening.

### Launch Target

4–6 modules at launch, seeded on Nexus and/or Steam Workshop under the studio's name — enough to demonstrate the possibility space, few enough that every pairwise interaction can actually be designed. If interaction design forces a choice, cut to 3 interacting modules rather than shipping 6 independent ones.

-----

## The World's Instability

*(Revision note, July 2026: the mechanical "break, then repair via mods" loop described here previously is cut along with the mod system. What survives is below — the unraveling remains real in the fiction, it's just no longer a mechanical state the player patches with an editor.)*

### What Survives the Cut

The Forge destabilized. That's still the source of the wrongness the player sees during Act One's slow-building weirdness (Document 2) and it still gives the world's condition a cause rather than random flavor. What's gone is the idea that the world enters a mechanically "broken" state post-Act-One that requires player-authored repair to progress.

### Replayability, Post-Cut

Run-to-run variety now comes from two independent sources, not from a break/repair cycle:

- **Anchor-and-fill map generation** (below) — different biomes, settlement names, and encounters fill the same fixed narrative skeleton each run
- **Endgame module combinations** (above) — different post-story content, outcomes, and truth-fragments depending on which modules are installed together

Neither requires the player to fix anything. Both are open design questions worth resolving together: how much does starting village affect anchor-and-fill output, and does any given seed's fill state interact with which endgame modules make narrative sense? Flagged in Document 6.

### Open Question

Whether any *player-visible* instability persists into the endgame (e.g., stub regions reading as still-unstable until a module is installed) or whether "unstable" is now purely an Act One atmospheric beat is undecided. Worth resolving before endgame module content is written, since it affects whether modules are framed as "repairs" narratively even though they're not mechanically required.

-----

## Anchor-and-Fill Map Generation

*(Full detail in Document 4. Summary here for mechanic context.)*

### The Problem

Procedurally generated maps risk making the critical narrative path (delivery route → Spooky Fluid maker → The Forge) incoherent or unnavigable.

### The Solution: Anchor-and-Fill

**Anchors** are fixed narrative requirements. Each critical path has a fixed number of touchpoints that always exist regardless of generation. The delivery route always has a midpoint rest, a border crossing, a first contact with outer weirdness, and a destination.

**Fill** is everything generated around the anchors. What a touchpoint *is* depends on which biomes the generator placed between start and end.

The generator places anchors first, then fills around them. The critical path is always there **by construction**, not verified after the fact.

### Content Pipeline

A spreadsheet (conceptually):

- Rows: touchpoint types (rest, border crossing, information source, obstacle, revelation)
- Columns: biome types
- Each cell: 2-3 encounters appropriate to that combination

Modders can add rows. Stub regions are empty columns waiting to be filled. The content pipeline scales with community contribution.

-----

## Starting Village Selection

At new game setup, the player chooses Patch’s home village from nine options. Each village comes with a mechanical pro and con that emerges from the village’s backstory — not a stats screen, but a character extension.

Villages with obfuscated descriptions on the selection screen (spoiler protection for first playthroughs) are noted below.

### The Nine Villages

-----

**AGAIN**
*Rebuilt six times. Residents are deeply committed.*

Patch’s forge has burned down twice. They rebuilt without asking for help. Keeps emergency materials under the floor out of habit. Has a scar they don’t explain.

- **Pro:** Starts with hidden emergency crafting cache. First time a crafted item fails, resources are not consumed.
- **Con:** Reduced effectiveness of NPC assistance early game. Again residents are too self-reliant to ask for or offer help naturally.

-----

**REVISED**
*Every neighboring village insists this used to be called something else. Nobody agrees what.*

Patch grew up with contradictory accounts of their own origin. Developed permanent immunity to confident people who don’t know what they’re talking about. Has an instinct for finding the one person in any room with accurate information.

- **Pro:** Identifies “sane, logical few” NPC type faster. Fewer conversation steps to unlock real information.
- **Con:** Patch’s paperwork lists a disputed village name. Bureaucratic interactions occasionally require extra steps.

-----

**TEMPORARY**
*Founded as a temporary logging camp. Nine hundred years later it has a cathedral.*

Nothing in Temporary is ever finished but nothing falls apart. Maintenance is a way of life. Patch is the best maintaining smith in the region and has never finished anything on a self-imposed deadline. External deadlines are sacred.

- **Pro:** Repair and maintenance cost fewer resources. In-progress crafting and repair projects retain progress if abandoned and returned to.
- **Con:** Self-imposed objectives have a timer penalty. Patch takes longer to self-motivate. The game will occasionally note he hasn’t finished something.

-----

**GOOD SOIL (PROBABLY)**
*The (Probably) is on every official map.*

Nobody in Good Soil (Probably) makes definitive claims about anything. Patch absorbed this. Never overpromises. Has almost supernatural ability to identify when something is about to go wrong.

- **Pro:** Early warning system. Patch gets a subtle environmental tell slightly before world-break events. Longer reaction window.
- **Con:** Some NPCs respond poorly to hedged language. Certain persuasion interactions require extra steps.

-----

**SEVEN CHICKENS**
*Unsure if this is a census or a warning.*

Nobody from Seven Chickens explains the name. Patch has been asked their whole life and responds with a slight shrug. Seven Chickens produces people who are comfortable with unexplained phenomena — not incurious, just unbothered.

- **Pro:** *(Obfuscated on selection screen — described only as “Patch has always been comfortable with things that don’t make sense. This has never caused him any problems.”)* Patch skips paralysis on first contact with overt world-break events. No stagger animation, faster return to player control. Compounds significantly in late game.
- **Con:** Patch occasionally misses contextual warnings — NPC fear expressions, audio cues, environmental danger signals. The game assumes he noticed. He didn’t always.
- **Balance note:** Pro has RNG component (doesn’t always trigger cleanly) AND Patch occasionally misreads hostile NPCs as neutral. High risk / high reward starting village.

-----

**ONE MORE MILE**
*Founded by settlers who were too exhausted to continue.*

Patch doesn’t plan routes — they handle whatever the route becomes. Never has the right kit. Always makes it work.

- **Pro:** Inventory improvisation — higher success rate substituting non-ideal materials in crafting and repair. Wrong materials still work. Not perfectly. But enough.
- **Con:** Starting inventory is smaller than other village starts. Packed for the errand expected, not the one actually happening.

-----

**FINE NOW**
*No further context provided by any official record.*

Something happened. It was handled. Nobody relitigates it. Patch does not dwell. Something breaks, it gets fixed, it’s fine now, next problem.

- **Pro:** Fastest recovery from setbacks of any village start. Failed crafts, lost resources, damaged gear — the penalty window is shorter.
- **Con:** Blind spot for unresolved problems that haven’t announced themselves. Won’t notice a slow structural failure, a brewing NPC conflict, or a piece of gear with a hidden flaw until it becomes acute.

-----

**HAY, MOSTLY**
*The comma is on every official map. The cartographer who added it was never identified.*

Patch communicates in partial sentences and meaningful pauses. Listens for what isn’t said. Generates subtext unintentionally.

- **Pro:** Registers NPC subtext, hesitation, and subject changes as data. Gets more out of conversations than other village starts.
- **Con:** Gives other characters incomplete information, assuming they’ll fill in the rest. Certain quest triggers and trade interactions require clarification steps.

-----

**NEW AGAIN**
*People from Again moved slightly uphill.*

Practical decision. Again residents never entirely forgave them. Patch grew up in the social blind spot between two stronger identities. Extremely good at being underestimated.

- **Pro:** Starts from neutral reputation baseline regardless of faction history. Useful in situations Again’s reputation would complicate.
- **Con:** Positive reputation effects take longer to build. Same anonymity that makes Patch invisible to enemies makes them invisible to friends.

-----

## Village Map Mechanic

Each starting village is on the map. The surrounding environs reflect the village’s pros and cons through:

- Mob types and difficulty
- Puzzles rewarding the village’s characteristic thinking style
- Challenges and minigames for out-of-the-box strategic thinking
- A safer route always available that bypasses rewards

Players who *play like* their village’s character get more out of their starting region. This is a mechanic, a narrative beat, and a replayability driver simultaneously.

-----

## The Circle Visibility Mechanic

*(Partially designed — full details deferred)*

At the true center of The Hold is untouched wilderness. Within it is a circle drawn by ancient engineers. Most people cannot see the circle. Visibility depends on the player’s starting village — specifically, their tolerance for and awareness of unexplained phenomena.

Seven Chickens: probably sees it immediately and shrugs.
Good Soil (Probably): sees something. Probably.
Fine Now: walked through it once. It was fine. Moved on.
Revised: argues about whether the line is even there.

**What’s in the circle:** Deliberately deferred. Whatever is there should recontextualize something the player already knows.

-----

## Crafting

Introduced organically in the opening sequence via the cart/wagon decision. No tutorial. No quest marker. Just a logistics problem and available materials.

Full crafting system design: TBD. Established principles:

- Non-ideal material substitution is a feature, not a bug (especially for One More Mile starts)
- Repair and maintenance are distinct from crafting new items
- The workshop in Patch’s home village is the player’s first crafting environment