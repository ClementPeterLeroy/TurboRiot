# City Square — avenue, street and checkpoint corrections

2026-11-27. **0.6.1-dev, Unreleased, pending developer acceptance.** The developer approved the house designs and requested editor stability, avenue access, wider joined street frontages, finish-line contact and broader checkpoints. No milestone or release is advanced.

## Actual changes

- City streets and both stair routes are now **20 m wide**, twice their initial 10 m. The avenue and fountain approaches retain **22 m**; timber decks remain 13 m and garden paths 10 m. Stair treads span the wider physical surface. The centerline topology is preserved; the avenue finishes its climb before the broad plaza junction, reaching +10.5 m without a raised entry lip.
- Removed the previous sampled avenue-end houses, including the obstructing fork-side placement. Replaced sampled frontage spacing with explicit continuous terrace blocks: consecutive lots share party-wall planes and reserve real intersections. Placement follows the baked road envelope and checks full footprints, rather than testing only road centers against a house rectangle. **135 native house instances** remain. Openings at road junctions are intentional; there are no empty intermediate lots inside a terrace row.
- All **six approved house GLBs and six Blender masters are byte-identical** to their pre-correction copies. Existing corner-house modules provide the two-faced corner vocabulary; no replacement house style was introduced. [Preservation hashes](../artifacts/v061_city_feedback_house_preservation.json). Other city site meshes/placements are rebuilt offline with `tools/build_city_square.py -- --site-only --replace-generated`; artist-edited house sources are skipped by that mode.
- The avenue's last checkpoint moves before the fountain fork, at canonical station **110 m**. Both avenue gates have explicit 11.5 m left/right extents to accept the full 22 m road. The source curve and existing ordered checkpoint rules remain authoritative.
- The garden's existing grass polygon now supplies connected runoff extents to both legality/progress corridors and checkpoint widths. Garden tests exercise real grass beyond the paved road. This does not extend support across water or remove ordering, directional crossing, route-window, travel or teleport checks. Road width and checkpoint/runoff coverage are separate metadata.

## Start-line and avenue diagnosis

The original start-line fixture reproduced a **4.415 m frame displacement**, including approximately **4.4 m sideways**, on the center lane at about 22 m/s. Reported contacts belonged to `PavedStreetsCollision`; this was solver displacement, not the recovery system teleporting the kart. The solid road's first and last sections met at coincident end caps. Those internal faces could survive the boolean union at the finish. The final road section now overlaps the first two samples before union, removing the touching-cap seam instead of changing kart physics or hiding it through camera smoothing.

The same three-lane physical fixture now crosses the finish and plaza entry with approximately **0.367 m maximum motion per 60 Hz tick**, near-zero lateral shift and normal speed. [Current contact measurements](../artifacts/v061_city_feedback_contact.json). Permanent regressions fail on a large step, sideways shift, stopped kart or incomplete traversal.

The avenue entrance also had missing paving near its narrowing/fork: old edge rays dropped from approximately +10.49 m to town support at +9.62 m. A kart could drop off the edge and meet the road's side as a curb. Widening the fork closes those gaps. The level landing now begins before the expanded plaza/branch footprint, preventing the flat plaza from cutting a vertical lip into the rising avenue. Post-correction edge probes and physical traversals pass; no artificial invisible ramp/barrier was added.

## Editor crash investigation

Opening `scenes/tracks/city_square.tscn` initially reproduced a **native signal-11 crash** on Godot 4.7.2 / OpenGL Compatibility. There was no GDScript exception identifying a failing line. Headless opening, isolated environment opening and isolated track-helper opening passed; a subsequent full opening also passed before hardening. This makes the original fault intermittent, and **does not prove a particular script or GPU driver was its root cause**.

The editor-time imported hierarchy plus tool-generated helper/material initialization is the area being hardened: AuthoredCircuit now defers editor helper creation until insertion is complete, resets its inherited queued-build flag, and material re-entry reuses existing overrides instead of cloning overrides again. Runtime still builds synchronously before race consumers bind checkpoints. Tests verify two successive rebuilds and material identity on re-entry.

`tools/validate_city_editor.py --godot <console-executable>` opens the actual full scene in the **native editor three times**, bounds each process lifetime and records exit/errors in [the editor report](../artifacts/v061_city_feedback_editor.json). Three final openings exited 0 without unexpected errors. This is stronger than headless import alone, but it does not establish that the intermittent crash can never recur. Reopen the corrected scene in the developer's normal editor session before accepting this fix. The known Windows certificate-store warning remains unrelated to scene geometry.

## Validation and manual acceptance

Current automated, native-lap, race and performance results are recorded in [validation.md](validation.md). The final 60 Hz headless regression suite includes full-width road support, joined frontage lots, full avenue gate crossings, genuine grass checkpoint/legality checks, six physical finish/plaza traversals, repeatable rebuilds and idempotent materials. Existing circuits and prior handling/presentation/item regressions remain enabled.

The initial AI stair-sector timing imbalance is improved in the current fixture: **9.3667 s outer / 9.4000 s inner**, both without recovery, including the fork/merge approaches. Both routes remain approximately **120.1593 m** and descend 5.4 m. [Current times](../artifacts/v061_city_stair_times.json); [initial times](../artifacts/v061_city_initial_stair_times.json) remain separate. This single-profile test does not replace manual time/feel comparison.

Inspect [avenue](../artifacts/v061_city_avenue.png), [fountain](../artifacts/v061_city_fountain.png), [city](../artifacts/v061_city_city.png) and [overview](../artifacts/v061_city_overview.png). The captures show the current assembly. Cumulative manual checks **222–228** append to 1–221. Verify both road edges, late-lap finish crossings, all grass approaches, party-wall/corner seams, developer-session editing and sustained performance before acceptance.

Files changed: city layout/curves/survey/widths/track scene; city driving/terrain/stair site sources and GLBs; native environment placement/collision; AuthoredCircuit and material tool; the base checkpoint-limits hook; author/bake/build/assembly outputs; editor/feedback/native-lap test helpers and documentation. No existing circuit geometry, house model design, kart driving/camera constants, version metadata or Git state was intentionally changed. No staging, commits, pushes, tags or GitHub operations.
