# Architecture and editing

## Scene composition

`main.tscn` composes the Track, Environment, Kart, RaceManager, ChaseCamera, HUD, sky and sun. `main.gd` routes start/restart/recover/exit actions. RaceManager derives the initial spawn and orchestrates race rules without implementing kart physics or camera math. There are no autoloads. Physics runs at the default 60 Hz; the camera and HUD update on rendered frames.

`kart.tscn` contains a CharacterBody3D, a box collision shape, primitive visual chassis/nose/seat/helmet/four wheels, and a PlayerInput child. The front is local **-Z** and has a yellow nose. Body layer 2 collides with static world layer 1. The wheel meshes are decorative; ground response is handled by the body rather than suspension.

## Driving

- `DrivingCommand` clamps throttle/brake to [0, 1], steering to [-1, 1], and maps nonfinite values to zero.
- `DrivingInput` defines `get_command()`. `player_input.gd` implements keyboard/gamepad input and registers semantic InputMap actions once at startup. A different provider can override this method without changing physics.
- `KartConfig` stores reusable exported handling parameters. `default_kart.tres` supplies the brief's defaults; each kart has an exported resource reference.
- `KartDynamics` contains pure longitudinal, damping and steering calculations, used directly by the tests.
- `KartController` projects velocity into forward/lateral components, adjusts longitudinal speed, exponentially damps slip, rotates with speed-sensitive steering, applies gravity, calls `move_and_slide()` and reduces retained velocity at walls. It never reads a keyboard or driving action. `driving_enabled` locks horizontal motion/input before GO and after finishing, while retaining ground/gravity behavior. KartRecovery handles falls and manual recovery separately.

The opposite pedal stops movement first; reversing/forward movement starts on the next tick after zero. Brake wins if both pedals are held. Analogue pedal strength scales acceleration/braking. Coasting uses `move_toward` in units per second. Grip uses `exp(-grip * delta)`, so damping over equal elapsed time does not depend on tick rate. Steering fades to zero at rest, reverses sign when backing up and reduces authority toward maximum speed. Horizontal inertia is preserved through yaw, then corrected by grip on subsequent ticks.

The controller is intentionally simple: no suspension, banked-surface alignment, engine simulation, off-road penalty or drift state. Wall collisions slide rather than bounce. The full rendered wheel footprint is wider than the body collider; the collider is deliberately forgiving for an arcade prototype.

## Camera and HUD

The independent Camera3D has exported target, distance, height, look-ahead, FOV and smoothing rates. It exponentially follows the desired world position and slerps its rotation. The kart's `reset_performed` signal immediately snaps the camera. No camera collision avoidance is implemented; the flat open circuit and low barriers keep the initial view readable.

The CanvasLayer RaceHUD reads the kart's actual horizontal/signed velocity and RaceSession's timers/lap data. Normal telemetry is shown during countdown/racing. A centered panel handles READY and FINISHED, and a large independent label handles countdown/GO. Results list all laps in a scrollable area, best lap and final time. Buttons call RaceManager methods. F3 uses a separate debug panel and toggles gate geometry. Recovery/exit/restart remain application actions, not driving commands.

## Race lifecycle and timing

`RaceSession` is a RefCounted deterministic model: state, one countdown value, ordered checkpoint cursor, lap results and timing. `RaceManager` is a scene Node that owns the session, resolves generated gates, samples the kart position each physics tick and updates the kart's driving lock/safe transform. The single-player scene uses one manager/session; another driver could use the same model later without a singleton or device dependency. This patch does not implement competitors.

```text
READY --Start Race--> COUNTDOWN --3 seconds / GO--> RACING --validated final lap--> FINISHED
  ^                       |                           |                             |
  +-----------------------+---------------------------+------ Return to Ready -------+
                          ^                                                         |
                          +-------------------- Restart Race -----------------------+
```

Start Race is ignored outside READY. Restart is explicit from any state and clears the session before beginning one fresh countdown. No asynchronous countdown tasks, Timer nodes or coroutines can survive a restart. Return to Ready resets the model and grid position without starting a countdown.

The manager advances the session once per physics tick. Before GO and after FINISHED, clocks do not advance. On the exact tick that countdown reaches zero, the manager emits RACING/GO and unlocks the kart; race time begins at zero and advances on subsequent active ticks. Total time is accumulated physics delta, not wall-clock time or displayed frame count. Lap time is total minus the last accepted lap boundary. Finish timing is quantized to a physics tick (about 16.7 ms at 60 Hz). If the app stops delivering physics ticks, the clock does not compensate for wall time. No pause/real-time competitive timing system is introduced.

Completed lap durations are the sole source for last/best/results. Final time is frozen on the final valid finish crossing. Restart clears total, current, last, best, final, results, countdown and checkpoint cursor. HUD formatting truncates to milliseconds; no persistent records are written.

## Directional checkpoints

`scenes/checkpoint.tscn` is a reusable CheckpointGate Node3D with an optional translucent debug mesh. It is a bounded plane rather than an Area3D: this equivalent swept implementation checks the segment between successive physics positions, so a high-speed kart cannot tunnel through a thin trigger. Detection is separate from its optional visual representation.

TrackBuilder creates `Generated/Checkpoints`: finish index 0 plus 11 ordered gates by default. **Checkpoint Count** includes finish and is editable. Gates are distributed by curve arc length, transformed along the local tangent, road-wide and 4 m high. The approach side is local +Z, race forward is local -Z. A forward crossing requires positive previous Z and nonpositive new Z; the intersection must be within width and vertical bounds. Reverse/side entries, standing on the plane, and remaining past it are rejected. Crossings in one segment are processed by intersection fraction rather than node order.

The session accepts only the expected numbered gate. Wrong order/repetition leaves the cursor unchanged. All numbered gates are required before finish 0 can award a lap, and a backwards finish never awards one. Initial spawn/finish crossing is ignored because the initial cursor expects gate 1. Three valid finishes complete the default race; **Lap Count** is exported on RaceManager. Optional debug gates are visible through F3 in gameplay or **Show Checkpoints** on Track in the editor.

## Recovery versus restart

`KartRecovery` lives under Kart and observes the body, with configurable fall height (-8 m), cooldown (1 second), and wall-jam duration (5 seconds; zero disables that detector). R/Pad Y requests recovery. Automatic fall recovery uses the same path. A wall jam requires sustained throttle > 0.5, brake < 0.1, steering magnitude < 0.2, speed < 0.4 m/s, grounded state and an actual near-horizontal wall collision. It deliberately avoids guessing about other stuck situations.

After each accepted gate, RaceManager assigns `kart.safe_spawn` to that gate's center, 2 m forward and 0.65 m above the road, facing its tangent. Before any numbered gate is validated, recovery uses the grid spawn 4 m behind the finish. Recovery clears velocity/commands and emits the existing reset signal; the independent camera snaps immediately. A cooldown prevents repeated recovery. The latest valid checkpoint and all timing/lap data are preserved; the active clock keeps running.

Every supported teleport emits `reset_performed`, which also resamples RaceManager's previous position. A reset cannot create a swept crossing from the old position to a new checkpoint. Restart always restores the initial grid spawn, replacing checkpoint state and timing. External scripts that directly change the kart transform must use/reset through this API rather than silently teleporting it. Recovery in READY/countdown/finished cannot unlock the kart or award progress.

## Editing the circuit in Godot

1. Open **`scenes/track.tscn`** directly. Select its `Track` Path3D root.
2. Use the 3D path tools to move Curve3D points and their Bézier handles. Work in top view; units are metres. The saved resource is the source of truth, so commit/save the scene after edits.
3. The final point is an explicit duplicate of point zero. Keep its **position and in/out handles identical** to point zero when editing either end. This closure convention avoids relying on newer Curve3D closed-property versions. The builder refuses an open curve with a warning.
4. Keep all points/handles at Y = 0.04. The mesh is forced flat at that height, but changing source Y would distort its baked arc length and scenery queries.
5. Change **Road Width** (default 10 m), **Sample Spacing** (1.5 m), and **Barrier Spacing** (4 m) in the Track Inspector. Curve edits and property changes rebuild automatically. The **Rebuild** toggle requests a manual refresh; it is an action, not a saved flag.
6. Maintain bend radii larger than half the road width, avoid self-intersections, and leave at least road width + 3 m between neighboring centerline runs. The builder does not repair arbitrary intersecting layouts or bad offsets. Run the geometry tests after edits.
7. Point zero sets the finish plane/start line; its outgoing tangent sets forward. Move it and its duplicate to change the start. The grid spawn is derived 4 m behind it. Checkpoint/recovery transforms follow the source curve automatically.
8. Reopen `main.tscn` to inspect the whole world. Environment has a seed, tree count, Infield Outline and Rebuild button. Track rebuild signals refresh the scenery, including width-only edits. Edit the grass footprint separately when replacing the circuit. A runtime track rebuild returns the race to READY with fresh gate references.

`TrackBuilder` samples the closed curve at equal arc-length intervals. Tangents produce lateral road offsets. An indexed ArrayMesh has explicit upward normals, clockwise triangle winding and trimesh collision. Road kerbs, start tiles and grid marks are thin noncollidable decoration; posts/banner are also decoration outside/above the driving area.

`BarrierMesh` creates one unit mesh with four triangles per faceted face. The raised face centers and vertex shades form an X; no reference texture is used. Approximately 1.2 m blocks follow both boundaries, using the same mesh in four MultiMesh batches with shared red/blue/yellow/green materials. That is four colour-batch draws per render pass rather than a draw per block (shadow passes add their own work). A separate static body has simple box segments at the configured Barrier Spacing. The faceted triangles are never used for collision; boxes approximate the small face protrusion and follow the same boundary. Keep collision spacing reasonable on tight bends.

`@tool` builders run in both editor and runtime. A rebuild removes and frees the old **Generated** subtree and creates exactly one replacement. Generated nodes have no scene owner, so they are not saved alongside the source curve. Opening the scene recreates them deterministically without accumulating duplicates. Do not edit generated children; modify the source settings instead. Exported scenes rebuild from the same source.

## Environment and assets

`RiotGeometry` shares original primitive creation helpers. EnvironmentBuilder uses a local seeded RandomNumberGenerator, sand floor, editable triangulated grass footprint traced from the overhead, shared rounded low-poly tree crowns and shared sphere-based hills. Tree trunks/crowns remain simple original geometry. Trees avoid the curve by half the road width plus 6 m. Scenery has no hidden obstacle colliders; only the floor and visible track barriers/road collide. The infield lies above sand and below asphalt without a collider. World ground spans 360 × 320 m; enlarge it and move the scenery ring for larger replacement layouts. Queued rebuilds are coalesced.

All three supplied images stay isolated under the existing `references/.gdignore` and Git ignore rule and are never loaded by game scenes. The brief's suggested `docs/references/circuit_01/` does not exist in this checkout. Review screenshots are isolated under `artifacts/.gdignore`.

Godot API reference: [Curve3D](https://docs.godotengine.org/en/stable/classes/class_curve3d.html), [editor tool scripts](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html).
