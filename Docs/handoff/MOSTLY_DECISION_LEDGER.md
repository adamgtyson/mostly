# MOSTLY_DECISION_LEDGER.md — Provenance for Every Claim

**Purpose.** Every significant item in the other seven documents traces to a row here. A new collaborator can check *who* established a thing, *when*, and *what happened to it afterward* instead of trusting a status tag.

**Sources (abbreviations used below):**

| Code | Source | Date | Nature |
|---|---|---|---|
| F | Founding session extract | 2026-06-07 | Chat; produced the original GDDs |
| J7 | Design & build session extract | 2026-07-07 (conversation may have run later — it references the Abbey rename) | Chat + Claude Code sessions 1–3 |
| J10 | Fable test / anchor-and-fill prompt / GitHub sync extract | 2026-07-10 | Chat; prompt drafted, build not confirmed run |
| J21 | Bridge lock-in / Abbey rename extract | 2026-07-21 | Chat |
| A5a | "Modding de-centered" memory-only extract | 2026-08-05 | Chat; sync broken |
| A5b | Doc sync / act structure extract | 2026-08-05 | Chat |
| A8 | Delivery-chain character sheets extract + 5 files | 2026-08-08 | Chat (Cowork) |
| A11 | Chronology recap extract | 2026-08-11 (actual 08-28) | Chat; no decisions |
| R | Repo `adamgtyson/mostly` HEAD `6a740fe` — Docs/00–06, CLAUDE.md, CHANGELOG | 2026-08-05 | Committed canon |
| B | Build code: dialogue JSON, `opening_cutscene.gd` | 2026-07-07 | Implemented |
| U | Adam's rulings in this session | 2026-08-28 | Direct rulings |

**Authority column:** *user-authored* (Adam wrote the words), *user-confirmed* (assistant proposed, Adam explicitly approved), *assistant-promoted* (assistant wrote it as locked without a recorded confirmation), *doc-only* (exists in R with no traceable chat origin in the extracts).

**Status legend:** LOCKED / PROVISIONAL / OPEN / INFERRED / REJECTED / TODO.

---

## A. Identity & pillars

| # | Item | Status | First | Last | Authority | Notes |
|---|---|---|---|---|---|---|
| A1 | Title *Mostly*, tagline *It's mostly fine.* | LOCKED | F | R | user-confirmed | Rejected titles: A2. |
| A2 | Rejected titles: *The Mostly (it's mostly fine)*, *The Hold*, *The Seventh Hammer*, *The Last Turning*, *Good Bearings* | REJECTED | F | F | user-authored list | *The Seventh Hammer* "strong contender, ultimately lost." |
| A3 | Title accommodates future playable characters | LOCKED | F | R | user-authored | |
| A4 | Price/scope: "$5–$10 steam game," not AAA | LOCKED | J21 | J21 | user-authored | Not in R. |
| A5 | Pillars: writing is the hook; no villain; completable by construction; combinations over count; deadpan not absurdist | LOCKED | F | R | user-confirmed | Pillar 4 now under review — see G-series. |
| A6 | Stub/module tone = release valve, weirder/sillier | LOCKED | A5b | R | user-authored ("really weird and often silly, tongue-in-cheek") | |
| A7 | Humor principle: restraint + one detail implying history; no surface-funny names | LOCKED | F | R | user-confirmed | Used to reject village names (A8). |
| A8 | Rejected village names: Up A Bit, Flat Enough, The Little Woods, Dry Mud, Turnip Junction, Slight Bend | REJECTED | F | F | user-authored list | "May be usable as throwaway map labels." |
| A9 | Chosen-one framing for Patch | REJECTED | J7 | J7 | user-authored (Draft 2 line struck) | "That instinct flagged as something to watch." |
| A10 | Back-of-box copy, Draft 4 | LOCKED | J7 | J7 | user-authored | Not in R. Docs/06 still lists it as undone. |
| A11 | Thesis paragraph ("…songs, festivals, recipes… stories about giants… turns out to be enough") | LOCKED | J7 | R (abridged in Docs/01) | user-confirmed | Full text J7. |
| A12 | Aesthetic refs: Chrono Trigger, Secret of Mana, FF4–6 | LOCKED | J7 | J7 | user-confirmed | |
| A13 | Engine Godot 4.6.2; GDScript only; 320×180; Mana Seed 16×16; nearest-neighbor | LOCKED | J7 | R/B | user-confirmed | Docs/00 "Confirm engine" is stale. |
| A14 | Asset strategy: free Mana Seed demo assets until vertical slice, then buy | LOCKED | J7 | J7 | user-confirmed | |
| A15 | EULA / indie-artist respect principle (verify Mana Seed terms before AI use) | LOCKED (memory) | J21 | J21 | user-authored | Lives in Claude memory, not Docs. |
| A16 | AI art tool shortlist (PixelLab, Sprite Fusion, Retro Diffusion, Scenario, Aseprite) | PROVISIONAL | J21 | J21 | assistant proposal | None chosen or tried. |
| A17 | Key references list (NWN, Minecraft, Undertale, Hacknet, Noita) | PROVISIONAL / stale | F | R | doc-only | Mod-ecosystem era. |

## B. Patch

| # | Item | Status | First | Last | Authority | Notes |
|---|---|---|---|---|---|---|
| B1 | Name Patch; rationale (blacksmith name / software term / "fix imperfectly" / personality) | LOCKED | F | R | user-confirmed ("HOLY SHIT YUP") | |
| B2 | Blacksmith; gender player's choice; home = 1 of 9 villages | LOCKED | F | R | user-confirmed | |
| B3 | Voice: competent, unglamorous, annoyed; does not dwell | LOCKED | F | R | user-confirmed | |
| B4 | Key lines: "Oh for the love of — I made that part." / "Fuck this. I'll fix it myself." / "I have one of those. Mine works." | LOCKED | F | R | user-authored | |
| B5 | Annoyed, not obligated | LOCKED | F | R | user-authored | |
| B6 | Precision smith, not combat smith; buys base gear; crafts mods/gadgets | LOCKED | J7 | J7 | user-confirmed | Not in R. |
| B7 | Notices-something-wrong → stops → figures it out → files it → moves on (trait) | LOCKED | J7 | B ("File that. Keep moving.") | user-authored | |
| B8 | Has a cat; cat spoiled the order form; cat is not sorry | LOCKED | J7 | B | user-authored | |
| B9 | Pronoun convention for authored text | OPEN | — | — | — | Docs mix they/he; prose uses he. |

## C. The Forge, Fluid, catastrophe

| # | Item | Status | First | Last | Authority | Notes |
|---|---|---|---|---|---|---|
| C1 | The Forge: floating gyroscope, defies physics, maintains The Hold barrier, runs on Spooky Fluid in hollow spheres | LOCKED | F | R | user-authored | |
| C2 | Spooky Fluid canonical name, no dignification | LOCKED | F | R | user-authored ("for realsies") | |
| C3 | Spheres perfect; Fluid wrong; no villain | LOCKED | F | R | user-authored | |
| C4 | Forge was low on power → Act One flickers; botched refuel → destabilization | LOCKED | F | R | user-confirmed | |
| C5 | Forge shares a name with Patch's forge — recurring joke | LOCKED | F | R | user-authored | |
| C6 | Original engineers: boringly competent, wrote maintenance schedules | LOCKED | J7 | J7 | user-confirmed | Docs/06 #2 still lists builder as open — now partially answered. |
| C7 | Maintenance hatch inscription (ROTATIONAL FIELD STABILIZATION ARRAY / 180 days / Central Engineering) + Patch's "…well that explains an awful lot." | LOCKED | J7 | J7 | user-confirmed | Not in R. |
| C8 | Forge age ~1,500 years | LOCKED (via thesis) | J7 | J7 | user-confirmed | |
| C9 | The Thrum (balanced) / the Grinding (low) as two distinct sounds never connected | **PROVISIONAL** | J21 (assistant addition) | R (written as "locked") | assistant-promoted | **U5: pulled back from locked.** |
| C10 | The Er'side (User's Guide, cover worn to "er's ide"; ancient maintenance manual treated as scripture) | LOCKED | J7 | J7 | user-confirmed | Not in R. |
| C11 | The reading device (steampunk microscope; one eyepiece left; three apprentices waiting) | LOCKED | J7 | J7 | user-confirmed | Eyepiece questline OPEN. |
| C12 | Fluid loaded only after Patch leaves; no witness overlap | LOCKED | J21 | U1 | user-confirmed, reaffirmed U | |
| C13 | Brack's ceremony cutscene (pink flash, disregarded Er'side entry, Patch watching) | PROVISIONAL — needs restaging | J7 | J7 | user-confirmed at the time | Conflicts with C12 if Patch sees the misread. U1 chose C12. |

## D. Story structure

| # | Item | Status | First | Last | Authority | Notes |
|---|---|---|---|---|---|---|
| D1 | Act One completable vanilla | LOCKED | F | R | user-authored | |
| D2 | Modding mandatory after Act One | REJECTED | F (locked then) | J7 (cut) | user-authored both times | Reason J21: "I liked the story so much that I didn't want to distract from it." |
| D3 | Reaching The Forge ends Act One, not the game; ≥2–3 acts | LOCKED | A5b | R | user-authored | |
| D4 | Three Act Two candidate directions (institutional fallout / chain in reverse / circle becomes reachable) | PROVISIONAL | A5b | A5b | assistant proposals | None chosen. |
| D5 | Five-beat bridge | LOCKED | J21 | R | user-authored concept + blanket confirmation | |
| D6 | Summons letter verbatim | LOCKED | J21 | R | assistant-drafted, user-approved verbatim | |
| D7 | The List — concept + 4 sample entries | LOCKED | J21 | R | assistant-drafted, user-approved | |
| D8 | Modules append entries to The List | **PROVISIONAL** | J21 (flagged "needs your veto") | R (written as "locked") | assistant-promoted | **U5: pulled back.** |
| D9 | Culpability stays private; monks never learn | LOCKED | J21 | R | user-confirmed | |
| D10 | Ending reflects truth known; completion always possible | LOCKED | F | R | user-confirmed | |
| D11 | Act One/Act Two exact boundary | OPEN | R (conflict) | — | — | Docs/01 vs bridge timing. |
| D12 | Opening deadline: "five days" (Docs/02) | **SUPERSEDED** by D13 | F | R | doc | Stale. |
| D13 | Opening: 8 days left on order form; nine days actually worked; horse + wagon; express-courier plan; Brindle at Near Enough | LOCKED | J7 | B (partial) | user-authored prose | |
| D14 | Cart/wagon build as crafting intro | **REJECTED** | F | U3 | user ruling | "Holdover from modding focus." |
| D15 | "Can't carry all spheres" logistics problem | REJECTED by implication of D14/D13 | F | U3 | — | Patch owns a wagon in the prose. |
| D16 | Star Wars-style crawl intro | OPEN | F | R | doc | Build has none. |
| D17 | Nine days: explanation exists in-world, never confirmed to Patch | OPEN | J7 | J7 | user-authored | |

## E. Characters

| # | Item | Status | First | Last | Authority | Notes |
|---|---|---|---|---|---|---|
| E1 | Chain: Patch → Brindle → Wren → Hobb → Sedge → Abbey → Brack | LOCKED | J7 | R | user-confirmed | Direction: order flowed Abbey→Patch; delivery flows Patch→Abbey. |
| E2 | Brindle = the casual acquaintance who delivered the order form; trader; Near Enough; cheerful, rattled by backward mill | LOCKED | J7 | J7 | user-confirmed | Resolves Docs/06 #10. |
| E3 | Wren: female cartographer; trading post between Near Enough and NW Hold border; missing river; bird flipbook; map notes; practical, resigned | LOCKED | J7 | J7 | user-authored (flipbook) / confirmed | |
| E4 | Hobb: male innkeeper; perfectly normal village near Turning border; rumor mechanic; outskirts miller + ferryman | LOCKED | J7 | J7 | user-confirmed | |
| E5 | Sedge: female monk of Most Sacred Mystery; Still Point six-month rotation; points to Abbey | LOCKED | J7 | J7 | user-confirmed | |
| E6 | Sedge leaves the order — timing | OPEN | J7 (after) | A8 (reopened) | user ruling A8 | J7's "encounter her again later, she has left" is now PROVISIONAL. |
| E7 | Brack: older monk; ran the fluid ceremony; not a villain | LOCKED (identity) | J7 | J7 | user-confirmed | |
| E8 | Brack's state when found: panicked into action, making it worse | LOCKED | A8 | A8 | user-selected | |
| E9 | Character sheets Draft 0 / A / B / C + comparison | PROVISIONAL, mid-selection | A8 | A8 | proposals | Adam's first picks (B/B/A/A/composite) withdrawn. |
| E10 | Sheets invert the order's direction of travel | INFERRED conflict | A8 | — | — | See STORY_STATE §6. |
| E11 | Latch: male gate guard, 23 years, "which is exactly how I like it"; errand to Bell at Last Post (soup salt ratio); rewards | LOCKED | J7 | J7 | user-authored | CLAUDE.md names him; Docs/06 #9 stale. |
| E12 | Bell: runs the kitchen at Last Post; soup buff | LOCKED | J7 | J7 | user-confirmed | |
| E13 | Brother Aldous | LOCKED | J21 | R | user-confirmed ("lock it in") | |
| E14 | Brother Edwin: archivist punchline + "every monastery has one; not the same person" | LOCKED | F / J7 | R (partial) | user-confirmed | Multi-Edwin gag not in R. |
| E15 | Monastic rosters for all seven orders; name-conflict renames | LOCKED | J7 | J7 | user-confirmed | Not in R. |
| E16 | Prior Balance clock moment; never explained | LOCKED | J7 | J7 | user-confirmed | |
| E17 | Party: max 3; Camp per region; swaps at Camp only, with cost | LOCKED | J7 | J7 | user-confirmed | Not in R. |
| E18 | Fletch (companion if Patch female; ranged; the sober monk) / Brace (companion if Patch male; support) | LOCKED | J7 | J7 | user-confirmed | |
| E19 | Brace is also the sober monk for male Patch | PROVISIONAL ("for now") | U6 | U6 | user ruling | |
| E20 | Companion is opposite gender to Patch | LOCKED | J7 | J7 | user-confirmed | |
| E21 | Bell-tower-running-fast detail (companion's first noticing) | LOCKED | J7 | J7 | user-confirmed | |
| E22 | Tine (rogue), Hasp (thief), Sprig (young herbalist) unlockables; camp visuals | LOCKED | J7 | J7 | user-confirmed | |
| E23 | Alchemist / Archivist (Margin, Records) / Fence | PROVISIONAL | J7 | J7 | proposals | Names, locations TBD. |
| E24 | NPC archetypes: Surveyor, Itinerant repair person, Census taker | PROVISIONAL | J7 | J7 | proposals | Unplaced. |
| E25 | Villager naming pool + convention | LOCKED | J7 | J7 | user-confirmed | |
| E26 | The sober monk = Docs/05's "young, anxious" sketch | SUPERSEDED by E18/E19 | F | R | doc | Docs/05 Future Decisions stale. |

## F. World & map

| # | Item | Status | First | Last | Authority | Notes |
|---|---|---|---|---|---|---|
| F1 | World names (Hold / Mostly / Principality…) | LOCKED | F | R | user-confirmed | |
| F2 | "The Mostly" in-world etymology | OPEN | A11 | A11 | assistant speculation, unadopted | |
| F3 | Margin, neighborhoods, four ministries; Bureau of Rotational Affairs never explained | LOCKED | F | R | user-confirmed | |
| F4 | Circle: center wilderness; visibility by village; contents deferred | LOCKED/OPEN | F | R | user-confirmed | Location contradiction (center vs Margin) in Docs/04. |
| F5 | Six regions named; circular world; stubs beyond | LOCKED | F | R | user-confirmed | |
| F6 | Region capitals, neighborhoods, government bodies (Docs/04) | PROVISIONAL | F | R | user-confirmed at F | Under review (F9). |
| F7 | Settlement lists in Docs/04 and Docs/05 | PROVISIONAL, conflicting | F | R | user-confirmed at F | Under review (F9). |
| F8 | July 7 settlement lists + one "Probably" per region | **NOT ADOPTED / REJECTED** | J7 | U2 | user ruling | "I don't want a settlement called Probably." |
| F9 | Settlements per territory and the territories themselves need thorough review | **TODO** | U2 | U2 | user ruling | |
| F10 | Stable Frequency, Nominal, Acceptable Variance, Within Tolerance, The Village of Sensible Decisions — include; first four in The Turning | LOCKED (inclusion) | F | U8 | user ruling | Forgotten, not rejected. |
| F11 | Near Enough (Brindle; half-day from start), Last Post (Bell; road home doesn't go back the way it came), Still Point (Sedge; nothing rotates) | LOCKED (plot-bearing places) | J7 | J7 | user-confirmed | Subject to F9 for placement. |
| F12 | Hobb's village: unnamed, perfectly normal, near Turning border | PROVISIONAL | J7 | J7 | | |
| F13 | Perfectly normal settlements concept; each has a questline | LOCKED | J7 | J7 | user-confirmed | |
| F14 | Postal service canonically dysfunctional; commissions travel by hand | LOCKED | J7 | J7 | user-confirmed | |
| F15 | Map layout clockwise from N: Turning, Measure, Flow, Balance, Quiet, Distance; stub positions | LOCKED at J7; **flag** | J7 | J7 | user-confirmed | Conflicts with Docs/04 "Balance adjacent to Turning" (they'd be opposite). Under F9. |
| F16 | One motto per region; each order's phrase relates to it | **TODO** | U4 | U4 | user ruling | J7 gave two motto sets; which survives is undecided. |
| F17 | Regional engineering purposes (Dynamic Stabilization, Calibration & Tolerance, Safe Exclusion Zone, Acoustic Monitoring, Thermal & Fluid Regulation, Countermass & Load) | LOCKED | J7 | J7 | user-confirmed | Their attached mottos fall under F16. |
| F18 | Shared children's story, six regional fragments | LOCKED | J7 | J7 | user-confirmed | |
| F19 | Biome pool (10 types); biome bleed; regional structure | LOCKED | F | R | user-confirmed | |
| F20 | Folklore vs reality per region | OPEN | F | R | — | Never designed. |
| F21 | Trees walking around (later game) | PROVISIONAL | J7 | J7 | user-authored idea | Not in opening. |

## G. Systems

| # | Item | Status | First | Last | Authority | Notes |
|---|---|---|---|---|---|---|
| G1 | Anchor-and-fill generation — architecture | LOCKED | F | R | user-authored concept | |
| G2 | Procedural generation / anchor-and-fill is a HARD requirement for replayability | LOCKED | U9 | U9 | user ruling | |
| G3 | Anchor-and-fill build spec (graph, RefCounted, 1000-seed validator, external config, MapGraph JSON) | PROVISIONAL spec, **not built** | J10 | A5b (claimed built — unverified) | assistant-drafted, user-approved as prompt | Absent from R. U9: "I don't think it ran." |
| G4 | Placeholders: biome pools per region; distance constraints; chain link count (default 4 — but chain is now 5 human links); village-specific route variation | OPEN | J10 | A5b | — | |
| G5 | Nine starting villages with pro/con | LOCKED | F | R | user-confirmed | Mechanics reference cut "world-break" loop — needs re-grounding. |
| G6 | Seven Chickens pro obfuscated | LOCKED | F | R | user-confirmed | |
| G7 | Village map mechanic; safer route always available | LOCKED | F | R | user-confirmed | |
| G8 | Circle visibility by village | PROVISIONAL | F | R | | |
| G9 | Forge network (home / blacksmith 3–5 errands / monastery forges); workbenches not portable | LOCKED | J7 | J7 | user-confirmed | Portable workbench REJECTED. |
| G10 | One long Zelda-style fetch quest, not in opening | LOCKED | J7 | J7 | user-confirmed | |
| G11 | Bird flipbook maps (Wren) | LOCKED | J7 | J7 | user-authored ("cool as fuck") | |
| G12 | Map notes evolve as world breaks; navigational puzzle tool; never flagged | LOCKED | J7 | J7 | user-confirmed | |
| G13 | Rumor network via innkeepers; Hobb's most accurate | LOCKED | J7 | J7 | user-confirmed | |
| G14 | Mill running against current — first weirdness errand; fix works; cause unexplained | LOCKED | J7 | J7 | user-confirmed | |
| G15 | Endgame modules: 4–6 studio-authored, optional, fill stubs, pairwise interaction matrix | LOCKED at R; **under revisit** | J7 | U7 | user ruling U7 | |
| G16 | New direction: ship complete with content for each outer region; regions replaceable by mods; example mods on Nexus | PROVISIONAL — **TODO revisit endgame** | U7 | U7 | user ruling | May change "stub regions are content-free at launch." |
| G17 | Modules "not DLC, open-source files" | PROVISIONAL | J7 | U7 | user-authored at J7 | Monetization otherwise undecided. |
| G18 | Community modding: optional, zero base-game dependency | LOCKED | J7 | R | user-confirmed | Consistent with G16. |
| G19 | Player-visible instability into endgame? | OPEN | R | R | — | |
| G20 | Dialogue JSON / CutsceneManager / CutsceneSkip architecture | BUILT | B | R | — | |
| G21 | Inventory, save system, combat, reputation | NEVER DESIGNED | — | — | — | Referenced by other systems. |

## H. Monastic orders

| # | Item | Status | First | Last | Authority | Notes |
|---|---|---|---|---|---|---|
| H1 | Naming convention The [Badass Noun] | LOCKED but unmet | F | R | user-confirmed | Only The Grinding complies. |
| H2 | Every order unknowingly describes Forge maintenance | LOCKED | F | R | user-confirmed | |
| H3 | Order of the Most Sacred Mystery — motto, greeting, virtues, litany, relics, festivals | LOCKED | F | R | user-confirmed | |
| H4 | Glorp Abbey | REJECTED | F | J21 | user-authored reason (Dungeon Crawler Carl "Glurp") | |
| H5 | The Abbey of the Hopefully Infinite Thrum + rationale | LOCKED | J21 | R | user-authored | |
| H6 | The Grinding vs Most Sacred Mystery — one order or two | OPEN | F | R | — | |
| H7 | Five other orders: beliefs, rituals, "accidentally describes" | LOCKED | F | R | user-confirmed | |
| H8 | Rejected order names: Rule Against Looking Directly Into The Sphere; Litany of Unpleasant Sloshing; Doctrine of Respectful Distance (absorbed); Order of the Sacred Spin; "Et Cetera" | REJECTED | F | F | user-confirmed | |
| H9 | Listening Stick never explained; Empty Box; Fifth Appendix; Bureau of Rotational Affairs | LOCKED-unresolved | F | R | user-confirmed | Unlabeled Key: decide intentionally. |
| H10 | Patch tells the orders / any order figures it out | OPEN | F | R | — | |

## I. Process & workflow

| # | Item | Status | First | Last | Authority |
|---|---|---|---|---|---|
| I1 | Build locally on Windows (the-rig), not the Ubuntu dev server (Godot needs the editor) | LOCKED | J7/J10 | A5b | user-authored |
| I2 | GitHub connector scoped to Docs/, CLAUDE.md, CHANGELOG.md; manual Sync now; delete manual uploads | LOCKED | J10 | A5b | user-confirmed |
| I3 | Start a new conversation whenever GitHub-side changes occurred | LOCKED | A5b | A5b | user-confirmed |
| I4 | Don't bundle doc updates into build prompts; use docs-only sync prompt or direct git push | LOCKED | A5b | A5b | user-confirmed |
| I5 | Don't add whole repo to Project Knowledge | LOCKED | A5b | A5b | user-confirmed |
| I6 | Fable autonomy test on anchor-and-fill; fresh session; `/model fable` | PROVISIONAL | J10 | J10 | user-confirmed plan |
| I7 | Use a second LLM for story drafting; character sheets before scenes; cherry-pick across variants | LOCKED (process) | A8 | A8 | user-authored |
| I8 | Final Task block verbatim; Prompt Workshop structure | LOCKED | profile | — | user-authored |
| I9 | Project instruction "check CLAUDE.md/CHANGELOG first" | LOCKED (confirmed present) | A5b | project | user-authored |
| I10 | Claude Code Remote Control for phone monitoring | INFO | A5b | A5b | — |

## J. Act One build rulings (Adam, 2026-08-28, second round)

| # | Item | Status | Authority | Notes |
|---|---|---|---|---|
| U2-1 | Act One ends when Patch, home after the delivery, receives the summons letter | LOCKED | user ruling | Supersedes Docs/01 "confronting their own role" as Act One's end; resolves D11. |
| U2-2 | During Act One only The Hold and The Turning are reachable; an in-world event around the letter unlocks the rest | LOCKED (rule); reason and event OPEN | user ruling | Canonical cause must be invented and locked before build. |
| U2-3 | After delivery Patch explores The Turning: battle encounters, resources, crafting intro | LOCKED | user ruling | Puts combat and the crafting intro inside Act One. |
| U2-4 | Handcraft Act One v1; generator must be able to drive it later | LOCKED | user ruling | |
| U2-5 | All nine villages selectable; Docs/03 mechanical pro/cons kept as designed (not downgraded) | LOCKED | user ruling (corrected mid-session) | Re-ground cut "world-break" vocabulary. |
| U2-6 | v1 PoC may use plot-bearing places only; shipped Act One = The Hold and The Turning fully explorable | LOCKED | user ruling | |
| U2-7 | Dialogue gender variants for Patch | LOCKED | user ruling | |
| U2-8 | Definition-of-done approach per BUILD_PLAN §7 | LOCKED | user adopted recommendation | |
| U2-9 | Multi-phase build; one workshop prompt per phase; dedicated engineering-constraints session first | LOCKED | user ruling | BUILD_PLAN §6, §8. |
| U2-10 | Act One writing list and weirdness-system spec are required pre-build deliverables | TODO | user ruling | BUILD_PLAN §4, §5. |
| U2-11 | Brack ceremony restage and chain character composite logged as pre-build TODOs | TODO | user ruling | BUILD_PLAN §3. |

## K. Engineering constraints (Adam, 2026-08-29)

| # | Item | Status | Authority | Notes |
|---|---|---|---|---|
| K0 | Engineering-constraints session held; Docs/ENGINEERING_CONSTRAINTS.md is the authoritative engineering layer | LOCKED | user ruling | BUILD_PLAN §6/§8 phase 0 complete. |
| EC-1 … EC-13 | Engineering constraints §1–§13 above | LOCKED | user-confirmed (assistant proposed; Adam chose with all stated qualifiers) | 2026-08-29 |
| EC-1a | Mobs: tongue-in-cheek — animated objects, weird pets, cryptids; each carries a real side-effect modifier; combinations drive diversity | LOCKED | user-authored | Roster is writing-track. |
| EC-2a | Border guards count crossing attempts per region and in total; get pissy; know other crossings' counts, hand-waved | LOCKED | user-authored | Dialogue is writing-track. |
| EC-4a | Optional realistic-weight mode at New Game; unlocks extra content as enticement | LOCKED | user-authored | Extra content is writing-track. |
| EC-6a | Rare, escalating exit misroute; no explanation; Patch's frustration sound | LOCKED | user-authored | Guarded: unlocked + visited areas only. |
| EC-12a | Mana Seed EULA verification before any AI use | OPEN (pre-launch gate) | user-authored `[A15]` | Cannot be closed by a session; closed by reading the license. |
