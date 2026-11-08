# Turbo Riot — v0.2.0-dev: Race Foundations

A Godot 4 single-player time-trial prototype for Windows, using GDScript and original low-poly geometry. **Unreleased development patch, pending developer review.** No plugins, downloaded game art, global singletons, AI, weapons, drifting, multiplayer or persistent records.

## Open and play

1. In Godot's Project Manager choose **Import** and select `project.godot` in this folder.
2. Open `scenes/main.tscn`. Allow the initial script scan to finish.
3. Press **F5** in the editor to play. The main scene is already configured.
4. On READY, click **Start Race** or press **Enter / Space / Pad A**. Drive after 3, 2, 1, GO.
5. Complete the checkpoints in order and cross the finish forward for each of three laps. Results include final time, individual laps and best lap.

The current project configuration and validation use Godot **4.7.2 stable**, Windows and the Compatibility renderer. Other Godot 4.x versions have not been validated. No .NET build is needed.

W/Up accelerates; S/Down brakes then reverses; A/D or Left/Right steers. **R / Pad Y recovers** at the latest validated checkpoint without stopping the clock. **F5 / Pad X restarts the entire race**, clearing timing/progress and starting a fresh countdown. F3 toggles debug information and checkpoint planes; Esc exits. Gamepads use the left stick and triggers. See [controls](docs/controls.md).

## Included

- CharacterBody3D arcade controller: acceleration, brake/reverse, coast, speed-sensitive steering, lateral grip, gravity, ground snapping, static collisions, and safe reset.
- Separate normalized input provider, reusable handling resource and kart scene.
- Independent smooth chase camera with immediate reset snapping.
- Editor-visible procedural circuit: saved Curve3D, asphalt mesh/collision, red-and-white kerbs, coloured collidable barriers and a checkered start line.
- Seeded low-poly trees, grass islands, sandy ground, distant green hills, sky and lighting.
- Speed in km/h, movement direction, controls, and optional debug HUD.
- READY/countdown/racing/finished lifecycle, ordered directional checkpoint validation, configurable three-lap time trial and active-race-only timing.
- Recovery from falls or a sustained grounded wall jam; cooldown and teleport-safe progression. Restart Race, Return to Ready and Exit result buttons.
- Shared faceted red/blue/yellow/green barrier mesh, grid markings, reference-shaped grass infield, rounded trees and low-poly hills.

The initial layout follows the supplied Mario Circuit 1 overhead as an educational reference. Its diagonal straight, left straight, central return and lower hairpin are represented with editable Bézier geometry; dimensions and barrier positions are adapted for this prototype. This is not a pixel-accurate reproduction. The supplied perspective reference guides the grey road, sandy ground, green scenery, coloured barriers and start gantry, with original primitive geometry and materials throughout.

## Project structure

```text
project.godot                 Engine configuration and main scene
scenes/                      Main, kart, camera, HUD and editable track
resources/                   KartConfig script and default handling resource
scripts/input/               Device input and normalized driving commands
scripts/kart/                Pure dynamics calculations and body controller
scripts/race/                RaceSession, RaceManager and bounded directed gates
scripts/camera/              Chase camera
scripts/track/               Reproducible editor/runtime track builder
scripts/world/               Primitive helpers and seeded environment
scripts/ui/                  HUD binding
scripts/main.gd              Start/restart/recover/exit application actions
tests/                       Headless tests and optional screenshot helper
docs/                        Architecture, controls, validation and audit
ROADMAP.md                   Preserved milestones and current scope
CHANGELOG.md                 Actual additions/changes/fixes under Unreleased
VERSIONING.md                Development version and acceptance conventions
references/                  Supplied reference, excluded by .gdignore
artifacts/                   Rendered review images, excluded by .gdignore
```

## Change handling or circuit

Open `resources/default_kart.tres` in the Inspector to tune handling. Defaults are 22 m/s forward, 7 m/s reverse, 16 m/s² acceleration, 28 m/s² braking, 6 m/s² coast, 110°/s steering and 9 s⁻¹ lateral grip. Duplicate this resource and assign it on a kart for independent tuning.

Open `scenes/track.tscn`, select the Path3D and use the path editing tools to move points and handles. The last point duplicates the first to close the circuit; keep their positions and handles identical. Edit road width and sampling in the Inspector. Details and constraints are in [architecture](docs/architecture.md).

The Track's **Checkpoint Count** includes finish gate zero (default 12), distributed by curve arc length. **Show Checkpoints** previews them in the editor; F3 shows them in play. The main scene's RaceManager exposes **Lap Count**. Recovery/fall/cooldown/stuck settings are on `Kart/Recovery`. The Environment's **Infield Outline** is a separate editable footprint; adjust it when replacing the reference circuit.

## Tests

From this directory, substituting your Godot executable:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 120
```

Import first on a fresh checkout so Godot registers global script classes. The test runner runs the existing physics suite plus `tests/race_tests.gd` and exits nonzero if a check fails. It tests real GDScript functions and running physics scenes. For optional rendered screenshots, run `godot --path . --script tests/capture_race_preview.gd`. This requires an actual display/graphics driver and saves `artifacts/race_*.png`. The results screenshot uses synthetic checkpoint crossings, not a manually driven record. The v0.1 preview helper remains available for baseline review.

See [validation](docs/validation.md) for actual results and limits, and the [pre-implementation audit](docs/v0.2.0-audit.md) for baseline findings/reference inspection. See [ROADMAP.md](ROADMAP.md), [CHANGELOG.md](CHANGELOG.md) and [VERSIONING.md](VERSIONING.md) for milestone scope, actual changes and development status.

## Reference and distribution

The three supplied images are in `references/` for private educational review only. The brief's suggested `docs/references/circuit_01/` path is absent in this checkout; references were inspected at their actual location. `references/` is ignored by Git and Godot; no game resource loads its images. All game geometry/materials are original. The Windows export preset excludes documentation, tests, references and review artifacts. Install matching export templates before exporting; no exported executable is included or validated. This patch performs no Git mutations or GitHub actions.
