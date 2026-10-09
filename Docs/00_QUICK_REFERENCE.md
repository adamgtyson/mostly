# MOSTLY — Quick Reference Card

> **Supersession notice (2026-08-28):** Where this document conflicts with
> `Docs/handoff/MOSTLY_CANON.md` or `Docs/handoff/MOSTLY_DECISION_LEDGER.md`, the
> handoff documents win. Status tags in this file are not authoritative; consult the
> ledger. See `Docs/handoff/MIGRATION_WARNINGS.md` for known errors in this file.

## Authoritative Documents

- Docs/handoff/ — canon, story state, decision ledger, open questions, build plan; wins over Docs/00–06.
- Docs/ENGINEERING_CONSTRAINTS.md — locked engineering decisions (2026-08-29); Claude Code designs within these, never chooses them.
- Docs/WEIRDNESS_SPEC.md — the Act One weirdness system (2026-10-08): flicker catalog, intensity ladder, deniability rules, and the `npc_line` pool; ledger §M.

*Single-page canonical summary. For full detail see numbered documents.*

-----

## The Game

**Title:** Mostly | **Tagline:** It’s mostly fine.
16-bit top-down RPG (Godot 4.6.2, Mana Seed, 320×180). Base game is a complete story-driven RPG — fully completable, no modules or mods required. Stub regions filled post-launch by studio-authored **endgame modules**; mix-and-match combinations change outcomes, routes, and endgame content. **The declarative in-game mod system is DISCARDED (July 2026)** — story-first won.

-----

## The Protagonist

**Patch** — blacksmith, reluctant, competent, annoyed. Accidentally contributed to the catastrophe. Reaction upon discovering this: *“Oh for the love of — I made that part.”* Then gets back to work. Core voice: *“Fuck this. I’ll fix it myself.”*

-----

## The Plot

Patch made **hollow spheres** for a commission. The spheres power **The Forge** — an ancient floating gyroscope that maintains a barrier (The Hold) keeping paranormal phenomena out of the known world. Someone refueled The Forge with a bad batch of **Spooky Fluid**. The Forge destabilized. The world is unraveling. No villain. A chain of ordinary people making reasonable mistakes. Patch just wants to go home.

**Patch’s relationship to The Forge:** It shares a name with their forge. It defies physics. It shouldn’t work. These facts will bother Patch for the entire game.

-----

## The World

|Name                                            |Meaning                                           |
|------------------------------------------------|--------------------------------------------------|
|The Hold                                        |Folk name, origin forgotten, accidentally accurate|
|The Mostly                                      |Common name                                       |
|The Principality of the Mostly Peaceful Interior|Official name                                     |
|Margin                                          |Capital, slightly NE of true center               |
|True center                                     |Untouched wilderness, circle only some can see    |

**Six outer regions:** The Turning (contains The Forge), The Measure, The Distance, The Quiet, The Flow, The Balance

**Stub regions** exist beyond named regions — content-free, waiting for endgame modules or expansions.

-----

## The Monks

Based at **The Abbey of the Hopefully Infinite Thrum** (named for the sound of properly balanced Spooky Fluid). Tended by **The Order of the Most Sacred Mystery**. Perpetually impaired. Accidentally correct about everything. Motto: *“Probably.”* Every other regional order is unknowingly describing Forge maintenance requirements through their theology.

-----

## Starting Villages (9)

|Village             |Pro                                      |Con                              |
|--------------------|-----------------------------------------|---------------------------------|
|Again               |Emergency cache; first craft failure free|Poor NPC assistance              |
|Revised             |Finds sane NPCs faster                   |Disputed paperwork               |
|Temporary           |Cheap repairs; partial progress saves    |Self-imposed deadline penalty    |
|Good Soil (Probably)|Early warning before breaks              |NPCs distrust hedged language    |
|Seven Chickens      |*(obfuscated)* No stagger on breaks      |Misses danger cues; RNG          |
|One More Mile       |Improvised material substitution         |Smaller starting inventory       |
|Fine Now            |Fastest setback recovery                 |Blind to slow-developing problems|
|Hay, Mostly         |Reads NPC subtext                        |Gives incomplete information     |
|New Again           |Neutral reputation baseline              |Slower positive rep building     |

Village location on map reflects its pros/cons via surrounding mobs, puzzles, and challenges. Safer route always available.

-----

## Key Canonical Names

|Thing                     |Name                                                                |
|--------------------------|--------------------------------------------------------------------|
|The machine               |The Forge                                                           |
|The power source          |Spooky Fluid                                                        |
|The protagonist           |Patch                                                               |
|The capital               |Margin                                                              |
|Primary monk settlement   |The Abbey of the Hopefully Infinite Thrum                          |
|Primary monastic order    |The Order of the Most Sacred Mystery                                |
|The monks’ motto          |Probably.                                                           |
|Monastic naming convention|The [Badass Noun]                                                   |
|Circle in Margin          |Ancient engineers drew it; dogs avoid it; grass is normal. Probably.|

-----

## Tone Rules

- World takes itself seriously. Inhabitants don’t always.
- Deadpan, not absurdist. Ridiculous things presented straight.
- Stakes are real. Patch refuses to treat them that way.
- Every funny name has a detail underneath that implies a whole history.
- Institutions manage Forge consequences through bureaucracy without knowing it.

-----

## Immediate Next Steps

1. Write the back-of-box copy (2-3 sentences) *(done — see handoff CANON §1 / STORY_STATE §3)*
1. Write the opening scene in prose *(done — see handoff CANON §1 / STORY_STATE §3)*
1. Characterize Brack, the Spooky Fluid botcher, beyond the now-locked delivery chain (see Document 2)
1. Define folklore vs. reality for each of the six regions
1. Engine confirmed: Godot 4.6.2
1. Sketch the map