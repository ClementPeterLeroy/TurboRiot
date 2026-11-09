# Changelog

## Unreleased — v0.3.0: Arcade Handling

Full handling development patch, pending developer acceptance. Metadata remains `0.3.0-dev`; this is not an accepted/released v0.3.0 build. The geometry correction was implemented and its 203 checks passed before adding surface/drift/boost/jump physics.

### Added

- SurfaceConfig resources for asphalt, grass, sand and boost pads; tagged physical ground plus procedural surface-region queries; debounced, exponentially smoothed handling multipliers and gradual excess-speed removal.
- Normalized drift commands on Shift/LB, grounded/speed/steering activation, reduced grip and steering response, countersteering, activity-based three-tier mini-turbo charge and valid-release-only rewards.
- Temporary BoostController with configurable strongest-wins/replace policy, expiry, smooth cap restoration and no mutation of base KartConfig.
- Reusable editor-visible cyan directional BoostPad scene, grounded Area activation, per-kart entry latch/cooldown and two source-curve-positioned pads.
- Reusable configurable amber ramp scene, placed in the wide outside sand of the long left straight. Ramp tangent movement supplies launch momentum; airborne movement retains inertia with reduced yaw authority, gravity and stable landing.
- Wheel pivots/steering/spin, body lean/pitch, procedural tyre dust/smoke, coloured charge feedback, boost exhaust, normal HUD charge indicator and expanded hidden debug information.
- Additional tuning for surfaces, drift, turbo tiers, boost policy, air steering, landing and probe/snap behavior. Original base speed/acceleration/braking/coasting/steering/gravity values are retained.
- BarrierSection resources with side selection, enabled/disabled intervals and optional clearance override; one outside opening on the upper diagonal and a faceted playable perimeter. Recovery has independent world bounds and upright checks.
- Exact cumulative manual checklist at `docs/testing/ACCEPTANCE_CHECKLIST.md`, preserving previously accepted 1–10 and adding pending 11–26 without claiming a new manual retest.
- Handling unit/integration tests for surface penalties/transitions, drift validity/countersteer/charge/release/interruption, boost overlap/expiry, real pad entry, ramp takeoff/landing, air restrictions, cleanup and barrier openings/perimeter.
- Independent editable left/right clearance Curve resources for segment-specific physical barrier placement along the closed circuit. Selected straights have sand/grass runoff; start and inner tight bends retain narrow containment.
- Separate closed outer-boundary polylines, with blocks spaced along their own arc length and box colliders at the same visible block positions.
- Sloped sand shoulders joining asphalt to the existing lower sand floor, allowing road re-entry without recovery.
- Decorative tree placement now respects each side's outer runoff envelope with a margin instead of populating the newly accessible aprons.
- Automated runoff checks covering side/segment variation, closed paths, asphalt clearance, block spacing, collider/visual source alignment, profile edits and actual kart exit/re-entry through sand and grass.
- A durable manual acceptance/regression document, preserving the v0.2.0 baseline and adding the current correction criteria and an append-only policy for future patches.

### Changed

- KartController composes surface, drift and boost models. Its grounded motion follows floor tangents and air movement no longer manufactures speed from throttle. Recovery, restart, race finish and pre-GO locks clear temporary states.
- Camera retains its chase architecture with a terrain obstruction ray and height floor for jump/landing follow.
- Runoff drive-test durations account for the new speed penalties while preserving wall/access/re-entry assertions.
- Coloured barriers no longer universally follow kerbs at a fixed distance. Road width, saved centerline, kerbs, checkpoints and handling parameters are preserved.
- Barrier collider segments now follow individual visual block endpoints, including transitions, so no kerb-side collision wall is left in widened areas.
- Updated milestone/version metadata, README, architecture and testing policy for v0.3.0 development.

### Fixed

- Grounded ramp motion presses into the floor normal so an ascending tangent does not prematurely detach the kart before the launch edge.
- Recovery/restart/finish no longer leave temporary drift charge, boost or launch motion; pad reset guards prevent immediate boost farming while remaining on a pad.
- Surface/boost cap reductions remove excess speed gradually rather than snapping velocity when a multiplier changes.

### Known limitations

- The new runoff correction still needs developer manual acceptance. Automated/visual validation does not carry forward manual acceptance to new geometry.
- Profile edits must avoid intersecting neighboring roads or creating tight/overlapping outer contours; arbitrary edits are not automatically repaired.
- Checkpoints remain road-wide: crossing them through runoff does not count, and recovery remains at the latest valid road checkpoint.
- Human driving feel, real controller hardware, manual checks 1–26 and packaged Windows export remain unverified for this new build. Automated/visual checks are reported separately.
- Surface regions assume the current flat sand/grass terrain; banked or layered original circuits need authoring review. Grass is a tagged polygonal region over the continuous sand support collider, avoiding a new collision step.
- The ramp is an optional test feature in runoff, not a route shortcut. Checkpoints remain road-wide. Keep authored ramp inclines below the body's floor-angle limit.
- Camera obstruction uses a ray rather than a swept camera volume; very tight geometry/corner clipping still needs manual review. Small barrier shadows may show aliasing.

## v0.2.0 — Race Foundations — Developer-accepted baseline

On 2026-11-08 the developer confirmed all ten manual acceptance checks passed. This records acceptance, not a Git tag, publication or release action. The following entries describe the actual earlier patch. Its automated/rendered results remain historical records.

### Added

- RaceManager orchestration and a deterministic RaceSession model with explicit READY, COUNTDOWN, RACING and FINISHED states.
- Three-second 3/2/1/GO countdown, pre-GO/post-finish driving lock and configurable default three-lap race length.
- Reusable directed checkpoint planes, 12 gates generated from the saved circuit, swept bounded crossing detection, ordered progression and finish validation.
- Total/current/last/best/final times, per-lap results, Restart Race, Return to Ready and Exit buttons.
- Enter/Space/Pad A to start; F5/Pad X to restart. R/Pad Y now recovers without clearing race progress or timing.
- KartRecovery with latest-validated recovery transforms, camera synchronization, configurable fall threshold, cooldown and conservative sustained-wall-jam recovery.
- Race tests for invalid order, repeated entries, reversed crossings, timing/state transitions, three-lap completion, restart, recovery and UI orchestration.
- Root ROADMAP.md, CHANGELOG.md and VERSIONING.md, previously absent. The prior milestone list is preserved.

### Changed

- Preserved the reference-based centerline and its corner sequence/width; moved the spawn 4 m behind the start/finish plane and added grid marks.
- Replaced rectangular barrier visuals with a reusable faceted X-face mesh, four shared colour batches and separate simple colliders.
- Neutral grey asphalt, an editable reference-shaped grass infield, sand, rounded polygonal trees and hills. Existing reference files remain private/ignored.
- Environment rebuilding now follows track geometry changes, including width changes, and coalesces queued rebuild requests.
- Existing physics tests now explicitly enter RACING before testing movement. The underlying handling defaults are unchanged.
- Version metadata and development HUD updated for the current milestone; Windows numeric version fields use `0.2.0.0`.

### Fixed

- Recovery teleports reset the checkpoint sweep baseline instead of creating crossings across the map.
- Repeated start/restart uses one countdown value rather than overlapping timers/coroutines.
- READY/results panels no longer overlap normal race telemetry.

### Known limitations

- The developer subsequently confirmed all ten manual acceptance checks passed. The exact checklist, absent at that review, was supplied in the full v0.3.0 brief and is now stored in the canonical checklist. Original device details are still not recorded; automation does not establish packaged Windows export validation.
- Timing uses active physics ticks, with finish/checkpoint times quantized to one tick; no sub-tick or real-time wall-clock timing.
- Swept gates assume continuous kart motion except through the supported reset/recovery API. Arbitrary external transform changes must also resample the baseline.
- No persistent records, penalties, pause/menu system, camera obstacle avoidance, off-road speed changes or network racing.
- Wall-jam recovery intentionally triggers only under sustained throttle, near-zero speed, ground and wall contact, without braking/steering; it is not a general stuck detector.
- Very tight/self-intersecting source curves still require author correction. The reference grass footprint must be edited separately for replacement layouts.
- Godot reports a certificate-store warning in the restricted validation environment; it did not block the checks.
- Small faceted blocks can show shadow-map aliasing at some camera angles; target-hardware lighting polish remains for developer review.

## v0.1.0 — Existing baseline

First Drive: CharacterBody3D kart, normalized keyboard/gamepad provider, KartConfig, chase camera, procedural reference circuit, primitive scenery, basic HUD and 58 automated checks. This entry records the pre-patch baseline rather than asserting release acceptance.
