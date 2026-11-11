# v0.6.1-dev — Figure-8 false-wall correction

Unreleased, pending developer acceptance. This fixes the reported sudden stop while driving over the Figure-8 upper crossing, within the existing v0.6.1 patch.

## Reproduced cause

The kart's original sharp box underside caught internal edges in the inclined asphalt triangle collision. The engine reported both a normal floor contact and an opposing horizontal contact at essentially the same point. One reproduction on the rising approach recorded:

```text
Floor normal: (-0.068811, 0.994939, 0.073226)
Additional normal: (-0.695829, 0.0, 0.718208)
Collider for both: Track/Generated/Asphalt/Asphalt_col
Contact approximately: (-74.750, 3.361, 17.337)
Velocity after collision: (0, 0, 0)
```

Inspecting only `get_slide_collision(i).get_normal()` hid the second contact. The diagnostic/regression now inspects every contact inside each motion result. Godot's [4.7.2 CharacterBody3D implementation](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/scene/3d/physics/character_body_3d.cpp) classifies each contact and can cancel motion when it encounters opposing wall contacts. The measured horizontal normal explains the wall-like stop despite a valid floor contact.

Disabling the barrier blocks did not remove the reproduced stop. Extra slide iterations and changing slope flags also failed to eliminate the problem across scenarios. Experimental road proxies and a beveled convex kart collider were rejected: broader testing found remaining snags or regressions in spin stability and momentum contacts. Those experiments are removed from the implementation. The original road builder, Figure-8 scene/trace, surfaces and loading code were restored and verified against their pre-investigation file hashes.

## Implemented collision correction

`scenes/kart.tscn` now uses a static compound hull made from Godot's native primitives:

- `Collision`: a 1.25 × 0.375 × 2.1 m upper box, centered at local Y=0.1875. It retains the full body width/length and broad kart/wall contact surfaces.
- `RoadContact` and `RearRoadContact`: two spheres of radius 0.375 m, centered at local Z=−0.675 and +0.675, with local Y=0. Their rounded undersides pass over the road's internal edges.

The combined bounds remain exactly **1.25 × 0.75 × 2.1 m**, including the original lowest point Y=−0.375. Human and AI use the same scene. There is no per-frame collider switching, suspension simulation, upward impulse, ground-height clamp or camera filter. Controller/input/handling constants, gravity, floor snapping, ramp takeoff, surface physics, race rules and visual transforms are unchanged.

The actual Figure-8 road collision, elevation profile, original scene, bridge clearance, kerbs and independent barriers remain unchanged. No lower barriers are moved or removed. The corrected kart still collides with genuine walls and other racers.

## Regression evidence

`tests/crossing_collision_tests.gd` adds **52 assertions** to the retained 989-check suite: **1,041 checks, zero failures**. Measured traversals use real kart movement, the actual track collision and its barriers, without teleports or velocity restoration during the run. Three lateral lanes (center, −4.5 m, +4.5 m) are tested in each scenario:

| Scenario | Lowest horizontal velocity | Lowest measured horizontal motion | Airborne frames | False wall contacts |
| --- | ---: | ---: | ---: | ---: |
| Upper road, 79.2 km/h | 22.000 m/s | 21.821 m/s | 0 | 0 |
| Upper road, mushroom at 110.9 km/h | 30.800 m/s | 30.551 m/s | 0 | 0 |
| Upper road in the opposite direction | 22.000 m/s | 21.814 m/s | 0 | 0 |
| Lower road beneath the crossing | 22.000 m/s | 21.999 m/s | 0 | 0 |

The slight difference between horizontal velocity and measured motion on slopes reflects travel along the incline. Every traversal completes. Floor rays across three lanes at 30 positions also confirm the unchanged road collision remains within **3.35 mm** of the sampled visual road height. Asphalt/sand detection and combined collider bounds are checked separately.

The unchanged traversal assertions were also run with `--legacy-box`, which substitutes only the old box and disables the new lower contacts. That run fails **13 of 52 assertions** with zero-speed frames and opposing false wall normals, demonstrating that the regression detects the reported mechanism. The corrected hull passes. The tests also inspect all contacts rather than only the first normal in a motion result.

All earlier momentum, reciprocal-contact, wall, drift, surface, jump/ramp, recovery, restart, spin and presentation assertions remain enabled and pass. Measured flat spin body-height ranges are approximately **0.00000036 m** for shells and **0.00000030 m** for bananas. No existing tolerance was relaxed or assertion removed.

Commands:

```text
godot --headless --path . --fixed-fps 60 --script tests/run_tests.gd
godot --headless --path . --fixed-fps 60 --script tests/run_crossing_tests.gd
godot --headless --path . --fixed-fps 60 --script tests/run_crossing_tests.gd -- --legacy-box
```

The last command intentionally returns a failing exit code. Engine/race/native validation is recorded in [validation](validation.md). Detailed metrics are in `artifacts/v061_crossing_fix_validation.json`; local diagnostic logs remain ignored under `.godot/`.

## Developer confirmation

Permanent manual criteria **152–156** extend the [cumulative checklist](testing/ACCEPTANCE_CHECKLIST.md), preserving 1–151. Drive across the upper road in the center and both passing lanes, with normal acceleration and mushroom boosts. Check the lower underpass, actual barrier impacts, drifting, shell/banana spins, ramp behavior, recovery and restart on all circuits. Rounded underside contacts can feel different at very low obstacles; controller feel and contact polish still require developer acceptance. Automated runs do not establish that acceptance or cover every entry angle and device.

Open `scenes/kart.tscn` to inspect the upper box and the two spherical lower contacts individually. The mesh and its cosmetic child animations are unchanged. No version increment, staging, commits, pushes, tags, releases or GitHub actions are part of this correction.
## Subsequent performance validation

The later [racing-performance correction](circuit-performance.md) changes only flat-road collision and minimap rendering. Figure-8 retains its elevated triangle collider and this rounded kart hull. All crossing assertions remain passing in the current 1,062-check suite; the 1,041-check evidence above records this correction's original validation.

