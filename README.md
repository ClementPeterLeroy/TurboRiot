# Turbo Riot - v0.6.1-dev - Circuit Selection & First Testing Grounds

A Godot 4 Windows arcade racer with a complete single-player application flow: main menu, Quick Race, Time Trial, pause, settings, sound and results. **v0.6.1 is Unreleased and pending developer acceptance.** Circuit selection includes the preserved reference circuit and **two new beta test circuits: Figure-8 Circuit and GCN Yoshi Circuit (DS)**. Both are playable greybox layouts **without finished environments or scenery**, intended as private educational testing grounds. This version also corrects racing FPS drops. See [circuit architecture, tracing and validation](docs/testing-grounds.md).

See [Playable Alpha play/configuration/architecture](docs/playable-alpha.md), [controls](docs/controls.md) and [validation](docs/validation.md). Earlier v0.4/v0.5 history and pending acceptance remain preserved. Only Mushroom (5A), Red Shell (5B), Green Shell (5C) and Banana (5D) are active in Quick Race; 5E remains reserved.

The Figure-8 upper-road stop is addressed by a rounded kart collision underside; see [diagnosis, fix and regressions](docs/figure-8-crossing-fix.md). This correction stays within v0.6.1-dev.

The racing-performance correction optimizes flat-road collision and caches minimap routes. Its controlled native benchmark measured Yoshi at 10.5 → 77.4 FPS; see [results, limitations and retesting](docs/circuit-performance.md). Stop and relaunch the game to initialize the updated generated scene.

## Open and play

1. In Godot's Project Manager choose **Import** and select `project.godot` in this folder.
2. Run **F5** to launch `scenes/app.tscn` and the main menu.
3. Choose **Quick Race** (0-6 AI, difficulty, laps, controls) or **Time Trial** (one human, no competitive items).
4. Select Choose Circuit, select a card and Start Race, then start from READY with Enter / Space / Pad A. Drive after 3, 2, 1, GO.
5. Use **Esc / Pad Start** for Pause, Settings, Restart or Main Menu. Results provide a fresh Restart and Main Menu.

Settings persist through Apply, including independent volume/mutes, VSync, UI scale, window size/fullscreen. Focus loss pauses rather than continuing the race. See [full procedures and limits](docs/playable-alpha.md).

The current project configuration and validation use Godot **4.7.2 stable**, Windows and the Compatibility renderer. Other Godot 4.x versions have not been validated. No .NET build is needed.

W/Up accelerates; S/Down brakes then reverses; A/D or Left/Right steers. **R / Pad Y recovers** at the latest validated checkpoint without stopping the clock. **F5 / Pad X restarts the entire race**, clearing timing/progress and starting a fresh countdown. F3 toggles debug information and checkpoint planes; Esc / Pad Start pauses. Gamepads use the left stick and triggers. See [controls](docs/controls.md).

**Left Shift / Pad LB:** hold while steering above 8.5 m/s on the ground to drift. Countersteer freely. Valid steering plus lateral slip charges tiers at 1.0 / 2.0 / 3.5 seconds of activity. Release while still valid to get a mini-turbo. Air, low speed, recovery and severe impacts cancel charge without a reward. The charge gauge and coloured tyre smoke show progress; exhaust and HUD show an active boost.

Sand and grass reduce acceleration, sustainable speed and grip smoothly; asphalt restores normal handling. Cyan arrow pads provide temporary boosts on the long left straight and upper diagonal (55% / 81% of the lap). The amber ramp is optional in the **outside sand of the long left straight**, around 56% of the lap; align with it and approach at speed. It does not replace a required route section. Air yaw has reduced authority, throttle does not add mid-air momentum, and gravity returns the kart to the terrain.

Use the Quick Race screen to configure opponents, difficulty, lap count and controls. Defaults retain 6 opponents / Challenging / 3 laps. The standalone authoring fixture `scenes/main.tscn` still exposes RaceManager properties and supports legacy CLI/testing; F6 on that raw scene retains its earlier direct-race shortcuts. **F3** shows AI telemetry and **F8** changes the selected AI. F5 in the focused running game restarts; editor F5 launches the application.

Collect a floating question-mark box, then press **Space / Pad B** to use the held item. Holding the button cannot consume subsequent pickups. Three rows of four boxes follow the blue-marked map; boxes respawn after five seconds. See [manual item tests](docs/power-up-mayhem.md).

The inherited [balancing correction](docs/power-up-balancing.md) adds mushroom-only off-road immunity, physical 360° shell / 540° banana spin-outs with smooth control recovery, and radial screen-edge feedback for mushrooms/pads. Its original development history is preserved; this application patch uses 0.6.0-dev. New acceptance checks 91–104 extend the retained 1–90; no release is claimed.

## Included

- Main menu, validated Quick Race/Time Trial setup, responsive keyboard/mouse/controller UI, pause and fresh-scene restart/results flow.
- ConfigFile settings, display/UI controls, independent audio buses and original synthesized placeholder music/engine/cues.

- Weighted one-slot inventories, four original item models/icons, homing/ricocheting shells, banana traps and 3 x 4 editor-visible loot boxes.
- Mass-based kart contact impulses and controllable one-entry boost pads.
- One human/six configurable AI competitors using the same kart scene/config, staggered coloured grid, cached pursuit and braking, stable passing targets and shared recovery.
- Live route-validated positions, independent per-racer clocks/checkpoints, persistent finish order and grace/timeout DNF.
- CharacterBody3D arcade controller: acceleration, brake/reverse, coast, speed-sensitive steering, lateral grip, gravity, ground snapping, static collisions, and safe reset.
- Separate normalized input provider, reusable handling resource and kart scene.
- Independent smooth chase camera with immediate reset snapping.
- Editor-visible procedural circuit: saved Curve3D, asphalt mesh/collision, red-and-white kerbs, coloured collidable barriers and a checkered start line.
- Seeded low-poly trees, reference-shaped grass infield, sandy ground, distant green hills, sky and lighting.
- Speed in km/h, movement direction, controls, and optional debug HUD.
- READY/countdown/racing/finished lifecycle, ordered directional checkpoint validation, configurable multi-kart three-lap race and active-race-only timing.
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
scripts/app/                 Application flow, session setup and settings
scripts/audio/               Buses, loops and synthesized cue library
scripts/input/               Device input and normalized driving commands
scripts/kart/                Dynamics, controller, surfaces, drift/boost and visuals
scripts/race/                Per-competitor state, field manager and directed gates
scripts/ai/                  Cached racing line and AI DrivingInput provider
scripts/items/               Inventory, catalog, models, actors, rows and feedback
scripts/camera/              Chase camera
scripts/track/               Track builder, BoostPad, Ramp and feature placement
scripts/world/               Primitive helpers and seeded environment
scripts/ui/                  HUD binding
scripts/main.gd              Managed race wrapper / standalone legacy actions
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

The same resource exposes drift activation/grip/steering, ordered positive charge thresholds, mini-turbo strengths/durations, boost policy/acceleration, air steering, gravity/landing, surface smoothing/debounce and probe/snap distance. Terrain multipliers live in `resources/surfaces/`. Defaults: grass acceleration/speed/grip = 0.75/0.75/0.70; sand = 0.60/0.60/0.55. Generic mini-turbo policy defaults to **strongest wins**: weaker requests are ignored; equal/stronger requests retain the longer remaining duration. The alternative **replace** policy overwrites strength and duration. Pad entries apply one arrow-aligned impulse, preserving stronger caps/longer timers. Steering, braking and drift remain available immediately. Mushroom boosts use the same non-additive cap policy. Nothing permanently changes the base config.

Open `scenes/track.tscn`, select the Path3D and use the path editing tools to move points and handles. The last point duplicates the first to close the circuit; keep their positions and handles identical. Edit road width and sampling in the Inspector. Details and constraints are in [architecture](docs/architecture.md).

The Track's **Checkpoint Count** includes finish gate zero (default 12), placed at authored arc fractions after corners; clearing Checkpoint Fractions restores uniform spacing. **Show Checkpoints** previews them in the editor; F3 shows them in play. The main scene's RaceManager exposes **Lap Count**. Recovery/fall/cooldown/stuck settings are on `Kart/Recovery`. The Environment's **Infield Outline** is a separate editable footprint; adjust it when replacing the reference circuit.

Road edges/kerbs are independent from physical barriers. Track's **Barrier Runs** references `resources/circuit_01_outer_fence.tres` and `circuit_01_infield_fence.tres`. Edit their local-space points and normalized fence-arc gaps; colour group size defaults to five. The circuit disables the optional generic rectangular perimeter because the stepped reference fence already contains it. Clearance Curve/BarrierSection authoring remains available as a fallback when no authored runs are assigned.

The early right straight and long left straight connect to grass through intentional infield fence openings. Cross both kerbs, traverse sand/grass, and rejoin using the shoulders. Gates cover the bounded corridor owned by their route sector, including legal runoff. They retain order, crossing direction, adjacent-route exclusion and minimum interval travel checks. Recovery stays at the latest validated road checkpoint. See [reference geometry and corridor authoring](docs/track-reference.md).

TrackFeatures places pads at 55%/81% and the ramp at 56% of source-curve length. Pads give one forward impulse even on reverse entry; they never take over yaw or continuously redirect movement. Strength/duration/cooldown/initial impulse are editable. Ramp geometry rebuilds from width/length/height; its center sits 10.5 m outside the long left straight.

The inherited v0.3.2 baseline retains the [vertical-contact correction](docs/vertical-stability.md): ordinary road/shoulder movement keeps automatic floor snapping available, while marked launch ramps retain genuine takeoff momentum.

The inherited [presentation correction and investigation](docs/presentation-investigation.md) retains **F4 modes, F6 CSV and F7 render cap**, shown with F3. Rerun **A Normal** at about 80 km/h as a v0.5.0 regression; stable body Y alone is insufficient.

## Tests

From this directory, substituting your Godot executable:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 120
```

Import first on a fresh checkout so Godot registers global script classes. The test runner runs all existing physics/race/runoff/handling/presentation suites plus `tests/competitor_tests.gd` and exits nonzero if a check fails. It tests real GDScript functions and running physics scenes. For optional rendered screenshots, run `godot --path . --script tests/capture_race_preview.gd`. This requires an actual display/graphics driver and saves `artifacts/race_*.png`. The results screenshot uses synthetic checkpoint crossings, not a manually driven record. The v0.1 preview helper remains available for baseline review.

The runner also includes `tests/runoff_tests.gd`, with real kart exits/rejoins on both sides, barrier geometry and legal runoff checkpoint registration. To capture separate correction previews use `godot --path . --script tests/capture_race_preview.gd -- --runoff`; output is `artifacts/runoff_*.png`.

`tests/handling_tests.gd` covers surface/drift/boost models plus real pad entry, airborne restrictions, ramp contact/launch/landing, cleanup and opening/perimeter collision. `godot --path . --script tests/capture_handling_preview.gd` drives scripted rendering scenarios and saves `artifacts/handling_*.png`. These are automated scene inspections, not a human playtest or accepted race record.

`tests/vertical_stability_tests.gd` measures body-height variance, contact flicker, cosmetic separation and camera stability on triangulated asphalt, plus actual source-track shoulder crossings.

`tests/corrective_tests.gd` adds reference landmarks, grouped colour continuity, bounded gate coverage, continuous off-road laps, reverse/wrong-heading pad entries and real trunk/foliage collision checks. `godot --path . --script tests/capture_corrective_preview.gd` saves the overhead review to `artifacts/corrective_layout.png`.

See [validation](docs/validation.md) for actual results and limits, the [cumulative manual checklist](docs/testing/ACCEPTANCE_CHECKLIST.md) for checks 1-161, and the [handling audit](docs/v0.3.0-audit.md) for baseline/reference inspection. The [earlier runoff procedures](docs/acceptance.md) are retained. See [ROADMAP.md](ROADMAP.md), [CHANGELOG.md](CHANGELOG.md) and [VERSIONING.md](VERSIONING.md) for scope, actual changes and development status. Each patch must rerun the accepted baseline and append its own manual criteria; v0.6.1 acceptance remains pending (earlier v0.4/v0.5 acceptance is not inferred); earlier history is retained.

For real physical AI-only validation, run `godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd`. Append `-- --difficulty=casual`, `-- --difficulty=challenging` or `-- --idle-human`; reports go to `artifacts/ai_race_*.json`. For an interactive AI-only game use `godot --path . -- --ai-only --auto-start`. The renderer preview is `tests/capture_competitor_preview.gd`; benchmark one/seven karts with `tests/benchmark_competitors.gd` **without** `--fixed-fps`. See [full instructions and limits](docs/racing-competitors.md).

## Reference and distribution

The three supplied images are in `references/` for private educational review only. The brief's suggested `docs/references/circuit_01/` path is absent in this checkout; references were inspected at their actual location. `references/` is ignored by Git and Godot; no game resource loads its images. All game geometry/materials are original. The Windows export preset excludes documentation, tests, references and review artifacts. Install matching export templates before exporting; no exported executable is included or validated. This patch performs no Git mutations or GitHub actions.

Run an item-enabled race with `godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd -- --items --laps=3`. Native model/row/HUD captures: `godot --path . --fixed-fps 60 --script tests/capture_items_preview.gd`. Performance: `godot --path . --script tests/benchmark_items.gd` (no fixed FPS). See [validation](docs/validation.md).
