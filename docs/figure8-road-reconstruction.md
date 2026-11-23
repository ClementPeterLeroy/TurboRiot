# Circuit 8 reconstruction — Milestone A

2026-11-26. **v0.6.1-dev, Unreleased; developer visual/driving acceptance pending.** Only the road study is implemented. Terrain/bridge structure (B), stadium architecture (C), and final safety/art polish (D) remain future work, in that order.

**Subsequent implementation:** the developer authorized continuing from this road stage. The [stadium environment](figure8-stadium.md) now supplies bridge/terrain, curved stands, pit/control architecture and safety/perimeter. The exact road-only scene is preserved at `scenes/tracks/archive/figure_8_road_study.tscn`. Results and defect descriptions below record the earlier road-stage state; they do not describe the current stadium.

## Audit and design decisions

The original road was already densely sampled, with a usable 15 m width relative to the kart's 1.25 × 0.75 × 2.1 m collision envelope. Increasing polygon count alone would not repair its shape. The saved centerline's independently chosen handles produced curvature changes at joins; the short crossing approaches reached 12.55% grade. Individual box kerbs and faceted colored barrier blocks emphasized segmentation. Flat ground beneath raised approaches did not form embankments. The previous straight canopy stands and small bridge assembly did not enclose the circuit or establish the requested curved stadium/pit architecture. Adding more props would leave those primary problems intact.

Retain the recognizable figure-eight, horizontal interpolation positions, width and race framework. Reconstruct its spline handles and elevation first. Keep the previous environment available as an archive rather than adapting its architecture prematurely.

| Measurement | Before | Milestone A |
| --- | ---: | ---: |
| Baked circuit length | 663.56 m | 663.43 m |
| Road width | 15 m | 15 m |
| Maximum sampled grade | 12.55% | 7.69% |
| Minimum sampled horizontal radius | 21.22 m | 24.40 m |
| Crossing rise | approximately 7 m | approximately 8 m |
| Road row spacing | 1 m | at most 0.5 m |

Measurements use half-metre samples of the actual Godot baked curve, not the intended mathematical profile alone. JSON evidence: [before](../artifacts/figure8_road_before.json), [after](../artifacts/figure8_road_milestone_a.json). Radius is a local heading-difference estimate over one metre.

All 35 unique horizontal interpolation positions are preserved. A periodic cubic solve gives matching first and second horizontal derivatives at joins, including closure. Elevation uses a quintic rise/fall profile converted into saved cubic Hermite handles, with matching first derivatives. The approximately 195 m ascent and 205 m descent extend into the loops: this is the deliberate tradeoff needed to fit an 8 m rise below 8% grade without changing the horizontal layout. The actual crossing top measures approximately Y=8.040 m; its lower road remains Y=0.040 m. No banking is introduced.

The existing cross-section sweep generates the road and shoulder collision. Half-metre rows improve silhouettes; normals still derive from the actual tangent and lateral vector. A single batched, noncollidable ribbon supplies temporary red/ivory kerbs. Neutral temporary barrier visuals retain existing physical barrier placement. They are not the final barrier/fence system. Kart physics, collision hull, jump/contact fixes, camera, progression, recovery, grid, and AI controllers are unchanged; their generated positions follow the new authoritative curve.

## Editable sources

- `scenes/tracks/figure_8.tscn`: authoritative saved Curve3D, width, sampling, bounds and temporary road-study switch. Edit its Path3D in Godot; no startup script rewrites its handles.
- `tools/reconstruct_figure8_road.py`: explicit offline authoring tool, standard-library Python. It records design parameters in `resources/tracks/figure_8_road_reconstruction.json`. Once the archive exists, rerunning requires `--replace-generated`, which discards subsequent active-scene edits; review those edits first. The game never invokes this tool.
- `scenes/tracks/archive/figure_8_before_reconstruction.tscn`: exact prior scene, including the owner's instance placement overrides. Its original environment, Blender sources and reusable assets remain available. It is not registered as another playable circuit. Existing environment contracts now run against this archive.
- `TrackBuilder.road_study_mode`: opt-in temporary presentation; the registry loader preserves the property. Other tracks keep their existing mode. `Generated` remains disposable; future authored modules belong outside it.

The old trace JSON remains historical reference evidence. The saved scene Curve3D is authoritative for the reconstruction. Future terrain/bridge authoring must use the new curve; the earlier bridge profile fits the archived road and must not be reattached unchanged.

## Visual inspection

[Top-down](../artifacts/v061_figure8_milestone_a_top.png) · [Perspective overview](../artifacts/v061_figure8_milestone_a_overview.png) · [Actual chase camera on the approach](../artifacts/v061_figure8_milestone_a_chase.png) · [Native application during a driven lap](../artifacts/v061_milestone_a_native_figure_8_minimap.png)

The images were captured and inspected. The road has flowing turns, continuous edge strips and a gradual crest, with no visible ribbon cracks in these views. Remaining visible defects: raised approaches float over flat placeholder ground, the deck has no thickness/supports, temporary barriers show their modular joins, and there is no enclosing stadium, pit complex, final material/lighting treatment or finished infield. Those omissions are explicit B–D work, not a finished environment. Static captures cannot establish motion comfort or eliminate every possible camera-clipping case.

Reproduce the three study views with:

```powershell
godot --path . --script tests/capture_figure8_road.gd
```

For manual acceptance, launch the application, select Figure-8 in Time Trial and Quick Race, and drive full laps through both decks and all lanes, including boosted/drifting passes. Inspect the crest, both loop approaches, camera clearance and recovery/restart. Use cumulative checks 188–192. Do not proceed to B merely because the scene loads.

## Validation

- Full retained suite plus 17 geometry contracts: **1,133 checks, zero failures**. The new contracts cover saved point preservation, closure, derivative continuity, measured grade/rise/radius/length, every cross-section width, triangle winding/degeneracy, temporary presentation isolation, independent crossing decks and archive preservation. The existing 52 real-physics crossing checks remain unchanged, including both directions, side lanes and mushroom passes.
- Seven AI-controlled racers, three laps, item seed 42: all finish, **zero recoveries and no DNF**, 32 pickups / 31 uses. [Race report](../artifacts/v061_figure8_milestone_a_ai_race_2_7_3_all_ai_items.json).
- Native application Time Trial: one full lap in **33.383 s**, zero recoveries, correct results, competitive items disabled. Uses the real chase camera and physical AI input, without scripted progress or movement.
- Same-process native 1080p benchmark, seven racers: archived environment 144.5 FPS versus road study 175.6 FPS; P99 frame times 14.12 ms versus 14.60 ms, physics about 60 Hz. [Benchmark](../artifacts/v061_figure8_milestone_a_performance.json). The road study omits the previous scenery and batches kerbs; these figures are not a like-for-like finished-art optimization, a minimum-FPS guarantee, or proof that future stadium geometry meets budget.

Engine validation and logs are recorded in [validation](validation.md). No version increment or Git mutations. The pre-existing banana resource edit is preserved. Human artistic acceptance, hand-driven laps, broader frame-rate/device tests and final environment performance remain pending.
