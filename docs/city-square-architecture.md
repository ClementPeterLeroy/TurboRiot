# City Square - final architectural corrections

2026-11-27. **0.6.1-dev / 0.6.1.0, Unreleased, pending developer acceptance.** This pass changes roofs and local entrance architecture. The preceding [structural refinement](city-square-structure.md) remains the baseline; no decoration phase or new milestone is introduced.

## Diagnosis and source changes

The six original house roofs were solid gabled prisms, rather than open planes. Their 40 cm side overhangs intersected neighbouring terrace roofs. The more serious open-sheet defect was in the twelve newer connecting buildings: the source audit found between 80 and 764 open roof edges per group, with raised roof profiles and no corresponding gable closure. See the [pre-edit diagnosis](../artifacts/v061_city_roof_diagnosis.json).

All six existing masters in `assets/environment/city_square/sources/` and their corresponding GLBs are corrected in place. Source objects remain editable; all original facade object geometry, transforms and UV coordinates are preserved exactly. No per-instance asset variants, inaccessible interiors or individually modelled tiles are introduced.

| Existing shared module | Roof | Views |
| --- | --- | --- |
| `townhouse` | Front/rear gables, ridge along depth | [Front](../artifacts/v061_city_architecture_townhouse_front.png), [rear](../artifacts/v061_city_architecture_townhouse_rear.png), [above](../artifacts/v061_city_architecture_townhouse_above.png) |
| `narrow_house` | Front/rear gables, ridge along depth | [Front](../artifacts/v061_city_architecture_narrow_house_front.png), [rear](../artifacts/v061_city_architecture_narrow_house_rear.png), [above](../artifacts/v061_city_architecture_narrow_house_above.png) |
| `wide_house` | Hipped ends, ridge along width | [Front](../artifacts/v061_city_architecture_wide_house_front.png), [rear](../artifacts/v061_city_architecture_wide_house_rear.png), [above](../artifacts/v061_city_architecture_wide_house_above.png) |
| `merchant_house` | Side gables, ridge along width | [Front](../artifacts/v061_city_architecture_merchant_house_front.png), [rear](../artifacts/v061_city_architecture_merchant_house_rear.png), [above](../artifacts/v061_city_architecture_merchant_house_above.png) |
| `corner_house` | Hipped ends, ridge along depth | [Front](../artifacts/v061_city_architecture_corner_house_front.png), [rear](../artifacts/v061_city_architecture_corner_house_rear.png), [above](../artifacts/v061_city_architecture_corner_house_above.png) |
| `harbour_house` | Side gables, ridge along width | [Front](../artifacts/v061_city_architecture_harbour_house_front.png), [rear](../artifacts/v061_city_architecture_harbour_house_rear.png), [above](../artifacts/v061_city_architecture_harbour_house_above.png) |

Each roof has sloped top and underside faces, 18 cm vertical thickness, closed perimeter edges and a 1.8-2.1 m rise. Eaves sit into the wall tops, preventing a daylight slit. Gabled modules have solid 18 cm plaster triangular caps; hipped modules close naturally on all four slopes. Front/rear eaves project 22 cm; the shared left/right sides stop at the party-wall plane. The [touching-house capture](../artifacts/v061_city_architecture_adjacent_roofs.png) shows the seam. All 117 existing house instances continue sharing the same six meshes and terracotta materials/textures. Existing simple wall collision proxies are unchanged.

`architectural_links.blend/.glb` retains all twelve named groups and the existing roof upper profiles. Roof undersides and perimeter thickness close the sheets; 885 short, closed plaster return prisms fill the gaps beneath the raised profiles. Separate vertex fans prevent four shell faces meeting along one edge at clipped point junctions. The original wall/footing bottoms receive caps; sub-millimetre clipped base slivers are welded and remaining bottom loops closed. Gable prisms remain separate closed volumes during this repair. Runtime material/theme code is unchanged.

## Local garden-to-avenue entrance

Only these eight existing house instances move, without rotation/model replacement:

- `Avenue_Left_00`, `_01`, `_02`: +2 m X, eastward.
- `Avenue_Right_00`, `_01`, `_02`: -2 m X, westward.
- `AvenueEntryWest_House01`, `AvenueEntryWest_House02`: -2 m X.

The existing `AvenueEntryWest` and `AvenueEntryEast` connector groups move -2 m and +2 m X respectively in their master. Their saved native collision transforms follow those translations. The first avenue houses already use the corner module. All other house placements and ten other group placements remain unchanged; no house is removed or added. The source manifest records the precise positions and setback metadata.

At route offset 1105, the former pinch changes from 5.030/4.770 m centre-to-facade distances to **7.023/6.765 m**, approximately **13.79 m total** instead of 9.80 m. Across the 1070-1140 entrance sector, 36 stations and three lane positions keep at least **5.181 m centre-to-facade clearance** and **7.158 m kart-to-camera distance**, with the kart in front of the camera. The sweep covers the full existing 10 m garden-road approach. It does not claim every point of the wider avenue has 13.79 m clearance.

Review [the former pinch before](../artifacts/v061_city_architecture_before_entry_1105.png), [after](../artifacts/v061_city_architecture_entry_1105.png), [turn-in](../artifacts/v061_city_architecture_entry_1095.png) and [overhead assembly](../artifacts/v061_city_architecture_entry_overview.png). Coverage rays for the two translated frontages follow their actual saved positions; the original street/coast/garden reach limits and all other continuity checks remain unchanged. New independent road/camera clearance assertions prevent a frontage test from accepting a blocked entrance.

## Frozen features and files

The [28-file baseline](../tests/fixtures/city_architecture_frozen.json) and source audit prove byte identity of all City route/width/layout/survey/structural resources, track scene, project metadata, kart scripts, camera script, fountain master/export and all three road/stair/terrain masters/exports. Overall layout, elevations, alternate routes, fountain, docks, garden paving, surface behaviour, checkpoints and water recovery are unchanged. Root `Ground` remains at identity. The six native house wrapper scenes and their collision dimensions are unchanged.

Changed production files are the seven architecture masters/exports, `assets/environment/city_square/manifest.json` and `scenes/environment/city_square/environment.tscn`. Test changes add source/freeze auditing, saved-instance/collision/clearance regressions and capture tooling; `tests/run_tests.gd` includes the new suite. The native lap fixture accepts an optional report prefix so later evidence need not overwrite earlier captures. Documentation updates are in CHANGELOG, README, VERSIONING, validation and the cumulative checklist; roadmap scope remains unchanged.

## Verification and performance

- Complete Godot suite: **1,460 checks, zero failures**, including the previous 1,417 and 43 architecture assertions.
- Read-only Blender/source audit: **120 checks, zero failures**. Checks include closed roof/core/gable topology, sloping undersides, shell volume/thickness, party-wall roof extents, unchanged original facades and frozen file hashes. [Audit](../artifacts/v061_city_architecture_audit.json), [source construction details](../artifacts/v061_city_architecture_sources.json).
- Actual native 1920x1080 application lap: **74.817 s**, zero recovery and zero sampled camera obstructions across 4,670 physics samples. [Report](../artifacts/v061_city_architecture_native_lap.json).
- Seven physical AI racers, Challenging, three laps, items enabled, seed 42: all finish, zero recoveries/DNFs; 31 item uses. [Race report](../artifacts/v061_city_architecture_ai_race_2_7_3_all_ai_items.json).
- Four stair flights still pass uphill/downhill, standstill/restart and reverse tests with zero airborne frames; garden off-road crossings, both dock edges, race launch and all earlier presentation/handling/item regressions pass.
- Godot headless editor import and actual native editor opening pass. [Editor report](../artifacts/v061_city_architecture_editor.json). Known Windows root-certificate-store warnings remain; final game/script validation has no other errors.

Matched native benchmark: 1920x1080, VSync off, uncapped rendering, seven racers, items/seed 42, Challenging, 360 warm-up and 720 measured physics ticks. Hardware: RTX 3070 Ti Laptop GPU / Ryzen 7 6800H. Compare the **City result** (`results[1]`) in each report; the Figure-8 result in each is a same-process reference, not the preceding City version.

| City sample | Before architecture | After architecture |
| --- | ---: | ---: |
| Average FPS | 76.33 | 73.72 |
| Mean frame | 13.10 ms | 13.57 ms |
| P95 / P99 frame | 19.33 / 67.91 ms | 28.23 / 61.32 ms |
| Mean rendered primitives | 286,239 | 350,755 |
| Mean draw calls | 1,313.54 | 1,392.50 |
| Nodes / collision shapes | 2,023 / 186 | 2,023 / 186 |

[Before report](../artifacts/v061_city_architecture_before_performance.json), [after report](../artifacts/v061_city_architecture_after_performance.json). Closed surfaces have a measured geometry/draw cost; this sample averages 3.4% fewer FPS. Average performance remains above 60 here, but existing spikes remain outside the 16.67 ms target. A single short run cannot distinguish all device/load variation or establish a sustained minimum. No smoothing, physics or road reduction conceals that limitation.

## Editing and repeatable checks

Continue editing the existing masters and native scene. Do not rerun initial site/route builders or remove their authored-refinement guards. `tools/correct_city_roofs.py` and `tools/setback_city_entry.py` document the one-time source edits and refuse duplicate application. Their resume/repair options are maintenance tools, not normal asset regeneration. `tools/apply_city_architecture.gd` synchronizes the source manifest and existing link colliders; use `-- --refresh-collision` only after an intentional architecture export/import. It does not rebuild paving, stairs or terrain collision.

After source edits: explicitly export GLB, import with Godot, refresh the affected saved collision, run the following checks and inspect **F5 -> City Square**. The environment scene alone is an authoring assembly, not a standalone race.

```text
blender --factory-startup --disable-autoexec --background --python tests/audit_city_architecture.py
godot --headless --editor --path . --import
godot --headless --path . --fixed-fps 60 --script tests/run_tests.gd
godot --path . --script tests/capture_city_architecture.gd
godot --path . --script tests/validate_city_square_lap.gd -- --report-prefix=v061_city_architecture
godot --headless --path . --fixed-fps 60 --script tests/run_ai_race.gd -- --circuit=delfino_square_ds --difficulty=challenging --laps=3 --items --item-seed=42 --report-prefix=v061_city_architecture
godot --path . --script tests/benchmark_city_square.gd -- --report-prefix=v061_city_architecture_after_performance
```

Run native performance checks without competing test processes. Local logs are `.godot/city_architecture_*.log`. Earlier diagnostic failures were corrected before the final passing source and runtime suites: clipped vertex fans/base seams and entrance rays aimed beyond a translated end cap. No current test failures remain.

Manual criteria **245-254** are appended to the [cumulative checklist](testing/ACCEPTANCE_CHECKLIST.md). Artist approval of all seams/lighting, human high-speed traffic tests, sustained target-PC performance and an exported build remain pending. Plain closed rear walls and existing terrain/footing appearance are retained intentionally with the approved facades. No decoration, road/gameplay redesign, staging, commits, pushes, tags or GitHub operations.
