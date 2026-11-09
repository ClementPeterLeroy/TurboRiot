# v0.3.0 development patch — persistent visual oscillation, second investigation

**Unreleased; developer acceptance pending.** The developer confirmed the first contact correction did not eliminate the original high-speed visual symptom. The shoulder fix is retained; stable body Y is not visual acceptance. No version advance or roadmap change.

- Read-only Git history compared v0.2.0/v0.2.1/v0.3.0/v0.3.1. The new cosmetic script and camera obstruction changes were inspected. A/B isolation reproduced camera/render timing oscillation with cosmetic pitch essentially zero; raw physics-target follow already existed in v0.2.0, so the exact reason for the developer's v0.3.0 regression remains subject to manual confirmation.
- Final complete `tests/run_tests.gd`: **519 checks, 0 failures**, exit 0, Godot **4.7.2.stable.official.ed1daf0bf**, Windows. The prior 491 controller/race/runoff/handling/corrective/contact assertions remain. Added **28 presentation assertions** cover render-rate/pacing-invariant follow, interpolation ownership, physics-safe A/B modes, fixed orientation, shared render projection, reset, optional CSV and debug HUD.
- Native renderer probe: **12 corrected mode/rate scenarios, 0 failures**. At 79.2 km/h on the long upper straight, Normal-mode projected screen-Y range is **0.307 px at 60 FPS**, **0.211 px at 120.2 FPS**, and **0.218 px at 299.6 FPS uncapped**. Historical committed-camera comparison gives **0.232 / 3.332 / 6.465 px**, respectively (uncapped historical rate 325.6 FPS). All samples stay grounded; the presentation measurement is separate from body Y.
- Actual saved-frame marker centroid varies by **3 px before** and **0 px across eight sampled corrected frames**. Pixel capture is outside the timed rate window because GPU readback changes pacing. Timed samples use `frame_post_draw`, after camera/visual updates. Optional pads/ramp are removed only from this fixed-speed probe scene; production driving physics and features are unchanged.
- Final editor import and configured main startup (`--headless --path . --quit-after 240`) both exit 0 without script/scene/physics errors. Rendered handling capture passes, reporting real drift activity (charge 1.0167 s), `mini_turbo` on release and ramp airborne state true; handling review images refreshed. The pre-existing Windows root-certificate-store warning remains.

Implementation: explicit render interpolation in `project.godot` (version untouched), shared-pose/moving-target follow in ChaseCamera, render-only cosmetic interpolation ownership in KartVisuals, scene-local PresentationDebug and HUD integration. New presentation tests, native capture helper and historical camera fixture accompany documentation updates and pending manual checks **46–49**. The earlier kart-controller/ramp shoulder correction is unchanged by this second investigation.

Use **F3** for telemetry, **F4** for A/B/C/D, **F6** for optional CSV and **F7** for temporary 60/120/uncapped rendering. **A — Normal** is the acceptance mode. Detailed evidence, controls, measurements, fixture limitations and historical attribution are in [presentation-investigation.md](presentation-investigation.md). The exact developer-visible symptom on their hardware remains unaccepted until manually confirmed, even with the improved transform and rendered-pixel evidence. No staging, commits, pushes, tags or GitHub actions.

---

# Historical v0.3.0 development patch — vertical-contact validation (2026-11-09)

**Unreleased, manual acceptance pending; project version remains `0.3.0-dev`.** This further correction stays within v0.3.0. The existing v0.3.1 documentation history below is preserved. No roadmap/version advance or Git actions.

- Final full `tests/run_tests.gd`: **491 checks, 0 failures**, exit 0, Godot **4.7.2.stable.official.ed1daf0bf**, Windows. All 464 previous assertions remain, including real ramp takeoff/upward momentum/landing, drifting, pads, race progression, recovery and camera tests. The new suite adds 27 quantitative vertical-contact assertions.
- Four 240-tick flat-floor scenarios (idle, acceleration/braking, steering and drifting) have **zero airborne frames**. Maximum body-height range is **0.00006187 m** (under 0.062 mm); maximum camera-height range is **0.00022888 m**, without changing camera smoothing or cosmetic animation. Both sides' actual source-road exit/re-entry crossings retain contact on every sampled tick.
- Diagnosis was performed before controller changes. An identical 6,000-tick source-circuit probe changes from **56 airborne frames before** to **0 after**. The permanent shoulder assertions were additionally exercised against a temporary subclass restoring the pre-fix movement equations: two re-entry regressions fail as expected (seven airborne frames each, 8 checks/2 failures). The corrected controller passes them unchanged. No production file was reverted for that comparison.
- Final editor import (`--headless --path . --editor --import --quit`) and main startup (`--headless --path . --quit-after 240`) both exit 0 without script/scene/physics errors. The existing Windows root-certificate-store warning remains.
- Rendered handling capture exits 0 and reports active drift with 1.0167 s charge, `mini_turbo` on release and real ramp airborne state true. Review images in `artifacts/handling_*.png` were refreshed. This is scripted validation, not manual acceptance.

Root cause, temporary debug channels, collision review, exact measurements and limitations are recorded in [vertical-stability.md](vertical-stability.md). Implementation changes are limited to ordinary ground movement/takeoff selection in `scripts/kart/kart_controller.gd` and a generated launch-surface marker in `scripts/track/ramp.gd`. Tests add `tests/vertical_stability_tests.gd` and extend the runner; README, changelog, architecture and acceptance documents are updated. Nine pending manual checks **37–45** are appended; previous checks/history are retained.

The reproduced cause is false takeoff at shoulder joins; straight asphalt was already stable before the change. The developer should confirm the original visible symptom on their hardware and rerun the cumulative manual checklist. No collider dimensions/margins, gravity/snap constants, road geometry, artificial suspension or camera smoothing changes conceal the underlying contact behavior. Different devices/frame rates and exhaustive possible driving lines remain unverified.

---

# Historical v0.3.1 — Corrective Patch validation (2026-11-09)

**Unreleased, pending developer acceptance**, following **v0.3.0-dev — Arcade Handling**. The corrective work is now documented as v0.3.1 at the developer’s request; tests below ran with project/HUD identity `0.3.0-dev` and Windows resource version `0.3.0.0`. This documentation relabeling does not rerun tests or change build metadata. Roadmap milestones and accepted v0.2.0 history are preserved. Manual checks 1–26 remain preserved and checks 27–36 are appended in [the cumulative checklist](testing/ACCEPTANCE_CHECKLIST.md). No current manual pass is claimed.

## Actual results

- Before this correction: **266 checks, 0 failures**. Final complete `tests/run_tests.gd`: **464 checks, 0 failures**, exit 0, Godot **4.7.2.stable.official.ed1daf0bf**, Windows. The new corrective suite alone passed **198 checks, 0 failures**.
- Editor import (`--headless --path . --editor --import --quit`) and configured main startup (`--headless --path . --quit-after 240`) both exited 0 without script, scene or physics errors. The existing Windows sandbox root-certificate-store warning remains; it did not prevent validation.
- Geometry checks cover traced landmarks, closed finite road, upward triangle winding after widening, shared block/collider positions, exact configurable colour groups and deterministic resource rebuilding. Existing runoff driving now uses the actual infield opening and physical fence bounds.
- Every gate accepts representative road/runoff lines on both sides, including 85% of each asymmetric extent; backwards crossings and finite-edge violations fail. Continuous movement fixtures complete three ordered laps with sand crossings and a final grass finish. Isolated distant gate crossings cannot fabricate progress. Original ordering, reverse-finish, reset/recovery, timing and lifecycle scenarios remain.
- Real Area3D entries activate and propel in pad-forward direction for forward, reverse and wrong-heading approaches. Scenarios check bounded displacement/yaw, reset cleanup and nondirectional mini-turbos. Existing latch/cooldown/overlap/expiry, drift, surface, ramp, recovery and camera regressions pass. Pad occupancy tests explicitly hold the kart on the Area while verifying the latch, since propulsion now moves it out naturally.
- Generated trunks share a lightweight inscribed cylinder. Ray queries and actual kart movement verify trunk obstruction and clear passage beside the trunk under non-solid foliage.

## Rendered inspection

`tests/capture_corrective_preview.gd` exited 0 on the Compatibility renderer with NVIDIA RTX 3070 Ti Laptop GPU and saved [the corrected overhead](../artifacts/corrective_layout.png). The image was directly inspected: stepped outer frame, T-shaped infield, two access gaps, widened road and continuous grouped colours. Its separate gate probe accepted all three sampled lines at each of twelve gates (36/36). Reference-shape agreement remains subject to developer comparison, particularly corner proportions.

`tests/capture_handling_preview.gd` exited 0, reporting active drift with 1.0167 seconds of charge, `mini_turbo` after release and real ramp airborne state true. It refreshed drift, mini-turbo, pad, ramp, airborne and landing review images. These scripted scenes are not a human-driven race or manual camera/feel acceptance.

## Files and limits

Implementation is in `scenes/track.tscn`; the new `resources/barrier_run.gd` and outer/infield fence resources; TrackBuilder, BoostPad and TrackFeatures; CheckpointGate/RaceManager; KartConfig, KartController/BoostController/KartRecovery; and EnvironmentBuilder. Tests add `corrective_tests.gd` and `capture_corrective_preview.gd`, extend the runner and adapt race/runoff/handling fixtures and the race capture helper. README, changelog, architecture, controls, reference authoring and cumulative/historical acceptance documents describe current behavior.

Human reference comparison, exhaustive possible off-road racing lines, driving feel, real controller hardware, complete manual regressions and packaged Windows export remain pending. Gate sector/travel guards are course-specific safeguards, not comprehensive anti-cheat; arbitrary replacement layouts need authoring review and coverage tests. Camera obstruction remains a ray; tight-corner clipping/shadow aliasing may need tuning. No staging, commits, pushes, tags, releases, remote changes or GitHub actions were performed.

---

# Historical full v0.3.0-dev validation — Arcade Handling (2026-11-09)

This full handling patch is **Unreleased and pending developer acceptance**. Prior v0.2.0 acceptance is preserved, but no current-version manual gameplay/feel/controller retest is claimed. The canonical checklist contains the supplied exact regression checks 1–10 and new manual checks 11–26 at [testing/ACCEPTANCE_CHECKLIST.md](testing/ACCEPTANCE_CHECKLIST.md).

## Audit and automated results

The [pre-implementation audit](v0.3.0-audit.md) records the existing architecture, all three directly inspected references, and the baseline **203 checks, 0 failures**. The already-implemented runoff geometry preceded surface physics.

Final `tests/run_tests.gd`: **266 checks, 0 failures**, exit 0, with Godot **4.7.2.stable.official.ed1daf0bf**, Windows. Existing controller/race/runoff assertions remain; runoff traversal duration increases to account for the new intended surface penalties. Added checks include:

- Surface resource values, calculated acceleration/sustainable caps, gradual overspeed removal, debounce, smoothing and asphalt restoration.
- Drift activation/rejection, lateral activity requirements, countersteering, all three charge thresholds, valid release and low-speed/air/wall/invalid-release cancellation.
- Boost activation/countdown, strongest-wins rejection/refresh, explicit replacement, expiry and unchanged base config.
- Side-specific/wrapped barrier sections, actual collider absence in the authored opening, opposite-side collision and outer perimeter containment.
- Real scene ray/region detection of asphalt, sand, grass and boost pads; actual kart drift/countersteer; pad entry and occupancy/reset retrigger prevention.
- Physical air behavior retaining horizontal speed despite throttle/steering, ramp contact along the incline, tangent-based launch, safe landing and finite camera positions.
- Recovery/restart clearing drift/charge/boost, race progression preservation, upright/world-bound recovery and repeatable pad/ramp generation without duplicates.

Final editor import/script registration and configured main scene startup (`--headless --path . --quit-after 240`) both completed with **exit 0**, without script/scene/physics errors. New scenes/resources are loaded through the main scene, feature preloads and kart/surface configuration. The known sandbox certificate-store message remains the only engine error emitted on those final successful runs. The child process uses project-local `.godot/sandbox_appdata` for APPDATA, without changing system settings.

## Rendered inspection

`tests/capture_handling_preview.gd` completed with exit 0 on the **NVIDIA GeForce RTX 3070 Ti Laptop GPU / OpenGL 3.3 Compatibility renderer**. Actual rendered 1280×720 captures in `artifacts/handling_*.png` were inspected for drift, mini-turbo, boost pad, airborne state, landing, ramp, circuit layout and perimeter. This is scripted scene inspection, not a human playtest or race record. The race clock is held for reproducible captures.

The scripted driving capture accumulated **1.0167 valid drift seconds**, released, and reported the real `mini_turbo` source. Pad feedback displayed the `boost_pad` source. Ramp capture showed airborne motion followed by grounded sand contact; the incline/launch assertions run separately in the physics suite. The original road/kerb outline remains recognizable, with two pads, the optional sand ramp, the intentional outside opening and independent perimeter. No supplied reference pixels are game assets.

## Remaining acceptance and limits

- Checks 1–26 and the retained runoff manual regressions are **pending** for this build. Human driving feel, real keyboard/controller hardware, complete human-driven races, target hardware variety and packaged Windows export are not verified by these automated scenarios.
- Surface regions target the current flat terrain; custom layered/banked worlds and tight/overlapping barrier edits need author review. Keep ramp inclines within the body floor-angle limit and adapt world/perimeter/recovery bounds together.
- Camera obstruction uses a ray, not a swept volume. Tight corners can still need camera tuning; small faceted blocks/ramp edges show some shadow-map aliasing.
- Timing still uses active physics ticks. No persistent records, AI, items/weapons, multiplayer, advanced menus, online services or realistic suspension were added.
- No staging, commits, pushes, tags, releases, remote changes or GitHub actions were performed by Codex.

---

# Historical v0.3.0-dev prerequisite validation — Barrier/runoff correction

The developer confirmed on 2026-11-08 that all ten v0.2.0 manual acceptance checks passed. That is the accepted regression baseline. The current correction remains **Unreleased, pending developer acceptance**; previous acceptance does not certify its new geometry. See [the cumulative manual checklist](acceptance.md).

Before modification, the existing **179 automated checks passed**. After the correction, `tests/run_tests.gd` reports **203 checks, 0 failures**, exit 0, in Godot 4.7.2 on Windows. All earlier race/controller checks remain. The narrow-wall regression now targets the retained narrow start section, rather than assuming the entire lap has kerb-side walls.

Final editor import and configured main-scene startup (`--headless --quit-after 240`) both completed with **exit 0**, without script/scene/physics errors. The pre-existing certificate-store warning remained.

`tests/runoff_tests.gd` adds independent left/right and section-specific clearance checks, closed/finite outer geometry, configured paths clear of asphalt, consistent block lengths, box-collider positions matching CPU visual transforms, resource-edit rebuilding without duplicate nodes, scenery clearance and runoff gate rejection. Actual CharacterBody3D driving crosses both kerbs into sand/grass, stops at the outer barriers and returns to asphalt without recovery. The original 12 cm asphalt edge initially prevented re-entry; collidable sloped shoulders fix that tested failure. Handling/grip/speed calculations are unchanged.

Godot's headless dummy renderer does not retain MultiMesh GPU transforms, so headless alignment checks compare the CPU transforms actually supplied to each batch with the collider positions. Actual rendered geometry was inspected separately with the Compatibility renderer on the NVIDIA RTX 3070 Ti Laptop GPU.

Rendered correction captures are `artifacts/runoff_*.png` (use `tests/capture_race_preview.gd -- --runoff`). The overhead and normal driving view were inspected: road shape/kerbs are retained, boundaries flare only in selected sections, narrow containment remains elsewhere, and visible sand/grass aprons are accessible. Results captures remain synthetic race crossings, not new manual acceptance. All new V03-R criteria remain pending developer review.

No surface-specific physics, drift/boost or handling tuning was introduced. Arbitrary profile edits still require author inspection for nearby-road intersections and tight/overlapping contours. Profiles are editable at runtime/editor and intentionally do not auto-repair invalid layouts. Checkpoints remain road-wide.

The same pre-existing sandbox certificate-store warning was emitted; it did not prevent tests or rendering. Child-process APPDATA was redirected within `.godot/sandbox_appdata` as before. No Git mutations or GitHub actions were performed by Codex.

---

# Historical v0.2.0-dev validation — Race Foundations

The following records the original implementation validation. The developer later confirmed all ten manual checks passed, as recorded above; its original pending-review wording is historical.

Validated on 2026-11-08 with Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer. This is an **Unreleased development patch pending developer approval**, not an accepted v0.2.0 release.

## Audit and automated checks

Before modification, all **58 baseline checks passed**. The [audit](v0.2.0-audit.md) records the existing architecture, missing root lifecycle documents, actual reference locations and direct inspection of all three images.

After implementation, `tests/run_tests.gd` reports **179 checks, 0 failures**, exit 0. The runner includes the original controller/geometry/integration checks, explicitly entering RACING for driving checks, and the new `tests/race_tests.gd` suite. New checks cover:

- READY/countdown locks, 3/2/1/GO, repeated start, restart during countdown and configurable lap count.
- Active-only clocks, first/current/last/best/final times, frozen finished timing, reset clocks and millisecond formatting.
- Ordered gates, skipped/repeated entries, initial finish rejection, backwards checkpoints and backwards finish, bounded width/height, transformed planes and high-speed sweeps.
- Exactly three laps and correct final results through the real scene's gate processing.
- Latest-checkpoint manual/fall recovery, residual velocity clearing, cooldown, completed-lap/progress/timing preservation, camera snapping and crossing-baseline resampling.
- A real grounded wall jam triggering exactly one recovery, using an accelerated detector threshold for the test rather than waiting the production five seconds.
- Results/restart/return-to-ready buttons, debug checkpoint visibility and track rebuilding without stale gate references.
- Shared barrier mesh across four colour batches, instance counts and box-only barrier collision.

The integration tests use actual CharacterBody3D motion for acceleration, reverse, static collision and wall recovery. Gate race-completion tests feed known directed segments through the scene's real checkpoint detector. They are automated scenarios, not human-driven races or physical keyboard/gamepad tests.

## Rendering and scene loading

Final editor import/script registration completed with **exit 0**, without script/scene parse errors. Configured main-scene startup with `--headless --path . --quit-after 240` also completed with **exit 0**, without script/scene/physics errors. The pre-existing certificate-store warning was the only engine error message emitted by those final runs.

`tests/capture_race_preview.gd` rendered successfully on **NVIDIA GeForce RTX 3070 Ti Laptop GPU / OpenGL 3.3**. Captured and inspected images under `artifacts/` include READY, 3 countdown, GO, driving HUD, results, 1024×576 results, overhead route/infield and a barrier close-up. Standard captures are 1280×720. The results were generated with synthetic timed gate crossings for UI inspection, not obtained by manual driving. The screenshots exposed a telemetry/panel overlap, fixed by hiding normal telemetry during READY/results and using a separate darker card style.

The overhead confirms the preserved circuit centerline with a reference-shaped grass footprint; the close-up confirms original faceted X-face red/blue/yellow/green barrier blocks. These are visual observations, not a driving-feel or full-route collision certification.

## Remaining review and environment limits

- A developer must drive all three laps, test a physical gamepad and exercise R near gates/finish. Keyboard/gamepad device hardware, human handling feel and packaged Windows export remain unverified.
- Timing uses active physics delta and is quantized to a physics tick; no persistent records or wall-clock compensation is provided.
- Tight/self-intersecting replacement curves, grass footprint changes and unsupported external teleports require author care; see architecture and changelog limitations.
- The validation commands redirect child-process APPDATA to `.godot/sandbox_appdata` to avoid restricted normal user-directory writes. Godot prints the existing certificate-store warning in this environment; it did not prevent tests, scene import or rendering. The game performs no network requests.
- No staging, commits, pushes, tags, releases or GitHub actions were performed by Codex for this patch.

---

# Historical v0.1.0 validation

Validated on 2026-11-08 using Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer. The rendered preview run used an NVIDIA GeForce RTX 3070 Ti Laptop GPU / OpenGL 3.3.

## Automated results

- Editor import and script-class registration: **exit 0**, no script or scene parse errors in the final import.
- `tests/run_tests.gd`: **58 checks, 0 failures**, exit 0.
- Configured main scene startup with `--headless --path . --quit-after 120`: **exit 0**, no script/scene/physics errors.
- Rendered `tests/capture_preview.gd`: **exit 0**, captured gameplay and overhead views for inspection.

The checks cover clamping/nonfinite inputs and preservation of analogue values; acceleration, braking, reverse transitions, pedal priority and coasting; forward/reverse caps and exponential damping at 30/60/144 Hz; stationary/forward/reverse steering signs; closed curve and road seams; finite vertices, valid indices, consistent width/elevation, nondegenerate triangles and clockwise upward-facing collision geometry; road collider generation and deterministic replacement of generated nodes; actual main-scene loading, asphalt grounding, idle stability, input registration, world displacement under acceleration, forward/reverse speed bounds, reverse braking, reset velocity/transform, camera reset and static barrier response.

The integration test drives a real CharacterBody3D through the real PlayerInput provider using `Input.action_press/release`. It is not a manual playtest or hardware input test. The loop waits for physics frames; the mathematical multi-rate tests exercise the shared pure dynamics functions.

## Rendered inspection

`artifacts/first_drive.png` shows the actual starting camera, HUD, kart, road, checkered line, barriers, gantry and environment. `artifacts/circuit_overview.png` shows the closed reference-inspired circuit and scenery. Both were captured from Godot's rendered viewport and visually inspected. Road bend handles were adjusted to remove narrow offset folds, and the road collision winding was corrected after an integration test exposed grounding on the sand below the road. Regression checks now require asphalt-height grounding and the correct face winding.

## Environment note

The restricted execution environment prevented writes to the normal roaming AppData directory. Validation commands redirected the child process's `APPDATA` into `.godot/sandbox_appdata` within this project. This temporary environment change was local to the validation command, not a project setting or system change.

Godot also printed `Failed to read the root certificate store` in the sandbox. It did not prevent import, scene loading, physics tests or rendering. The game makes no network requests. Normal interactive editor launch outside this sandbox has not been checked.

## Limits and review work

- **Manual driving feel and physical keyboard/gamepad hardware have not been tested.** Check responsiveness, trigger mapping, camera readability and corner speeds in the editor.
- The circuit is an adapted centerline reconstruction, not an exact trace of every road edge or infield barrier. Scenery uses the supplied palette with simple original primitives.
- The builder assumes a flat, nonintersecting curve with adequate bend radii. It does not automatically repair invalid user edits, crossing roads or overlapping offset edges. Width-only edits require an Environment rebuild to refresh scenery clearance.
- No camera obstacle avoidance, suspension, off-road penalty, lap validation, race results, audio or Windows exported executable is included/tested. Race foundations belong to v0.2.0.
- Matching Windows export templates must be installed before using the supplied export preset. Other Godot versions and GPUs have not been exercised.
