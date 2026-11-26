# City Square — initial construction

2026-11-27. **v0.6.1-dev, Unreleased; developer acceptance pending.** City Square is playable through the existing gallery, Quick Race and Time Trial. It promotes the reserved `delfino_square_ds` catalog identifier, replacing the provisional Sunhaven Square display name. Existing circuit IDs, scenes and assets remain intact.

Current [developer-feedback corrections](city-square-feedback.md) preserve the approved house models, widen streets, correct contact and expand checkpoints. The initial construction evidence remains recorded separately in validation.

## Layout, elevation and assets

The supplied overhead map is the topology authority. `resources/tracks/city_square/layout.json` records traced pixel stations, the 0.75 m/pixel scale and origin. The annotated guide informs sectors, and the separate elevation reference informs the climb/descent. No reference bitmap/model/branding enters runtime content.

The canonical lap is approximately **1,160.91 m**: Avenue → Fountain → City Streets → Docks → Gardens → Avenue. The broad 22 m avenue climbs from the waterfront toward the roughly 10.5 m plaza; technical streets are now 20 m wide. Docks are 13 m wide at about +2 m above the water, followed by low stone garden paths and grass. Water is at approximately zero. The start/finish lies on the avenue at the overhead reference's stripe position. The fountain has a circular paved plaza, simple basin/pedestal and collision; both sides are physically drivable.

The two city streets share entrance/exit stations and descend **5.4 m**, from +8.2 to +2.8 m. As requested, the left has one long stair flight and the right three shorter flights. Three-dimensional path lengths are **approximately 120.1593 / 120.1593 m**, matched by a sub-metre correction at the inner corner. Both follow the two pale streets in the overhead image. Visual stair treads sit over smooth collision rather than adding individual tread colliders. The coast then descends gently to the harbour.

Six independently authored Blender house types share a coherent stucco/terracotta/shutter vocabulary: townhouse, narrow three-storey, wide two-storey, merchant/shopfront, developed corner and harbour house. **135 native instances** (206 in the initial assembly before frontage corrections) form frontage and interior blocks. Houses border urban streets directly; there are no sidewalks, kerbs or racing fences. Sources retain architectural components; GLB exports merge each house for efficient sharing. Roof, cobble and timber patterns are original repeating SVG textures. No inaccessible interiors or decorative market/vegetation assets are modeled.

Road strips, branch junctions and the circular plaza are combined offline into an authored seamless paved volume. Wooden decks are separate thick solids with longitudinal/cross beams and piles. Dock edges are open: no guardrails, invisible walls or support floor beneath the seaward edge. Graded solid town land and coastal faces are separate from garden grass and the harbour island. Lightweight opaque water has no collision, simulation or reflection effects.

## Scene hierarchy and reusable architecture

- `scenes/tracks/city_square.tscn`: `AuthoredCircuit` Path3D, authoritative curve, widths, branches, checkpoints and track-specific recovery height. `Ground` instances the native environment.
- `scenes/environment/city_square/environment.tscn`: Roads, Terrain, Fountain, StairsAndDockStructure, Architecture and simplified collision. Six house wrapper scenes reference shared GLB models and simple box masses.
- `assets/environment/city_square/sources/*.blend`: ten editable model/site sources, excluded from automatic Blender import with `.gdignore`. Corresponding GLBs are explicit exports. `manifest.json` retains deterministic house placements and dimensions.
- `resources/tracks/city_square/`: saved centerline, two directed alternatives, width profile, traced layout and baked survey. These are authoring resources, not runtime generated scenery.
- `tools/author_city_square.py`, `tools/bake_city_routes.gd`, `tools/build_city_square.py`, `tools/assemble_city_square.gd`: offline trace/bake/model/assembly helpers. Blender source rebuilding requires `--replace-generated`; do not overwrite later artist edits casually. The Godot bake/assembly tools also replace their outputs when explicitly run; normal iteration should edit the saved resources/scenes.
- `city_materials.gd`: binds shared repeating materials. `AuthoredCircuit` creates only race gates/finish markings, not the standard road ribbon/barriers. Original procedural circuits keep their original builder.

`TrackDefinition` now retains a circuit's TrackBuilder subclass at the original sibling position. Race initialization ensures checkpoint geometry exists before sibling consumers bind it. It supports authored roads without a City-specific loading bypass.

`RouteBranch` and `CircuitRoutes` provide reusable directed alternatives between canonical lap stations. Human projection recognizes either branch; AI uses deterministic route masks, including both city streets and both fountain sides. All routes map onto common progress stations and shared ordered gates. Minimum travel uses the shortest valid branch length inside an interval, with a 2 cm station-rounding tolerance at shared gates; it does not reduce the global anti-shortcut policy. Ranking uses common normalized progress. AI expected gates and recovery poses are mapped into its chosen route, avoiding a respawn facing the wrong branch. Inclined checkpoint recovery/grid headings stay upright; corner planning measures horizontal heading rather than mistaking grade changes for lateral turns. No driving constants, gravity, jump or boost equations were changed.

The gallery and HUD retain the canonical curve; the gallery additionally draws actual alternative curves. Four circuits are now launchable. Original three-circuit tests remain, extended with the new availability/launch entry rather than replacing previous gameplay assertions.

## Water recovery and progression

City Square sets the existing KartRecovery fall threshold to **−0.35 m**; other tracks retain −8 m. Falling from a dock genuinely leaves support and falls through the non-solid sea before recovery. The last validated checkpoint supplies the safe position. Recovery clears only unvalidated interval travel, preserves validated checkpoints/laps and does not award progress from teleport distance. Tests physically drop a kart off the seaward edge and verify recovery/progression. Garden grass uses the existing off-road SurfaceConfig; there are no speed pads or launch ramps.

## Evidence and limitations

[Avenue](../artifacts/v061_city_avenue.png) · [Fountain](../artifacts/v061_city_fountain.png) · [City streets](../artifacts/v061_city_city.png) · [Stair entrance](../artifacts/v061_city_outer_stairs.png) · [Docks](../artifacts/v061_city_docks.png) · [Gardens](../artifacts/v061_city_gardens.png) · [Overview](../artifacts/v061_city_overview.png) · [Top](../artifacts/v061_city_top.png) · [Dock structure](../artifacts/v061_city_dock_side.png)

Captures use the actual chase camera for sector views, including the [left long flight](../artifacts/v061_city_left_long_stairs.png) and [right short flights](../artifacts/v061_city_right_short_stairs.png). Source map tracing retains the major corners and branch topology; hand comparison and artistic acceptance remain required. No boats, crates, vegetation, furniture, signs, environmental audio/particles, animated fountain/water, custom arrival artwork or speed pads are introduced.

The permanent suite measures actual support on all four route combinations, equal street length/drop, station mapping, minimum-travel rounding, authored loading, exposed dock edges, water recovery and unchanged progress. The existing circuit/handling/contact/item/presentation regressions remain enabled. See [actual validation results](validation.md).

Important remaining limits:

- The initial isolated stair-sector times were **10.77 / 9.42 s**. After widening/contact corrections the same fixture reports **9.37 / 9.40 s**, both without recovery. Length/drop still match; manual driving and other profiles remain necessary to accept route balance. No artificial speed penalty was added.
- A three-lap, seven-racer item-enabled diagnostic rerun finished all seven in 213.8–253.35 s, with 0–4 recoveries. Earlier seed-42 runs had six finishers and one DNF under traffic. This is a working beta race, **not** validated robust no-recovery AI behavior; narrow junctions and traffic still need tuning. Passing and failing reports are retained rather than overwritten into a success claim.
- Native 1080p lap and performance measurements are recorded separately. The short benchmark is near the 60 FPS target, not a guarantee of sustained 60 FPS or all-device performance. Different route/view timing means it is a workload comparison, not a percentage optimization claim.
- Basic repeating materials, broad terrain and building connections are an initial construction pass. Roof/shutter variation, full coastline/foundation/house seam inspection, both stair visuals, manual route choice, surface transitions, exports and hardware remain developer acceptance work.

Reproduce with Godot's `--path . --script` and the relevant script: `tests/capture_city_square.gd`, `tests/measure_city_stairs.gd`, `tests/validate_city_square_lap.gd`, `tests/benchmark_city_square.gd` (native, no fixed FPS). For a physical item race use `--headless --fixed-fps 60 --path . --script tests/run_ai_race.gd -- --circuit=delfino_square_ds --difficulty=challenging --laps=3 --items --item-seed=42 --report-prefix=v061_city_recheck`. Reports are `artifacts/v061_city_*.json`; local logs are `.godot/city_*.log`. Different rendering/tick scheduling can change traffic interactions; retain failures as well as passes.

Changed shared files: TrackDefinition/Registry/Builder, RaceManager/CheckpointGate, RacingLine, CircuitCard/Outline and relevant tests. New route-resource/mapping/authored-track/material-binding scripts, city resources/assets/scenes, tools and dedicated tests are listed above. No existing circuit meshes/scenery were edited. No staging, commits, pushes, tags or GitHub actions. This implementation remains pending acceptance, with editor/manual/traffic/performance acceptance still outstanding.
