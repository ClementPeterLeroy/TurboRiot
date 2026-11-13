# Bikini Bottom curve-road export diagnosis

2026-11-13. Source inspected: `resources/tracks/Bikini_bottom/Blender/bikini_bottom_test.blend`. This is an export correction only; no circuit layout, Blender source, racing code or existing scene reference is changed.

## Cause

`BikiniBottom_test_v1` is a CURVE object with the `GeometryNodes_Elevation` modifier. Its evaluated result has 3,072 vertices and 1,536 faces, but both `bikini_bottom_environment_v01.glb` and `bikini_bottom_test_track.glb` contain a node of that name with **no mesh reference**. Buildings and seabed do have mesh references. This is missing exported geometry, not merely a missing Godot material. A scene-tree Node3D cannot display mesh geometry it does not contain.

Blender's glTF documentation explains that curves/non-mesh data need mesh conversion for export. In the locally installed exporter, Apply Modifiers is described as applying modifiers to mesh objects; do not assume toggling it alone converts a curve-generated road. See [Blender glTF manual](https://docs.blender.org/manual/en/dev/addons/scene_gltf2.html).

## Corrected export and validation

Created a separate export at `resources/tracks/Bikini_bottom/Exports/bikini_bottom_test_track_mesh.glb`. A background Blender process opened the saved source with auto-execution disabled, converted only the road to a mesh in memory, exported visible/renderable geometry with modifiers enabled, then exited **without saving the .blend**. File SHA-256 was identical before/after that process. Original curve, node setup, material/placement data and previous exports remain intact.

The corrected GLB includes a mesh primitive for `BikiniBottom_test_v1`, with 3,072 vertices and road bounds X −224.544…214.568 m, Y −12.004…10.002 m, Z −139.068…85.941 m in glTF/Godot coordinates. Validation also loads the corrected GLB through Godot and checks that the road is a MeshInstance3D with a nonempty mesh surface. This is an import/geometry check, not a full driving or performance qualification.

The export includes visible/renderable geometry, excluding hidden helpers and cameras/lights. It reflects the saved Blender file, not unsaved edits in the owner's open Blender session. It does not include collision generation or replace the old blockout in the driving test scene; that integration must update collision and road bindings together.

## Repeat manually without destroying the editable road

1. Save the environment in Blender. Select `BikiniBottom_test_v1` in Object Mode.
2. Duplicate it with Shift+D, then cancel the move with right-click so its position is unchanged.
3. Convert **the duplicate only** using Object → Convert → Mesh. Preserve the original curve and Geometry Nodes setup.
4. Select the converted road plus the intended buildings/seabed/other runtime objects. Export GLB with Selected Objects and Apply Modifiers enabled. Exclude the original curve and modeling helpers from this export selection.
5. Remove the temporary export duplicate after exporting to avoid two overlapping road surfaces in Blender. Keep the authoritative editable curve.
6. In Godot, inspect the new GLB: the road must be a MeshInstance3D with a mesh, not just a Node3D. Preview geometry before adding physics or swapping it into an existing driving scene.

For the long-term pipeline, automate evaluated road conversion in the export/import process rather than maintaining a permanent hand-edited mesh copy beside the curve. The owner retains full geometry authorship. No Git mutations or version changes accompany this correction.
