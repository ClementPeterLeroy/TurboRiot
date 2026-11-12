# Bikini Bottom Grand Prix — workflow review

2026-11-12. Repository and import-configuration inspection only. No Blender files, model placement, scene, collision, import settings or gameplay code changed. This report does not claim a fresh reimport, race validation or 1080p benchmark. Version remains v0.6.1-dev, Unreleased.

## Assessment

Subsequent implementation: the [sandbox recovery correction](validation.md) adds per-road startup bounds only to the existing test scene and passes 1,076 checks. The recovery-limit finding below records the original audit; collision reimport, imported race loading and camera integration remain outstanding. Blender files and authored geometry/placements remain unchanged.

The supplied workflow fits the confirmed ownership boundary: the owner builds the complete environment in Blender; Godot owns race metadata and technical integration. Preserve the six-sector sequence and all authored geometry/placements. The document needs the concrete amendments below before its reimport guarantees can be relied on.

The owner confirmed that `resources/tracks/Bikini_bottom/Blender/bikini_bottom_track_blockout.blend` is the current master. Do not create or rename a replacement master merely to match the conceptual `BikiniBottom_Master.blend` name.

## Actual assets and scene

| Role | Existing path / finding |
| --- | --- |
| Authoritative Blender source | `resources/tracks/Bikini_bottom/Blender/bikini_bottom_track_blockout.blend` |
| Currently referenced engine asset | `resources/tracks/Bikini_bottom/Exports/bikini_bottom_track_blockout.glb` |
| Native test scene | `scenes/tracks/Bikini_bottom_test.tscn` |
| Earlier test pair | `Blender/bikini_bottom_test.blend` and `Exports/bikini_bottom_test.glb`; neither is the environment instance referenced by the current test scene |
| Route reference data | `Blender/centerline_export.csv`, `Blender/bikini_bottom_elevation_centerline.csv`; these are not wired into racing by the current test scene |
| Existing runtime composition | `scenes/main.tscn`: shared kart, RaceManager, ChaseCamera, HUD, items, procedural Track and environment |

The test scene already references the owner's GLB and the shared `scenes/kart.tscn`. It adds a static road collision beneath the editable imported `TR_BikiniBottom_Road_Test` node, Sun, WorldEnvironment and a child `Test_Camera3D`. It has no RaceManager, authored grid/checkpoint route integration or shared chase-camera instance. It is a driving sandbox, not a complete race-ready catalog entry.

The GLB has two meshes: Cube and the road mesh (3,072 triangles). It also includes curve-named empty nodes and a large-scaled Empty. These are evidence that the export set needs an explicit audit; the generic Cube/Empty might be intentional helpers, so do not delete them without asking the owner. A modeling collection name alone does not establish export exclusion. The full authored environment is still in development; this asset does not establish that buildings/props are integrated.

## Immediate issues, in priority order

1. **Recovery bounds already conflict with the road.** Imported road vertex bounds are approximately X = −224.54…214.57 m and Y = −12.00…10.00 m. KartRecovery defaults to X half-extent 178 m and fall height −8 m; the test scene does not override them. Valid portions of this road can therefore trigger recovery. Replace these assumptions with circuit-specific/local playable bounds and safe recovery poses. Do not alter Blender elevations or enlarge every circuit's defaults as a workaround. This is a static code/asset finding, not a new dynamic reproduction.
2. **Collision is a saved snapshot.** The native test scene serializes a ConcavePolygonShape3D with 3,072 triangles under an imported mesh child. Counts and outer bounds currently correspond to the exported road; this does not establish point-for-point equality. Re-exporting visual geometry does not regenerate that manually saved collision. Use configured import-time physics generation or explicit simplified proxies, with validation and Godot-owned surface/layer bindings. Regeneration must replace the previous generated collision exactly once, not append a duplicate.
3. **The test kart overrides its layer to 3.** This sets both world layer 1 and kart layer 2. Restore the shared kart layer contract in the eventual test harness: kart bodies on layer 2, physical environment on layer 1, surface regions on mask 8. Other systems query layer 1 for environment, so a kart should not also identify as world geometry.
4. **Surface metadata is absent from the saved road body.** The current detector falls back to asphalt, so apparent asphalt behavior does not demonstrate correct integration. Explicitly bind SurfaceConfig metadata to physical support, including future terrain, rather than interpreting Blender colors or relying on fallback.
5. **Full-race loading is not compatible yet.** TrackDefinition copies procedural TrackBuilder settings, moves only Ground and frees the remaining source scene. Registering this Node3D test scene as a track will not preserve it or provide the required API. Introduce imported-circuit support behind the shared race contract; preserve the existing three circuits.
6. **Camera assumptions need qualification.** ChaseCamera currently clamps world Y to at least 0.3 m, while this road descends below zero. The sandbox uses a different simple child camera and cannot prove shared chase-camera clearance or presentation. Test the actual chase camera below zero and inside tunnels, preserving its existing interpolation/stability corrections.

## Import decision

**Recommend direct `.blend` as the primary local iteration workflow, subject to a round-trip qualification.** Blender 5.2 is installed at `C:/Program Files/Blender Foundation/Blender 5.2/blender.exe`; Godot's editor settings reference that executable. Both `.blend` files already have import metadata and cached imported scenes. These facts make a direct-import pilot reasonable; cached scenes alone do not prove fresh import reliability or Blender/Godot version compatibility.

Godot converts `.blend` through Blender's glTF exporter. Pin/document Blender and Godot versions and import options for machines that regenerate those assets. The current project uses Godot 4.7.2 Compatibility. The supplied save-and-refresh loop can be the eventual local workflow once the actual master and collision-refresh path pass validation. See [Godot's Blender/glTF import documentation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).

Keep the current GLB reference unchanged during this review. Pilot the direct source in an isolated integration scene, using the same model transform and gameplay data; switch the one active environment reference only after comparison. Keep GLB as an explicit derived export fallback for machines without Blender or if direct import proves unreliable. Blender remains the only geometry source of truth in either case. Never instance both versions or maintain edits independently in the exported GLB.

For now, keep existing source/import paths stable; moving them adds reference churn without solving integration. Later, separate authoritative master, linked source assets and exports using a documented naming/layout policy. Verify linked `.blend` dependencies and texture paths work from a fresh project location; do not depend on unrelated absolute paths on the owner's machine.

The direct-import settings currently allow lights and cameras and do not limit import to an active collection. Define an explicit runtime export set that excludes References, construction helpers and modeling cameras/lights. A future master containing linked assets, procedural materials or Geometry Nodes needs an export preview: Blender's appearance and collection organization are not a guarantee of the imported result. Use supported PBR materials/textures, baking procedural material output when necessary without changing the source artistically. Godot lighting stays engine-owned. See [model export considerations](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html).

The source directory also contains centerline CSV import metadata generating translation resources. Route CSVs are technical data, not localization tables: isolate/exclude them from Godot's CSV translation importer or select an appropriate nontranslation import mode when wiring the route pipeline. Do not delete existing files during review.

## Reimport-safe structure

Use one reusable circuit wrapper plus a separate shared test/race host:

```text
SharedRaceOrTestHost
  Circuit — native reusable wrapper
    Environment
      BlenderEnvironment — exactly one imported source instance
    TrackPhysics — bindings and generated/simplified collision as appropriate
    RaceData — Route, StartingGrid, Checkpoints, Recovery, Bounds
    Features — item rows, pads, launch bindings
    Lighting — optional circuit-specific configuration
  Kart / AI field       — existing shared systems
  RaceManager           — existing shared system
  ChaseCamera / HUD     — existing shared systems
```

The supplied conceptual hierarchy places KartInstances and LapDetection inside the circuit. Make clear that lap detection delegates to the existing race system and that the reusable circuit does not create its own kart field. Otherwise loading it into the shared race host risks duplicate racers/managers. Keep a single effective WorldEnvironment/sun configuration; avoid importing Blender lights on top of shared and circuit lighting.

Godot gameplay nodes must live outside the generated imported subtree. Stable names/paths support bindings, but renamed or missing nodes must produce validation errors. A visual reimport preserves authored gameplay nodes; it does **not** guarantee their positions, AI corridor, spawn support or checkpoint coverage are still valid. Revalidate them whenever road geometry/elevation changes. Use [import configuration and automation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html) rather than hand-copying source meshes.

## Minimal implementation sequence

1. Establish the isolated imported-environment wrapper and shared driving test host, preserving the current sandbox and original models. Add deterministic collision/surface binding plus track-local recovery settings. No layout changes.
2. Prove reimport safety with an owner-made geometry change: visual and collision agree, node bindings resolve, authored gameplay nodes survive, stale placements are reported, and no duplicate geometry/colliders appear.
3. Add imported-circuit adapter/whole-scene loading to the existing race contract, then route/gates/grid/recovery and a catalog entry. Reuse RacingLine's existing route pursuit; general navmesh pathfinding is not automatically required for a mandatory lap route. Optional Blender CSV may seed the Godot route with an explicit axis/unit conversion; afterward identify which data owns subsequent edits and do not silently overwrite the Godot-authored route on model reimport.
4. Qualify bridge/tunnel deck association, launch-ramp bindings and jump landing/recovery using the existing [architecture requirements](blender-circuit-workflow.md). Preserve ordinary ground-contact corrections; an imported incline alone does not enable the controller's `launch_ramp` behavior.
5. Run existing regression tests plus imported collision/reimport/bounds tests, physical races and native 1080p timing. Append manual criteria when implementation exists; do not mark an audit or cached import as acceptance.

Triangle collision is reasonable for this 3,072-triangle blockout only as an initial measured choice. Finished art should not automatically become high-detail collision; simplify and section it as needed without filling bridge/tunnel openings. Godot documents both the cost of triangle collision and pitfalls of convex level geometry: [collision import options](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html).

The supplied workflow should explicitly carry the agreed **60 FPS at 1920 × 1080 on the owner's current PC**, full environment, seven racers, items/effects. Capture actual GPU/settings and frame-time percentiles over representative warmed-up laps. Earlier 720p results do not qualify this circuit at 1080p. No redesign of the owner-authored road is permitted as a silent performance or AI workaround.

## Review result

Adopt the ownership rules and native-wrapper approach. Amend the document with collision regeneration, validation after reimport, source/import selection, runtime-helper exclusion, local recovery/camera requirements and the performance target. Actual import switching and runtime infrastructure remain pending; no staging, commits, pushes, tags, releases or GitHub actions were performed.
