# Circuit 8 — stadium environment and immersion

2026-11-26. **v0.6.1-dev, Unreleased; developer artistic/driving acceptance pending.** The developer approved continuing beyond the road study. This implements the requested bridge, stands, pit/control complex, safety/perimeter, materials/signage and validation stages. No road reconstruction, kart physics changes, version increment or Git mutations.

**Subsequent final-polish brief:** the developer approved this environment reconstruction and artistic direction. The [final polish](figure8-final-polish.md) changes only the gantry branding and adds two speed pads. Earlier measurements/screenshots below retain their historical pre-polish scope; individual manual/device checks and release acceptance are not inferred.

## What was built

**Bridge and terrain.** A surveyed continuous 18.1 m structural deck sits below the existing driving ribbon, with blue edge girders, four chamfered concrete piers on footings, pier caps and two ground-connected abutments. Grass banks support the long approaches; curved retaining toes meet the ground. The central opening spans the lower road rather than filling it with pillars. Sampled physical headroom is **6.738 m**. The deck, bank and support collision is separate from the original asphalt; every sampled driving lane still hits that original asphalt first.

**Stands.** Fifteen native instances of one curved module surround the two broad corners and the finish area. Each has nine rising concrete terraces, individual seat pans/backs in coordinated blue/orange/gold sections, a central stair aisle, a solid rear wall/parapet, columns, canopy ribs, partial roof and advertising bands. A small batched silhouette crowd occupies selected rows. The model is a closed architectural assembly, not an inclined seat-colored plane. Module spacing deliberately leaves access breaks; it is not a continuous roof.

**Pit complex.** Eight garage bays form one frontage, with segmented doors, framing, numbering, service access, tool cabinets, upper observation glazing, balcony railings and metal roof/parapets. A connected taller control tower has window bands, an observation cabin, crown and original race-control signs. The non-drivable service apron has marked work areas. A new braced start gantry supplies five modeled lamps, timing/lap board and Turbo Riot branding.

**Safety and enclosure.** Continuous curve-fitted safety plinths and three metal rail bands cover the existing physical barriers. Catch fencing uses regularly spaced posts and batched opaque grid geometry, avoiding layered transparency. The stadium perimeter follows an inflated circuit footprint, with 120 simple collision sections, varied heights, concrete/blue architecture, service-panel recesses, lintels, buttresses, ochre caps and original signs. Six shared floodlight masts form distant silhouettes. Turf islands and modest planted edging interrupt the infield; clear grass areas are intentional.

Colors and signage are original. Reference images under ignored `references/` informed composition only; they are not imported into runtime assets.

## Sources and Godot assembly

| Location | Purpose |
| --- | --- |
| `scenes/tracks/figure_8.tscn` | Existing authoritative road, now with one `EnvironmentArt` stadium instance |
| `scenes/environment/figure8_stadium/stadium.tscn` | Native assembly: Bridge, Terrain, Grandstands, Pits, Safety, Perimeter, Signage, Lighting |
| Same folder, six module scenes | Curved grandstand, garage bay, control tower, gantry, sponsor panel and lighting mast wrappers with shared models and appropriate simple masses |
| `assets/environment/figure8_stadium/sources/*.blend` | Ten editable model sources; `.gdignore` prevents direct Blender import |
| `assets/environment/figure8_stadium/*.glb` | Matching explicit Godot exports, approximately 6 MB combined |
| `assets/environment/figure8_stadium/stadium_manifest.json` | Survey provenance, authoring placements, structural and bank collision data |
| `tools/build_figure8_stadium.py` | Offline modeling recipe: curved sectors, stepped rows, beams, columns, fencing and fitted infrastructure |
| `tools/assemble_figure8_stadium.py` | Offline initial native scene/collision assembly |
| `scripts/track/stadium_environment.gd` | Presentation binding and detail visibility; no movement or collision mutation |
| `scenes/tracks/archive/figure_8_road_study.tscn` | Exact pre-stadium road-study scene for comparison; older assembly archive also retained |

Open `stadium.tscn` to move/hide individual stand, garage, sign or mast instances. Each model's architectural roles remain named Blender meshes: terraces, seating, stairs, structure, glazing, canopy and so on. Edit the relevant `.blend`, then export over its matching `.glb`; existing native placement/collision wrappers remain. For collision-changing edits, revise the wrapper too. Fitted bridge/banks and route safety are site-specific meshes rather than independently editable repeated native fence nodes; their source files retain named mesh groups and the authoring recipe supplies their repeated sections. Stand/garage geometry and materials are shared across native instances.

Both authoring tools refuse to overwrite existing assets/scenes unless `--replace-generated` is supplied. That option discards later edits to their outputs. **Do not routinely rerun it after manual authoring.** Normal revision means edit a source or the native assembly directly. No environment modeling/scattering runs inside the game.

The original road curve, handles, width, row spacing, driving collider, checkpoints, gates, recovery bounds, AI, handling and chase camera remain unchanged. The environment binding hides only superseded generated block/gantry visuals and applies road/ground materials, including after a road rebuild. Existing barrier collision and finish/grid markings remain. Ground contact and jump corrections are retained. Changing the road later requires resurveying and refitting the site-specific infrastructure; it does not automatically deform the saved stadium.

## Visual evidence and reproduction

All six requested sites were captured with the actual shared kart chase camera and inspected:

| Location | Capture |
| --- | --- |
| Starting grid | [Grid and garage frontage](../artifacts/v061_stadium_grid.png) |
| First sweeping corner | [Curved terraces, canopy and crowd](../artifacts/v061_stadium_sweeping_corner.png) |
| Elevated approach | [Approach and surrounding architecture](../artifacts/v061_stadium_bridge_approach.png) |
| Bridge crossing | [Upper road and enclosure](../artifacts/v061_stadium_bridge_deck.png) |
| Lower-road underpass | [Deck, abutment and lower route](../artifacts/v061_stadium_underpass.png) |
| Final corner | [Control tower and finish return](../artifacts/v061_stadium_final_corner.png) |

[Perspective overview](../artifacts/v061_stadium_overview.png) · [Top-down](../artifacts/v061_stadium_top.png) · [Bridge side](../artifacts/v061_stadium_bridge_side.png) · [Native driven lap](../artifacts/v061_stadium_native_lap.png)

```powershell
godot --path . --script tests/capture_figure8_stadium.gd
godot --path . --script tests/validate_figure8_stadium_lap.gd
godot --headless --fixed-fps 60 --path . --script tests/run_tests.gd
```

The six-site capture positions the kart for inspection; the separate native lap uses real driving input and no scripted transforms or progression injection. Full game: choose Figure-8 in Time Trial or Quick Race. Cumulative manual criteria **193–202** cover hand-driven review.

## Validation and compromises

- Full suite: **1,154 checks, zero failures**; 1,133 retained plus 21 stadium contracts. Every metre is checked at three lateral lane positions for original-road identity. Curve/handle identity, modeled architecture, reuse, opaque materials, bank support, underpass clearance and rebuild preservation pass. Earlier environment tests still run on the earlier archive.
- Seven racers, three item-enabled laps, seed 42: all finish, zero recoveries/DNF; 32 pickups and 31 uses. [Physical race report](../artifacts/v061_stadium_ai_race_2_7_3_all_ai_items.json).
- Native 1920×1080 Time Trial: one lap in **33.383 s**, zero recoveries. Kart-head-to-camera collision rays report **zero obstructions in 2,184 physics samples**. [Lap report](../artifacts/v061_stadium_native_lap.json). This is a useful camera clearance regression, not exhaustive proof against every possible off-line camera view or noncollidable visual clipping.
- Engine validation and measured performance are recorded in [validation](validation.md), with the [same-process comparison](../artifacts/v061_stadium_performance.json). The new scene is compared against the exact road-study archive, at 1080p with the same seven-racer settings.

Spectators are static stylized silhouettes, not animated NPCs. Windows are opaque tinted surfaces. Floodlight masts are modeled daytime scenery and add no real-time lights. Starting lamps and the gantry's lap board are decorative, not connected to countdown/timing; the existing HUD remains authoritative. The pit apron is blocked from racing and adds no pit gameplay. Thin fence geometry can alias without antialiasing. Repeated canopy/access breaks remain visible. Terrain outside the closed stadium remains the inherited test ground and is visible in aerial inspection, not a finished exterior environment. No baked lightmaps, bespoke texture atlas, exported-build certification, night setup or broad device testing is claimed. Human visual quality/comfort and target-PC sustained frame times remain acceptance items; these limits do not remove any of the requested architectural systems.
