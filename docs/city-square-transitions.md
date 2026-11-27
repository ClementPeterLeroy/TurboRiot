# City Square - local transition fixes

2026-11-27. **0.6.1-dev / 0.6.1.0, Unreleased, pending developer acceptance.** This follows the [roof correction](city-square-architecture.md). The later brief authorizes local garden paving changes; it does not reopen the broader layout or housing pass. The three screenshots in the ignored `references/screenshots/` folder guided this work.

## Exact architectural changes

No original house is deleted. Of the previous 117 instances, **115 retain their exact manifest data and native transforms**. Only these two existing instances move:

| Instance | Previous X / Y / Z | New X / Y / Z | New rotation |
| --- | --- | --- | --- |
| `AvenueEntryWest_House01` | -129.716 / 1.200 / 128.252 | -139.840 / 1.200 / 129.000 | -90 degrees Y |
| `AvenueEntryWest_House02` | -138.241 / 1.250 / 115.815 | -139.340 / 1.200 / 138.000 | -90 degrees Y |

They become the last two lots of the garden-facing western terrace. Their wide-house/merchant-house assets remain unchanged.

**Eleven shared-module instances are added**, bringing the total to 128:

| Native instance names | Existing modules reused | Purpose |
| --- | --- | --- |
| `FountainEntry_West_00`, `_01` | Merchant, corner | Close the west avenue/fountain housing gap |
| `FountainEntry_East_00`, `_01` | Merchant, corner | Close the east avenue/fountain housing gap |
| `GardenEntry_West_00`, `_01`, `_02` | Corner, wide, merchant | Connect the existing avenue terrace to the two relocated western houses |
| `GardenEntry_Corner` | Corner | Frame the avenue/garden corner with complete facades |
| `GardenLandEdge_00`, `_01`, `_02` | Harbour, merchant, narrow | Close the 21.495 m land-side opening between the existing garden row and coast frontage |

Only the new lots receive small width fits: about 6.4-8.7% at the fountain and 2.4% in the two garden rows. Height/depth remain unchanged; meshes are still shared. Their native collider scales follow the instances. The land survey confirms the existing foundations seat correctly; no additional footing extension was necessary.

The two irregular `AvenueEntryWest` / `AvenueEntryEast` infill objects and their native collision bodies are removed. These are the malformed connectors shown in the screenshots, rather than the approved house modules. The other **ten connector meshes preserve their geometry, material assignments, UVs and transforms exactly**. All six house GLBs, Blender masters and wrapper scenes are byte-identical to the preceding pass; no roof is reauthored.

The [change manifest](../artifacts/v061_city_transitions_changes.json) records all added lots, precise positions, rotations, scales, footings and before/after values. Every new lot is an ordinary editable instance under `Ground/Architecture` in `scenes/environment/city_square/environment.tscn`.

## Paving and width

The fountain road was already continuous and remains geometrically unchanged. The four inserted modules close its enclosure without narrowing the 22 m avenue or blocking the fountain/alternative route. Horizontal rays through both new frontages measure at least **13.5 m centre-to-facade clearance**. Their bases and local footings meet the existing grade.

At the garden entrance, the physical paved bend expands gradually from the existing **10 m path to an 18 m apron**, then joins the existing avenue. A bounded forecourt reaches the replacement house fronts, approximately **28.7 m apart** on the avenue approach, removing the exposed slab edges and grass slits seen in the screenshots. It tapers back to the preserved street. This is additional drivable paving around the existing route, not a new centreline, checkpoint system or width change elsewhere. Nominal racing-corridor resources remain unchanged; existing garden progress rules already allow this area.

Only the paving inside **X -146 to -75 / Z 80 to 144** is remeshed. The existing volume is clipped locally, joined to a constrained triangulation of the paved union and given the source route's projected grade. It has one top support surface, rather than a floating collision overlay. The existing stone texture and UV scale are retained. Grass is clipped out beneath the apron; new seam vertices sample the actual paving top with a vertical query, avoiding a nearest-point query accidentally selecting the slab side below its top.

Clipping dust with sub-5 mm triangle altitude is removed in the edited grass area before export. The collision refresh also rejects collapsed triangles inside the local crop after import. Final meshes required **zero such collision removals**. A separate nonlinear height blend proved incompatible with the ribbon's long constrained edges during development; the final mesh retains the ribbon's projected grade. No controller constants, camera smoothing or movement logic are changed to conceal geometry problems.

The garden's northern land-facing edge now connects through to the coast frontage. Its western edge is framed by the modular terrace. Route openings and the intended waterfront remain open; no fence, curb, barrier or new decoration is added.

## Locality and validation

The [baseline fixture](../tests/fixtures/city_transitions.json) preserves **89 untouched files**, including all six house assets, stairs/dock assets, fountain, route/width/checkpoint resources, project metadata and runtime scripts. The previous roof-pass freeze remains recorded; only the four approved paving/terrain source/export hashes are superseded for the later authorized paving change. The ten retained connector meshes, timber mesh, land, water and cliffs additionally pass exact component fingerprints.

- **1,683 Godot checks, zero failures**, including original handling, launch, drift, items, checkpoint, water recovery, staircase and presentation regressions.
- **115 source/locality checks and 114 roof/volume checks, zero failures**. Outside the crop, 4,453 paving and 1,052 grass support samples retain height within **0.000003815 m**. Shared-edge normal aliases are checked against the original adjacent faces. [Locality audit](../artifacts/v061_city_transitions_audit.json), [roof audit](../artifacts/v061_city_transitions_roof_audit.json).
- All three physical entrance probes, at lane offsets -6 / 0 / +6 m, complete with **zero airborne frames**. Peak per-tick height changes are about 17.7 / 16.7 / 24.2 mm at the fixture's conservative driving speed. The entire sampled 15 m lane envelope has walkable paved support. Eleven real grass crossings retain smooth entry, exit and surface detection. [Lane report](../artifacts/v061_city_transitions_driving.json), [structural regressions](../artifacts/v061_city_transitions_structure_physics.json).
- Native 1920x1080 full lap: **74.850 s**, zero recovery and zero sampled camera obstructions over 4,672 physics samples. [Lap report](../artifacts/v061_city_transitions_native_lap.json).
- Seven Challenging AI racers finish three laps with items/seed 42 and **no DNFs**; there are 35 item uses and one recorded recovery. This is not a zero-recovery claim. [Item race](../artifacts/v061_city_transitions_ai_race_2_7_3_all_ai_items.json). The separate no-item probe is recorded in [validation](validation.md).
- All seven also complete the no-item one-lap probe with **zero recovery/DNF**. [No-item race](../artifacts/v061_city_transitions_ai_race_2_7_1_all_ai_baseline.json). This isolates the basic route/traffic test from item effects without attributing an unobserved cause to the item-race recovery.
- Headless import, native editor opening, final presentation captures and the matched performance sample are recorded in [validation](validation.md). The known Windows certificate-store warning is unrelated to game/script validation.

Review [fountain before](../artifacts/v061_city_transitions_before_fountain_oblique.png) / [after](../artifacts/v061_city_transitions_fountain_oblique.png), [garden before](../artifacts/v061_city_transitions_before_race_1095.png) / [after](../artifacts/v061_city_transitions_race_1095.png), [avenue approach](../artifacts/v061_city_transitions_race_1105.png) and [garden enclosure](../artifacts/v061_city_transitions_garden_overhead.png).

The matched native 1080p protocol uses seven racers, Challenging, items/seed 42, VSync off and uncapped rendering, with 360 warm-up and 720 measured physics ticks on the RTX 3070 Ti Laptop GPU / Ryzen 7 6800H. No other validation processes run during the benchmark.

| Metric | Before local pass | After local pass |
| --- | ---: | ---: |
| City average FPS | 57.39 | 75.99 |
| City mean frame | 17.42 ms | 13.16 ms |
| City P95 / P99 | 32.39 / 108.57 ms | 29.13 / 46.01 ms |
| Figure-8 reference FPS | 101.43 | 137.85 |
| City mean draw calls | 1,392.55 | 1,532.13 |
| City rendered primitives | 353,154 | 395,610 |
| City nodes / collision shapes | 2,023 / 186 | 2,072 / 195 |

[Before report](../artifacts/v061_city_transitions_before_performance.json), [after report](../artifacts/v061_city_transitions_after_performance.json). The reference also becomes substantially faster, so the FPS increase cannot be attributed to this patch; this indicates variable machine/load conditions. Added architecture has a real complexity cost. The final sample averages above 60 but retains frame spikes; sustained minimum-60 performance is not established. Artist approval, longer sessions and an exported build remain pending.

## Files and editing

Production changes are limited to `manifest.json`, the existing native environment scene, and the masters/exports for `driving_surfaces`, `coast_and_terrain` and `architectural_links`. No new building mesh asset is introduced. Import compression settings remain unchanged.

`tools/fix_city_transitions.py` and `tools/apply_city_transitions.gd` document the guarded one-time edits. Do not rerun the initial city builders. For normal iteration, edit the existing masters/native instances, export/import explicitly, and use `apply_city_transitions.gd -- --refresh-surfaces` to update only the two affected saved floor colliders after an intentional paving change. It does not refresh docks, stairs, other houses or the remaining infills. Keep the constrained grade triangulation; inspect the exported/imported collision as well as the Blender surface.

```text
blender --factory-startup --disable-autoexec --background --python tests/audit_city_transitions.py
blender --factory-startup --disable-autoexec --background --python tests/audit_city_architecture.py
godot --headless --editor --path . --import
godot --headless --path . --fixed-fps 60 --script tests/run_tests.gd
godot --path . --script tests/capture_city_transitions.gd
godot --path . --script tests/validate_city_square_lap.gd -- --report-prefix=v061_city_transitions
```

The structural tests now find the actual grass edge beyond the wider apron and allow the existing surface debounce to complete. Wall probes begin on the road so that a point inside a house cannot masquerade as accessible grass. Only the two replaced infill coverage paths are superseded; independent modular-frontage, clearance and driving checks cover their replacements. The remaining original frontage reach limits and all earlier acceptance wording remain unchanged.

The new runtime suite contributes 229 assertions. Six former assertions specifically for the two removed infills are superseded (two frontage paths and four link/collider checks); the remaining 1,454 previous assertions plus the new 229 produce the 1,683-check total. Historical manual checks 248/250 refer to the preceding assembly; the new checklist explicitly maps those two local replacements to 257-258 without deleting the old wording or excusing other locations.

Manual criteria **255-262** remain pending. Artistic approval of the joints, human racing at speed, longer item/traffic sessions, target-PC performance and an exported build are still required. This pass does not claim the next milestone, a released patch or zero recovery in every item race. No staging, commits, pushes, tags or GitHub operations.
