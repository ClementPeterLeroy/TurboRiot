# Architecture and editing

Applies to **v0.3.0-dev — Arcade Handling** with **v0.3.1 — Corrective Patch**. Both are Unreleased, pending developer acceptance. Project/HUD/export build identifiers are unchanged by this documentation update; see [versioning](../VERSIONING.md).

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

`scenes/boost_pad.tscn` is an editor-visible directional pad. Its non-solid Area3D requires ground contact/active driving and calls `activate_directional_boost` with the pad's world -Z axis (the source tangent for generated pads). Entries from forward, reverse or a wrong heading all accelerate horizontal velocity toward that axis, bounded by `pad_propulsion_acceleration` (42 m/s²), and turn yaw toward it at `pad_turn_rate` (180°/s). The default redirect phase is one second, bounded by the boost duration; this phase takes authority over pedals/steering. Normal control then resumes for the remaining boost. No position is teleported.

Pads always apply direction: STRONGEST_WINS retains a stronger existing multiplier and longer remaining duration, while REPLACE uses pad strength/duration. Generic mini-turbos still use ordinary kart-forward movement and their existing overlap policy; an accepted mini-turbo clears pad direction. Expiry/reset/lock clears temporary direction. A per-kart entry latch and physics-time cooldown prevent repeated rewards while occupied; reset callbacks suppress an immediate occupied-pad retrigger. Strength/duration/cooldown/redirect duration are exported; rebuild after size edits.

`scenes/ramp.tscn` authors a wedge from width, length and height, with visible incline/stripes and corresponding trimesh collision tagged asphalt. Keep inclines below CharacterBody's floor-angle limit; the default is 1.3 m rise over 7 m length. There is **no jump impulse or contact-triggered jump**. Verified ramp-floor contact uses the rising tangent and measured ground motion at takeoff; ordinary asphalt/sand contact delegates slope projection and snapping to CharacterBody3D. Air retains horizontal inertia, applies gravity and reduces heading yaw to 20%; throttle/grip do not manufacture or rotate horizontal air momentum. Landings restore floor motion without bounce, with 0.98 horizontal retention for impacts above the soft-landing threshold. The physical body remains upright; extreme unexpected tilt goes through recovery.

TrackFeatures deterministically places two pads at 55%/81% arc fractions and one ramp at 56%, 10.5 m outside the long left straight. The optional ramp has a clear approach/landing apron and does not alter the saved circuit or checkpoint order. Track rebuilds replace one Generated feature subtree; the reusable scenes also work independently. No new full circuit is introduced.

## Camera and HUD

Presentation now explicitly enables physics render interpolation. The independent chase camera samples the body's interpolated transform once per rendered frame and shares it across position, obstruction focus and look calculations. Camera and render-updated Visual local transforms disable automatic interpolation; Visual still inherits its parent's interpolated placement. Position follow uses exact exponential integration of a linearly moving target at the unchanged 8/s rate; orientation smoothing remains 10/s. This avoids render/physics pose mismatches and frame-duration-dependent follow distance without altering physics. Reset still snaps immediately and resets interpolation.

`PresentationDebug` is a scene-local optional diagnostic node, not a gameplay singleton. F4 selects four cosmetic/camera isolation modes, F6 controls optional CSV capture and F7 changes only the temporary render limit/VSync. F3 shows mode, measured rates and angle/screen telemetry. Modes never write kart transforms, velocity or config. Details, historical comparison and measurements are in [presentation-investigation.md](presentation-investigation.md). Stable physics Y does not establish visual acceptance.


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

TrackBuilder creates `Generated/Checkpoints`: finish index 0 plus 11 ordered gates by default. **Checkpoint Count** includes finish and is editable. Gates follow authored source-curve arc fractions after major corners (uniform spacing if the array length differs from the count), are tangent-aligned and 4 m high. Independent left/right extents cover the legal sand/grass corridor; the debug mesh uses the same asymmetric bounds. The approach side is local +Z, race forward is local -Z. A forward crossing requires positive previous Z and nonpositive new Z; the intersection must be within width and vertical bounds. Reverse/side entries, standing on the plane, and remaining past it are rejected. Crossings in one segment are processed by intersection fraction rather than node order.

The session accepts only the expected numbered gate. Wrong order/repetition leaves the cursor unchanged. All numbered gates are required before finish 0 can award a lap, and a backwards finish never awards one. Initial spawn/finish crossing is ignored because the initial cursor expects gate 1. Three valid finishes complete the default race; **Lap Count** is exported on RaceManager. Optional debug gates are visible through F3 in gameplay or **Show Checkpoints** on Track in the editor.

`corridor_limits()` intersects each lateral ray with enabled, independently authored fence edges, subtracting collider half-thickness. Gate extents stop at the first neighboring route sector, and crossing points must lie inside the stepped outer polygon and the gate's source-arc window. This covers connected legal runoff without catching an adjacent asphalt leg. The source circuit uses twelve nonuniform fractions to put gates in clearer corridors.

RaceManager also requires travel of at least 55% of the source-arc interval since the preceding valid gate, accumulated only inside the legal outer polygon and expected route sector. Single movement sweeps over 8 m are rejected. Recovery/restart resample position and clear interval travel. This combines finite corridor coverage, order, direction and travel guards against large shortcuts; it is not a general-purpose anti-cheat system. A substantially different circuit requires reauthoring fractions/windows and rerunning legal-line and shortcut checks.

## Recovery versus restart

`KartRecovery` lives under Kart with fall height (-8 m), world-space safety half-extents (178/158 m), cooldown (1 second), upright-angle limit from KartConfig, and wall-jam duration (5 seconds; zero disables that detector). R/Pad Y and automatic bounds/fall/tilt recovery use the same path. Safety bounds are independent of road, kerbs and physical barrier openings; adapt them and the perimeter/terrain size together for original worlds. A wall jam requires sustained throttle > 0.5, brake < 0.1, steering magnitude < 0.2, speed < 0.4 m/s, grounded state and an actual near-horizontal wall collision.

After each accepted gate, RaceManager assigns `kart.safe_spawn` to that gate's center, 2 m forward and 0.65 m above the road, facing its tangent. Before any numbered gate is validated, recovery uses the grid spawn 4 m behind the finish. Recovery clears velocity/commands and emits the existing reset signal; the independent camera snaps immediately. A cooldown prevents repeated recovery. The latest valid checkpoint and all timing/lap data are preserved; the active clock keeps running.

When a grounded, throttling, nearly stationary kart reports only floor contact at a real wall, a short forward ray verifies a near-horizontal obstacle before the existing sustained-jam timer can recover it. Steering/braking, cooldown and disabled-stuck safeguards remain.

Every supported teleport emits `reset_performed`, which also resamples RaceManager's previous position. A reset cannot create a swept crossing from old to new position. Reset clears drift/charge, active boost, normalized command, cached launch motion and surface transition state; camera and pad guards synchronize through the signal. Driving locks (READY/countdown/finished) clear temporary movement effects too. Restart restores the original grid and all race clocks/cursors, without changing lap validation. External scripts must use this reset API rather than silently teleporting. Recovery cannot unlock the kart or award progress.

## Editing the circuit in Godot

1. Open **`scenes/track.tscn`** directly. Select its `Track` Path3D root.
2. Use the 3D path tools to move Curve3D points and their Bézier handles. Work in top view; units are metres. The saved resource is the source of truth, so commit/save the scene after edits.
3. The final point is an explicit duplicate of point zero. Keep its **position and in/out handles identical** to point zero when editing either end. This closure convention avoids relying on newer Curve3D closed-property versions. The builder refuses an open curve with a warning.
4. Keep all points/handles at Y = 0.04. The mesh is forced flat at that height, but changing source Y would distort its baked arc length and scenery queries.
5. Change **Road Width** (source circuit 14.4 m; reusable script fallback 10 m), **Sample Spacing** (1.5 m), and **Barrier Spacing** (4 m) in the Track Inspector. Curve edits and property changes rebuild automatically. The **Rebuild** toggle requests a manual refresh; it is an action, not a saved flag.
6. Maintain bend radii larger than half the road width, avoid self-intersections, and leave at least road width + 3 m between neighboring centerline runs. The builder does not repair arbitrary intersecting layouts or bad offsets. Run the geometry tests after edits.
7. Point zero sets the finish plane/start line; its outgoing tangent sets forward. Move it and its duplicate to change the start. The grid spawn is derived 4 m behind it. Checkpoint/recovery transforms follow the source curve automatically.
8. Reopen `main.tscn` to inspect the whole world. Environment has a seed, tree count, Infield Outline and Rebuild button. Track rebuild signals refresh the scenery, including width-only edits. Edit the grass footprint separately when replacing the circuit. A runtime track rebuild returns the race to READY with fresh gate references.

`TrackBuilder` samples the closed curve at equal arc-length intervals. Tangents produce lateral road offsets. An indexed ArrayMesh has explicit upward normals, clockwise triangle winding and trimesh collision. Road kerbs, start tiles and grid marks are thin noncollidable decoration; posts/banner are also decoration outside/above the driving area.

`BarrierMesh` creates one unit mesh with four triangles per faceted face. The raised face centers and vertex shades form an X; no reference texture is used. Blocks share one mesh in four MultiMesh colour batches (plus shadow-pass work). The faceted triangles are never used for collision.

## Outer barriers and runoff — v0.3.1 Corrective Patch

The source circuit now uses independent `BarrierRun` resources: a stepped outer perimeter and the reference T-shaped infield fence. These are polylines in local metres, not asphalt offsets. The 14.4 m ribbon and smoothed Bézier centerline were re-proportioned from the overhead at 0.18 m/pixel. See [track-reference.md](track-reference.md) for coordinate mapping, landmarks, gaps and constraints.

Each exact polyline edge is split at normalized fence-arc gap boundaries. Blocks never diagonally bridge corners or gaps. One cursor advances through the whole connected physical run: R × 5, B × 5, Y × 5, G × 5. `barrier_color_group_size` is configurable. Open runs end on complete groups; closed runs have a complete four-colour cycle across the seam. Short blocks are distributed across edges to retain exact corners and a maximum segment length of min(Barrier Spacing, 1.2 m). Four shared MultiMesh batches remain. Each simple box collider uses the same endpoints as its visible block; CPU transforms, colours, run ranges and enabled edges support headless checks.

Without authored runs, the existing left/right clearance Curve and BarrierSection authoring APIs remain available. Last matching section wins, including wrapped intervals and disabled spans. The optional generic rectangular perimeter remains reusable but is disabled in `track.tscn`; the stepped outer fence supplies containment. Recovery bounds remain independent.

Two 1.2 m shoulders slope from road Y = 0.04 to sand Y = -0.08, allowing re-entry without a collision ledge. The infield fence has deliberate openings beside the early right and long left straights. Surface physics remains separate from geometry. Gates cover connected legal runoff and recovery remains on the latest valid road checkpoint.

Run edits rebuild visuals/colliders, gates, scenery and features. Keep outlines simple, gaps intentional and bend radii greater than half the road plus shoulder width. Arbitrary self-intersections are not repaired. Follow the retained and appended [manual acceptance criteria](testing/ACCEPTANCE_CHECKLIST.md).

`@tool` builders run in both editor and runtime. A rebuild removes and frees the old **Generated** subtree and creates exactly one replacement. Generated nodes have no scene owner, so they are not saved alongside the source curve. Opening the scene recreates them deterministically without accumulating duplicates. Do not edit generated children; modify the source settings instead. Exported scenes rebuild from the same source.

## Environment and assets

`RiotGeometry` shares original primitives. EnvironmentBuilder uses a local seeded generator, sand support floor, triangulated grass footprint, shared low-poly crowns and hills. Trees avoid the nominal runoff envelope plus 3 m. Each generated trunk has a stationary layer-1 cylinder, sharing one CylinderShape3D (radius 0.18 m, height 1.4 m), inscribed in the visible tapered trunk (radii 0.25 to 0.18 m). Crowns have no colliders. Floor/asphalt/shoulders/ramps/barriers supply the remaining physical support. Two outer grass patches match the stepped overhead corners; distant hills were moved outside the corrected board. The grass region identifies physics properties over the continuous sand collider, without adding a collision step. World ground spans 360 × 320 m; adapt floor/perimeter/recovery bounds and scenery for larger layouts. Rebuilds coalesce.

All three supplied images stay isolated under the existing `references/.gdignore` and Git ignore rule and are never loaded by game scenes. The brief's suggested `docs/references/circuit_01/` does not exist in this checkout. Review screenshots are isolated under `artifacts/.gdignore`.

Ordinary ground movement requests horizontal velocity plus the existing world-down contact speed. CharacterBody3D handles slope projection and automatic floor snapping, with `floor_constant_speed = true`, `floor_stop_on_slope = true`, the default 45-degree `floor_max_angle` and the existing 0.4 m snap length. Supplying an upward tangent on an ordinary shoulder disabled snapping and caused false takeoffs, so that path is now restricted to actual walkable contact with a collider tagged `launch_ramp` by KartRamp. Only that verified ramp contact can carry measured upward ground motion into takeoff. Airborne motion applies gravity and never calls `apply_floor_snap()` to pull a legitimate jump down. See [vertical-contact diagnosis and regressions](vertical-stability.md). See Godot's [CharacterBody3D floor snapping documentation](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html#class-characterbody3d-property-floor-snap-length). Launch momentum still comes from actual ground motion, without a jump trigger/impulse.

Godot API reference: [Curve3D](https://docs.godotengine.org/en/stable/classes/class_curve3d.html), [editor tool scripts](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html).
