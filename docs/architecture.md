# Architecture and editing

## Scene composition

`main.tscn` composes Track, Environment, TrackFeatures, Kart, RaceManager, ChaseCamera, HUD, sky and sun. `main.gd` routes start/restart/recover/exit actions. RaceManager derives the initial spawn and orchestrates race rules without implementing kart physics or camera math. There are no autoloads. Physics runs at the default 60 Hz; camera, visual feedback and HUD update on rendered frames.

`kart.tscn` contains a CharacterBody3D, box collision shape, primitive visual chassis/nose/seat/helmet, four wheel pivots with spinning tyre children, PlayerInput and Recovery. The front is local **-Z** with a yellow nose. Body layer 2 collides with static world layer 1. Layer 4 (bit mask 8) is reserved for non-solid surface regions/triggers. Wheel animation and body lean/pitch are cosmetic, not suspension or physical body rotation.

## Driving

- `DrivingCommand` clamps throttle/brake to [0, 1], steering to [-1, 1], maps nonfinite values to zero and carries a drift-held boolean.
- `DrivingInput` defines `get_command()`. `player_input.gd` implements keyboard/gamepad input and registers semantic InputMap actions once at startup. A different provider can override this method without changing physics.
- `KartConfig` stores handling, drift/charge/turbo, boost policy, surface smoothing/probe, airborne steering and landing parameters. `default_kart.tres` retains the original base defaults; new defaults live on its script and remain editable in the Inspector.
- `KartDynamics` contains pure longitudinal, damping and steering calculations, used directly by the tests.
- `KartController` projects velocity into forward/lateral components, adjusts longitudinal speed, exponentially damps slip, rotates with speed-sensitive steering, applies gravity, calls `move_and_slide()` and reduces retained velocity at walls. It never reads a keyboard or driving action. `driving_enabled` locks horizontal motion/input before GO and after finishing, while retaining ground/gravity behavior. KartRecovery handles falls and manual recovery separately.

The opposite pedal stops movement first; reversing/forward movement starts on the next tick after zero. Brake wins if both pedals are held. Analogue pedal strength scales acceleration/braking. Coasting uses `move_toward` in units per second. Grip uses `exp(-grip * delta)`, so damping over equal elapsed time does not depend on tick rate. Steering fades to zero at rest, reverses sign when backing up and reduces authority toward maximum speed. Horizontal inertia is preserved through yaw, then corrected by grip on subsequent ticks.

The controller composes the SurfaceDetector, DriftController and BoostController models described below. There is no realistic suspension or engine simulation. The body remains upright/yaw-controlled, while visuals pitch to slopes and lean into drift. Walls slide rather than bounce. The rendered wheel footprint is wider than the deliberately forgiving box collider.

## Surface configuration and detection

`SurfaceConfig` is a reusable resource with identifier, acceleration/max-speed/grip/resistance multipliers, debug colour and optional particle identifier. The four resources in `resources/surfaces/` define asphalt (1/1/1), grass (0.75/0.75/0.70) and sand (0.60/0.60/0.55), plus boost-pad surface identity with normal road multipliers. Resistance is 1/1.35/1.7 for asphalt/grass/sand. Strength/duration of a pad's boost is separate from its surface identity.

The procedural asphalt trimesh and sand/shoulder colliders are explicitly tagged with SurfaceConfig metadata. SurfaceDetector casts a physical ground ray against layer 1, excluding the kart. It then queries layer 4 regions: a CollisionPolygon3D extruded from the actual grass footprint over continuous sand support, or an Area3D over a boost pad. Grass overrides sand only; it cannot accidentally replace a tagged road/ramp. A boost region takes precedence over supporting asphalt. Detection never infers physics from material colours. The grass polygon avoids adding a new collision ledge at the visible grass/sand border.

Candidate changes must persist for `surface_debounce` seconds (0.06 by default). Four effective multipliers blend exponentially using `surface_smoothing` (8/s). No physical support in ray range preserves the last surface while airborne. Surface identity and effective handling are distinct: F3 reports the accepted identifier, while its properties settle smoothly.

KartDynamics accepts effective multipliers without mutating KartConfig. Pedals/braking/reverse retain their existing semantics. When terrain or an expiring boost lowers the allowed forward speed, excess is removed with `overspeed_deceleration * resistance` per second rather than clamping. Opposite pedals retain explicit braking authority. Reverse caps use the surface multiplier, not boost strength. Lateral grip is the base grip times effective terrain grip, and reduced again while drifting.

## Drift and mini-turbo state

`DriftController` is a deterministic RefCounted model. It receives normalized commands and observed forward/lateral speeds, contact and interruption information; it reads no devices. Entry requires ground contact, forward speed >= 8.5 m/s, steering magnitude >= 0.3 and drift held. While held, it preserves controlled steering/countersteering; steering is multiplied by 1.18 and grip by 0.28 by default. No fixed curve or forced orientation snap is used.

Charge advances only with valid steering, speed, ground contact and at least 0.65 m/s lateral slip. Straight-line button holding cannot charge. Default positive increasing thresholds are 1.0/2.0/3.5 valid seconds. Keeping an active drift with momentarily neutral steering retains its state but adds no charge. A release grants a tier only if current activity is still valid. Speed loss, air, severe impact, reset or a release without valid activity clears charge without a reward. Severe collision is measured from the incoming velocity into a near-horizontal wall normal; awards are applied only after collision/contact validation.

Mini-turbo forward-cap multipliers are 1.18/1.30/1.45 with durations 0.65/1.0/1.5 s. BoostController stores source, multiplier and remaining time, advanced once per active movement tick. KartConfig's default **STRONGEST_WINS** policy ignores weaker requests; equal/stronger requests use the new source/strength and the longer remaining duration. Alternative **REPLACE** overwrites both. Nothing adds source strengths or permanently changes a base parameter. Active boosts multiply acceleration by 1.8 and the allowed forward cap by their strength; expiry restores the normal cap smoothly through excess-speed deceleration.

`kart_visuals.gd` animates wheel pivot steering and tyre spin, body lean/slope/air pitch, world-space CPU tyre dust/smoke and a primitive boost exhaust. Blue/gold/purple smoke indicates charge tiers. RaceHUD adds a small charge gauge/level and active boost feedback; F3 separately reports surface, speed, contact, drift, charge, source and remaining duration. These effects do not drive physics.

## Boost pads, ramps and air

`scenes/boost_pad.tscn` is an editor-visible procedural directional pad. Its non-solid Area3D recognizes karts by their shared controller, requires ground contact/active driving and requests a normal BoostController effect. A per-kart latch permits one request per entry (even if a stronger boost ignores that request), and a physics-time cooldown controls re-entry. Remaining inside cannot repeatedly boost. Reset callbacks suppress immediate retriggers at an occupied recovery point. Strength/duration/cooldown are exported; use its Rebuild Inspector action after changing dimensions.

`scenes/ramp.tscn` authors a wedge from width, length and height, with visible incline/stripes and corresponding trimesh collision tagged asphalt. Keep inclines below CharacterBody's floor-angle limit; the default is 1.3 m rise over 7 m length. There is **no jump impulse or contact-triggered jump**. Grounded velocity projects onto the floor tangent, and actual ground motion supplies vertical momentum at takeoff. Air retains horizontal inertia, applies gravity and reduces heading yaw to 20%; throttle/grip do not manufacture or rotate horizontal air momentum. Landings restore floor motion without bounce, with 0.98 horizontal retention for impacts above the soft-landing threshold. The physical body remains upright; extreme unexpected tilt goes through recovery.

TrackFeatures deterministically places two pads at 55%/81% arc fractions and one ramp at 56%, 9 m outside the long left straight. The optional ramp has a clear approach/landing apron and does not alter the saved circuit or checkpoint order. Track rebuilds replace one Generated feature subtree; the reusable scenes also work independently. No new full circuit is introduced.

## Camera and HUD

The independent Camera3D retains target, distance, height, look-ahead, FOV and exponential position/rotation smoothing. A terrain obstruction ray shortens its desired position, with a height floor, while ascent/landing remain smoothed. The reset signal immediately snaps it. This is a lightweight ray solution, not a swept camera volume; tight corners may still require tuning.

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

`KartRecovery` lives under Kart with fall height (-8 m), world-space safety half-extents (178/158 m), cooldown (1 second), upright-angle limit from KartConfig, and wall-jam duration (5 seconds; zero disables that detector). R/Pad Y and automatic bounds/fall/tilt recovery use the same path. Safety bounds are independent of road, kerbs and physical barrier openings; adapt them and the perimeter/terrain size together for original worlds. A wall jam requires sustained throttle > 0.5, brake < 0.1, steering magnitude < 0.2, speed < 0.4 m/s, grounded state and an actual near-horizontal wall collision.

After each accepted gate, RaceManager assigns `kart.safe_spawn` to that gate's center, 2 m forward and 0.65 m above the road, facing its tangent. Before any numbered gate is validated, recovery uses the grid spawn 4 m behind the finish. Recovery clears velocity/commands and emits the existing reset signal; the independent camera snaps immediately. A cooldown prevents repeated recovery. The latest valid checkpoint and all timing/lap data are preserved; the active clock keeps running.

Every supported teleport emits `reset_performed`, which also resamples RaceManager's previous position. A reset cannot create a swept crossing from old to new position. Reset clears drift/charge, active boost, normalized command, cached launch motion and surface transition state; camera and pad guards synchronize through the signal. Driving locks (READY/countdown/finished) clear temporary movement effects too. Restart restores the original grid and all race clocks/cursors, without changing lap validation. External scripts must use this reset API rather than silently teleporting. Recovery cannot unlock the kart or award progress.

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

`BarrierMesh` creates one unit mesh with four triangles per faceted face. The raised face centers and vertex shades form an X; no reference texture is used. Blocks share one mesh in four MultiMesh colour batches (plus shadow-pass work). The faceted triangles are never used for collision.

## Outer barriers and runoff — v0.3.0 prerequisite correction

Road edges and kerbs still use the original 10 m asphalt ribbon. Physical barriers now have **separate left/right outer paths**, controlled by exported Curve resources `circuit_01_left_barriers.tres` and `circuit_01_right_barriers.tres`. Curve X is normalized arc length along the source centerline (0–1); Y is metres beyond the asphalt edge (clamped to 0.95–25 m). Left/right are relative to driving forward, so the inner grassy side of the early right straight uses the right profile. A missing/empty profile retains the original narrow 0.95 m clearance for reusable replacement scenes.

The supplied profiles retain narrow start/finish and tight inner bends, give the early straight 10 m outside/20 m inside clearance, and open the long left straight toward grass. Other straights use moderate aprons. This is not a uniform translation of every barrier. First/last profile Y values must agree to preserve a smooth seam. Resources use gentle interpolated transitions; keep offsets below safe bend radii and away from nearby road runs. Arbitrary author edits are not automatically repaired.

The builder samples both outer paths at 0.6 m centerline intervals, closes them, then spaces blocks along each outer path's **own arc length**. This keeps block sizes consistent when the boundary flares away from the kerb. Each visual block and simple box collider uses the same endpoint pair. Maximum segment length is the smaller of Barrier Spacing and 1.2 m; the previous default of 4 m is therefore capped to match block geometry. Colliders live only at the visible outer boundary; no old kerb-side wall is retained. `barrier_block_transforms` holds the CPU transforms uploaded to MultiMesh, enabling headless checks without relying on dummy-renderer GPU readback.

Two 1.2 m-wide shoulder strips slope from road Y = 0.04 to sand Y = -0.08. Their trimesh collision prevents catching the original 12 cm asphalt edge on return. This geometry correction was implemented/tested before the surface handling above. Source road width/centerline/kerbs remain fixed. Checkpoints stay road-wide and recovery remains at the latest valid road checkpoint.

BarrierSection resources add normalized start/end fractions (including wrapped intervals), side selection, barrier enabled/disabled state and an optional clearance override. Last matching section wins; -1 clearance preserves the side Curve. The default outside opening is left-side 82–88% on the upper diagonal. Both visual and collider generation skip the same blocks; sampling makes the opening edge accurate to approximately one block. A separate faceted perimeter at X ±170/Z ±150 supplies containment beyond open segments; it shares the four existing colour batches. Its extent/enabled controls do not alter kerbs or recovery bounds.

To author a section, edit its Curve/BarrierSection in Track's Inspector and inspect the full lap. Profile/section changes coalesce one track rebuild, refreshing collision, gates, scenery and track features. Trees stay outside the nominal outer envelope plus a 3 m margin; an open segment exposes more world, so inspect scenery in that extra area when authoring. Keep the grass region footprint aligned for original circuits. See [cumulative acceptance criteria](testing/ACCEPTANCE_CHECKLIST.md).

`@tool` builders run in both editor and runtime. A rebuild removes and frees the old **Generated** subtree and creates exactly one replacement. Generated nodes have no scene owner, so they are not saved alongside the source curve. Opening the scene recreates them deterministically without accumulating duplicates. Do not edit generated children; modify the source settings instead. Exported scenes rebuild from the same source.

## Environment and assets

`RiotGeometry` shares original primitives. EnvironmentBuilder uses a local seeded generator, sand support floor, triangulated grass footprint, shared low-poly crowns and hills. Trees avoid the nominal runoff envelope plus 3 m. Decorative scenery has no obstacle colliders; floor/asphalt/shoulders/ramps/visible barriers supply physical support. The grass region identifies physics properties over the continuous sand collider, without adding a collision step. World ground spans 360 × 320 m; adapt floor/perimeter/recovery bounds and scenery for larger layouts. Rebuilds coalesce.

All three supplied images stay isolated under the existing `references/.gdignore` and Git ignore rule and are never loaded by game scenes. The brief's suggested `docs/references/circuit_01/` does not exist in this checkout. Review screenshots are isolated under `artifacts/.gdignore`.

Ground contact adds a small configurable speed into the floor normal so a kart stays attached along an ascending incline until its edge. Automatic floor snapping does not apply during upward movement, which is why tangent projection alone is insufficient. See Godot's [CharacterBody3D floor snapping documentation](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html#class-characterbody3d-property-floor-snap-length). Launch momentum still comes from actual ground motion, without a jump trigger/impulse.

Godot API reference: [Curve3D](https://docs.godotengine.org/en/stable/classes/class_curve3d.html), [editor tool scripts](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html).
