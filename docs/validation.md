# v0.2.0-dev validation — Race Foundations

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
