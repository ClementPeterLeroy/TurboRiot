# Architecture and editing

## Scene composition

`main.tscn` composes the Track, Environment, Kart, ChaseCamera, HUD, sky and sun. `main.gd` derives the safe spawn from the curve's first point and forward tangent, resets the kart and handles reset/exit actions. There are no autoloads. Physics runs at 60 Hz; the camera and HUD update on rendered frames.

`kart.tscn` contains a CharacterBody3D, a box collision shape, primitive visual chassis/nose/seat/helmet/four wheels, and a PlayerInput child. The front is local **-Z** and has a yellow nose. Body layer 2 collides with static world layer 1. The wheel meshes are decorative; ground response is handled by the body rather than suspension.

## Driving

- `DrivingCommand` clamps throttle/brake to [0, 1], steering to [-1, 1], and maps nonfinite values to zero.
- `DrivingInput` defines `get_command()`. `player_input.gd` implements keyboard/gamepad input and registers semantic InputMap actions once at startup. A different provider can override this method without changing physics.
- `KartConfig` stores reusable exported handling parameters. `default_kart.tres` supplies the brief's defaults; each kart has an exported resource reference.
- `KartDynamics` contains pure longitudinal, damping and steering calculations, used directly by the tests.
- `KartController` projects velocity into forward/lateral components, adjusts longitudinal speed, exponentially damps slip, rotates with speed-sensitive steering, applies gravity, calls `move_and_slide()` and reduces retained velocity at walls. It never reads a keyboard or driving action. Falling below the world resets to the same safe spawn.

The opposite pedal stops movement first; reversing/forward movement starts on the next tick after zero. Brake wins if both pedals are held. Analogue pedal strength scales acceleration/braking. Coasting uses `move_toward` in units per second. Grip uses `exp(-grip * delta)`, so damping over equal elapsed time does not depend on tick rate. Steering fades to zero at rest, reverses sign when backing up and reduces authority toward maximum speed. Horizontal inertia is preserved through yaw, then corrected by grip on subsequent ticks.

The controller is intentionally simple: no suspension, banked-surface alignment, engine simulation, off-road penalty or drift state. Wall collisions slide rather than bounce. The full rendered wheel footprint is wider than the body collider; the collider is deliberately forgiving for an arcade prototype.

## Camera and HUD

The independent Camera3D has exported target, distance, height, look-ahead, FOV and smoothing rates. It exponentially follows the desired world position and slerps its rotation. The kart's `reset_performed` signal immediately snaps the camera. No camera collision avoidance is implemented; the flat open circuit and low barriers keep the initial view readable.

The CanvasLayer HUD reads the kart's actual horizontal velocity and signed forward velocity. F3 exposes position, floor state, FPS and normalized commands. Reset/exit stay in scene orchestration; they are not driving commands.

## Editing the circuit in Godot

1. Open **`scenes/track.tscn`** directly. Select its `Track` Path3D root.
2. Use the 3D path tools to move Curve3D points and their Bézier handles. Work in top view; units are metres. The saved resource is the source of truth, so commit/save the scene after edits.
3. The final point is an explicit duplicate of point zero. Keep its **position and in/out handles identical** to point zero when editing either end. This closure convention avoids relying on newer Curve3D closed-property versions. The builder refuses an open curve with a warning.
4. Keep all points/handles at Y = 0.04. The mesh is forced flat at that height, but changing source Y would distort its baked arc length and scenery queries.
5. Change **Road Width** (default 10 m), **Sample Spacing** (1.5 m), and **Barrier Spacing** (4 m) in the Track Inspector. Curve edits and property changes rebuild automatically. The **Rebuild** toggle requests a manual refresh; it is an action, not a saved flag.
6. Maintain bend radii larger than half the road width, avoid self-intersections, and leave at least road width + 3 m between neighboring centerline runs. The builder does not repair arbitrary intersecting layouts or bad offsets. Run the geometry tests after edits.
7. Point zero sets the start line and kart spawn; its outgoing tangent sets forward. Move this point and its duplicate to change the start. Main scene startup derives the spawn automatically.
8. Reopen `main.tscn` to inspect the whole world. The Environment node has a seed, tree count and Rebuild button. Refresh it after width-only edits to reevaluate tree clearance.

`TrackBuilder` samples the closed curve at equal arc-length intervals. Tangents produce lateral road offsets. An indexed ArrayMesh has explicit upward normals, clockwise triangle winding and trimesh collision. Road kerbs and start tiles are very thin noncollidable decoration. Barriers have visible box meshes and matching box collision shapes; posts/banner are noncollidable decoration outside/above the driving area.

`@tool` builders run in both editor and runtime. A rebuild removes and frees the old **Generated** subtree and creates exactly one replacement. Generated nodes have no scene owner, so they are not saved alongside the source curve. Opening the scene recreates them deterministically without accumulating duplicates. Do not edit generated children; modify the source settings instead. Exported scenes rebuild from the same source.

## Environment and assets

`RiotGeometry` shares original primitive creation helpers. `EnvironmentBuilder` uses a local seeded RandomNumberGenerator, a sand floor, flat grass islands, cone trees and distant polygonal hills. Trees avoid the curve by half the road width plus 6 m. Scenery has no hidden obstacle colliders; only the floor and visible track barriers/road collide. World ground spans 360 × 320 m; enlarge it and move the scenery ring for larger replacement layouts.

The supplied overhead image is isolated under `references/.gdignore` and is never loaded by a game scene. Review screenshots are likewise isolated under `artifacts/.gdignore`.

Godot API reference: [Curve3D](https://docs.godotengine.org/en/stable/classes/class_curve3d.html), [editor tool scripts](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html).
