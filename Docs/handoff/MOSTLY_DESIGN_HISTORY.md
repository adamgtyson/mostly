# MOSTLY_DESIGN_HISTORY.md — Settled Decisions and How They Were Reached

**Version:** 2026-08-28. Now built from the actual conversation record (eight extracts, June 7 – Aug 11) plus the repo and Adam's rulings, not reconstructed from doc residue. Ledger IDs in brackets. Where a rationale is Adam's, it is quoted.

---

## Timeline

| Date | What happened |
|---|---|
| 2026-06-07 | Founding session. Modding-as-metagame premise; title; Patch; world; nine villages; six regions; monastic orders; GDDs generated. |
| 2026-06-18 → 07-07 | Claude Code sessions 1–3: workshop scene, dialogue system, opening cutscene. |
| ~06 → 07-07 (one long conversation) | The July 7 design session: **mod system cut**; back-of-box; opening prose; Latch; chain characterized; places; rosters; crafting; party; map layout; naming pool. Very little of it reached the Docs. |
| 2026-07-10 | Fable autonomy test planned on anchor-and-fill; build prompt drafted; GitHub connector chosen. Build not confirmed run. |
| 2026-07-21 | Bridge locked; summons letter; The List; Brother Aldous; **Glorp Abbey → Abbey of the Hopefully Infinite Thrum**; price target; EULA principle. |
| 2026-08-05 | Repo under git and pushed; Docs synced to Project; mod-removal fully propagated; **Forge = end of Act One**; stub tone lock; Claude Code doc-lock pass (commit `cab2ff6`). Last commit. |
| 2026-08-08 | Delivery-chain character sheets: Draft 0 + three variants from a second model + comparison. Selection paused. |
| 2026-08-11 (actually 08-28) | Recap for Adam's wife; "The Mostly" etymology question; no decisions. |
| 2026-08-28 | This handoff; ten rulings from Adam. |

---

## D1. Modding as the game → story-first

- **Original (founding, LOCKED then):** "The game is a completable RPG with a built-in declarative mod system. Modding is the meta-game. The character experiences the world breaking; the player repairs it via mods." Act One winnable vanilla; after that "some form of modding becomes necessary." Community sharing load-bearing. Repair primitives guarantee solvability.
- **Cut (July 7):** Adam: "Are we overcomplicating the game with this modding first mentality, especially the declarative modding system? Should we instead build the game as it is beginning today?"
- **Reason (July 21, Adam):** "This whole thing started out as an idea for a game where modding was a core concept (in-game and as a meta game), but then I liked the story so much that I didn't want to distract from it."
- **Propagated to Docs:** Aug 5 (Adam: "we need to break that reliance on modding").
- **Status:** REJECTED, permanently. `[D2]`
- **Residue:** village pro/cons mention "world-break events"; Docs/03 "Modders can add rows"; Docs/01 references; Project description; the cart-build beat (see D6).

## D2. Break-and-repair world state → narrative unraveling only

Cut with D1. The unraveling stays real in fiction; no mechanical broken state requiring player repair. Residual OPEN: whether stubs read as unstable until filled. `[G19]`

## D3. What replaces modding: stub regions + endgame modules → *under revisit*

- **July 7:** "the stub regions effectively become a build-your-own-end game setup." Studio ships 4–6 seeded mods on Nexus, "Not DLC — proof of concept with open source files." Stubs must be "legibly empty."
- **Docs (Aug 5):** 4–6 studio-authored endgame modules; pairwise interaction matrix required; "combinations over count."
- **Aug 28 (Adam):** "the game should ship complete with modules for each 'outer region,' but I DO want to give the ability to mod the game by replacing those regions. An initial set of mods, sure, we can release on Nexus to give examples."
- **Status:** the whole endgame layer is TODO. Stub-regions-as-empty may not survive. `[G15–G17]`

## D4. Reaching The Forge: the ending → the end of Act One

Adam (Aug 5): "I think Patch's journey to The Forge shouldn't be the end of the game, rather the end of Act 1. I don't have a ton of good ideas yet but I think this should be a game in at least 2-3 acts, before the modding/stub regions/endgame content." LOCKED. Three assistant-proposed directions for Act Two exist, none chosen. `[D3–D4]`

## D5. The opening: five-day deadline + cart decision → Adam's prose

- **Founding:** note says five days; can't carry the spheres; optional cart build "introduces crafting philosophy."
- **July 7:** Adam wrote the opening in prose — eight days on the form, address lost to the cat, horse and wagon, express-courier plan, nine days worked. The build implements most of it.
- **Aug 28:** cart build REJECTED — "a holdover from when I wanted to focus more on modding."
- **Consequence:** how crafting is first introduced is now OPEN. `[D12–D15]`

## D6. "Glorp Abbey" → "The Abbey of the Hopefully Infinite Thrum"

- Adam (July 21): "There's a very popular book series out which uses 'Glurp' as a verb and in a perfect world, there will be a ton of overlap between Dungeon Crawler Carl readers, and players of this game. It's going to break the immersion." Wanted "a bit more of a grandiose name." Chose his own: "I think I like mine, The Abbey of the Hopefully Infinite Thrum. Named for the overriding intention of every action taken by its monks…"
- LOCKED. Never reintroduce Glorp. `[H4–H5]`

## D7. The Thrum/Grinding "two sounds" and "modules append to The List" — locked in Docs, actually unconfirmed

Both were assistant additions on July 21, explicitly flagged as needing Adam's veto. The Aug 5 Claude Code pass wrote them into Docs as "(locked)." Adam, Aug 28: "I did not [confirm them], pull them back as 'locked' please." PROVISIONAL. **Lesson for the collaborator:** a build prompt can promote a proposal to canon by accident; check the chat record, not just the Docs. `[C9, D8]`

## D8. The bridge and the culpability rules

Adam's idea (July 21), then blanket "Yes, please lock this in to the documentation, including your suggestions." That package: odd-jobs tutorial; no witness overlap; the letter; The List; monks summon a fixer, not a suspect. Reaffirmed Aug 28 over the July 7 ceremony scene. `[D5–D9, C12–C13]`

## D9. The delivery chain: vague → seven named links → characterized → sheets

- Founding: "someone just as ordinary… a chain of mundane transactions." Links OPEN.
- July 7: Patch → Brindle → Wren → Hobb → Sedge → Abbey → Brack, each characterized; mechanics hung on Wren (maps) and Hobb (rumors). LOCKED. (Docs say "Locked, August 2026" — the names were committed then; they were decided July 7.)
- Aug 8: character sheets from two models; Adam chose sheets-before-scenes and cherry-picking; withdrew his first picks. PROVISIONAL.
- The sheets inverted the chain's direction — flagged, not adopted. `[E1–E10]`

## D10. Settlement lists — three generations, none final

Founding lists (in Docs/04 and /05, conflicting) → July 7 lists with mottos and a "Probably" per region → Aug 28: July 7 lists NOT ADOPTED, "Probably" REJECTED ("I don't want to hit people over the head with it"), thorough review of settlements *and territories* TODO. Stable Frequency / Nominal / Acceptable Variance / Within Tolerance / Village of Sensible Decisions were forgotten, not rejected — reinstated. `[F7–F10]`

## D11. Mottos — two sets → one per region + one per order

July 7 produced folk mottos and engineering mottos per region. Adam, Aug 28: one motto per region; the order's phrase should relate to it. TODO. `[F16]`

## D12. The sober monk — "young, anxious" → Fletch / Brace

Founding sketch; July 7 made Fletch the sober monk (female-Patch path); Aug 28 Adam: use Brace for male Patch "for now." `[E18–E19, E26]`

## D13. Latch

Named and fully written July 7 (Adam's dialogue). CLAUDE.md picked up the name; Docs/06 never did. Not an invention by Claude Code. `[E11]`

## D14. Titles, order names, village names rejected at founding

- Titles: *The Mostly (it's mostly fine)*, *The Hold*, *The Seventh Hammer* ("strong contender"), *The Last Turning*, *Good Bearings*.
- Orders: The Rule Against Looking Directly Into The Sphere; The Litany of Unpleasant Sloshing; The Doctrine of Respectful Distance; The Order of the Sacred Spin; "Et Cetera."
- Villages: Up A Bit, Flat Enough, The Little Woods, Dry Mud, Turnip Junction, Slight Bend ("throwaway map labels" at most).
- Also rejected at founding: a mandatory programmer audience; unwinnable runs as intentional design. `[A2, A8, H8]`

## D15. Patch as a combat smith / portable workbench / chosen one

All REJECTED July 7. Patch buys base gear and crafts modifications; forges are location-based and earned; no chosen-one language anywhere (Draft 2's back-of-box line struck). `[B6, G9, A9]`

## D16. Engine and environment

Godot 4 confirmed by build (June); building on the Ubuntu dev server REJECTED July 7 ("Godot requires a visual editor. Build locally."); Claude's own SSH assumption corrected July 10 and Aug 5. `[A13, I1]`

## D17. Anchor-and-fill: concept → build spec → not built → hard requirement

Founding concept (Adam: "the map generator (silently, but literally) connects the dots"); July 10 build spec for a Fable autonomy test (graph, headless, 1000-seed validator); Aug 5 extract claims a build happened — the repo says otherwise; Aug 28 Adam: "I don't think it ran but this is a HARD requirement." `[G1–G4]`

## D18. Workflow decisions (Aug 5, July 10)

GitHub connector scoped to Docs/CLAUDE.md/CHANGELOG, manual "Sync now," delete manual uploads; new conversation whenever GitHub-side changes; REJECTED bundling doc updates into build prompts (build sessions don't make lore decisions) → docs-only sync prompt or direct push; REJECTED adding the whole repo to Project Knowledge. `[I2–I5]`

## D19. Deliberately undecided (decisions *not* to decide)

Empty Box; Fifth Appendix; Bureau of Rotational Affairs; Listening Stick; Brother Edwin; Prior Balance's clocks; the backward mill; the flipbook bird; the nine days (to Patch). The Unlabeled Key: decide intentionally either way. What's in the circle: Adam, "frankly I don't know yet."

## D20. Rejected or superseded ideas whose reasons are not recorded

- The one-sound explanation of The Grinding's name (replaced by the provisional two-sounds idea).
- Docs/02's "Star Wars-style crawl" — not rejected, just never built.
- "Probably" as a settlement was rejected at founding *and* again Aug 28; July 7's revival was the assistant's, not Adam's, as far as the extracts show.
