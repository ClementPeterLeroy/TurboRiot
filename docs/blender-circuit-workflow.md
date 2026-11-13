# Blender-authored circuits: proposed workflow and architecture

Design proposal, 2026-11-12. This document records the next circuit-authoring foundation; the runtime refactor, editor tools and imported-track support described below are **not implemented**. Version remains v0.6.1-dev, Unreleased. Existing circuits and tests remain the migration baseline.

## Why importing a model is not enough today

`TrackDefinition.instantiate_race()` currently copies properties from a procedural TrackBuilder, moves its Ground child and frees the rest of the source scene. Imported model children would be discarded. RaceManager, RacingLine, ItemSystem, TrackFeatures and CircuitMap also depend on TrackBuilder, generated checkpoint paths, one road width and procedural sampling. TrackRegistry hardcodes its three entries. The current geometry validator checks procedural vertex arrays and cannot certify an arbitrary imported mesh.

The next foundation must instantiate and retain a complete circuit scene, while separating race metadata from the tool that creates the road. Adding imported art beneath the current TrackBuilder or replacing the JSON is not a complete integration.

## Authoring boundary

Developer-confirmed workflow (2026-11-12): **build the complete track and scenery in Blender; author gameplay markers and routes in Godot**. Bridges and tunnels are expected in the first authoring foundation, and jumps are a near-term requirement. Named Blender empties are optional future tooling, not required by this workflow; arbitrary names alone do not implement checkpoints or AI paths, and Blender curves must not be assumed to arrive as usable Godot Curve3D resources.

The subsequent owner-supplied environment workflow requests evaluation of direct `.blend` importing as the primary local development loop. The [Bikini Bottom repository review](bikini-bottom-workflow-review.md) confirms the current master, installed/configured Blender and existing GLB-backed sandbox. Recommend qualifying direct master import locally, while keeping the current GLB scene reference until that pilot passes. GLB remains a derived fallback; Blender remains the sole authoritative geometry source. Use exactly one active imported environment instance in a normal Godot `.tscn`, with gameplay nodes outside its generated subtree. Direct `.blend` import requires Blender on machines regenerating imported assets; a GLB workflow can exclude Blender source from automatic import. Do not import and instance both representations accidentally.

Proposed circuit package:

```text
circuits/harbor_loop/
  definition.tres        # Stable ID, title, wrapper scene, preview, test status
  harbor_loop.tscn       # Persistent editable wrapper, engine integration
  assets/track.glb       # Re-exported model and authored collision proxies
  materials/            # Optional engine-owned materials
```

Proposed scene nodes (new runtime types are design names, not existing classes):

```text
HarborLoop (CircuitRoot: Node3D)
  Model                 # Instance of assets/track.glb
  Gameplay
    Route (Path3D)      # Closed ordered 3D lap path, not a road generator
    Gates              # Ordered directional CheckpointGate scenes
    Grid               # Explicit Marker3D poses for supported racer count
    Recovery           # Safe poses associated with validated route progress
    Items               # Authored pickup rows and boost-pad instances
    SurfaceBindings    # Asphalt/sand/grass metadata on physical support
    Bounds             # Fall threshold, playable bounds and optional kill areas
  Environment          # Optional circuit lighting, sky and scenery overrides
```

The selected circuit is one scene instance under the shared race world. It does not contain a separate copy of the player, AI, HUD, camera or RaceManager. All child nodes survive loading. Editor preview must not secretly create a race or regenerate imported geometry.

## Runtime contract and migration

1. Introduce a shared circuit contract consumed by racing systems: route sampling in consistent coordinates, per-section left/right drivable extents, ordered gates, spawn/recovery poses, surface bindings, bounds and optional feature nodes. Route progress remains authoritative for ranking and checkpoints; artistic geometry does not define lap rules.
2. Adapt existing TrackBuilder circuits to that contract, retaining their generated geometry and all existing regressions. Add a separate imported-scene implementation. Avoid per-circuit controller scripts or another copy of kart physics.
3. Replace property copying with whole-scene loading. Connect references and signals before entering the race tree; define a single circuit-ready event after collision/gameplay initialization. Dispose the entire circuit on restart or switch. Do not require `Generated/Checkpoints` for hand-authored scenes.
4. Move definitions into `.tres` resources listed by a catalog resource. Adding one validated entry exposes a circuit without editing a match statement. Reject duplicate IDs and invalid/missing definitions with an actionable error; never silently run the reference circuit when testing an unknown ID. A draft circuit stays in a development catalog until approved for the normal menu.
5. Cache lightweight previews/route metadata separately from full scenery. Circuit Selection must not instantiate every detailed Blender scene to draw thumbnails. Load only the selected circuit and release its resources when leaving.
6. Provide a shared test launcher referencing a definition, runnable with F6, plus a CLI definition-path option. This allows testing a draft without publishing it in the selection menu. These launch paths need implementation; current scripts accept only registry IDs.

Keep one closed, unbranched lap route for the first imported circuit. Variable widths require per-section corridor data, not the current single road width. Bridges/tunnels require height-aware route association and bounded gates that cannot count the other deck. Recovery must land on the correct deck. Replace origin-centered/global fall assumptions with circuit-local bounds and track-specific thresholds. Do not flatten imported roads or assume every driveable surface lies at Y=0.04.

Current kart physics keeps the body upright and has a floor-angle limit. Gentle grades, real jumps and conservative banking need physical validation; loops, wall driving, steep banks and alternate-route ranking are separate mechanics, not promises made by model import.

## Bridges, tunnels and upcoming jumps

These requirements affect the foundation now, rather than being treated as scenery-only additions later:

- **Deck identity:** use the ordered 3D route and bounded route-progress searches to distinguish vertically stacked roads. Do not reacquire the globally nearest XZ point. At a crossing, checkpoints and surface probes must associate with the intended deck; recovery poses must be explicit, supported and clear of the other deck. A lap cannot advance just by passing above or below its gate.
- **Collision clearance:** author separate simplified road/deck, underside, wall and ceiling proxies as needed. Do not fill a bridge opening with a convex hull encompassing the whole structure. Test real kart sweeps through the underpass and over the deck, including boosted speeds and multiple lanes. Avoid hidden duplicate collision from automatic import plus manually added proxies.
- **Camera:** validate ceilings, tunnel entrances/exits and bridge undersides with the actual chase camera. Current ChaseCamera uses a single obstruction ray and a world-Y minimum of 0.3 m; the latter assumes the old floor arrangement and cannot be retained as a universal rule for circuits below that height. The ray is not proof that the camera's near plane clears a tunnel wall. Any camera correction must preserve the existing moving-target smoothing and high-speed stability regressions, without masking physics faults. Test circuit-local elevations both above and below world zero.
- **Jump intent:** keep launch intent separate from asphalt surface identity. Current KartController only carries rising-ground takeoff velocity for physical colliders tagged `launch_ramp`. An arbitrary Blender ramp mesh will not automatically acquire that behavior. The Godot wrapper must offer an explicit binding to the relevant imported ramp collider, reapply it on fresh instantiation and validate that the binding survives reimport. Tag only intended launch sections, not the full bridge or circuit. Preserve the prior shoulder-contact correction and ordinary continuous ground support.
- **Airborne route intervals:** jumps require declared takeoff/landing sections so support validation can distinguish an intended gap from missing collision. Keep gates out of ambiguous mid-air positions initially. Recovery chooses a safe supported pose from validated progress, never an airborne route sample. AI jump approach, landing clearance and ranking through the gap need dedicated tests; ordinary curve pursuit alone is not evidence of reliable jumping.

Qualification order: first a minimal imported loop to prove loading/reimport, then an overpass-and-tunnel fixture to prove height separation/camera/recovery, then a physical jump fixture to prove collider tagging, airborne progress and landing. Full scenery should follow those functional proofs. This does not require the developer to abandon their current Blender circuit; small fixtures isolate integration defects before debugging them inside a large model.

## Blender preparation

The current Bikini Bottom curve/Geometry Nodes road requires evaluated mesh conversion for GLB export; otherwise its node can arrive without a mesh while buildings and terrain export correctly. See the [confirmed road-export diagnosis and non-destructive procedure](blender-road-export.md). Preserve the editable source curve and convert only an export copy or in-memory export representation.

- Model at metric scale, targeting 1 imported Godot unit per metre. Apply mesh scale/rotation before final export; keep the circuit wrapper at unit scale. Check a known-size reference against the existing 1.25 × 0.75 × 2.1 m kart hull after import. Let glTF perform the axis conversion; verify forward orientation in Godot instead of adding a second corrective rotation blindly.
- Separate visible road/scenery from simplified collision proxies. Use contiguous, clean driving surfaces; avoid duplicate coplanar colliders, seam steps, flipped faces and thin decorative kerbs crossing the road. Keep materials and collision surface identity separate: a green material is not automatically grass physics.
- Godot import suffixes such as `-colonly` can produce hidden static collision from explicit proxy meshes. Use simple primitive/convex segments where appropriate and measured, simplified triangle sections for irregular road. Never wrap an entire winding circuit in one convex hull: that can fill gaps and block bridges. Do not recreate the expensive whole-detail road collider that caused the Yoshi slowdown.
- Split art into sensible spatial sections, reuse meshes/materials for repeated props, and control shadow/texture costs. Neither thousands of tiny objects nor one giant combined mesh is a universal optimization. Measure with the intended camera and full racing field before adding all scenery.
- Keep stable names for imported nodes referenced by surface bindings. Blender edits can invalidate Godot-authored marker placement even when the nodes survive reimport; validation and manual review must run after geometry changes.

## Validation and testing workflow to implement

1. **Editor validation:** missing references, duplicate circuit IDs, unit/nonfinite transforms, closed route, monotonic gate order and offsets, matching finish direction, grid count/clearance, road support under route samples, surface metadata and safe recovery poses. Show actionable node paths and errors/warnings. Separate shared race-contract checks from procedural-only mesh checks. Extra probes around seams/overpasses cannot be replaced by sparse route raycasts alone.
2. **Solo greybox test:** shared launcher, one kart, no items/AI. Drive all seams and corners; inspect visible collision shapes temporarily. Test high-speed camera/presentation, runoff transitions, actual barriers, fall recovery, restart, ramp takeoff/landing and underpass clearance.
3. **Race correctness:** full laps, skipped/reversed gates, close neighboring road sections, correct-deck recovery and grid starts. An AI route is authored navigation data, not inferred from the rendered mesh. Use authored checkpoint windows to reject shortcuts.
4. **AI qualification:** shared physical AI race harness, all difficulties, fixed seeds, full field, first without items and then with items. Report finishes, DNF, recovery counts and lap times; review stuck/shortcut behavior. AI finishing does not establish human handling quality.
5. **Native performance:** developer-confirmed target is **60 FPS at 1920 × 1080 on the developer's current PC**, with complete scenery and normal full-field racing (one human plus six AI), items and effects. This is a target, not an achieved result for future custom circuits. A 60 FPS frame has a 16.67 ms budget; average FPS alone must not conceal recurring hitches. Compare READY, solo racing and full-field racing on the same GPU/settings; record the actual adapter, CPU, engine/build and display settings in each report, since earlier runs selected different adapters on this PC. Profile warmed-up full laps including bridges, tunnels and jumps with overlays off, VSync disabled and uncapped native rendering to expose headroom. Record frame-time percentiles, physics cost, draw calls and memory; also check normal VSync play. Headless or fixed-FPS runs verify behavior, not rendered FPS. Derive geometry/material/shadow budgets from those measurements rather than inventing a universal triangle limit. Earlier 720p measurements are not evidence of meeting this 1080p target.
6. **Reimport/lifecycle:** move a Blender road section, re-export, verify persistent gameplay nodes and catch stale placements; switch/restart repeatedly, test selected circuit retention and no old colliders/audio/projectiles. Verify exported builds can load the catalog and GLB-derived scene without Blender installed.

Finish one small imported oval through this entire workflow before migrating a large detailed circuit. Then use its package as the template. Existing suite and manual checks 1–161 remain required; append new imported-circuit acceptance criteria when the implementation exists. Do not label this proposal as tested imported-track support.

## Confirmed decisions and remaining questions

- Confirmed: complete track/scenery in Blender, all gameplay markers/routes in Godot, bridges/tunnels expected and jumps coming shortly.
- Confirmed performance target: 60 FPS at 1920 × 1080 on the developer's current PC, with full scenery and normal full-field racing. Capture exact hardware/active GPU during qualification.
- Not requested as initial mechanics: alternate routes, loops, wall driving or steep banking. Supporting import does not imply support for these mechanics.
- Remaining scale decisions: expected circuit sizes and any racer counts beyond the current seven-kart field.
- Source asset storage/size policy, art ownership and development-only versus distributable catalog entries.

## Import documentation

- [Godot supported formats and Blender/glTF workflow](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)
- [Godot scene import configuration and customization](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)
- [Collision import name suffixes and their limitations](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html)
