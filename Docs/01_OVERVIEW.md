# MOSTLY — Game Design Document

## Document 1: Overview & Core Concept

-----

## Title

**Mostly**
*Tagline: It’s mostly fine.*

-----

## Elevator Pitch

Mostly is a 16-bit top-down RPG in which the player character — a blacksmith named Patch — accidentally contributed to a catastrophe that is causing the fabric of the world to unravel. The base game is a complete, fully completable story from start to finish, no modification required. Replayability comes from two places: an anchor-and-fill map generator that varies biomes, settlements, and encounters around a fixed set of narrative touchpoints each run, and a set of studio-authored **endgame modules** that fill the game's stub regions with additional post-story content. Ordinary people were handed a civilization-saving machine and preserved it through songs, recipes, village customs, and stories about giants — and that turns out to be enough. That's the thesis. The writing and tone carry the game; the systems support it.

*(Revision note, July 2026: the original design made in-game modding the mandatory Act Two+ progression mechanic. That has been permanently discarded — see Document 3 and Document 6. This section reflects the current, story-first design.)*

-----

## Core Design Pillars

1. **The writing is the hook.** Pratchett-adjacent deadpan tone, not systems depth, is what sells this game. Every other pillar serves the writing; none should compete with it for the player's attention.
1. **No villain.** The catastrophe was caused by a chain of ordinary people making reasonable decisions without anyone seeing the whole picture. Nobody intended this. Nobody is to blame in a satisfying narrative sense. Everyone is implicated.
1. **Completable by construction.** The base game is a finished, complete story. It does not depend on the player building or installing anything to reach an ending. Stub regions are a visible, legible invitation to come back later — they are not a wall.
1. **Combinations over count.** Replayability comes from studio-authored endgame modules whose value lies in how they interact with each other (shared NPCs, route conflicts, outcome changes) — not from shipping a large quantity of independent content. See Document 3.
1. **Tone: deadpan, not absurdist.** The world takes itself seriously. Its inhabitants do not always. Patch does not think anything is funny. The player does. That gap is where the humor lives. Stakes are real. The protagonist just refuses to treat them that way. *(Exception, locked August 2026: stub regions / endgame modules are the tonal release valve — they can lean weirder and sillier than the main story ever does. See Document 4.)*

-----

## Genre & Aesthetic

- 16-bit top-down RPG aesthetic (Mana Seed assets, 320×180 viewport)
- Procedurally varied world content per run (anchor-and-fill architecture — see Document 4); fixed narrative anchors, generated fill
- Studio-authored endgame modules extend the story into stub regions post-launch; base game requires none of them
- Optional post-launch community modding is a possible future layer, with zero base-game dependency on it happening
- Engine: Godot 4.6.2 (confirmed)

-----

## Audience

Primary: Narrative indie players — people who play for writing, tone, and world, in the vein of Pratchett-influenced fiction. Not a systems-depth pitch.

Secondary: Players who enjoy replaying story-driven RPGs to see different runs, region content, and endgame module combinations.

Not targeted at: Players looking for a deep crafting/modding sandbox (RimWorld, Dwarf Fortress) as the primary draw — that was the original pitch and has been discarded in favor of the story-first design.

-----

## Structural Overview

|Act     |Status                    |Notes                                                                  |
|--------|---------------------------|-----------------------------------------------------------------------|
|Act One |Completable vanilla        |Introduces world, character, mechanics, and the slow onset of weirdness. Ends with Patch reaching The Forge and confronting their own role in the catastrophe.|
|Act Two |Completable vanilla, content TBD|The story continues past the Forge. Not yet designed — see Document 6.|
|Act Three (working)|Completable vanilla, content TBD; existence not fully confirmed|At least a 2–3 act main story is the locked target. Whether Act Three is a distinct act or Act Two runs long is undecided.|
|Endgame |Optional, module-driven    |Studio-authored modules fill stub regions after the main story ends; combinations change outcomes, routes, and endgame content|

*(Revision note, August 2026: reaching The Forge was previously an implicit stand-in for "the rest of the game." It's now explicitly locked as the Act One climax, not the ending. The main story is at least 2–3 acts; the endgame module layer comes after the story concludes, not instead of a second and third act.)*

The base game — Act One through the main story's conclusion, however many acts that turns out to be — ships as a complete release. Endgame modules are additive post-story content, not a requirement to finish the game.

-----

## Key References / Analogies

- **Neverwinter Nights** — full campaign plus legendary toolset; community modules rivaled the base game; still alive decades later because of the ecosystem
- **Minecraft** — shipped as barely functional sandbox; community defined what it was before the developer did
- **Undertale / Oneshot / Omori** — deliberate collapse of the boundary between player and character
- **Hacknet** — the “game” is navigating a broken system; interface is the fiction
- **Noita** — world has rules; discovering and exploiting them is the game; modding encouraged as exploration

-----

## What Has Not Been Decided Yet

- Platform targets beyond PC
- Monetization model (base price; whether endgame modules ship free, as DLC, or mixed)
- Timeline / development scope
- Content of Act Two and (working) Act Three — structure is locked at 2–3 acts minimum, content is not (see Document 6)
- Number of launch endgame modules and their pairwise interaction design (see Document 6 — this is now the hardest open design problem)
- Whether/how to bless community modding post-launch (deferred; zero base-game dependency)
- Additional playable characters beyond Patch (noted as a future state; title "Mostly" was chosen partly to accommodate this)
- What is in the circle at the center of The Hold (deliberately deferred)