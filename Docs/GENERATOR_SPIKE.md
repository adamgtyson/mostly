# Generator Spike — Anchor-and-Fill (Session 8)

**Status of this document:** build record for the `[G3]` spike. It rules nothing: every number it touches is a `[G4]` PLACEHOLDER, and the design authorities remain ENGINEERING_CONSTRAINTS §7 (input format), Docs/04 "Map Generation (Anchor-and-Fill)" (algorithm), and the ledger.

## What was built

Three `RefCounted` classes under `scripts/generator/` — `MapGraph`, `RegionGenerator`, `GraphValidator` — plus `tools/generator_sweep.gd` (1000 seeds per region, wired into `tools\check.bat` as step 4/4 at ~115 ms) and `data/generator/config.json` with its schema. Eight tests in `tests/test_generator.gd`. No scenes, no tiles, no `SceneRouter` changes: the output is a resolved graph and nothing consumes it yet.

## The algorithm as implemented

1. **Anchors first**, as nodes, in the order `region.json` declares them (Docs/04: fixed elements every run).
2. **Edges in declared order**, each resolved one of three ways:
   - `via_slot` → a chain of fill nodes between the endpoints; count = the slot's `length_hint` clamped to the touchpoint type's `[min_distance, max_distance]` band (clamping is recorded as a warning). Every chain currently uses the `default` band — see open question 1.
   - an endpoint that **is a slot id** (EC-7 allows `from`/`to` to name a slot) → that slot materialises as a single terminal fill node. This is how the Hold's dev slot hangs off the workshop.
   - neither → a direct anchor-to-anchor link.
3. **Fill node contents:** biome drawn from slot pool ∩ region pool (an empty intersection falls back to the slot's own pool, with a warning); `spawn` from `spawn_pool` or null; `area` = the slot's `default_area`; `name` always null — settlement names come from biome-appropriate pools (Docs/04) and those pools are writing-track.
4. **Determinism:** one `RandomNumberGenerator` seeded by the caller, drawn in a fixed order. Same inputs → byte-identical `to_json()` (asserted).
5. **Validation** (`GraphValidator`, all errors reported, never just the first): every anchor reachable from every entry point; no orphan slots (a slot no edge references); chain lengths inside their band; every `required_exits` entry matched by an edge; the graph connected.
6. `MapGraph.resolve_default_areas()` is the EC-7 v1 bridge — every fill node mapped to the hand-filled scene it stands for. Exercised by tests, consumed by nobody.

## Config placeholders → `[G4]`

| Config key | `[G4]` item | State |
|---|---|---|
| `touchpoint_types.*.min_distance/max_distance` | distance constraints per touchpoint type | PLACEHOLDER values; only `default` is reachable (open question 1) |
| `regions.*.biome_pool` | biome pools per region | PLACEHOLDER: all ten `[F19]` biomes for both regions, so no region–biome mapping is invented |
| `regions.*.biome_bleed_to_hold` | biome bleed | empty; bleed not built |
| `chain_link_count` | chain link count | 5, because CANON's delivery chain has five human links (`[G4]` said 4 — cited, not ruled); nothing consumes it yet |
| `village_route_variation` | village-specific route variation | empty object, OPEN |

## Deliberately not built

Scene driving (EC-7: v1 fills every slot by hand; `SceneRouter` untouched). Tile painting. Biome bleed into The Hold. Village-specific route variation. Settlement naming. Stub-region behaviour. The `[G3]` spec text itself was not found in `Docs/handoff/` — only its description in the ledger, DESIGN_HISTORY D17 and PROMPT_WORKSHOP_HANDOFF's extracts — so the spike proceeds from EC-7 and Docs/04, with `[G3]`'s recorded architecture (graph, RefCounted, 1000-seed validator, external config, MapGraph JSON) and meta-rules (report all failing seeds; never relax an assertion) honoured.

## Sweep output (session 8, build machine)

```
== generator sweep: 1000 seed(s) per region ==
region hold: 1000/1000 valid, 0 warnings
region turning: 1000/1000 valid, 0 warnings
sweep: ~115 ms
generator_sweep: all seeds valid
```

## Open questions the spike surfaced

1. How does a fill slot or edge name its touchpoint type, given that the EC-7 `region.json` shape has no type field — does the shape grow an optional field, or does a naming convention carry it?
2. When the `[G4]` biome pools stop being placeholders, which side wins a slot/region pool conflict as a matter of design (the spike's slot-wins-with-a-warning is an implementation choice, not a ruling) — and is biome bleed into The Hold a property of the border slot or of the Hold's own manifest?
3. What does a resolved fill node become at scene level — one area scene per fill node, as `default_area` implies today, or can several fill nodes share one scene — and what does that choice do to `<region>/<area>` ids in flags and saves (§6)?
