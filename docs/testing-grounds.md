# v0.6.1-dev — Circuit Selection & First Testing Grounds

Unreleased, pending developer acceptance. This is the first Testing Grounds delivery. It preserves the v0.6.0 application, original reference circuit and all preceding handling/contact/presentation/item mechanics. No Git mutations were performed.

The subsequent [Figure-8 crossing correction](figure-8-crossing-fix.md) removes the kart's false wall contacts on the upper incline through a rounded native collision hull. The later [racing-performance correction](circuit-performance.md) optimizes flat-road collision and caches minimap routes while retaining the crossing's elevated triangle collider. Current validation is **1,062 checks, zero failures**; manual checks now extend through **161**. Initial-delivery evidence below is preserved.

## Repository audit and architecture

Read-only local history at the start was clean HEAD `1d97794` (v0.6.0), preceded by `e22a2f2`, `a31ff9f` and `0d69490`. Commit names do not establish acceptance or publication. The baseline suite passed **925 checks, zero failures**. The canonical roadmap already assigned circuit work to v0.6.1; v0.7+ scopes remain unchanged.

Existing `app.tscn` / TurboApplication owns configuration, menus, audio, settings and one disposable PAUSABLE gameplay world. `main.tscn` composes the original TrackBuilder, environment, features, kart, shared RaceManager, Items, camera and HUD. TrackBuilder already generates asphalt/collision/UVs/shoulders/independent barriers/finish/gates from a saved closed Curve3D. RaceManager already derives grids, recovery poses and cached RacingLine data from that same track. Replacing those controllers was unnecessary.

The minimal extension is:

- `TrackDefinition` carries ID, name, category, description, optional track scene, default laps, grid tuning and explicit pickup/pad progress fractions. The track scene owns Curve3D, width, sampling, gates, surfaces/ground and safety bounds. Finish is offset zero with curve-forward orientation; ordered gates also supply respawn poses. The AI route and previews derive from the same curve.
- `TrackRegistry` exposes exactly three playable definitions. The reference definition instantiates the original fixture unchanged. New definitions apply their scene's track properties to the existing Track sibling **before entering the tree**, preserving scene references and initialization order, then supply greybox terrain and track-local features/items. There is one race controller for all circuits.
- `RaceSetup.circuit_id` survives validation, configuration Back, fresh restart and per-mode preferences. Invalid IDs fall back to the reference circuit. Launch remains cancellable and disposes the previous world/audio bindings. Circuit selection is after configuration, before Start Race; cards use existing keyboard/mouse/controller focus and scrolling.
- `CircuitMap` draws actual baked curve samples for both menu previews and the HUD, preserving XZ aspect ratio. Yellow marks start/player; white dots show AI. It reads interpolated kart positions for presentation without altering world transforms.
- TrackBuilder's opt-in elevation and banking use authored Curve3D height/tilt. Defaults retain the original flat behavior. Road cross-sections use normalized right vectors and slope normals; independent barriers and shoulders follow the authored height. These circuits have zero banking. The only elevated part is the developer-approved Figure-8 crossing.
- RacingLine acquisition includes vertical distance so the two crossing decks remain distinct; normal bounded-hint pursuit and curvature braking are retained. New-circuit safety bounds apply equally to all racers. No kart driving constants or camera/interpolation code changed.

`scenes/tracks/figure_8.tscn` and `scenes/tracks/yoshi_ds.tscn` are editable geometry scenes; run the main application to race them. Use the Remote scene tree while running to inspect generated mesh/collision nodes. `scenes/main.tscn` remains the original direct-run fixture.

## Reference audit and trace evidence

The supplied files were located and directly inspected before reconstruction:

| Circuit | Private source | Dimensions | Mapping / width |
| --- | --- | --- | --- |
| Figure-8 | `references/tracks/Figure 8/figure_8_overhead_map.png` | 1046 × 511 | 0.5 m/pixel; 15 m asphalt |
| GCN Yoshi (DS) | `references/tracks/Yoshi circuit/yoshi_circuit_overhead_map.png` | 512 × 542 | 0.75 m/pixel; 19.5 m asphalt |

Both references are overhead road maps. Their grey/dark asphalt boundaries, finish stripes, major corners and close route sections are visible. The Figure-8 diagonal occludes the horizontal straight. The developer explicitly approved a simple grade-separated crossing with conservative slopes. The upper deck reaches 7 m above the base; exact height/approaches are engineering assumptions, not a recovered Nintendo elevation profile. The route travels left from the horizontal finish, around the lower-left loop, over the diagonal and around the upper-right loop. No at-grade intersection or alternate route is added.

Yoshi's lower finish straight travels left, then turns right into the lower-left outline. The trace preserves the head/snout, upper lobe, back, inward elbow, long tail region, lower turns and limb. The central decorative island is not a shortcut. The supplied DS image is authoritative; no remake geometry was substituted. Supporting route descriptions corroborate the [Figure-8 bridge](https://www.mariowiki.com/Figure-8_Circuit) and [Yoshi's first right turn](https://www.mariowiki.com/GCN_Yoshi_Circuit); those descriptions do not determine the traced coordinates.

Normalized coordinates are `u=x/W`, `v=y/H`; world XZ is `((u−0.5)W, (v−0.5)H) × metres_per_pixel`. This preserves image aspect/orientation. Scale uses the existing 1.25 × 0.75 × 2.1 m kart and generous racing widths, not invented official track lengths. The resulting loops measure about **663.56 m** and **1188.52 m** in Turbo Riot units.

`resources/tracks/*_trace.json` records reviewed landmarks, normalized controls, elevations, handle tension and scale. `tools/build_circuit_traces.py` reproducibly emits the original Curve3D scenes. Figure-8 uses 35 landmarks. Yoshi starts with 82 landmarks; resampling and bounded-curvature spline fitting round meaningful corners rather than retaining pixel stair steps. Initial direct Catmull-Rom fitting produced folded inner edges at tight corners; those builds were rejected. The final fit constrains sampled cubic curvature before road generation and passes all face-winding/width/seam checks. It changes geometry rather than kart physics or AI authority. Runtime needs neither Python nor its offline Pillow/NumPy/SciPy dependencies.

Road widths are conservative constant-width approximations. The source's local width variation, exact elevation/banking, friction and original internal checkpoints cannot be recovered exactly from these images. The new gates, 7-kart grids and pickup fractions are original gameplay placements. New circuits do not inherit the original world's pads or optional ramp; original items, mushroom/mini-turbo boosts and drifting still operate. The reference circuit retains exactly its three blue-marker rows of four boxes, pads, ramp and segment-specific runoff.

## Reference comparison

`tests/capture_circuit.gd` captures native orthographic views with the same dimensions, orientation and image-to-world mapping as each source. Geometry-only screenshots are in `artifacts/v061_*_top.png`. `tools/compare_circuit_traces.py` generates the following **private, ignored** images under `references/analysis/`:

- `figure_8_annotated.png`, `yoshi_ds_annotated.png`: proposed centerline, sample markers and start/direction.
- `*_overlay.png`: source and native image blended at the common alignment.
- `*_comparison.png`: source plus trace beside native reconstruction.

Private sources/annotations remain under `references/`, excluded by Git, Godot import and export. No Nintendo bitmap, model, texture, music or game code is loaded by the game. New asphalt, terrain and barriers use original Turbo Riot geometry/materials. No bridges/tunnels/ramps are inferred for Yoshi. These educational layouts are not release-ready original content.

The public numeric report is `artifacts/v061_trace_comparison.json`. Generated centerline-to-manually-traced-landmark mean deviations are approximately **0.68 px** (Figure-8) and **1.14 px** (Yoshi); symmetric maxima **2.09 px** and **9.16 px**. These are fitting measurements against our own trace, **not independent proof of source accuracy**. Approximate source/native asphalt-mask overlap is **0.661 / 0.753 IoU**; that diagnostic also includes source buildings, markings, occlusion, width variation and differing materials. Final silhouette/width fidelity requires the developer's side-by-side review. The native renders were visually inspected by Codex; developer acceptance is not inferred.

## Validation and manual review

Run with Godot 4.7.2 Compatibility, using separate local settings for test fixtures:

```text
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script tests/run_tests.gd
godot --headless --path . --fixed-fps 60 --script tests/validate_circuit.gd -- --circuit=figure_8
godot --headless --path . --fixed-fps 60 --script tests/validate_circuit.gd -- --circuit=yoshi_ds
godot --headless --path . --fixed-fps 60 --script tests/run_ai_race.gd -- --circuit=figure_8 --laps=3 --items --item-seed=42 --difficulty=challenging --report-prefix=v061_figure
godot --headless --path . --fixed-fps 60 --script tests/run_ai_race.gd -- --circuit=yoshi_ds --laps=3 --items --item-seed=42 --difficulty=challenging --report-prefix=v061_yoshi
godot --path . --fixed-fps 60 --script tests/capture_circuit_menu.gd
```

Figure-8 geometry and a complete three-lap item race were validated **before Yoshi geometry began**. Seven racers finished both three-lap Challenging/item runs with no DNFs. Initial Figure-8 run: 36 pickups / 34 uses, two recoveries total. Yoshi: 30 pickups / 30 uses, zero recoveries. Reports preserve exact lap times/results. Native one-lap Time Trials completed on both circuits, without items or AI competitors, using injected AI commands for the human kart: Figure-8 **34.867 s**, Yoshi **77.633 s**, both zero recoveries. These are automated physical driving checks, not human/controller tests.

The expanded permanent suite passes **989 checks, zero failures**, covering geometry, projected crossing separation, grid spacing, directed gates, adjacent-route rejection, recovery, pickup anchoring, shared minimap data, configuration/selection, both modes and six switch/restart/menu cycles. Existing v0.2.0 checks and cumulative checks 1–119 remain unchanged; new manual criteria **120–151** are in the [canonical checklist](testing/ACCEPTANCE_CHECKLIST.md). Final engine/suite results are recorded in [validation](validation.md). The final Figure-8 rerun after normalized boundary cross-sections also passes, with 36 pickups, 35 uses and the same two total recoveries.

For manual review, run F5 → Quick Race or Time Trial → configure → Choose Circuit → select a card → Start Race. Confirm high-speed visual stability, bridge traversal/camera clearance, source comparisons, drifting/items/recovery, all AI difficulties and repeated transitions on real keyboard/controller hardware. Capture notes alongside checks 120–151. Physical controllers, human handling feel, different hardware/refresh rates, exported builds and long-duration memory profiling remain unverified. Curvature fitting is an approximation; exact original banking/elevations and width variation remain unavailable. Banking is an opt-in geometry capability, not a claim of full banked-track gameplay validation.

Original circuit development remains required within Testing Grounds. GCN Baby Park, Wario Stadium (DS) and Delfino Square (DS) are deferred; none is presented as playable. No version is marked released or accepted.
