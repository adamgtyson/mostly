# MOSTLY_COLLABORATION_GUIDE.md — How to Work With Adam on Mostly

**Version:** 2026-08-28. Now grounded in the actual conversation record (eight session extracts), the Docs, Adam's standing instructions, and his rulings in this session. Operational, not descriptive of personality.

---

## 1. Invention latitude

- **Design conversations: invent freely, in batches, inside the constraints.** The record shows Adam asking for and accepting large generative passes — settlement lists, rosters, mottos, institution jokes — then keeping some and cutting others. The constraints are fixed: no villain; no chosen-one language; deadpan not absurdist; every institution accidentally manages The Forge; humor via restraint plus one implied-history detail; nothing surface-funny.
- **Build sessions: invent nothing.** `CLAUDE.md`: "Do not invent names, places, or mechanics not found in the docs. Ask first."
- **Never propose answers to the BY DESIGN mysteries** (Empty Box, Fifth Appendix, Bureau of Rotational Affairs, Listening Stick, Brother Edwin, Prior Balance's clocks, the backward mill, the flipbook bird).
- **Don't hit the theme too hard.** Adam rejected a "Probably" village in every region: "that surfaces enough already and I don't want to hit people over the head with it." One motif per beat; let the reader find it.

## 2. Proposals vs. canon — the most important section

The record shows the single biggest failure mode of this project: **assistant proposals getting promoted to canon without Adam's confirmation.** Two cases are documented — the "two sounds" irony and "modules append to The List" were flagged PROVISIONAL on July 21 and written into the Docs as "(locked)" on Aug 5 by a Claude Code pass. Adam pulled them back on Aug 28.

Rules:
- Tag everything: LOCKED / PROVISIONAL / OPEN / INFERRED / REJECTED. "Locked" requires one of: Adam wrote it; Adam said "lock it in" / "yes" to that specific thing; or Adam gave a blanket "lock this in, including your suggestions" *and the item was in that package*.
- When Adam gives a blanket approval, list what the package contained so the record shows it.
- When drafting a Claude Code prompt that writes to Docs, quote the status of each item from the chat, not from your own summary. A build prompt is where PROVISIONAL becomes LOCKED by accident.
- Nothing is canon until it is in `Docs/` and committed. Chats are working memory; the repo is the record. But the repo is also *incomplete* — see §11.
- Keep a ledger row for anything new (MOSTLY_DECISION_LEDGER.md format): item, status, first seen, authority.

## 3. How much to generate when brainstorming

Observed and accepted batch sizes: 5–9 settlement names per region; 5 monks per order; 4 back-of-box drafts; 3 Act Two directions; 3 character-sheet variants plus a comparison. Short items, many of them, each with one twist. For a decision rather than a name list: 2–3 options with trade-offs and a recommendation, and say which you'd pick.

Adam also runs the same brief through a second model and has Claude compare (Aug 8). Expect to be asked to write a prompt for another model in a matching format, and to compare its output against your own honestly — the comparison on Aug 8 ranked Claude's own draft third of four and Adam accepted that.

## 4. Terminology

Canonical names exactly (CANON §7, §6). "Spooky Fluid," never dignified. Never "Glorp." Keep Patch's key lines, Latch's exchange, the hatch inscription, the letter, and Adam's opening prose verbatim. New names come from the villager naming pool's logic: "practical/maintenance words, old trades, natural materials." De-conflict against the pool (monk names were renamed for collisions).

## 5. Contradictions

Surface, don't resolve. The record shows the Docs, the chats, and the build drifting apart repeatedly (five-days vs. nine-days vs. eight-days; three settlement-list generations; a chain direction inverted by the character sheets; a build claimed that never happened). Adam's standing project instruction: flag date conflicts "rather than resolving them silently." Extend that to every conflict.

Authority order when sources disagree: Adam's latest explicit ruling → later Adam-authored text → later Adam-confirmed text → earlier text → assistant proposals. `CLAUDE.md` and code win only on *build state*.

## 6. When to ask, when to propose

- **Ask** when: a build needs a name/mechanic that doesn't exist; a change touches a LOCKED item; a command mutates anything outside the repo; the choice is Adam's taste (settlement names, mottos, endings).
- **Propose and proceed** when: it's a design conversation and the gap is small; label PROVISIONAL and move on. Adam's rule: "Good and launched beats perfect and delayed."
- **Ask one thing at a time** where possible; Adam answered ten rulings in one message when asked as a numbered list with one-line-answer permission. That format works.

## 7. Tone of the collaboration

Adam's standing rules, verbatim: "Be direct. No sugarcoating." "Skip preambles. Don't restate the question. Get to the answer." "Explain technical concepts from first principles without being condescending. Don't over-explain business concepts." "Concrete examples always preferred." "End every substantive conversation with a concrete next step, not a summary." Minimal formatting; prose unless a list is the content.

## 8. Humor

Write in-world text straight-faced. Adam's own writing is the reference: the opening prose, Latch's exchange, the back-of-box. Note the register — dry, domestic, specific ("Damn cat simply could not leave a cup unturned"). Test every joke against the humor rule. Stub/module content may be sillier; mainline may not. Don't repeat a motif until it becomes a tic.

## 9. Spoiler discipline

Separate PLAYER KNOWLEDGE / WORLD BELIEF / AUTHOR TRUTH in all story material. Player-facing text never leaks author truth. Seven Chickens' pro is obfuscated on the selection screen — that's the bar. The monks never learn Patch's role. Patch is never present when the Forge fails.

## 10. Mysteries and reveals

Permanent mysteries stay permanent. Reveals recontextualize rather than explain. Hedged claims are true; confident claims are false — new institutions and NPCs must obey this. The nine days, the backward mill, the flipbook bird: implied cause, never confirmed.

## 11. How seriously to treat the Docs

- Read `CLAUDE.md`, `CHANGELOG.md`, and `Docs/00` before the first substantive reply (project instruction).
- The Docs are authoritative *for what they cover* — but roughly half the locked canon (July 7 material) never reached them, and two "locked" tags in them are wrong. Use the Docs together with MOSTLY_CANON.md and the ledger until the Docs are updated.
- Preserve crafted wording. Fix cross-references and residue freely.

## 12. Editing existing material

Edit in place with a dated revision note; never append contradictory text below old text. Update Docs/06's decisions table in the same edit that locks anything. Rename repo-wide (the Glorp rename touched 9 occurrences across four Docs). `CLAUDE.md`'s two sections are overwritten, never appended; one CHANGELOG line per session; fixed commit message. Doc edits from a chat go to the repo via a docs-only sync prompt or a direct push — never bundled into a build prompt (Adam rejected that on Aug 5).

## 13. Designing new material

Start from constraints and the ledger. Check the ledger for a REJECTED row before proposing anything (titles, order names, village names, mechanics have all been rejected before). Structure deliverables to be "easily digestible by Claude.ai… and translatable to Claude Code." For anything that becomes a build task, reduce it to a Prompt Workshop prompt.

## 14. Workflow facts

- Mostly is built locally on Adam's Windows machine ("the-rig"); Claude Code runs in `C:\Projects\Mostly`. Claude wrongly assumed the SSH/Ubuntu workflow twice and was corrected both times. Don't.
- GitHub connector is manual "Sync now." Start a new conversation after any GitHub-side change.
- Adam's loop: plan in a claude.ai project → one prompt per phase → paste into Claude Code → paste the session summary back. Claude Code Remote Control is used for phone monitoring.
- Adam sometimes drafts story with a second LLM and compares.
- Adam's own words (Aug 28): "I'm having trouble keeping track of all of the details, and the AI models I'm using understandably lose track as well with context creep." The collaborator's job includes being the continuity department: restate status tags, cite the ledger, and flag when something you're about to write contradicts an earlier lock.

---

## Things That Tend To Annoy The User

Supported by the record:

1. **Proposals promoted to canon without confirmation.** Documented twice (two sounds; List-append). Adam pulled both back.
2. **Claude asserting things that didn't happen.** The Aug 5 session reported an anchor-and-fill build "done" on July 10 via a conversation search; it never happened. Verify against the repo before stating build facts.
3. **Assuming the wrong environment.** The SSH dev-server assumption was corrected on July 10 and again Aug 5.
4. **Stale memory/notes presented as current.** Claude's memory note said "no story or characters developed yet" on Aug 5 while the chain had been characterized on July 7; Adam had to untangle a memory-file vs. project-file confusion on Aug 8.
5. **Extract/summary models mis-dating or contaminating.** Two extracts flagged their own date conflicts; the July 7 extract references a rename that happened July 21. Adam's standing instruction exists because of this: flag date conflicts, don't resolve them silently.
6. **Overusing the theme** ("Probably" everywhere).
7. **Chosen-one drift** — struck from the back-of-box and flagged as a recurring instinct to watch.
8. **Preambles, restated questions, summaries instead of next steps; softened criticism; over-explained business concepts** (standing rules, emphasized).
9. **Paraphrasing the Final Task block; commands that could touch production without permission** (recorded as absolute rules).
