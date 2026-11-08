# v0.1.0 validation

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
