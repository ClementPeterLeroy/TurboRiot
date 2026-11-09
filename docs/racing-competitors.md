# v0.4.0-dev — Racing Competitors

**Unreleased, pending developer testing.** Default play is one human plus six AI racers on the existing circuit. v0.3.2 is the developer-reported released baseline; see [the initial audit](v0.4.0-audit.md) for the untagged/stale-metadata discrepancy. No prior history is silently reclassified.

## Shared architecture

All seven racers instantiate `kart.tscn` and share the **same unmodified KartController, KartDynamics and KartConfig**. `AIInput` extends DrivingInput and returns the existing DrivingCommand (throttle, brake, steering, drift). It never writes a kart transform or velocity during normal racing. Navigation recovery emits a request handled through KartRecovery's existing reset/cooldown API. Boosts, mini-turbos, terrain penalties, air steering and ramp launch remain the same mechanics for every driver. Profiles affect decisions, not physical capabilities; there is no rubber-banding.

AI decisions run at physics priority -10, all kart movement at 0, and RaceManager validation at +10. Camera and cosmetics retain the v0.3.2 render interpolation behavior. The global physics frequency stays 60 Hz. AI state, drift and boosts are per instance; the shared configuration resource is not mutated.

The manager creates `Opponents` once and a CompetitorState per racer. Each record owns its RaceSession, validated checkpoint cursor, interval travel, previous position, safe spawn, rank fraction, finish and DNF fields. `race.session` remains the human's model for existing UI/tests. Rebuilding the track refreshes racing-line/gate references and returns the entire existing field to READY without duplicating opponents.

## Circuit-derived pursuit and speed planning

RacingLine caches source-curve samples approximately every 2 m in world space: position, forward, curvature and physical corridor limits. It also caches the legal outer polygon. Navigation normally searches only 25 nearby segments and projects onto their edges continuously; teleports/lost tracks can trigger one full search. No repeated full Curve3D search is needed for ordinary AI movement or traffic.

The lookahead distance is a base plus speed × lookahead seconds. A pure-pursuit yaw request is converted to the current KartDynamics steering authority, then rate-limited. Curvature over a braking horizon limits target speed using lateral confidence and the shared kart braking capability. This anticipates corners rather than chasing a succession of points with full throttle. Pedal decisions never deliberately reverse when waiting behind traffic.

The line itself remains on the road; bounded passing targets use available asphalt width. The ordinary pursuit also rejoins from legal runoff. Staying more than 2 m outside the asphalt envelope, prolonged lack of forward route progress, or passing the expected checkpoint without validating it can request recovery. Standard delays are 2 s off-road, 4 s stalled, 1.25 s past a missed expected gate. These requests preserve validated progress/timing and use the shared one-second cooldown. They do not teleport to a future waypoint or award checkpoints.

## Difficulty resources

Edit `resources/ai/casual.tres`, `standard.tres`, `challenging.tres`, or assign RaceManager's **Driver Profile Override**. All profiles use one implementation and the same base handling. The optional deterministic Casual steering imperfection is small and only applied on straights.

| Parameter | Casual | Standard | Challenging |
| --- | ---: | ---: | ---: |
| Normal target-speed fraction of shared 22 m/s cap | 0.78 | 0.92 | 1.00 |
| Lateral confidence (m/s²) | 4.5 | 7 | 9 |
| Braking confidence | 0.38 | 0.55 | 0.70 |
| Lookahead base (m) + seconds × speed | 4.5 + 0.40v | 3.8 + 0.32v | 3.5 + 0.28v |
| Steering response (normalized units/s) | 3.2 | 4.5 | 5.2 |
| Traffic lookahead (m) | 15 | 20 | 25 |
| Lane change speed (m/s) | 1.4 | 1.8 | 2.0 |
| Stalled / off-road recovery delay (s) | 5 / 2.5 | 4 / 2 | 3 / 1.5 |
| Drift | Off | Basic, release at tier 1 or 1.25 s | Longer, release at tier 2 or 2.1 s |

Ordinary pedal speed planning is separate from boost-pad propulsion: an AI on the same directional pad as the human can reach the same boosted speed above 22 m/s. No AI-only boost is granted. Real validation shows Standard and Challenging can charge/release mini-turbos through the unchanged drift rules.

## Traffic and collisions

Nearby karts are checked by longitudinal/lateral separation, avoiding a world geometry search. On straights, a slower kart can trigger a free left/right lane target within road width minus a safety margin. Other nearby karts veto occupied lanes. A deterministic initial preference, a 2.5 s hold and one retained pass target prevent repeated side changes; the lane returns toward zero after the target drops behind. Lane offset starts at the physical grid/recovery offset, avoiding an initial swerve inward before an outward pass. Steering and lane movement are bounded; a close blocked kart lowers target speed. Prolonged blockage can still use normal recovery.

Kart bodies use **layer 2, mask 3**: static world layer 1 plus other kart bodies. CharacterBody3D collision slides/stops the karts; this is not rigid-body crash simulation. Every finished/DNF kart becomes nonblocking to other racers while remaining on world collision, so parked finishers cannot seal the line. Restart restores every kart's normal layer/mask.

## Grid and lifecycle

RaceManager exposes Opponent Count (0–11; default 6), Difficulty, AI Only, Lap Count, grid row/lane spacing and stagger. Defaults are 5.5 m between rows, 4.2 m between columns and 2 m stagger. Grid poses sample the actual source curve behind the finish, preserving its tangent and avoiding collider overlap. One-competitor mode retains the original center grid spawn for time-trial regressions. Change field size/profile before launching; there is no live field editor or kart-selection menu.

All racers lock during READY/countdown and release on one GO transition. A racer finishing locks only that racer. Human results can open while opponents continue; they update with completed times, RACING or DNF until the field is complete. AI can finish before or after the human. Defaults allow **60 s after the first finisher**, with an overall **480 s** race timeout. Remaining racers are then DNF. Both limits are configurable. Early F5 restart/Return to Ready explicitly replaces the entire race; no result is persisted.

Restart restores every grid pose, timer, lap/cursor, collision state, AI navigation/pass/drift/recovery state and finish/DNF flag. Each kart's recovery resamples only its own sweep/travel cursor. R remains human recovery, not field restart.

## Ranking and finish order

Active progress is ordered by `completed_laps × gate_count + validated_gate_count + segment_fraction`. Fractional progress must belong to the expected source interval and legal bounded corridor, and is capped by actual interval travel. Off-route positions or unsupported sweeps over 8 m cannot create forward rank progress. The original order, direction, bounded gate and minimum-travel checks apply to every racer. Moving physically near finish does not imply a lap or a leading position.

Finishers rank first in permanent crossing order. Crossings within one physics tick are sorted using their interpolated segment crossing timestamp, with ID only resolving exact ties. RaceSession displayed lap/total times retain physics-tick precision. Active racers follow, then DNF racers ordered by validated progress. This is a prototype route-integrity system, not online anti-cheat.

## Godot play and debugging

1. Import/open `project.godot` in Godot 4.7.2 and open `scenes/main.tscn`.
2. Select RaceManager to configure field size/profile/laps. F5 runs; Enter/Space/Pad A starts the countdown. Six opponents appear by default.
3. F3 enables gates, cached racing-line/waypoint marks, live target lines and per-AI labels. The HUD adds selected driver/profile, target/actual speed, steering/braking, drift, recovery, lap/gate and recovery count. **F8** cycles the selected AI telemetry; it does not change camera/player ownership.
4. F4/F6/F7 presentation A/B/CSV/render-rate diagnostics remain available. Use A Normal for the high-speed visual-stability acceptance regression.
5. Race through three laps; check positions, finishing order and live results. Try staying still at the start, blocking another kart, recovering, and restarting before/after finishing. Record actual hardware and outcomes; automation does not accept the patch.

For an AI-only game, use Godot's main run arguments after `--`:

```powershell
godot --path . -- --ai-only --auto-start --difficulty=standard
godot --path . -- --opponents=3 --difficulty=casual
```

## Automated and rendered validation

```powershell
godot --headless --path . --editor --import --quit
godot --headless --fixed-fps 60 --path . --script tests/run_tests.gd
godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd
godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd -- --difficulty=casual
godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd -- --difficulty=challenging
godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd -- --idle-human
godot --fixed-fps 60 --path . --script tests/capture_competitor_preview.gd
godot --path . --script tests/benchmark_competitors.gd
```

`--fixed-fps 60` advances the simulation at the existing 1/60 step without waiting for wall time; it is not increased gravity, a larger physics step or runtime rubber-banding. AI runs use real movement/collisions/gates, no synthetic transforms or checkpoint events, and exit nonzero if required racers fail to complete every lap. Reports are saved as `artifacts/ai_race_*.json`. `--idle-human` expects only the deliberately idle human to DNF; `--laps=1` provides a shorter diagnostic. The rendered preview captures a real seven-AI one-lap race. Benchmark the actual renderer **without** `--fixed-fps` and without simultaneous heavy work; it compares one/seven karts on the same machine. Screenshot/benchmark helpers are not a manual race result.

See [validation.md](validation.md) for measured results. Existing 519 assertions are retained in isolated one-competitor fixtures; new tests exercise the default field and inter-kart interactions. The cumulative manual checklist adds checks 50–65 and retains the v0.3.2 presentation regressions.

## Limits

This is one original arcade AI implementation, not advanced tactics. Passing is primarily straight-line, traffic density and hard blocking can require recovery, and physical crashes do not model rigid-body impulses. Difficulty changes competence rather than guaranteed finish position. Custom circuits require navigation/gate/corridor review. No rubber-banding, networking, split-screen, items, weapons, new full circuit, kart selection or persistent leaderboard is added. Real controller hardware, broad GPU/device performance and developer feel/acceptance remain pending. The educational reference circuit still needs replacement for an original-content distribution milestone.
