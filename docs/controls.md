# Controls

Applies to **v0.5.0-dev — Power-Up Mayhem**, Unreleased and pending developer acceptance. Earlier v0.3/v0.4 implementation and validation records are preserved; see [versioning](../VERSIONING.md).

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Accelerate | W / Up | Right trigger |
| Brake, then reverse | S / Down | Left trigger |
| Steer | A/D or Left/Right | Left stick X |
| Hold drift while steering | Left Shift | Left shoulder / LB |
| Use held item during racing | Space (new press) | B / right face button |
| Start race from READY | Enter / Space | A / bottom face button |
| Recover at latest valid checkpoint | R | Y / top face button |
| Restart entire race | F5 (in game window) | X / left face button |
| Toggle debug HUD and AI line/targets | F3 | Back / Select |
| Cycle AI telemetry selection | F8 | — |
| Exit | Esc | Start |

Steering and triggers accept analogue values with a 0.12 action deadzone. All connected gamepads can supply input; this milestone has one human player and six AI opponents by default. Gamepad bindings use Godot's standard mapped controller layout. Physical gamepad testing is still required for the developer's device.

Hold S while going forward to brake; keep holding after stopping to reverse. W brakes reverse movement before accelerating forward. If both pedals are held, the brake action takes priority. Releasing both pedals coasts to a stop. Steering requires motion and reverses naturally when backing up.

Start Race runs a three-second countdown. All racers remain locked until one shared GO. Complete the whole circuit forward, visiting all ordered gates, before crossing the finish. Three valid laps display your finishing position, competitor names/order/times, your lap/best times and Restart Race, Return to Ready and Exit buttons. Other AI can continue while this table updates. Finished/DNF karts no longer block racing traffic. Gates are invisible normally.

R clears velocity, restores the latest validated checkpoint's safe location/orientation and immediately resets the camera. It **preserves all race timing and checkpoint/lap progress**; the clock keeps running. Until the first numbered checkpoint, recovery uses the starting grid. Falling below the configured threshold also recovers. Sustained grounded wall contact under throttle with no steering/braking attempt triggers recovery after 5 seconds by default; this is not a universal stuck detector. A one-second cooldown prevents repeated resets.

F5/Pad X **restarts the whole field**: all grid poses, empty results, zero clocks, checkpoint/AI state reset and a fresh countdown. It works during countdown, racing and results. In the editor F5 runs the project; the restart binding applies to the focused game window. Enter/Pad A starts only from READY. Results buttons can be clicked with the mouse; no separate main-menu system exists.

F3 shows checkpoint planes plus floor contact, coordinates, FPS, normalized inputs and expected checkpoint in a separate debug panel. Speed uses actual horizontal velocity in km/h; direction is FORWARD, REVERSE or STOPPED based on longitudinal movement. Esc/Pad Start exits as before; it is not pause. No timings or records are saved between runs.

Drift requires ground contact, forward speed at least 8.5 m/s and steering magnitude at least 0.3 by default. Keep holding Shift/LB and countersteer freely. Charge accumulates only with sufficient steering and actual lateral slip (at least 0.65 m/s); holding the button on a straight does not earn a turbo. Levels arrive at 1.0/2.0/3.5 seconds of valid activity. Release while that activity remains valid to boost. Air, low speed, severe wall impact, recovery and restart cancel charge. Blue/gold/purple smoke and the charge gauge indicate tiers.

The cyan arrow pads give one arrow-aligned impulse per grounded entry, including reverse entry, plus temporary acceleration/speed bonuses. Steering, braking and drifting remain available immediately; there is no yaw or direction lock. Exit/re-enter after cooldown to reuse one; standing on a pad cannot repeatedly trigger it. The optional amber ramp is outside the long left straight, reached through sand near 56% lap fraction. Approach along its incline at speed; no jump button is needed. Air steering has 20% yaw authority and cannot redirect/add horizontal momentum. Required checkpoints include legal sand/grass runoff within their route corridor. Follow the ordered circuit; skipping route sections still invalidates progress.

F3 also shows surface, grounded/airborne state, drift/charge level, boost source and remaining duration. Sand and grass restore to asphalt handling gradually on return. R/restart clear drift charge, active boosts and launch state; recovery also handles extreme body tilt and independent world safety bounds.

## Presentation A/B diagnostics — pending acceptance

Focus the game window. F3 displays the debug panel; F4 cycles **A Normal**, **B Static visuals**, **C Fixed camera orientation** and **D Minimal rendering**. F6 toggles optional per-frame CSV capture (path printed in Godot Output). F7 cycles 60/120/uncapped rendering and disables VSync temporarily; physics stays at 60 Hz. Restart restores the normal render settings and mode A. These controls do not change driving physics or race progress.

Use a straight at about 80 km/h; C freezes world camera orientation and D omits camera obstruction response, so they are diagnostic views. Return to A for acceptance. Compare with recording off as well. See [the investigation and exact procedure](presentation-investigation.md).

RaceManager in `main.tscn` configures opponents, difficulty and race limits before launch. F3 includes selected AI target/actual speed, steering/braking, drift, recovery and lap/gate; F8 changes telemetry selection only. An idle player can DNF after the configurable finish grace/overall timeout. See [multi-kart instructions](racing-competitors.md).

## Items

Drive through a floating question-mark box while your single inventory slot is empty. Full inventory leaves the box available. Press Space / Pad B once to use; release before another use. Space starts only from READY and does not auto-use an item held through countdown. Mushroom boosts for 1.8 seconds and ignores sand/grass acceleration, speed and grip penalties without changing the displayed terrain. Red shells seek an eligible opponent ahead with bounded turning and otherwise fly straight; green shells fly straight and ricochet up to four times. Shell hits cause a physical 360° / 1.35-second spin. Bananas drop behind, settle and cause a 540° / 1.65-second spin. Shell owner grace is 0.6 seconds; banana grace is 1 second. Owners can subsequently hit their own returning items. 5E is excluded.

Boxes respawn after 5 seconds. Boosts never add their multipliers; pads/mushrooms retain the stronger cap and longer timer under the default policy, while weaker mini-turbos are ignored. Mushroom immunity has its own timer and fades back to normal terrain behavior; pads/mini-turbos retain normal terrain penalties. Mushroom and pad activations produce radial edge speed lines with a brief burst and smooth fade.

During a spin, forward momentum falls significantly and steering/acceleration are temporarily impaired, then return over 0.35 seconds. The body really rotates, and banana can leave you facing backward. The HUD shows SPIN-OUT / RECOVERING CONTROL. Overlapping hits cannot extend an active reaction; a short post-recovery guard remains. R clears held item and temporary effects; F5/Return to Ready clears every inventory, projectile, trap, effect and box timer. Full procedures: [Power-Up Mayhem](power-up-mayhem.md) and [balancing correction](power-up-balancing.md).
