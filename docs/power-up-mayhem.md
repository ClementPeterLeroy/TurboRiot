# v0.5.0-dev — Power-Up Mayhem

Unreleased; developer acceptance pending. This milestone preserves the v0.4 racing field and v0.3 ground/presentation fixes. No item 5E, extra circuit, multiplayer, selection screen or persistent item statistics is implemented.

## Play and inspect

Open `scenes/main.tscn`, run F5, start the race and drive through a floating question-mark box. **Space / Pad B** uses the held item once; release before the next use. A full inventory cannot consume another box. Space starts only from READY; holding it through GO cannot automatically consume a pickup. The HUD shows item icon/name/readiness, plus the existing boost timer.

In Godot, select `Items` in the main scene to inspect its three row configuration resources. All three generated rows appear in the editor's 3D viewport; their generated children can be inspected individually in the running **Remote** scene tree. Edit `resources/items/row_*.tres` for anchors/count/spacing/respawn, then toggle Items → Rebuild. Open `scenes/items/mushroom.tscn`, `red_shell.tscn`, `green_shell.tscn`, `banana.tscn` or `loot_box.tscn` and use the 3D viewport to inspect individual models. Procedural geometry appears after the tool script runs; enable **Debug → Visible Collision Shapes** while running to inspect actual triggers/bodies.

All geometry is original and replaceable. The private PNG references remain ignored and are never loaded by the game. Native review captures are `artifacts/items_models.png`, `items_rows.png`, `items_row_close.png` and `items_racing_hud.png`. These are developer aids, not manual visual acceptance.

## Collision response

KartController records real slide contacts and pre-movement velocity. KartContactSolver runs after all bodies and resolves each unordered kart pair once, using relative closing speed along the contact normal, configurable mass (default 100), restitution (0.1) and maximum per-contact velocity change (18 m/s). Normal momentum transfers between both karts; tangential forward motion survives a side contact. Separating/resting contacts add no impulse, and impulses cannot add kinetic energy. All player/AI bodies use the same rule. CharacterBody3D remains responsible for collision separation; the solver never teleports or rotates a body.

World walls retain their existing sliding and speed retention. Dense multi-kart contacts are sequential rather than a full iterative rigid-body solver; hard blocking can still invoke ordinary recovery. This change removes the previous world-wall speed penalty from kart-to-kart contacts.

## Pads and boost overlap

A grounded pad entry applies one horizontal arrow-aligned impulse. It removes a reverse component along that axis, then adds up to **12 m/s**, capped by the boosted speed limit. It preserves lateral/vertical motion and body yaw; ordinary steering, braking and drift run immediately. There is no continued direction override. An occupied pad cannot retrigger until exit/cooldown; reset guards remain.

Default pad bonus: **1.5 strength / 1.4 seconds**. Mushroom: **1.4 / 1.8 seconds**. Both increase acceleration using the existing boost acceleration multiplier. Under default STRONGEST_WINS, these sources retain the stronger cap and longer timer; they never add multipliers. REPLACE overwrites the bonus. Mini-turbos retain their established weaker-ignore policy. Sources remain `boost_pad`, `mushroom` and `mini_turbo`. Expiry uses existing smooth excess-speed deceleration; base KartConfig is never mutated.

## Inventory and item architecture

`ItemDefinition` resources contain identifier, name, scene/icon, weight and effect/projectile tuning. `ItemCatalog` includes exactly four shared definitions, with weights **35/25/25/15**. There is no position advantage or hidden AI pool. `5E` is explicitly reserved and cannot be drawn. Model scenes and native SVG icons can be replaced without changing activation code.

Each reusable kart has `KartInventory`: one held definition, a press latch and 0.35-second use cooldown. Pickup atomically succeeds before a box hides. Full inventory leaves the box available; a rejected entry requires leaving before another attempt. Reset requires button release before use. `DrivingCommand.use_item` extends the existing command; device reads remain in PlayerInput. ItemSystem consumes the same command for every competitor, after race validation. Failed activation due to the actor cap preserves the held item.

| ID | Item | Default behaviour |
| --- | --- | --- |
| 5A | Mushroom | 1.8-second acceleration/speed boost; no direction lock or drift interruption. |
| 5B | Red Shell | Forward launch, 30 m/s; acquire an active opponent within 45 m, forward cone and unobstructed line of sight. Turn at most 110°/s. If no target, continue straight. Hit or world-wall contact consumes it; lifetime 8 seconds. |
| 5C | Green Shell | Forward 30 m/s; no homing even if a target exists. Reflect from world-wall normals, up to four bounces, 8-second lifetime. |
| 5D | Banana | Drop 2 m behind, fall onto support, then remain stationary. One eligible contact causes a 1.1-second grip disturbance. Lifetime 20 seconds. |
| 5E | Reserved | No definition, actor, model, pickup or active probability. |

Shells use swept sphere queries and explicit initial-overlap detection, so a thin wall or close opponent is not skipped. Spawn paths check static obstacles. Forward target selection cannot guarantee a hit around corners; red shells have no path planner or automatic reacquisition. Ground-follow rays keep shells above support; missing ground applies gravity. Bananas settle before checking kart overlaps. Fresh shells exclude their owner for 0.6 seconds; bananas for 1 second. Returning items may hit their owner after grace. Each actor is spent once.

`KartEffects` holds temporary speed/grip and repeat-hit immunity. A hit queues one bounded planar impulse and one momentum-retention application; the controller applies them on the next physics tick. Shell defaults: 0.8-second penalty, speed cap multiplier 0.78, grip 0.75, retained momentum 0.75. Banana defaults: grip 0.4, speed 0.92, retention 0.92. These preserve steering and pedals, never impose a full stop, and clear drift charge. A 0.65-second guard limits repeated hits; effects do not stack permanent penalties, rotate/teleport bodies or change race progress.

## The three blue-marker rows

The supplied annotated overhead is 1008 × 1011 pixels. Inspected blue-mark centroids map to the existing circuit using `(pixel - (500,500)) × 0.18`, then project onto the saved Curve3D. Rows use its local tangent and road height, without moving any road, shoulder, kerb, barrier or scenery.

| Row | Pixel anchor | Location |
| --- | --- | --- |
| 1 | (340.47, 115.15) | Upper-left beginning of the long diagonal. |
| 2 | (228.46, 686.56) | Lower-left diagonal after the left bend. |
| 3 | (565.52, 643.09) | Central-lower descending transition. |

Each row has four centres at **−4.8, −1.6, +1.6, +4.8 m**, with 3.2 m spacing perpendicular to the tangent. Each 1.65 m-wide trigger remains inside the 14.4 m asphalt. Boxes are roughly 1.07 m wide, float/rotate independently of physics, and respawn after five seconds. Reusable `LootBoxRow`/`LootBox` scenes separate placement, model/animation, pickup latch, weighted selection and respawn state. All twelve are tested with actual kart/Area overlap.

## AI, lifecycle and performance

AI follows available box lanes only while empty and not passing; traffic retains priority and existing bounded lane interpolation. Mushroom decisions require suitable straight/speed, red shells require a target ahead, green shells require a tighter ahead cone, and bananas require useful speed. Decisions have a 1.5–2-second cooldown, then use the common DrivingCommand/inventory route. No free items, unlimited use, targeting certainty or physics advantage is granted.

Recovery clears inventory, active combat modifiers/immunity and queued impulses; it retains valid race progress/timing. F5/Return to Ready synchronously clears every inventory, actor/trap, box timer, feedback and AI decision state. Finished drivers cannot activate or be targeted. Active effects cannot grant checkpoints, laps or ranking progress.

Caps: **32 active actors, 12 transient feedback rings, 8 spatial audio voices**. Procedural meshes/materials are shared, including shell scutes; four short synthesized cues distinguish pickup/use/hit/ricochet. Headless simulations omit audiovisual feedback and audio playback; native rendering exercises them. No camera shake or kart vertical bob is added. The inherited camera/shared-render-pose and visual update timing remain unchanged.

## Developer acceptance procedure

Run cumulative checks **1–90**, with new checks **66–90** still unchecked. First compare rear/side/head-on contact and confirm control while boosted, including reverse pad entry and drifting. Collect/use each of the four items; compare models with the private references. Check all three rows against the marked map, all four lanes, full inventory, respawn and simultaneous pickup contention. Check homing limits, thin-wall ricochet, owner grace, temporary hit recovery, AI item use and F5/R during effects.

Rerun F3/F4 A Normal at approximately 80 km/h and F7 60/120/uncapped where supported. Stable body Y alone does not accept visual stability. Confirm ordinary drifting, shoulder contact, a real ramp jump/landing and per-driver recovery/results. Record real keyboard/controller feel and visual/audio results separately from automation.

Automated commands and measured limits are in [validation](validation.md). Models approximate the references with original low-poly geometry; art approval and balance remain manual. AI is contextual rather than tactical, homing does not navigate obstacles, performance covers one machine, and exported/controller builds have not been manually accepted. No Git staging, commits, pushes, tags, releases or GitHub actions are performed by Codex.
