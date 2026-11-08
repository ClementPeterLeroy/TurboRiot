# Turbo Riot — v0.1.0: First Drive

A Godot 4 arcade kart prototype for Windows, using GDScript and original low-poly primitives. No plugins, downloaded art, global singletons, AI, weapons, drifting, or multiplayer.

## Open and play

1. In Godot's Project Manager choose **Import** and select `project.godot` in this folder.
2. Open `scenes/main.tscn`. Allow the initial script scan to finish.
3. Press **F5** to play. The main scene is already configured.

Godot **4.3 or newer** is the intended baseline; actual validation used **4.7.2 stable**, Windows, and the Compatibility renderer. Earlier 4.x versions have not been tested. No .NET build is needed.

W/Up accelerates; S/Down brakes then reverses; A/D or Left/Right steers. R resets, F3 toggles debug information, Esc exits. Gamepads use the left stick and triggers. See [controls](docs/controls.md).

## Included

- CharacterBody3D arcade controller: acceleration, brake/reverse, coast, speed-sensitive steering, lateral grip, gravity, ground snapping, static collisions, and safe reset.
- Separate normalized input provider, reusable handling resource and kart scene.
- Independent smooth chase camera with immediate reset snapping.
- Editor-visible procedural circuit: saved Curve3D, asphalt mesh/collision, red-and-white kerbs, coloured collidable barriers and a checkered start line.
- Seeded low-poly trees, grass islands, sandy ground, distant green hills, sky and lighting.
- Speed in km/h, movement direction, controls, and optional debug HUD.

The initial layout follows the supplied Mario Circuit 1 overhead as an educational reference. Its diagonal straight, left straight, central return and lower hairpin are represented with editable Bézier geometry; dimensions and barrier positions are adapted for this prototype. This is not a pixel-accurate reproduction. The supplied perspective reference guides the grey road, sandy ground, green scenery, coloured barriers and start gantry, with original primitive geometry and materials throughout.

## Project structure

```text
project.godot                 Engine configuration and main scene
scenes/                      Main, kart, camera, HUD and editable track
resources/                   KartConfig script and default handling resource
scripts/input/               Device input and normalized driving commands
scripts/kart/                Pure dynamics calculations and body controller
scripts/camera/              Chase camera
scripts/track/               Reproducible editor/runtime track builder
scripts/world/               Primitive helpers and seeded environment
scripts/ui/                  HUD binding
scripts/main.gd              Spawn and application actions
tests/                       Headless tests and optional screenshot helper
docs/                        Architecture, controls, roadmap and validation
references/                  Supplied reference, excluded by .gdignore
artifacts/                   Rendered review images, excluded by .gdignore
```

## Change handling or circuit

Open `resources/default_kart.tres` in the Inspector to tune handling. Defaults are 22 m/s forward, 7 m/s reverse, 16 m/s² acceleration, 28 m/s² braking, 6 m/s² coast, 110°/s steering and 9 s⁻¹ lateral grip. Duplicate this resource and assign it on a kart for independent tuning.

Open `scenes/track.tscn`, select the Path3D and use the path editing tools to move points and handles. The last point duplicates the first to close the circuit; keep their positions and handles identical. Edit road width and sampling in the Inspector. Details and constraints are in [architecture](docs/architecture.md).

## Tests

From this directory, substituting your Godot executable:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 120
```

Import first on a fresh checkout so Godot registers global script classes. The test runner exits nonzero if a check fails. It tests real GDScript functions and a running physics scene; it does not substitute a second implementation in another language. For optional rendered screenshots, run `godot --path . --script tests/capture_preview.gd`. This requires an actual graphics/display driver and saves `artifacts/first_drive.png` and `artifacts/circuit_overview.png`.

See [validation](docs/validation.md) for actual results and limits. Lap validation and race results are deliberately deferred to v0.2.0. See the [roadmap](docs/roadmap.md).

## Reference and distribution

The supplied image is in `references/` for private educational review only. That directory has `.gdignore`; no game resource references it. All rendered game geometry/materials are authored primitives. The Windows export preset also excludes documentation, tests, references and review artifacts. Install Godot's matching export templates before exporting; no exported executable is included or validated.
