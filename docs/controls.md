# Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Accelerate | W / Up | Right trigger |
| Brake, then reverse | S / Down | Left trigger |
| Steer | A/D or Left/Right | Left stick X |
| Reset to starting line | R | Y / top face button |
| Toggle debug HUD | F3 | Back / Select |
| Exit | Esc | Start |

Steering and triggers accept analogue values with a 0.12 action deadzone. All connected gamepads can supply input; this milestone has one player. Gamepad bindings use Godot's standard mapped controller layout. Physical gamepad testing is still required for the developer's device.

Hold S while going forward to brake; keep holding after stopping to reverse. W brakes reverse movement before accelerating forward. If both pedals are held, the brake action takes priority. Releasing both pedals coasts to a stop. Steering requires motion and reverses naturally when backing up.

R clears velocity, restores the starting position/orientation and immediately resets the camera. Falling below the world also resets. F3 shows floor contact, coordinates, FPS and input values. Speed uses actual horizontal velocity in km/h; direction is FORWARD, REVERSE or STOPPED based on longitudinal movement.
