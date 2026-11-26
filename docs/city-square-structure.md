# City Square — annotated structural refinements

2026-11-27. **v0.6.1-dev, Unreleased, pending developer acceptance.** Implements `feedback_city_square.png` in the private reference layout folder. No decoration pass, circuit redesign or new milestone is introduced.

## Preserved content and targeted edits

All **three curves retain every original X/Z point and handle**, verified against pre-edit SHA-256 snapshots. The lap footprint, branches, corners, fountain, avenue, garden paths and harbour centreline remain recognizable and unchanged horizontally. Only city-street elevations are redistributed. Three-dimensional lap length becomes approximately **1,160.98 m**. Checkpoint stations, widths and runoff stations are remapped to the same physical locations after that small arc-length change.

All **six approved house GLBs and six Blender masters**, plus the fountain model/master, remain **byte-identical**. All **79 retained houses** preserve their models, X/Z positions and yaw. Some stair-side houses move vertically to match the redistributed grade and receive separate stone footing extensions. [Preservation report](../artifacts/v061_city_structural_preservation.json).

The edit opens the existing site masters and changes only requested objects; it does not run the initial whole-site generator:

- **Black harbour annotation:** removed `HarbourIsland`, its collision, and `Harbour00`–`Harbour02`. Water is visible inside the U. Timber platforms widen **13 → 19.5 m**, exactly 50%, following the existing centreline and corners. Beams, crossbeams and piles move outward. Saved collision matches the wider decks; inner and outer water edges have no rail, invisible wall or support floor.
- **Red architecture:** added **38 house instances** and **12 named groups of roofed architectural links** around the fountain, city entrances/outer streets/interior blocks, harbour descent, central coast, garden-town boundary and avenue entrance. Links close curved/corner gaps with stucco, stepped foundations, pitched terracotta roofs, shuttered windows and sills. Shared facade/roof palettes divide long frontages into warm-toned sections. Actual road openings are cut out of these footprints, rather than blocked with building masses. Existing street houses are retained. Some existing coast/garden corner faces sit up to 5 m behind the land boundary; they are preserved rather than moved merely to match a line.
- **Purple background annotation:** removed **53 rear `Block*` houses** and their native instances/collision. The avenue's first row and underlying terrain remain. No replacement background assets were added. Total house count is now **117** (135 − 53 − 3 + 38), with separate architectural-link groups.
- **Orange stairs:** one long left flight and three shorter right flights now have straight visible treads, clear of the four corner/junction footprints. Collidable paving remains continuous inclined support. Both streets still descend **5.4 m**, +8.2 → +2.8 m. Flight lengths/locations are in the saved structural plan; maximum designed grade is about 0.214 (roughly 12 degrees). No kart climbing, snap, gravity or handling constants changed.
- **Garden accessibility:** replaced the low flat grass face with constrained, graded triangles sharing the actual path edges. Grass is cut away beneath paving, avoiding competing coincident surface tags. Terrain under changed roads/grass is kept below support; separate visible footings support nearby buildings. Existing grass slowdown/grip, checkpoint ordering, travel validation, recovery and surface detection remain.

The two stair-route lengths are now approximately **120.331 / 120.225 m**. Their 0.107 m difference is below 0.1%; the old 1 cm test tolerance was replaced with a 25 cm near-equality limit because the approved straight-flight elevation redistribution changes 3D arc length while all horizontal coordinates remain identical. Matching manual traversal time still requires developer review.

## Geometry diagnosis and verification

The full suite caught a junction issue during implementation that the isolated stair traversals did not reveal. A nearest-centreline height delta was being applied to overlapping road faces from different original levels, lowering part of the left merge almost a metre too far. The corrected edit classifies original upper/lower faces and maps actual upper support to the new union surface, keeping lower faces below it and removing collapsed faces. The original committed paving master was read and hash-checked against the task baseline before this correction; no Git state was modified. At the reproduced point the final floor is **Y≈2.800001**, matching the new **2.8 m** route. The failed intermediate test/AI results are summarized in [the diagnosis record](../artifacts/v061_city_structural_diagnosis.json); they do not count as successful verification.

The permanent structural suite checks:

- Three curve point/handle hashes; preserved frontages; removed island/background groups; all 12 architectural groups.
- Horizontal collision rays along each marked boundary outside genuine road openings. Every sampled ray reaches architecture, within 4 m on street boundaries and 5 m at preserved coastal/garden corner transitions. This checks physical continuity, not artistic approval of every joint.
- Real support beyond the old dock width, open water in the former island, falls/recovery from **both** widened dock edges without awarded progress.
- All four stair flights **uphill and downhill**, **zero airborne frames**, stopping halfway, accelerating again and reversing uphill. Actual tread centers form straight lines and their bounds avoid junction footprints.
- **11 open garden crossings**: drive from grass onto paving, restore asphalt detection, then drive off the path onto real slowing grass. A path behind the intentional avenue frontage is excluded only after a body-height ray identifies a real building; terrain/road lips are never excluded this way.

See [current measurements](../artifacts/v061_city_structure_physics.json) and [full validation](validation.md) for actual suite/race/camera/performance results. All earlier handling, jump/contact, presentation, item and circuit regressions remain enabled.

## Editing and file organization

- `resources/tracks/city_square/structural_plan.json`: named annotation zones, dock width, flight ranges, garden boundary and pre-edit horizontal hashes. `survey.json` retains mapped source sections, height edits and flight endpoints.
- `assets/environment/city_square/sources/driving_surfaces.blend`: existing paving, locally re-levelled; widened timber mesh. `stairs_and_dock_structure.blend`: four straight flights and widened supports. `coast_and_terrain.blend`: island removal and compatible garden terrain. **Unaffected models are not regenerated.**
- New `architectural_links.blend/.glb`: 12 named, editable boundary meshes with shared facade/window/roof materials. Individual houses remain native instances of the original six modules. The new groups are ordinary saved geometry, not runtime generated barriers.
- `scenes/environment/city_square/environment.tscn`: retained instances plus additions/removals, visible footings and matching saved collision. `scenes/tracks/city_square.tscn` keeps Ground's local transform at identity.
- `tools/refine_city_routes.gd`, `refine_city_structure.py`, `apply_city_structure.gd`: one-shot offline refinement operations. Their revision guards prevent accidental repeat application. Initial route/site generators also refuse to overwrite this authored refinement. Do not remove these guards casually after artist edits.
- For normal iteration, edit the relevant existing master or native instance, explicitly export GLB, run Godot import, then use `tools/refresh_city_collision.gd` to refresh the existing saved collision shapes without rebuilding architecture. Run the permanent suite and inspect the result through **F5 → City Square**, not F6 on the environment-only authoring scene.

No boats, vegetation, furniture, signage, animated water, particles, audio, pads or other decorative content are added. The roadmap/version metadata remain unchanged. New manual criteria **231–244** preserve all earlier checks. Review all corners, foundation/roof joins, both dock edges, grass edges, sustained target-device performance and an exported build before acceptance. No staging, commits, pushes, tags or GitHub operations.
