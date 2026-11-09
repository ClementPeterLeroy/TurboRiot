# v0.3.0 development patch — vertical-contact correction

> **Developer follow-up:** the original high-speed visual porpoising remained after this contact fix, even with `Ground true`. The shoulder fix is retained. This report establishes contact behavior only; see [the second presentation investigation](presentation-investigation.md) for camera/visual isolation, rendered-pixel evidence and pending acceptance.

Unreleased, pending developer acceptance. This correction stays within the existing `0.3.0-dev` project version. The documentation history for **v0.3.0-dev — Arcade Handling** and **v0.3.1 — Corrective Patch** remains preserved; no new patch number, roadmap milestone or release is introduced.

## Diagnosis before changes

Inspected KartController, SurfaceDetector, KartConfig, the kart collision/visual scene, KartVisuals, KartRamp, procedural road/shoulders/sand, recovery and ChaseCamera. Temporary probes logged physics-body global Y, vertical velocity, floor state/normal, ray ground distance, visual-child local Y/pitch and camera global Y. A 6,000-tick source-circuit trace included normal steering followed by drifting. Temporary scripts/CSV traces remain local under ignored `.godot/`; no diagnostic UI or per-frame product logging was added.

Straight flat asphalt did **not** reproduce a repeated bounce: the body settled near Y=0.41594, floor normal stayed (0,1,0), vertical velocity stayed zero and the Visual child's local Y stayed zero. The longer trace reproduced **56 airborne frames** at road/shoulder joins. One re-entry recorded an uphill normal near (-0.0423,0.9950,-0.0901), followed by loss of contact and an upward velocity around 0.805 m/s before returning to asphalt. The camera followed that body movement; it did not originate it.

The ordinary grounded branch manually projected motion onto a rising floor tangent and subtracted a small normal contact velocity. That could still leave a positive world-Y request at speed. Godot disables automatic snapping for rising velocity. At a shoulder crest the kart therefore detached despite adjoining support, and the generic takeoff branch reused the preceding measured upward displacement as airborne velocity. Repeated shoulder encounters could repeat this false takeoff. SurfaceDetector only queries metadata and blends horizontal handling multipliers; it does not move the body.

This identifies a reproduced false-takeoff mechanism. It does not establish that every possible visual symptom on the developer's hardware has been reproduced; manual confirmation is still required.

## Collision and visual review

- Asphalt triangle vertices remain flat at Y=0.04; the existing geometry suite checks winding, finite/nondegenerate triangles and source seams. Sand's support top is Y=-0.08, 12 cm below the road, with sloped 1.2 m shoulders joining those levels. This is deliberate support under the road, rather than two coincident floor faces.
- Kerbs/grid/start markings are noncollidable decoration. The kart's existing centered box is 1.25 × 0.75 × 2.1 m. No collider dimensions, safe margins, road triangles or collision layers were changed for this fix; the traces did not identify an excessive-margin or overlapping-floor geometry cause.
- KartVisuals changes child rotations for lean/pitch and wheel spin. Its root translation stays zero and it does not overwrite the physics-body transform. Automated tests verify that separation during idle, acceleration/braking, steering and real drifting.
- ChaseCamera already has one world-position interpolation and separate orientation interpolation, without vertical bob animation. Its response to the stable body is measured below. No extra vertical filter, height clamp or artificial suspension was introduced.

## Controller correction and jump preservation

Ordinary grounded movement now supplies horizontal velocity plus the **existing world-down contact speed**. `move_and_slide()` handles slope projection with automatic snapping available. Existing settings remain: snap length 0.4 m, `floor_constant_speed = true`, `floor_stop_on_slope = true`, default 45-degree `floor_max_angle`, gravity and collision margins. See [Godot's CharacterBody3D reference](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html#class-characterbody3d-property-floor-snap-length) for upward-motion snap exclusion and the distinction from `apply_floor_snap()`.

KartRamp tags its generated physical collider with `launch_ramp`, separately from its asphalt handling identity. Only actual walkable collision contact with that marked surface uses the prior rising-tangent motion and carries measured incline velocity into takeoff. Ordinary asphalt/sand joins cannot enter that takeoff path. Reset/locks still clear cached ground motion and temporary handling state.

The airborne branch retains inertia and gravity. It never calls `apply_floor_snap()` to pull a jump onto the ground. A broad unconditional manual snap would risk suppressing legitimate launches, so it was not added. The existing real ramp tests retain their upward-momentum, incline-contact, takeoff and safe-landing assertions; none was relaxed.

## Quantitative regressions

`tests/vertical_stability_tests.gd` adds **27 assertions** to the existing 464-check suite. It uses the real kart on a subdivided flat asphalt trimesh, then tests exits/rejoins across both shoulders of the actual source track. Each flat scenario samples 240 physics ticks after settling, with deterministic calls to the existing visual/camera update functions at 60 Hz.

| Scenario | Body Y range (m) | Body Y variance (m²) | Airborne frames | Camera Y range (m) |
| --- | ---: | ---: | ---: | ---: |
| Idle | 0 | 0 | 0 | 0.00009346 |
| Acceleration and braking | 0.00002971 | 3.56e-12 | 0 | 0.00022459 |
| Steering | 0.00000066 | below reported precision | 0 | 0.00022078 |
| Drift | 0.00006187 | 1.589e-11 | 0 | 0.00022888 |

Pass limits are 2 mm peak-to-peak body/camera height range, body variance below 1e-6 m², zero airborne frames, near-zero vertical velocity and unchanged child translation/physics transform during cosmetic updates. Steering and drifting use alternating inputs on the isolated flat fixture so leaving the finite source road cannot confuse a flat-floor measurement.

All four real source-track asphalt/sand transitions retain contact on every sampled tick and cross the boundary. The same shoulder assertions were also run against a temporary subclass restoring the original grounded/takeoff equations: each re-entry produced seven airborne frames, peaked near Y=0.47085 and failed its contact regression (8 checks, 2 failures, expected nonzero exit). The corrected controller passes those unchanged assertions. The final identical 6,000-tick circuit probe reports **zero airborne frames**, versus 56 before the fix.

A box/shoulder crest can have up to 2 cm solver clearance above the flat-road resting height; that test allowance does not permit airborne frames. Recovery and restart also pass. Permanent manual checks **37–45** are appended to [the cumulative checklist](testing/ACCEPTANCE_CHECKLIST.md), preserving checks 1–36 and their history.

The complete test and engine-validation results are recorded in [validation.md](validation.md). Real controller hardware, different rendering/physics frame rates and the developer's original visible symptom still require manual confirmation. No version metadata, roadmap, staging, commits, pushes, tags or GitHub actions were changed/performed.
