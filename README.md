# Turbo Riot — v0.3.0-dev — Arcade Handling + v0.3.1 Corrective Patch

A Godot 4 single-player time-trial prototype for Windows, using GDScript and original low-poly geometry. The developer accepted all ten v0.2.0 manual checks. **v0.3.0-dev — Arcade Handling and v0.3.1 — Corrective Patch are unreleased and pending developer acceptance.** It includes surfaces, drifting, mini-turbos, pads and jumps, plus the v0.3.1 corrective patch for reference geometry, runoff gates, directional propulsion and tree trunks. No plugins, downloaded game art, global singletons, AI, weapons/items, multiplayer, persistent records or realistic suspension.

The documentation identifies the corrective work as **v0.3.1**. Existing project/HUD metadata still reads `0.3.0-dev` and Windows export metadata `0.3.0.0`; this documentation pass does not change build identifiers or publish a release. See [versioning](VERSIONING.md).

## Open and play

1. In Godot's Project Manager choose **Import** and select `project.godot` in this folder.
2. Open `scenes/main.tscn`. Allow the initial script scan to finish.
3. Press **F5** in the editor to play. The main scene is already configured.
4. On READY, click **Start Race** or press **Enter / Space / Pad A**. Drive after 3, 2, 1, GO.
5. Complete the checkpoints in order and cross the finish forward for each of three laps. Results include final time, individual laps and best lap.

The current project configuration and validation use Godot **4.7.2 stable**, Windows and the Compatibility renderer. Other Godot 4.x versions have not been validated. No .NET build is needed.

W/Up accelerates; S/Down brakes then reverses; A/D or Left/Right steers. **R / Pad Y recovers** at the latest validated checkpoint without stopping the clock. **F5 / Pad X restarts the entire race**, clearing timing/progress and starting a fresh countdown. F3 toggles debug information and checkpoint planes; Esc exits. Gamepads use the left stick and triggers. See [controls](docs/controls.md).

**Left Shift / Pad LB:** hold while steering above 8.5 m/s on the ground to drift. Countersteer freely. Valid steering plus lateral slip charges tiers at 1.0 / 2.0 / 3.5 seconds of activity. Release while still valid to get a mini-turbo. Air, low speed, recovery and severe impacts cancel charge without a reward. The charge gauge and coloured tyre smoke show progress; exhaust and HUD show an active boost.

Sand and grass reduce acceleration, sustainable speed and grip smoothly; asphalt restores normal handling. Cyan arrow pads provide temporary boosts on the long left straight and upper diagonal (55% / 81% of the lap). The amber ramp is optional in the **outside sand of the long left straight**, around 56% of the lap; align with it and approach at speed. It does not replace a required route section. Air yaw has reduced authority, throttle does not add mid-air momentum, and gravity returns the kart to the terrain.

## Included

- CharacterBody3D arcade controller: acceleration, brake/reverse, coast, speed-sensitive steering, lateral grip, gravity, ground snapping, static collisions, and safe reset.
- Separate normalized input provider, reusable handling resource and kart scene.
- Independent smooth chase camera with immediate reset snapping.
- Editor-visible procedural circuit: saved Curve3D, asphalt mesh/collision, red-and-white kerbs, coloured collidable barriers and a checkered start line.
- Seeded low-poly trees, reference-shaped grass infield, sandy ground, distant green hills, sky and lighting.
- Speed in km/h, movement direction, controls, and optional debug HUD.
- READY/countdown/racing/finished lifecycle, ordered directional checkpoint validation, configurable three-lap time trial and active-race-only timing.
- Recovery from falls or a sustained grounded wall jam; cooldown and teleport-safe progression. Restart Race, Return to Ready and Exit result buttons.
- Shared faceted red/blue/yellow/green barrier mesh, grid markings, reference-shaped grass infield, rounded trees and low-poly hills.
- Reference-traced stepped outer fence and T-shaped infield fence, with two explicit grass access openings and collidable shoulders for road re-entry.
- Configurable barrier colour groups (five red, five blue, five yellow, five green), continuous through corners; shared trunk collision without solid foliage.
- SurfaceConfig resources, smoothed terrain response, DriftController and BoostController models, reusable BoostPad/Ramp scenes and visible steering/lean/dust/exhaust feedback.

The initial layout follows the supplied Mario Circuit 1 overhead as an educational reference. Its diagonal straight, left straight, central return and lower hairpin are represented with editable Bézier geometry; the corrective pass uses 0.18 m per overhead pixel and a 14.4 m asphalt ribbon. Physical fences follow independently traced polylines, rather than road offsets. Curved corners remain an approximation; manual reference comparison is pending. The supplied perspective reference guides the grey road, sandy ground, green scenery, coloured barriers and start gantry, with original primitive geometry and materials throughout.

## Project structure

```text
project.godot                 Engine configuration and main scene
scenes/                      Main, kart, camera, HUD and editable track
resources/                   KartConfig, surface resources and boundary data
scripts/input/               Device input and normalized driving commands
scripts/kart/                Dynamics, controller, surfaces, drift/boost and visuals
scripts/race/                RaceSession, RaceManager and bounded directed gates
scripts/camera/              Chase camera
scripts/track/               Track builder, BoostPad, Ramp and feature placement
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

The same resource exposes drift activation/grip/steering, ordered positive charge thresholds, mini-turbo strengths/durations, boost policy/acceleration, air steering, gravity/landing, surface smoothing/debounce and probe/snap distance. Terrain multipliers live in `resources/surfaces/`. Defaults: grass acceleration/speed/grip = 0.75/0.75/0.70; sand = 0.60/0.60/0.55. Generic mini-turbo policy defaults to **strongest wins**: weaker requests are ignored; equal/stronger requests retain the longer remaining duration. The alternative **replace** policy overwrites strength and duration. Directional pad entries always redirect toward the pad arrow; strongest-wins preserves any stronger cap/longer timer while applying that direction. Nothing permanently changes the base config.

Open `scenes/track.tscn`, select the Path3D and use the path editing tools to move points and handles. The last point duplicates the first to close the circuit; keep their positions and handles identical. Edit road width and sampling in the Inspector. Details and constraints are in [architecture](docs/architecture.md).

The Track's **Checkpoint Count** includes finish gate zero (default 12), placed at authored arc fractions after corners; clearing Checkpoint Fractions restores uniform spacing. **Show Checkpoints** previews them in the editor; F3 shows them in play. The main scene's RaceManager exposes **Lap Count**. Recovery/fall/cooldown/stuck settings are on `Kart/Recovery`. The Environment's **Infield Outline** is a separate editable footprint; adjust it when replacing the reference circuit.

Road edges/kerbs are independent from physical barriers. Track's **Barrier Runs** references `resources/circuit_01_outer_fence.tres` and `circuit_01_infield_fence.tres`. Edit their local-space points and normalized fence-arc gaps; colour group size defaults to five. The circuit disables the optional generic rectangular perimeter because the stepped reference fence already contains it. Clearance Curve/BarrierSection authoring remains available as a fallback when no authored runs are assigned.

The early right straight and long left straight connect to grass through intentional infield fence openings. Cross both kerbs, traverse sand/grass, and rejoin using the shoulders. Gates cover the bounded corridor owned by their route sector, including legal runoff. They retain order, crossing direction, adjacent-route exclusion and minimum interval travel checks. Recovery stays at the latest validated road checkpoint. See [reference geometry and corridor authoring](docs/track-reference.md).

TrackFeatures places pads at 55%/81% and the ramp at 56% of source-curve length. Pads accelerate toward their own forward axis even when approached in reverse; velocity and yaw change gradually during the default one-second redirect. Strength/duration/cooldown/redirect duration are editable. Ramp geometry rebuilds from width/length/height; its center sits 10.5 m outside the long left straight.

## Tests

From this directory, substituting your Godot executable:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 120
```

Import first on a fresh checkout so Godot registers global script classes. The test runner runs the existing physics suite plus `tests/race_tests.gd` and exits nonzero if a check fails. It tests real GDScript functions and running physics scenes. For optional rendered screenshots, run `godot --path . --script tests/capture_race_preview.gd`. This requires an actual display/graphics driver and saves `artifacts/race_*.png`. The results screenshot uses synthetic checkpoint crossings, not a manually driven record. The v0.1 preview helper remains available for baseline review.

The runner also includes `tests/runoff_tests.gd`, with real kart exits/rejoins on both sides, barrier geometry and legal runoff checkpoint registration. To capture separate correction previews use `godot --path . --script tests/capture_race_preview.gd -- --runoff`; output is `artifacts/runoff_*.png`.

`tests/handling_tests.gd` covers surface/drift/boost models plus real pad entry, airborne restrictions, ramp contact/launch/landing, cleanup and opening/perimeter collision. `godot --path . --script tests/capture_handling_preview.gd` drives scripted rendering scenarios and saves `artifacts/handling_*.png`. These are automated scene inspections, not a human playtest or accepted race record.

`tests/corrective_tests.gd` adds reference landmarks, grouped colour continuity, bounded gate coverage, continuous off-road laps, reverse/wrong-heading pad entries and real trunk/foliage collision checks. `godot --path . --script tests/capture_corrective_preview.gd` saves the overhead review to `artifacts/corrective_layout.png`.

See [validation](docs/validation.md) for actual results and limits, the [cumulative manual checklist](docs/testing/ACCEPTANCE_CHECKLIST.md) for checks 1–36, and the [handling audit](docs/v0.3.0-audit.md) for baseline/reference inspection. The [earlier runoff procedures](docs/acceptance.md) are retained. See [ROADMAP.md](ROADMAP.md), [CHANGELOG.md](CHANGELOG.md) and [VERSIONING.md](VERSIONING.md) for scope, actual changes and development status. Each patch must rerun the accepted baseline and append its own manual criteria; v0.3.0-dev handling and v0.3.1 corrective acceptance remain pending.

## Reference and distribution

The three supplied images are in `references/` for private educational review only. The brief's suggested `docs/references/circuit_01/` path is absent in this checkout; references were inspected at their actual location. `references/` is ignored by Git and Godot; no game resource loads its images. All game geometry/materials are original. The Windows export preset excludes documentation, tests, references and review artifacts. Install matching export templates before exporting; no exported executable is included or validated. This patch performs no Git mutations or GitHub actions.
