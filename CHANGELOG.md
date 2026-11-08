# Changelog

## Unreleased — v0.2.0: Race Foundations

Developer acceptance pending. Project metadata is `0.2.0-dev`; no v0.2.0 release, tag or GitHub release is implied.

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

- Human driving feel, physical gamepads, a manual three-lap race and a packaged Windows export remain unverified.
- Timing uses active physics ticks, with finish/checkpoint times quantized to one tick; no sub-tick or real-time wall-clock timing.
- Swept gates assume continuous kart motion except through the supported reset/recovery API. Arbitrary external transform changes must also resample the baseline.
- No persistent records, penalties, pause/menu system, camera obstacle avoidance, off-road speed changes or network racing.
- Wall-jam recovery intentionally triggers only under sustained throttle, near-zero speed, ground and wall contact, without braking/steering; it is not a general stuck detector.
- Very tight/self-intersecting source curves still require author correction. The reference grass footprint must be edited separately for replacement layouts.
- Godot reports a certificate-store warning in the restricted validation environment; it did not block the checks.
- Small faceted blocks can show shadow-map aliasing at some camera angles; target-hardware lighting polish remains for developer review.

## v0.1.0 — Existing baseline

First Drive: CharacterBody3D kart, normalized keyboard/gamepad provider, KartConfig, chase camera, procedural reference circuit, primitive scenery, basic HUD and 58 automated checks. This entry records the pre-patch baseline rather than asserting release acceptance.
