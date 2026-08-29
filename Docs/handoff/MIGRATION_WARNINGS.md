# MIGRATION_WARNINGS.md — What This Handoff Cannot Vouch For

**Version:** 2026-08-28 (rebuilt). Read this first.

## 0. Reading order
MIGRATION_WARNINGS → MOSTLY_DECISION_LEDGER → MOSTLY_CANON → MOSTLY_STORY_STATE → MOSTLY_ACT1_BUILD_PLAN → the rest. Nine files total.

## 1. What was used

- The repo `adamgtyson/mostly` at `6a740fe` (Aug 5): Docs/00–06, CLAUDE.md, CHANGELOG.md, code, dialogue JSON, git history.
- Eight per-conversation handoff extracts produced by Claude inside each thread (June 7, July 7, July 10, July 21, Aug 5 ×2, Aug 8, Aug 11). These are *secondary* — a model's summary of a conversation, not the transcript.
- Five character-sheet documents and the comparison from Aug 8.
- Adam's ten rulings and clarifications in this session.
- Adam's profile-level instructions and memory notes.

## 2. What was NOT used

- **Raw transcripts.** Adam has the claude.ai data export but it was not needed for this pass. If any ledger row's authority looks wrong, the export is the tiebreaker.
- **The Prompt Workshop v1 skill file.** Still not seen. Part B of PROMPT_WORKSHOP_HANDOFF.md is reconstructed from profile instructions plus three observed outputs.
- **`mostly_story_primer.md`** (Aug 8, the onboarding doc given to the second model) and **`mostly_lore_summary.md`** (July 21). The character sheets cite the primer's "Section 10 tone checklist." Not inspected; may contain phrasing that drifted from canon.
- **The local working tree** at `C:\Projects\Mostly` — may be ahead of `main` (Adam says Aug 5 was likely his last session; unverified).
- Claude Code session transcripts.

## 3. Known unreliability in the extracts themselves

- The **July 7 extract** references the Abbey rename (July 21) as "a prior session." Either that conversation ran past July 21 or the extracting model contaminated it from project knowledge. Adam ruled the rest of its content stands. Treat its *dates* as approximate.
- The **Aug 5 doc-sync extract** states an anchor-and-fill build "was done in a 2026-07-10 session." The July 10 extract and the repo both say it wasn't. Adam agrees it didn't run. **Any extract claim about build state that isn't in git is suspect.**
- The **Aug 11 extract** is actually from Aug 28 and contains no decisions.
- The **Aug 8 character sheets** (all four sets) invert the direction the commission traveled. They were written from the primer, so the primer may carry the same error.

## 4. Canon I am still unsure about

- **The Grinding vs. the Order of the Most Sacred Mystery** — one order or two. July 7 gave each a roster, which leans "two," but nobody has said so.
- **Brack's identity across sources** — July 7: older monk running the ceremony; Aug 8 sheets: a technician with no monastic framing. Adam has only ruled on Brack's *state* (mid-panic).
- **Whether the July 7 map layout survives** the territory review Adam asked for. It's LOCKED in the ledger with a flag; the Balance/Turning adjacency contradiction is real.
- **Stonemonth, 32 spheres** — build-only; Adam has not ruled.
- **Fletch/Brace as the sober monk** — Brace is "for now."
- **Which motto set** per region survives (Adam ruled on the *rule*, not the *values*).
- **Whether the "Probably" village was ever Adam's idea** — extracts show it rejected at founding and again Aug 28; the July 7 "LOCKED" tag on it was likely the extracting model's.

## 5. Contradictions still requiring resolution

Circle location; act boundary; Grinding/Mystery; naming convention vs. names; settlement lists (three generations); map adjacency; Brack's ceremony vs. no-witness-overlap (ruling given, restaging not done); village pro/cons in cut vocabulary; pronouns; stale cross-references. Full list: MOSTLY_OPEN_QUESTIONS.md.

## 6. Structural risk: the Docs are behind the canon

Roughly half of the LOCKED material in MOSTLY_CANON.md exists only in the July 7 chat: back-of-box, opening prose, Latch, Near Enough/Last Post/Still Point, chain characterization, the Er'side, the hatch inscription, engineering purposes, the children's story, all monastic rosters, Brother Edwin's multiplicity, the forge network, the party system and companions, the naming pool, the map layout. Any collaborator who reads only `Docs/` will re-invent or contradict these. **First job for the next collaborator: a docs-only Claude Code prompt that writes this material into Docs/ with status tags and dated revision notes**, then commit, push, Sync now.

## 7. Two Docs "locks" are wrong

Docs/05 "two sounds… (locked)" and Docs/02 "Endgame modules append entries to it" are assistant-promoted. Adam pulled them back. The Docs still say locked until edited.

## 8. Endgame model is in flux

Docs/03's endgame-module section, Docs/04's stub-region section, and pillar 4 ("combinations over count") are all PROVISIONAL pending Adam's revisit. Don't design against them.

## 9. Parts of the Prompt Workshop not faithfully reconstructed

The v1 skill's additions, if any; the concrete cheap-signal/expensive-check commands for Godot (never recorded); the phase-planning step that precedes the workshop in Adam's loop.

## 10. On Adam's memory question (secondary-brain platforms)

Answered in chat; summarized here for the record: the failure mode in this project was not recall, it was *unratified proposals being promoted and stale summaries being trusted*. A retrieval layer over chat history reproduces that (the Aug 5 `conversation_search` hallucination is the example). The fix that fits the existing workflow is a single ledger in the repo (MOSTLY_DECISION_LEDGER.md) as the only source of truth for status, updated at the end of every design session via the docs-only sync prompt, and synced to the Project. External memory tools are optional on top of that, not a substitute.
