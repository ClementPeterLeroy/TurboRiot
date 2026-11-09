# Manual acceptance and regression baseline

**Current canonical checklist:** [docs/testing/ACCEPTANCE_CHECKLIST.md](testing/ACCEPTANCE_CHECKLIST.md), including the exact ten v0.2.0 criteria supplied in the full v0.3.0 brief and new checks 11–26. The earlier procedures below are preserved as history/regressions. V03-R02's correction-only "no off-road penalty" expectation is superseded by the full patch's surface tests; it is not a regression failure. No pending manual result has been silently accepted.

## Acceptance record and policy

- **v0.2.0:** Developer confirmed on 2026-11-08 that all ten manual acceptance checks passed, then confirmed to proceed. This is developer-reported acceptance, not a Codex manual test or publication.
- The original checklist wording was not stored in this checkout. The ten durable regression procedures below codify the accepted Race Foundations behavior for subsequent patches; they are not presented as a verbatim copy of an unavailable checklist.
- **v0.3.0 barrier/runoff correction:** Pending developer acceptance. The boxes below are intentionally unchecked for the current patch. Previous acceptance does not approve new geometry.
- For every subsequent patch, rerun V02-01 through V02-10 and all still-applicable later checks. Append a new section with stable IDs, steps and expected outcomes. Keep previous results/history; do not remove deferred checks or substitute automated results for manual ones. Record date, build, tester, devices and outcomes when reviewed. A patch is not released/accepted until the developer approves it.

## v0.2.0 durable baseline — rerun for the current patch

- [ ] **V02-01 Startup/readiness:** Open the configured main scene, run it, confirm READY, correct grid spawn and readable HUD. Kart throttle/steering cannot move it before GO.
- [ ] **V02-02 Countdown:** Start with Enter/Space or the Start Race button. See 3, 2, 1, GO once. Timing starts at GO. Repeated start input does not spawn/reset overlapping countdowns.
- [ ] **V02-03 Driving/input/camera:** Check acceleration, coast, brake/reverse and both steering directions with keyboard; exercise supported gamepad input when available. Confirm speed/direction and useful chase camera behavior. Record actual devices.
- [ ] **V02-04 Ordered progression:** Drive the proper route forward. Gates advance in order; skip a gate and verify the finish cannot award a lap.
- [ ] **V02-05 Crossing rejection:** Verify the initial start-line crossing is not a lap. Back across finish after a valid sequence; no lap. Remaining at/re-entering a gate cannot repeatedly increment progress.
- [ ] **V02-06 Timing/laps:** Complete three valid forward laps. Verify lap count, total/current/last/best times, per-lap results and a frozen final time. Exactly three laps finish the default race.
- [ ] **V02-07 Manual recovery:** Use R at several route positions and near the finish. Recover at the latest validated safe checkpoint, clear velocity, snap the camera and preserve valid progress/results. Active timing continues; no checkpoint is awarded by teleporting.
- [ ] **V02-08 Automatic recovery/cooldown:** Exercise a fall and a sustained grounded wall jam (or test-configured threshold). Recover once, oriented safely; cooldown prevents immediate repeated resets. Attempts to steer/brake should not satisfy the wall-jam detector.
- [ ] **V02-09 Restart/results controls:** Restart during countdown, racing and results. Grid position, checkpoints, laps and all clocks reset, with one fresh countdown. Return to Ready and Exit work without hidden race state.
- [ ] **V02-10 Editor/debug/rebuild:** Confirm the recognizable circuit, road/ground alignment, coloured barriers and readable HUD. Toggle F3 to inspect gates/debug. Reopen/rebuild scenes without duplicate nodes or stale race gates. Record target resolution/hardware and visible issues.

## v0.3.0 correction — new criteria, all pending

- [ ] **V03-R01 Accessible sand:** On the early right-hand straight (roughly 5.5–7.5% of centerline lap length), drive outward across the kerb into the wide sandy apron. Reach the outer blocks, then steer back onto asphalt without R or an invisible kerb-side wall.
- [ ] **V03-R02 Accessible grass:** At the same straight, cross the inside sand strip into the green infield; repeat on the long left straight (roughly 53–58%). Return to road safely. No off-road grip/speed penalty should be introduced by this patch.
- [ ] **V03-R03 Section-specific placement:** Inspect the full lap: start/finish and tight inner bends stay narrow; selected straights have wider aprons. Left/right boundaries differ. The asphalt corner sequence, width, kerbs and start line remain recognizable.
- [ ] **V03-R04 Outer collision:** Drive into blocks in wide, narrow and transition sections on both sides. Collision matches visible blocks, contains the kart and leaves no old invisible wall at the kerbs. Check transition ends for catching/gaps.
- [ ] **V03-R05 Road re-entry:** Cross both sand/road shoulders slowly and at speed in both directions. No raised-edge lock, fall-through or forced recovery; road/ground support remains aligned.
- [ ] **V03-R06 Profile authoring:** In a disposable scene/resource copy, change one left/right profile point; only the intended boundary changes smoothly. Kerbs/asphalt/checkpoints stay fixed. Both loops close at start/finish. Undo/reopen and verify no duplicated generated nodes.
- [ ] **V03-R07 Race integrity through runoff:** Bypass a checkpoint through runoff; it must not count, nor may a skipped gate/finish award a lap. Rejoin and complete the required ordered gates. R from runoff preserves the latest validated road checkpoint and the running clock.
- [ ] **V03-R08 Regression/identity review:** Pass the ten V02 regressions again, inspect the overhead and normal chase view, confirm coloured faceted blocks/grey road/sand/grass identity and `0.3.0-dev` development status. Approve this correction before any off-road surface physics patch.

## Subsequent patches

Before implementing surface physics, drifting/boost or further handling changes, append specific controls, expected behavior and acceptance criteria for that patch. Keep the runoff correction and V02 race checks as cumulative regressions. Record actual changes in CHANGELOG.md; keep future scope in ROADMAP.md. Git operations remain exclusively with the developer.
