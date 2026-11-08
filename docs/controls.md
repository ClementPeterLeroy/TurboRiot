# Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Accelerate | W / Up | Right trigger |
| Brake, then reverse | S / Down | Left trigger |
| Steer | A/D or Left/Right | Left stick X |
| Start race from READY | Enter / Space | A / bottom face button |
| Recover at latest valid checkpoint | R | Y / top face button |
| Restart entire race | F5 (in game window) | X / left face button |
| Toggle debug HUD | F3 | Back / Select |
| Exit | Esc | Start |

Steering and triggers accept analogue values with a 0.12 action deadzone. All connected gamepads can supply input; this milestone has one player. Gamepad bindings use Godot's standard mapped controller layout. Physical gamepad testing is still required for the developer's device.

Hold S while going forward to brake; keep holding after stopping to reverse. W brakes reverse movement before accelerating forward. If both pedals are held, the brake action takes priority. Releasing both pedals coasts to a stop. Steering requires motion and reverses naturally when backing up.

Start Race runs a three-second countdown. The kart cannot drive until GO. Complete the whole circuit forward, visiting all ordered gates, before crossing the finish. Three valid laps display results, final/individual/best times and Restart Race, Return to Ready and Exit buttons. Gates are invisible normally.

R clears velocity, restores the latest validated checkpoint's safe location/orientation and immediately resets the camera. It **preserves all race timing and checkpoint/lap progress**; the clock keeps running. Until the first numbered checkpoint, recovery uses the starting grid. Falling below the configured threshold also recovers. Sustained grounded wall contact under throttle with no steering/braking attempt triggers recovery after 5 seconds by default; this is not a universal stuck detector. A one-second cooldown prevents repeated resets.

F5/Pad X **restarts the race**: initial spawn, empty results, zero clocks, checkpoint cursor reset and a fresh countdown. It works during countdown, racing and results. In the editor F5 runs the project; the restart binding applies to the focused game window. Enter/Pad A starts only from READY. Results buttons can be clicked with the mouse; no separate main-menu system exists.

F3 shows checkpoint planes plus floor contact, coordinates, FPS, normalized inputs and expected checkpoint in a separate debug panel. Speed uses actual horizontal velocity in km/h; direction is FORWARD, REVERSE or STOPPED based on longitudinal movement. Esc/Pad Start exits as before; it is not pause. No timings or records are saved between runs.
