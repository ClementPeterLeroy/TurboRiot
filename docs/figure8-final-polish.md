# Circuit 8 — final branding and two speed pads

2026-11-26. The developer approved the stadium/environment reconstruction and artistic direction, then requested only these two improvements. **Version remains 0.6.1-dev, Unreleased.** This approval is not a release or a reconstruction of individual manual/device test results.

## Official arch artwork

`references/brand` contains one candidate, `logo_overhead.png`. Its byte-identical runtime copy is `assets/brand/turbo_riot_logo.png`: 1920 × 819 RGBA with transparency. Original source SHA-256 and runtime SHA-256 both equal `2e248ca86eb58fc27596fd556199e1ef78bad1f04254f679195bf97997a584fe`. The source was not modified.

Removed only the old `GantryBrand` font object from the gantry's Blender source and GLB, and removed its generation instruction from the authoring recipe. The native gantry now instances `scenes/branding/gantry_logo.tscn`. It shares one textured QuadMesh/material between opposite outward-facing panels, preserving color with unlit white modulation, original UVs and alpha transparency. Dimensions **3.84 × 1.638 m** preserve the artwork ratio and center it inside the unchanged **22 × 1.8 m** beam. The mark cannot span that whole wide beam without stretching or extending beyond it. No supplementary branding text was added; existing light bank and decorative timing equipment remain.

[Front, normal chase camera](../artifacts/v061_final_polish_arch_front.png) · [Reverse face, normal chase camera](../artifacts/v061_final_polish_arch_back.png)

Both images were inspected: no mirrored wordmark, rectangular image background, stretching or clipping. The original supports, header, bracing, lamps and architectural materials remain.

## Two functional pads

`scenes/environment/figure8_stadium/speed_pads.tscn` contains two editable instances of `scenes/figure8_speed_pad.tscn`, retained by the existing circuit loader as authored track children. They do not introduce a second reference-track feature generator or another movement system.

| Pad | Route offset | Placement |
| --- | ---: | --- |
| BridgeApproach | 278 m | Centered on the gently curving/straight rising approach, about 56 m before the upper crossing crest |
| CornerExit | 614 m | After the northeast sweeping corner, on the long return into the finish straight |

The 6.4 × 5.2 m artwork lies 1.5 cm above the road, with its full orientation aligned to the local road tangent. The pad has no solid collider; the existing 0.9 m-high Area3D detects karts without producing a bump. Cyan/ivory chevrons, dark backing, gold corner accents and a low constant emission provide an original, readable skin. Both new textures use mipmaps for distance filtering. There is no animated material or new particle loop. Visuals are supplied through a new optional `BoostPad.visual_scene` property; existing pads retain exactly their previous default appearance and tuning.

Both use the existing directional boost, surface and screen-space feedback systems: **1.25× strength**, **1.0 s duration**, **5 m/s initial impulse**, **2 s cooldown** and the existing occupancy latch. The ordinary 22 m/s cap becomes 27.5 m/s while this pad boost is active; existing strongest-wins interaction retains stronger mushroom/mini-turbo effects without additive stacking. Steering and drift are not locked. The pad itself never adds vertical velocity. An occupied pad cannot repeatedly activate, and resetting while already occupying it remains latched. Teleporting onto a different pad is a new entry, subject to its reset cooldown.

[Approach pad](../artifacts/v061_final_polish_pad_approach.png) · [Corner-exit pad](../artifacts/v061_final_polish_pad_exit.png)

Edit placements in the native SpeedPads scene. The `route_offset` metadata records their authoring locations and tests assert alignment against the authoritative curve; moving the pad requires updating that metadata. The circuit curve itself is unchanged.

## Validation

- **1,183 checks, zero failures:** retained 1,154 plus 29 branding/pad contracts. Tests cover exact artwork hash, aspect, centering, outward orientation/alpha, absent old text, exact pad count/alignment/tuning, physical trigger crossings, one entry impulse, speed bounds, expiry, occupied/reset latching and a fresh AI-driven lap activating both pads. Grounded human-input crossings remain below 27.75 m/s and produce zero airborne frames.
- Seven-racer, three-lap, seed-42 item race: all finish, **zero recoveries/DNF**, 34 pickups / 33 uses. [Race report](../artifacts/v061_final_polish_ai_race_2_7_3_all_ai_items.json). The separate [AI crossing trace](../artifacts/v061_final_polish_pad_ai.json) records six racers entering the bridge pad and all seven entering the exit pad; accepted activation is independently asserted by the permanent real-AI integration test.
- Native 1080p lap: **33.283 s**, zero recoveries, no kart-to-camera obstruction in **2,178 physics samples**. [Report](../artifacts/v061_final_polish_native_lap.json). Existing road/underpass, handling, camera, item and race regressions remain enabled.
- [Preservation report](../artifacts/v061_final_polish_preservation.json): every previously approved model/module file remains byte-identical except the gantry source/export/wrapper. The track scene only gains the SpeedPads scene reference/instance; curve/width/elevation/geometry tests still pass. No shared kart or camera code changed.
- Headless import/runtime and performance evidence are in [validation](validation.md). Engine logs remain under ignored `.godot/final_polish_*.log`.

The isolated 1080p comparison measures 118.91 FPS with new pads/logo disabled and 134.80 FPS enabled; P99 is 17.02 / 15.20 ms. This is not an optimization claim: boosts alter view timing, and the removed old wordmark is absent in both cases. Use `tests/benchmark_figure8_polish.gd` without fixed-FPS mode for the same comparison. A short run does not establish sustained minimum performance.

Reproduce the review screenshots with `godot --path . --script tests/capture_figure8_polish.gd`; launch the application and select Figure-8 for manual driving. Manual criteria **203–207** extend the complete checklist. Imported branding is the only intentional alpha material inside stadium architecture; the general structural-material regression still requires all other stadium materials to remain opaque.

## Exact file scope for this pass

Modified existing files:

- `assets/environment/figure8_stadium/sources/start_gantry.blend`, `assets/environment/figure8_stadium/start_gantry.glb`: remove the old wordmark only.
- `scenes/environment/figure8_stadium/start_gantry.tscn`: attach the official logo scene.
- `scenes/tracks/figure_8.tscn`: add the two-pad scene instance.
- `scripts/track/boost_pad.gd`: optional visual scene; detection/boost logic unchanged.
- `tools/build_figure8_stadium.py`, `tools/assemble_figure8_stadium.py`: preserve the branding change on intentional authoring rebuilds.
- `tests/figure8_stadium_tests.gd`, `tests/run_tests.gd`: narrowly allow official artwork alpha and register new tests.
- `CHANGELOG.md`, `README.md`, `ROADMAP.md`, `VERSIONING.md`, `docs/roadmap.md`, `docs/testing-grounds.md`, `docs/figure8-stadium.md`, `docs/validation.md`, `docs/testing/ACCEPTANCE_CHECKLIST.md`: current status, approval provenance, evidence and cumulative checks.

New files:

- `assets/brand/turbo_riot_logo.png`, its Godot import settings, `assets/brand/README.md`.
- `assets/gameplay/circuit8_speed_pad.svg` and its Godot import settings.
- `scenes/branding/gantry_logo.tscn`, `scenes/figure8_speed_pad.tscn`, `scenes/figure8_speed_pad_visual.tscn`, `scenes/environment/figure8_stadium/speed_pads.tscn`.
- `tests/figure8_polish_tests.gd`, `tests/capture_figure8_polish.gd`, `tests/benchmark_figure8_polish.gd` and generated script UID companions.
- This guide and `artifacts/v061_final_polish_*` screenshots/JSON evidence.

The earlier uncommitted reconstruction files and owner's banana edit remain intact. No Git mutations, GitHub operations, new environment design or version advancement. The logo remains small relative to the very wide beam to honor the supplied aspect ratio; no panel enlargement was authorized. Artistic feedback, hand-driven pad feel, sustained performance and exported-build checks remain developer acceptance items.
