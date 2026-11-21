# Yoshi — coastal garden raceway

2026-11-21. Implemented within **v0.6.1-dev**, Unreleased pending developer/artistic acceptance. No new release or milestone is introduced.

## Art direction and delivered content

The preserved 1,188.52 m, 19.5 m-wide circuit now sits on an authored coastal island with a sand rim, low cliff sides and animated opaque sea. The private overhead map informed the island/raceway relationship; all new models, colors and signage are original project assets. The coast is a conservative original outline rather than an exact recreation of the reference shoreline.

The garden/paddock composition contains **21 individually placed broadleaf trees, 12 flowerbed instances, two short garden tunnels, two paddock houses, a race-control tower, two start-area stands and a pedestrian square/walkway**. Trees use faceted overlapping crowns; beds group coral/cream flowers and stems into reusable meshes. Buildings use warm plaster, teal roofs/awnings and opaque blue windows. Two canopy grandstands reuse Circuit 8's geometry with a separate Coastal GP banner wrapper. No crowd simulation or copied reference artwork is included.

The two 14 m-long arched passages have approximately 28 m-wide openings. They are deliberately short garden tunnels, not large mountains or newly elevated road sections. Convex arch sections provide actual wall/roof collision; their sampled headroom across the road is **9.768 m** or greater. Existing colored barriers, road mesh/collision, checkpoints, AI pursuit, recovery and camera remain unchanged.

## Artist-facing structure

```text
scenes/tracks/yoshi_ds.tscn
  Ground (island_ground.tscn)
    Island — imported land, sand and cliff geometry
    GroundBody — upward-facing, grass-tagged support
  EnvironmentArt (yoshi_environment.tscn)
    Sea — editable ShaderMaterial, subtle animated streaks
    Trees / GardenTree00…20
    Flowers / Flowerbed00…11
    Tunnels / Tunnel0…1
    Paddock / Building0…2
    Grandstands / StartStand0…1
    Promenade / PaddockSquare, GardenWalk
```

Each tree, bed, tunnel and building is a reusable PackedScene under `scenes/environment/yoshi/`, with separately editable placement. The scene contains saved instances and transforms; nothing scatters or rebuilds scenery at runtime. Native primitive/convex collisions are separate from visible imported models. Flowers, promenade overlays and sea have no extra physical obstruction; the underlying island supports the promenade. Water outside the island has no invisible grass floor.

Editable models are in `assets/environment/yoshi/sources/*.blend`; `.gdignore` keeps source files out of Godot imports/builds. Engine assets are neighboring GLBs. Edit the appropriate Blender source, export over that GLB and validate collision/support afterward. Edit `yoshi_environment.tscn` for placements, vegetation density and sea material. Open a prop's `.tscn` to change its collision or reuse it in another circuit. Imported-child changes should be made through source assets or wrapper overrides, preserving reimport safety.

`resources/tracks/yoshi_environment_layout.json` records initial design placements/coast/route anchors. `tools/build_yoshi_environment.py` is an explicit authoring helper that writes editable source and scenes, using the existing Blender authoring functions without executing Circuit 8's build. It refuses existing output unless invoked with `-- --replace-generated`. Rebuilding deliberately discards subsequent manual source/scene edits; normal play, import and scene opening never run it. The promenade and portal-caption refinements are native scene edits and must be preserved manually if intentionally rebuilding. This is a source-and-scenes workflow, not a runtime procedural environment.

## Validation

The complete suite passes **1,114 checks, zero failures**: 1,103 retained plus 11 Yoshi environment assertions. They cover authored-child loading/counts, reusable tree scenes, road-lane collider identity across 600 samples and three lanes, island support outside both shoulders, tunnel headroom, upward grass support/metadata, absence of invisible sea floor and preservation through procedural road rebuild. All original handling, visual stability, ramps, crossing, race, items and other-circuit regressions remain enabled.

The road Curve3D, tracing JSON, TrackBuilder, kart controller, chase camera and shared scene loader are unchanged. The only intentional support change is replacing Yoshi's rectangular greybox ground with the authored grass island. Existing owner-authored Baby Park files and Circuit 8 scene are preserved. No game version/export metadata or Git mutations.

Native multi-view captures and the seven-AI, three-lap, Challenging item race are recorded in `artifacts/v061_yoshi_environment_*.png` and `artifacts/v061_yoshi_environment_ai_race_2_7_3_all_ai_items.json`. Performance is measured by `tests/benchmark_yoshi_environment.gd`, using a preserved pre-change scene and the new scene in one process at 1920 × 1080, uncapped/VSync off, seven AI, items seed 42 and 60 Hz physics. Each case warms for 360 ticks and samples 720 ticks. The ignored pre-change snapshot must be supplied with `--baseline-scene=...` when reproducing elsewhere; the initial standalone baseline is preserved separately.

Final physical item race: all seven finish three laps, **zero recoveries and zero DNF**, finishing times 227.800–232.033 s. Native 1080p application Time Trial also completes in **77.633 s**, zero recovery, using existing AI commands on the human kart. These are physical simulation checks, not human-controller acceptance.

On the Ryzen 7 6800H / RTX 3070 Ti Laptop GPU, the controlled comparison measured **130.89 → 126.68 FPS**, P95 frame **13.68 → 12.21 ms**, P99 **15.91 → 15.02 ms**. Draw calls rose from 1,714 to 1,860; visible primitives from 398,129 to 436,922; collision shapes from 3,206 to 3,256. Static memory was 92.80 → 95.19 MB and reported video memory 38.72 → 40.35 MB. Render CPU was 3.18 → 3.39 ms and render GPU approximately 0.92 ms in both. Physics mean was 7.69 → 7.11 ms; variation is not evidence of a physics optimization. Cache/order-affected load timings of 576 → 350 ms are not a cold-loading improvement claim. Measurements span twelve seconds per case, not a complete-lap minimum or prolonged-play guarantee. Report: [same-process comparison](../artifacts/v061_yoshi_environment_comparison.json).

See [current engine, race and performance results](validation.md). These are measured checks, not artistic acceptance, a universal minimum-FPS guarantee or a claim of shipped studio-quality content. Human high-speed driving, underpass/camera inspection, exported builds, all AI difficulties and prolonged sessions remain manual checks **177–184**.

## Preview

- [Overall coastal composition](../artifacts/v061_yoshi_environment_overview.png)
- [Top view](../artifacts/v061_yoshi_environment_top.png)
- [Start-line paddock](../artifacts/v061_yoshi_environment_paddock.png)
- [Garden tunnel](../artifacts/v061_yoshi_environment_tunnel.png)
- [Trees and flowers](../artifacts/v061_yoshi_environment_gardens.png)

Play with F5 → Quick Race/Time Trial → select GCN Yoshi Circuit (DS). Stop and relaunch an already running game to load the new scene. Adjustments to placement/density/style remain under the developer's artistic control.
