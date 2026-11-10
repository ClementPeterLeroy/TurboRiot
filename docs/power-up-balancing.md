# Power-Up Balancing & Feedback — v0.5.0 development correction

**Unreleased, pending developer acceptance.** This request is implemented within `0.5.0-dev`, not as a new v0.5.1 release. At the start of this correction, local HEAD was `0d69490` (v0.4.0), no tags existed, project/export metadata remained `0.5.0-dev` / `0.5.0.0`, and CHANGELOG explicitly marked v0.5.0 Unreleased. Existing staged work was inspected without changing the index. Earlier changelog entries, milestone numbering and metadata are preserved; ROADMAP requires no scope change.

## Mushroom terrain immunity

BoostController tracks mushroom duration independently of its display source and retained strongest boost timer. A pad or stronger mini-turbo cannot grant or refresh mushroom immunity. Under STRONGEST_WINS, accepted overlapping sources keep the stronger speed cap/longer overall timer while the mushroom's own timer expires normally. REPLACE ends the previous source's immunity and feedback.

SurfaceDetector continues its usual ground/region queries, debounce, terrain blend and displayed identifier. Its `handling_multipliers()` neutralizes only reduced acceleration, speed-cap and grip multipliers while the mushroom timer is active. Terrain resistance and combat penalties remain. After expiry, the override returns exponentially to the live terrain values using existing surface smoothing; the normal excess-speed deceleration remains. Base resources are never mutated, and no separate mushroom movement branch is added. Pads and mini-turbos on their own retain their original terrain behavior.

## Shared spin-out reaction

ItemActor passes ItemDefinition hit tuning to the existing KartController/KartEffects path. Human and AI bodies use exactly the same implementation.

| Item | Spin | Initial disruption | Retained planar momentum | Speed-cap / grip multiplier |
| --- | ---: | ---: | ---: | ---: |
| Red Shell | 360° | 1.35 s | 0.55 | 0.55 / 0.24 |
| Green Shell | 360° | 1.35 s | 0.55 | 0.55 / 0.24 |
| Banana | 540° | 1.65 s | 0.50 | 0.50 / 0.20 |

The reaction applies one bounded horizontal hit impulse/retention, clears drift charge and incrementally rotates the **CharacterBody3D**, including its real box collider and attached kart model, during physics updates. It never animates an unrelated mesh or teleports the body. An eased angular curve reaches the configured rotation. Steering/acceleration retain 12% authority during the initial reaction; braking retains partial authority. The kart slides along its incoming traction frame under inertia instead of being forced around a scripted circle. Impaired steering still turns that frame and the physical body. Banana leaves the physical kart facing the opposite direction after 540°; its final orientation affects subsequent driving.

After the initial spin, a 0.35-second smooth recovery restores speed/grip/input authority and traction toward the body's actual final heading. These durations, angle, control, speed/grip and retention values are configurable in ItemDefinition resources. There is no arbitrary zero-velocity reset. Vertical velocity, gravity, snapping and ramp launch rules retain their existing behavior.

An active spin/recovery rejects overlapping hits. Repeat-hit protection lasts through spin/recovery plus a 0.35-second grace period; later independent hits remain possible. Recovery, restart, READY/countdown/finish locks clear spin, recovery, pending impulses and immunity. No effect awards checkpoints or race progress.

The chase camera uses the body's interpolated position and a physics-interpolated `FollowHeading` child representing the traction heading. This lets the actual kart rotate visibly without orbiting the chase view around every spin. During normal driving the helper matches body heading. The existing moving-target position integration and orientation smoothing remain; no extra vertical filter, bob or shake is added. The visual animation script and collision geometry are unchanged.

## Radial speed lines

`scenes/ui/boost_speed_lines.tscn` / `scripts/ui/boost_speed_lines.gd` is a reusable Control drawn behind the HUD. Accepted mushroom and pad activations increment a feedback serial, allowing a fresh 0.24-second burst even when the source name stays the same. Their own feedback timer supports subtle sustained streaks, then an exponential fade. Strength scales intensity. Mini-turbos alone do not start this feedback; overlapping eligible boosts retain their own feedback duration.

Twenty-eight deterministic, narrow tapered streaks start near the viewport edges and point toward the kart's projected helmet position, leaving its central area clear. Projection uses the current camera and canvas transform; dimensions and widths scale with the viewport. The effect reads render poses after the chase update and writes no camera/body transforms. It uses no textures, particles, per-kart drawing or full-screen shader. Recovery and race locks clear it immediately; ordinary expiry fades it smoothly.

## Developer checks

Run cumulative manual checks **1–104**; the new **91–104** remain unchecked. On sand and grass, use a mushroom and confirm acceleration/speed/grip immunity while F3 still reports the real surface. Continue driving as it expires and inspect the smooth return. Compare pads/mini-turbos without a mushroom.

Take a red/green shell and banana hit on a straight, while steering, during a jump and beside a barrier. Observe the actual kart's turn, meaningful speed loss, impaired input and smooth control return. Banana is deliberately longer and can leave you facing backward. Compare AI responses and exercise R/F5/finish during effects; repeated projectiles must not extend one spin forever.

Inspect mushroom/pad burst, sustained lines and fade at different resolutions/camera settings. The HUD and central driving view must stay readable. Rerun F4 **A Normal** at about 80 km/h and F7 60/120/uncapped where supported; a stable physics Y alone is insufficient acceptance. Actual keyboard/controller feel, art intensity and motion comfort still require developer testing.

## Automated evidence and limitations

Baseline: **691 checks, zero failures**. Expanded suite: **842 checks, zero failures**. New coverage includes terrain/boost overlap and restoration, spin integration at 30/60/120/144 Hz, overlap rejection, smooth recovery, human/opponent equivalence, actual 360°/540° body turns, wall separation, airborne ascent/landing, cleanup and screen-space feedback geometry/lifecycle. The old item-expiry test now waits for configured spin plus recovery rather than the superseded short penalty.

Native captures in `artifacts/balance_*.png` show 720p/1080p feedback, changed FOV/camera height/distance, fade, actual spin poses and active sand detection. A real seven-AI Challenging three-lap run with item seed 42 finished all racers in 92.717–105.767 seconds, with 29 pickups, 28 uses and one ordinary recovery. All 12 native presentation A/B scenarios at 60/120/uncapped passed the retained one-pixel screen-Y limit. Detailed measurements and reproduction commands are in [validation](validation.md).

This is an arcade kinematic spin, not a rigid-body angular-momentum or suspension simulation. Dense traffic/corner traps can still require the existing recovery system. Native checks cover the available Windows/Compatibility setup; exported builds, real controller feel and subjective line intensity/motion comfort remain unaccepted. Historical validation/artifacts remain separate, and no Git staging, commits, pushes, tags, releases or GitHub actions are performed by Codex.
