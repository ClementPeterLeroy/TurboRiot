# v0.5.0-dev — Power-Up Balancing & Feedback validation

2026-11-10. **Unreleased; developer acceptance pending.** Local history at the start of this correction showed HEAD `0d69490` (v0.4.0), no tags, `0.5.0-dev` / Windows `0.5.0.0` metadata and an explicit Unreleased v0.5.0 changelog. This work stays inside that patch; no v0.5.1 release or metadata change is claimed. Earlier reports and release entries below retain their original wording/results.

## Automated regressions

Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer. Before correction: **691 checks, zero failures**. Expanded suite: **842 checks, zero failures**, adding 151 assertions. Headless editor import/runtime validation pass. The only engine error output is the existing Windows sandbox root-certificate-store warning; no network access is required. Test logs/traces remain under ignored `.godot/` and process-local APPDATA stays within that folder.

`tests/powerup_balance_tests.gd` covers mushroom acceleration/cap/grip immunity on both terrains, unchanged identity/resistance/resources, smooth expiry, independent overlap timers, unaffected pad/mini terrain rules, REPLACE cleanup; spin integration at 30/60/120/144 Hz, overlapping-hit rejection, exact angles, smooth recovery and later re-hit; actual moving human/opponent bodies, real wall separation, airborne ascent/landing and recovery/restart/finish cleanup; burst/sustain/fade, strength scaling, repeated same-source activation, non-eligible mini-turbos, race locks and streak geometry at four aspect/resolution settings and varied focus positions.

The earlier item expiry assertion now waits for the configured spin plus control recovery rather than assuming the old short penalty. All other prior assertions remain; ground/shoulder/ramp, drifting, collisions, ordered checkpoints/results, inventory/projectile behavior and presentation regressions pass.

| Actual-body test, starting at 20 m/s | Measured spin | Early hit speed | Body Y range | Maximum chase lateral offset while spinning |
| --- | ---: | ---: | ---: | ---: |
| Red shell | 360.000° | 11.284 m/s | 0.00000003 m | 0.151 m |
| Green shell | 360.000° | 11.284 m/s | 0.00000003 m | 0.151 m |
| Banana | 540.000° | 10.305 m/s | 0.00000286 m | 0.160 m |

These samples use real CharacterBody movement on a flat fixture with identical commands for human/opponent bodies. Every spin stays grounded, takes at most nine degrees per sampled physics tick and finishes with normal authority restored. The wall case reports **zero measured box penetration** and no excessive movement. An airborne hit preserves an existing +6 m/s vertical launch, continues rising and later lands normally. Actual sand/grass runs exceed 29 m/s during mushroom immunity, keep the detected identifier and return below ordinary terrain caps afterward. This evidence does not replace developer feel/visual acceptance.

## Native presentation and feedback

Captured and directly inspected scripted `artifacts/balance_*.png` previews: mushroom burst/sustain/fade at 1280×720, burst at 1920×1080 with changed FOV/height/distance, pad feedback, actual shell/banana spin poses and active sand detection. These are review captures, not accepted gameplay or race records. The effect is one Control with 28 edge streaks, no textures or transform writes, drawn behind the HUD; the kart center stays clear.

The retained native moving-target A/B probe ran all 12 scenarios, preserving its one-pixel screen-Y limit at about 79.2 km/h. New files use the `balance_` prefix, leaving previous captures/traces intact.

| Render cap | A Normal screen-Y range | B Static visuals | C Fixed orientation | D Minimal follow |
| --- | ---: | ---: | ---: | ---: |
| 60 | 0.24979 px | 0.18506 px | 0.16141 px | 0.000061 px |
| 120 | 0.20081 px | 0.20828 px | 0.17050 px | 0.000061 px |
| Uncapped | 0.21686 px | 0.21771 px | 0.17181 px | 0.000061 px |

Result: **12 scenarios, 0 failures**. Normal-mode relative-pitch ranges are 0.04702° / 0.03888° / 0.04157° respectively. This checks actual render/camera/screen-position timing, not only stable physics Y. Hardware: NVIDIA RTX 3070 Ti Laptop GPU, OpenGL Compatibility. No broad device/export guarantee is inferred.

## Real AI races

Seven physical AI racers, item seed 42, no transform driving/checkpoint injection:

| Difficulty | Laps | Finish times | Pickups / uses | Recoveries / DNF |
| --- | ---: | --- | ---: | ---: |
| Casual | 1 | 39.317–46.450 s | 9 / 9 | 0 / 0 |
| Standard | 1 | 33.383–39.567 s | 9 / 9 | 0 / 0 |
| Challenging | 3 | 92.717–105.767 s | 29 / 28 | 1 / 0 |

All seven finish each run with valid ordered progress. Challenging simulation lasts 108.8 s, with 8,139 braking frames, 2,894 drifting frames and 609 mini-turbo frames. The stronger reactions can legitimately require ordinary recovery. Distinct reports: `artifacts/balance_ai_race_*_items.json`; earlier v0.5 baseline reports remain intact. The seed makes this validation repeatable; normal gameplay remains random.

## Reproduce and accept

```powershell
godot --headless --editor --path . --quit
godot --headless --fixed-fps 60 --path . --script tests/run_tests.gd
godot --headless --fixed-fps 60 --path . --quit-after 180
godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd -- --items --laps=3 --difficulty=challenging --report-prefix=balance --item-seed=42
godot --path . --fixed-fps 60 --script tests/capture_balance_preview.gd
godot --path . --script tests/capture_presentation_probe.gd -- --report-prefix=balance
```

Do not use fixed FPS for the native render-rate probe. Re-run cumulative checks **1–104**; new **91–104** remain unchecked. Manual work includes actual input/control recovery, spin motion comfort, edge-line intensity/visibility, real gamepads and exported builds. This remains a kinematic arcade reaction with simple traffic/homing; dense corner/traffic traps may use existing recovery. See [implementation/tuning/procedures](power-up-balancing.md). No Git index changes, commits, pushes, tags, releases or GitHub actions by Codex.

---

# v0.5.0-dev — Power-Up Mayhem validation (2026-11-10)

**Unreleased, pending developer acceptance.** Current identity: `0.5.0-dev` / numeric Windows `0.5.0.0`. Earlier reports below retain their original versions/results; they are not claims about the new patch.

## Automated evidence

Engine: Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer. Baseline before edits: **568 checks, 0 failures**. Expanded `tests/run_tests.gd`: **691 checks, 0 failures**, including 123 new item/contact assertions. Engine imports and runtime smoke checks pass without script/parse errors. Windows emits the existing sandbox root-certificate-store warning; no network access is needed by the game/tests. Headless simulation omits audiovisual feedback/audio playback; native captures and the benchmark exercise the render/audio path.

The retained suite still covers surfaces, drifting, ramp launch/landing, shoulder contact, recovery, race progress/results, AI passing and shared render-pose/camera interpolation. Only superseded requirements changed: pad tests now measure the initial forward impulse and unrestricted controls instead of a one-second direction lock; the frozen-kart collision test still checks nonpenetration but does not require a full stop. Pad-surface detection samples the traversal rather than assuming a boosted kart remains over a four-metre pad after 20 ticks. Other pre-item fixtures explicitly disable items; new integration tests run with items enabled.

`tests/item_tests.gd` covers mass-weighted momentum/energy/tangential conservation, head-on/rear-end strength, separating/resting contacts, actual moving CharacterBody pair transfer and deduplication/nonpenetration; reverse pad impulse, immediate brake/steer/drift and expiry; active pool/5E exclusion/weights/assets; 3×4 rows, road clearances, spacing/tangent and actual Area pickup at every source-track box; one-slot/full-inventory/edge latch/contention/respawn; mushroom consumption/source/overlap/expiry; red target/turn/fallback/real hit; green straight flight/thin-wall reflection/bounce limit/tagged-support separation; initial overlap and owner exclusion; banana settling/grace/temporary grip; hit control/expiry/recovery; actor cap/lifetime; restart cleanup and unchanged race progress.

The four flat-road vertical scenarios still report zero airborne frames and a body Y range at most 0.00006187 m; all four real shoulder crossings retain contact. These are physics regressions, not a substitute for visible high-speed acceptance. Presentation A/B regressions remain; neither camera nor KartVisuals source is changed by this milestone.

## Real item-enabled AI races

Real seven-kart physical races, with no synthetic transforms/checkpoint injection:

| Run | Result | Pickups / uses | Recovery / DNF |
| --- | --- | --- | --- |
| Challenging, 1 lap | All seven finish, 30.750–35.467 s | 8 / 8 | 0 / 0 |
| Challenging, 3 laps | All seven finish, 91.183-101.467 s | 30 / 27 | 0 / 0 |
| Casual, 1 lap | All seven finish, 39.417–46.483 s | 9 / 9 | 0 / 0 |
| Standard, 1 lap | All seven finish, 33.400–38.900 s | 8 / 8 | 0 / 0 |

The final three-lap simulation lasted 104.5 s (18.78 s wall time with fixed render stepping), with 7,891 braking frames, 3,214 drift frames and 729 mini-turbo frames. Random item distribution can change results on reruns. Reports use distinct `artifacts/v05_ai_race_*_items.json` names, preserving v0.4 baseline reports. Counters in this validation are transient test evidence, not a persistent gameplay statistics system.

## Native render inspection and load

Captured and directly inspected original models, all three source-track rows, a close row and the racing item HUD in `artifacts/items_*.png`. Corrected local detail transforms exposed by gallery inspection. Models use shared geometry/materials and retain a recognizable cap/spots/stem, segmented shell/rim, three-peel banana and framed question-mark cube. These captures do not constitute developer reference-art acceptance.

Native 1280×720, OpenGL Compatibility, NVIDIA RTX 3070 Ti Laptop GPU, VSync off/uncapped, no `--fixed-fps`: `tests/benchmark_items.gd` warms a seven-AI field and measures three seconds with/without twelve boxes and a sustained approximately seven shells spawned ahead of the player. This is a short local observation, not an export/device guarantee.

| Configuration | Render FPS | Physics Hz | Mean / max sampled physics ms | Mean draw calls | Mean active actors |
| --- | ---: | ---: | ---: | ---: | ---: |
| Seven karts, items disabled | 455.0 | 59.95 | 2.49 / 2.90 | 397.7 | 0.00 |
| Seven karts, boxes + sustained shells | 213.7 | 59.90 | 2.88 / 3.08 | 953.3 | 6.91 |

Actual report: `artifacts/items_performance.json`. The measured field sustains 60 Hz physics with seven concurrent item queries. Actor/feedback/audio caps are 32/12/8; this benchmark does not establish worst-case performance at the full cap or on other hardware.

## Reproduction

From project root, using your Godot executable in place of `godot`:

```powershell
godot --headless --editor --path . --quit
godot --headless --fixed-fps 60 --path . --script tests/run_tests.gd
godot --headless --fixed-fps 60 --path . --quit-after 180
godot --headless --fixed-fps 60 --path . --script tests/run_ai_race.gd -- --items --laps=3
godot --path . --fixed-fps 60 --script tests/capture_items_preview.gd
godot --path . --script tests/benchmark_items.gd
```

Here automated runs redirected process-local APPDATA to `.godot/sandbox_appdata` to stay within workspace permissions. `--fixed-fps 60` accelerates simulated time with the normal physics step; it is omitted for native wall-time performance measurement. Logs/traces stay locally under ignored `.godot/`.

Remaining manual work: cumulative checks **1–90**, all new **66–90** unchecked; real keyboard/gamepad feel, reference comparison, audio balance, exported build and A Normal at ~80 km/h with 60/120/uncapped rendering where supported. Homing does not route around obstacles, AI item tactics are basic, dense kart piles may still require shared recovery, and local performance is not a device matrix. See [procedures/tuning](power-up-mayhem.md), [audit](v0.5.0-audit.md) and [checklist](testing/ACCEPTANCE_CHECKLIST.md). No Git mutations or publication by Codex.

---

# v0.4.0-dev — Racing Competitors validation (2026-11-10)

**Unreleased, pending developer testing/acceptance.** The developer identifies v0.3.2 as the latest released baseline. [The initial audit](v0.4.0-audit.md) records local commit `96934a4`, absent local tags and the older `0.3.0-dev` metadata found there; earlier history below remains preserved. Current project/HUD identifiers are `0.4.0-dev`, with numeric Windows export fields `0.4.0.0`.

## Baseline and complete regression suite

Before implementation: **519 checks, 0 failures**. Final `tests/run_tests.gd`: **568 checks, 0 failures**, exit 0, Godot **4.7.2.stable.official.ed1daf0bf**, Windows. All 519 existing assertions are retained, including contact, camera/render interpolation, drifting, surface transitions, directional pads, ramps, race/recovery and presentation diagnostics. Their single-kart fixtures explicitly set Opponent Count to zero so unrelated traffic cannot invalidate isolated mechanics measurements. New field tests use the default seven racers and actual kart-to-kart interaction.

The 49 added assertions cover default grid spacing/orientation and actual-lane initialization, shared physical config with independent states, synchronized countdown clocks/lock/GO, cached closed racing line, curvature anticipation and profile decisions, steering response/sign, stall/missed-gate recovery and cooldown, per-driver isolation, AI-first/human-first finishing, results/continued racing/DNF, all-driver restart, validated progress ranking, teleport rejection, subtick ordering, optional debug/cache regeneration, a real controlled overtake with held passing side/return to line, and actual CharacterBody kart collision. Restart tests include AI timers, target/pass/drift state and collision restoration.

Use `--fixed-fps 60` for fast deterministic headless simulation at the existing 1/60 physics step. It does not increase the runtime physics tick rate or alter handling.

## Physical race completion

`tests/run_ai_race.gd` drives real karts through actual collisions, surfaces and directed gates. It never injects transforms or checkpoint events during racing. The final seven-AI three-lap runs all exit 0:

| Profile | Finished | First–last race time | AI recoveries / DNFs | Drift / mini-turbo active frame observations |
| --- | --- | --- | --- | --- |
| Casual | 7/7, three laps each | 115.250–124.083 s | 0 / 0 | 0 / 0 |
| Standard | 7/7, three laps each | 97.517–104.767 s | 0 / 0 | 2,730 / 390 |
| Challenging | 7/7, three laps each | 89.383–97.017 s | 0 / 0 | 3,315 / 810 |

These are deterministic scenario observations, not promises of fixed player-relative performance. Difficulty parameters change decisions; the shared KartConfig is unchanged. Pads can produce the same boosted speeds for all racers. Counts refer to active frames across the field, not unique drift/turbo awards. Reports: `artifacts/ai_race_0_7_3_all_ai.json`, `ai_race_1_7_3_all_ai.json`, `ai_race_2_7_3_all_ai.json`.

The final mixed run with a deliberately idle human also exits 0: all six AI complete three laps in **96.467–106.433 s**, with **zero AI recoveries/DNFs**, while the idle human becomes DNF at the configured first-finisher grace deadline. A default one-lap idle-human diagnostic also passes. A **twelve-AI one-lap** configuration stress run completes **12/12**, with zero recoveries/DNFs (32.783–40.983 s). Physical/unit fixtures separately force stuck/missed-gate recovery; successful ordinary runs are not the only recovery evidence. Reports are saved under `artifacts/ai_race_*.json`.

## Presentation, rendering and performance

The retained native presentation probe passes **12/12** Normal/Static/Fixed-orientation/Minimal scenarios at 60/120/uncapped rendering. Normal-mode screen-Y range is **0.263 / 0.209 / 0.220 px**, respectively, below its one-pixel limit. This is an isolated single-competitor straight regression, not a claim of manual acceptance or collision-induced motion stability. Camera, KartController and the validated shoulder/ramp correction code are unchanged by v0.4.0.

`tests/capture_competitor_preview.gd` completes a **real seven-AI one-lap rendered race**, exit 0. Its grid, racing, optional F3 debug and finished results images were inspected directly. All seven default standings fit the 720p result card; longer lap details remain scrollable. Captures: [grid](../artifacts/competitors_grid.png), [racing](../artifacts/competitors_racing.png), [debug](../artifacts/competitors_debug.png), [results](../artifacts/competitors_results.png). No synthetic finish event was used for these screenshots.

`tests/benchmark_competitors.gd` uses the native Compatibility renderer on **NVIDIA RTX 3070 Ti Laptop GPU**, 1280×720, VSync disabled/uncapped, sequential three-second samples after warmup, with no simultaneous benchmark workload:

| Moving racers | Measured render FPS | Measured physics Hz | Mean physics time | Maximum sampled physics time | Mean draw calls |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 560.0 | 57.3 | 0.779 ms | 0.937 ms | 288.1 |
| 7 | 476.8 | 59.9 | 2.701 ms | 3.276 ms | 322.3 |

Report: `artifacts/competitors_performance.json`. This representative chase-view sample shows the seven-kart workload within a 60 Hz frame budget on this machine. It is not a worst-case guarantee, broad hardware benchmark or claim that every kart is in the camera frustum throughout the sample. Headless fixed-step simulation throughput is not presented as graphical FPS.

## Engine checks and remaining acceptance

Final editor import and configured main-scene startup (`--headless --path . --quit-after 300 -- --auto-start`) both exit 0 without script/scene/physics errors. The pre-existing Windows root-certificate-store warning remains. Read-only diff/whitespace and cumulative checklist checks also pass. No packaged Windows export or physical controller test is claimed.

Manual checks **50–65** are appended while preserving **1–49**, including visible high-speed stability. Human driving feel, hard blocking/complex traffic, broad device/VSync/controller behavior, alternate authored circuits and packaged export remain pending. Passing is basic/primarily straight-line, recovery can be necessary under deliberate obstruction, and route guards are prototype safeguards rather than online anti-cheat. No new circuit geometry, rubber-banding, weapons/items, networking, split-screen, selection menu or persistent leaderboard is introduced. **No staging, commits, pushes, tags, releases or GitHub actions.**

See [architecture, parameters and manual play instructions](racing-competitors.md), [current roadmap](../ROADMAP.md) and [version policy](../VERSIONING.md).

---

# Historical v0.3.x validation record

# v0.3.0 development patch — persistent visual oscillation, second investigation

**Unreleased; developer acceptance pending.** The developer confirmed the first contact correction did not eliminate the original high-speed visual symptom. The shoulder fix is retained; stable body Y is not visual acceptance. No version advance or roadmap change.

- Read-only Git history compared v0.2.0/v0.2.1/v0.3.0/v0.3.1. The new cosmetic script and camera obstruction changes were inspected. A/B isolation reproduced camera/render timing oscillation with cosmetic pitch essentially zero; raw physics-target follow already existed in v0.2.0, so the exact reason for the developer's v0.3.0 regression remains subject to manual confirmation.
- Final complete `tests/run_tests.gd`: **519 checks, 0 failures**, exit 0, Godot **4.7.2.stable.official.ed1daf0bf**, Windows. The prior 491 controller/race/runoff/handling/corrective/contact assertions remain. Added **28 presentation assertions** cover render-rate/pacing-invariant follow, interpolation ownership, physics-safe A/B modes, fixed orientation, shared render projection, reset, optional CSV and debug HUD.
- Native renderer probe: **12 corrected mode/rate scenarios, 0 failures**. At 79.2 km/h on the long upper straight, Normal-mode projected screen-Y range is **0.307 px at 60 FPS**, **0.211 px at 120.2 FPS**, and **0.218 px at 299.6 FPS uncapped**. Historical committed-camera comparison gives **0.232 / 3.332 / 6.465 px**, respectively (uncapped historical rate 325.6 FPS). All samples stay grounded; the presentation measurement is separate from body Y.
- Actual saved-frame marker centroid varies by **3 px before** and **0 px across eight sampled corrected frames**. Pixel capture is outside the timed rate window because GPU readback changes pacing. Timed samples use `frame_post_draw`, after camera/visual updates. Optional pads/ramp are removed only from this fixed-speed probe scene; production driving physics and features are unchanged.
- Final editor import and configured main startup (`--headless --path . --quit-after 240`) both exit 0 without script/scene/physics errors. Rendered handling capture passes, reporting real drift activity (charge 1.0167 s), `mini_turbo` on release and ramp airborne state true; handling review images refreshed. The pre-existing Windows root-certificate-store warning remains.

Implementation: explicit render interpolation in `project.godot` (version untouched), shared-pose/moving-target follow in ChaseCamera, render-only cosmetic interpolation ownership in KartVisuals, scene-local PresentationDebug and HUD integration. New presentation tests, native capture helper and historical camera fixture accompany documentation updates and pending manual checks **46–49**. The earlier kart-controller/ramp shoulder correction is unchanged by this second investigation.

Use **F3** for telemetry, **F4** for A/B/C/D, **F6** for optional CSV and **F7** for temporary 60/120/uncapped rendering. **A — Normal** is the acceptance mode. Detailed evidence, controls, measurements, fixture limitations and historical attribution are in [presentation-investigation.md](presentation-investigation.md). The exact developer-visible symptom on their hardware remains unaccepted until manually confirmed, even with the improved transform and rendered-pixel evidence. No staging, commits, pushes, tags or GitHub actions.

---

# Historical v0.3.0 development patch — vertical-contact validation (2026-11-09)

**Unreleased, manual acceptance pending; project version remains `0.3.0-dev`.** This further correction stays within v0.3.0. The existing v0.3.1 documentation history below is preserved. No roadmap/version advance or Git actions.

- Final full `tests/run_tests.gd`: **491 checks, 0 failures**, exit 0, Godot **4.7.2.stable.official.ed1daf0bf**, Windows. All 464 previous assertions remain, including real ramp takeoff/upward momentum/landing, drifting, pads, race progression, recovery and camera tests. The new suite adds 27 quantitative vertical-contact assertions.
- Four 240-tick flat-floor scenarios (idle, acceleration/braking, steering and drifting) have **zero airborne frames**. Maximum body-height range is **0.00006187 m** (under 0.062 mm); maximum camera-height range is **0.00022888 m**, without changing camera smoothing or cosmetic animation. Both sides' actual source-road exit/re-entry crossings retain contact on every sampled tick.
- Diagnosis was performed before controller changes. An identical 6,000-tick source-circuit probe changes from **56 airborne frames before** to **0 after**. The permanent shoulder assertions were additionally exercised against a temporary subclass restoring the pre-fix movement equations: two re-entry regressions fail as expected (seven airborne frames each, 8 checks/2 failures). The corrected controller passes them unchanged. No production file was reverted for that comparison.
- Final editor import (`--headless --path . --editor --import --quit`) and main startup (`--headless --path . --quit-after 240`) both exit 0 without script/scene/physics errors. The existing Windows root-certificate-store warning remains.
- Rendered handling capture exits 0 and reports active drift with 1.0167 s charge, `mini_turbo` on release and real ramp airborne state true. Review images in `artifacts/handling_*.png` were refreshed. This is scripted validation, not manual acceptance.

Root cause, temporary debug channels, collision review, exact measurements and limitations are recorded in [vertical-stability.md](vertical-stability.md). Implementation changes are limited to ordinary ground movement/takeoff selection in `scripts/kart/kart_controller.gd` and a generated launch-surface marker in `scripts/track/ramp.gd`. Tests add `tests/vertical_stability_tests.gd` and extend the runner; README, changelog, architecture and acceptance documents are updated. Nine pending manual checks **37–45** are appended; previous checks/history are retained.

The reproduced cause is false takeoff at shoulder joins; straight asphalt was already stable before the change. The developer should confirm the original visible symptom on their hardware and rerun the cumulative manual checklist. No collider dimensions/margins, gravity/snap constants, road geometry, artificial suspension or camera smoothing changes conceal the underlying contact behavior. Different devices/frame rates and exhaustive possible driving lines remain unverified.

---

# Historical v0.3.1 — Corrective Patch validation (2026-11-09)

**Unreleased, pending developer acceptance**, following **v0.3.0-dev — Arcade Handling**. The corrective work is now documented as v0.3.1 at the developer’s request; tests below ran with project/HUD identity `0.3.0-dev` and Windows resource version `0.3.0.0`. This documentation relabeling does not rerun tests or change build metadata. Roadmap milestones and accepted v0.2.0 history are preserved. Manual checks 1–26 remain preserved and checks 27–36 are appended in [the cumulative checklist](testing/ACCEPTANCE_CHECKLIST.md). No current manual pass is claimed.

## Actual results

- Before this correction: **266 checks, 0 failures**. Final complete `tests/run_tests.gd`: **464 checks, 0 failures**, exit 0, Godot **4.7.2.stable.official.ed1daf0bf**, Windows. The new corrective suite alone passed **198 checks, 0 failures**.
- Editor import (`--headless --path . --editor --import --quit`) and configured main startup (`--headless --path . --quit-after 240`) both exited 0 without script, scene or physics errors. The existing Windows sandbox root-certificate-store warning remains; it did not prevent validation.
- Geometry checks cover traced landmarks, closed finite road, upward triangle winding after widening, shared block/collider positions, exact configurable colour groups and deterministic resource rebuilding. Existing runoff driving now uses the actual infield opening and physical fence bounds.
- Every gate accepts representative road/runoff lines on both sides, including 85% of each asymmetric extent; backwards crossings and finite-edge violations fail. Continuous movement fixtures complete three ordered laps with sand crossings and a final grass finish. Isolated distant gate crossings cannot fabricate progress. Original ordering, reverse-finish, reset/recovery, timing and lifecycle scenarios remain.
- Real Area3D entries activate and propel in pad-forward direction for forward, reverse and wrong-heading approaches. Scenarios check bounded displacement/yaw, reset cleanup and nondirectional mini-turbos. Existing latch/cooldown/overlap/expiry, drift, surface, ramp, recovery and camera regressions pass. Pad occupancy tests explicitly hold the kart on the Area while verifying the latch, since propulsion now moves it out naturally.
- Generated trunks share a lightweight inscribed cylinder. Ray queries and actual kart movement verify trunk obstruction and clear passage beside the trunk under non-solid foliage.

## Rendered inspection

`tests/capture_corrective_preview.gd` exited 0 on the Compatibility renderer with NVIDIA RTX 3070 Ti Laptop GPU and saved [the corrected overhead](../artifacts/corrective_layout.png). The image was directly inspected: stepped outer frame, T-shaped infield, two access gaps, widened road and continuous grouped colours. Its separate gate probe accepted all three sampled lines at each of twelve gates (36/36). Reference-shape agreement remains subject to developer comparison, particularly corner proportions.

`tests/capture_handling_preview.gd` exited 0, reporting active drift with 1.0167 seconds of charge, `mini_turbo` after release and real ramp airborne state true. It refreshed drift, mini-turbo, pad, ramp, airborne and landing review images. These scripted scenes are not a human-driven race or manual camera/feel acceptance.

## Files and limits

Implementation is in `scenes/track.tscn`; the new `resources/barrier_run.gd` and outer/infield fence resources; TrackBuilder, BoostPad and TrackFeatures; CheckpointGate/RaceManager; KartConfig, KartController/BoostController/KartRecovery; and EnvironmentBuilder. Tests add `corrective_tests.gd` and `capture_corrective_preview.gd`, extend the runner and adapt race/runoff/handling fixtures and the race capture helper. README, changelog, architecture, controls, reference authoring and cumulative/historical acceptance documents describe current behavior.

Human reference comparison, exhaustive possible off-road racing lines, driving feel, real controller hardware, complete manual regressions and packaged Windows export remain pending. Gate sector/travel guards are course-specific safeguards, not comprehensive anti-cheat; arbitrary replacement layouts need authoring review and coverage tests. Camera obstruction remains a ray; tight-corner clipping/shadow aliasing may need tuning. No staging, commits, pushes, tags, releases, remote changes or GitHub actions were performed.

---

# Historical full v0.3.0-dev validation — Arcade Handling (2026-11-09)

This full handling patch is **Unreleased and pending developer acceptance**. Prior v0.2.0 acceptance is preserved, but no current-version manual gameplay/feel/controller retest is claimed. The canonical checklist contains the supplied exact regression checks 1–10 and new manual checks 11–26 at [testing/ACCEPTANCE_CHECKLIST.md](testing/ACCEPTANCE_CHECKLIST.md).

## Audit and automated results

The [pre-implementation audit](v0.3.0-audit.md) records the existing architecture, all three directly inspected references, and the baseline **203 checks, 0 failures**. The already-implemented runoff geometry preceded surface physics.

Final `tests/run_tests.gd`: **266 checks, 0 failures**, exit 0, with Godot **4.7.2.stable.official.ed1daf0bf**, Windows. Existing controller/race/runoff assertions remain; runoff traversal duration increases to account for the new intended surface penalties. Added checks include:

- Surface resource values, calculated acceleration/sustainable caps, gradual overspeed removal, debounce, smoothing and asphalt restoration.
- Drift activation/rejection, lateral activity requirements, countersteering, all three charge thresholds, valid release and low-speed/air/wall/invalid-release cancellation.
- Boost activation/countdown, strongest-wins rejection/refresh, explicit replacement, expiry and unchanged base config.
- Side-specific/wrapped barrier sections, actual collider absence in the authored opening, opposite-side collision and outer perimeter containment.
- Real scene ray/region detection of asphalt, sand, grass and boost pads; actual kart drift/countersteer; pad entry and occupancy/reset retrigger prevention.
- Physical air behavior retaining horizontal speed despite throttle/steering, ramp contact along the incline, tangent-based launch, safe landing and finite camera positions.
- Recovery/restart clearing drift/charge/boost, race progression preservation, upright/world-bound recovery and repeatable pad/ramp generation without duplicates.

Final editor import/script registration and configured main scene startup (`--headless --path . --quit-after 240`) both completed with **exit 0**, without script/scene/physics errors. New scenes/resources are loaded through the main scene, feature preloads and kart/surface configuration. The known sandbox certificate-store message remains the only engine error emitted on those final successful runs. The child process uses project-local `.godot/sandbox_appdata` for APPDATA, without changing system settings.

## Rendered inspection

`tests/capture_handling_preview.gd` completed with exit 0 on the **NVIDIA GeForce RTX 3070 Ti Laptop GPU / OpenGL 3.3 Compatibility renderer**. Actual rendered 1280×720 captures in `artifacts/handling_*.png` were inspected for drift, mini-turbo, boost pad, airborne state, landing, ramp, circuit layout and perimeter. This is scripted scene inspection, not a human playtest or race record. The race clock is held for reproducible captures.

The scripted driving capture accumulated **1.0167 valid drift seconds**, released, and reported the real `mini_turbo` source. Pad feedback displayed the `boost_pad` source. Ramp capture showed airborne motion followed by grounded sand contact; the incline/launch assertions run separately in the physics suite. The original road/kerb outline remains recognizable, with two pads, the optional sand ramp, the intentional outside opening and independent perimeter. No supplied reference pixels are game assets.

## Remaining acceptance and limits

- Checks 1–26 and the retained runoff manual regressions are **pending** for this build. Human driving feel, real keyboard/controller hardware, complete human-driven races, target hardware variety and packaged Windows export are not verified by these automated scenarios.
- Surface regions target the current flat terrain; custom layered/banked worlds and tight/overlapping barrier edits need author review. Keep ramp inclines within the body floor-angle limit and adapt world/perimeter/recovery bounds together.
- Camera obstruction uses a ray, not a swept volume. Tight corners can still need camera tuning; small faceted blocks/ramp edges show some shadow-map aliasing.
- Timing still uses active physics ticks. No persistent records, AI, items/weapons, multiplayer, advanced menus, online services or realistic suspension were added.
- No staging, commits, pushes, tags, releases, remote changes or GitHub actions were performed by Codex.

---

# Historical v0.3.0-dev prerequisite validation — Barrier/runoff correction

The developer confirmed on 2026-11-08 that all ten v0.2.0 manual acceptance checks passed. That is the accepted regression baseline. The current correction remains **Unreleased, pending developer acceptance**; previous acceptance does not certify its new geometry. See [the cumulative manual checklist](acceptance.md).

Before modification, the existing **179 automated checks passed**. After the correction, `tests/run_tests.gd` reports **203 checks, 0 failures**, exit 0, in Godot 4.7.2 on Windows. All earlier race/controller checks remain. The narrow-wall regression now targets the retained narrow start section, rather than assuming the entire lap has kerb-side walls.

Final editor import and configured main-scene startup (`--headless --quit-after 240`) both completed with **exit 0**, without script/scene/physics errors. The pre-existing certificate-store warning remained.

`tests/runoff_tests.gd` adds independent left/right and section-specific clearance checks, closed/finite outer geometry, configured paths clear of asphalt, consistent block lengths, box-collider positions matching CPU visual transforms, resource-edit rebuilding without duplicate nodes, scenery clearance and runoff gate rejection. Actual CharacterBody3D driving crosses both kerbs into sand/grass, stops at the outer barriers and returns to asphalt without recovery. The original 12 cm asphalt edge initially prevented re-entry; collidable sloped shoulders fix that tested failure. Handling/grip/speed calculations are unchanged.

Godot's headless dummy renderer does not retain MultiMesh GPU transforms, so headless alignment checks compare the CPU transforms actually supplied to each batch with the collider positions. Actual rendered geometry was inspected separately with the Compatibility renderer on the NVIDIA RTX 3070 Ti Laptop GPU.

Rendered correction captures are `artifacts/runoff_*.png` (use `tests/capture_race_preview.gd -- --runoff`). The overhead and normal driving view were inspected: road shape/kerbs are retained, boundaries flare only in selected sections, narrow containment remains elsewhere, and visible sand/grass aprons are accessible. Results captures remain synthetic race crossings, not new manual acceptance. All new V03-R criteria remain pending developer review.

No surface-specific physics, drift/boost or handling tuning was introduced. Arbitrary profile edits still require author inspection for nearby-road intersections and tight/overlapping contours. Profiles are editable at runtime/editor and intentionally do not auto-repair invalid layouts. Checkpoints remain road-wide.

The same pre-existing sandbox certificate-store warning was emitted; it did not prevent tests or rendering. Child-process APPDATA was redirected within `.godot/sandbox_appdata` as before. No Git mutations or GitHub actions were performed by Codex.

---

# Historical v0.2.0-dev validation — Race Foundations

The following records the original implementation validation. The developer later confirmed all ten manual checks passed, as recorded above; its original pending-review wording is historical.

Validated on 2026-11-08 with Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer. This is an **Unreleased development patch pending developer approval**, not an accepted v0.2.0 release.

## Audit and automated checks

Before modification, all **58 baseline checks passed**. The [audit](v0.2.0-audit.md) records the existing architecture, missing root lifecycle documents, actual reference locations and direct inspection of all three images.

After implementation, `tests/run_tests.gd` reports **179 checks, 0 failures**, exit 0. The runner includes the original controller/geometry/integration checks, explicitly entering RACING for driving checks, and the new `tests/race_tests.gd` suite. New checks cover:

- READY/countdown locks, 3/2/1/GO, repeated start, restart during countdown and configurable lap count.
- Active-only clocks, first/current/last/best/final times, frozen finished timing, reset clocks and millisecond formatting.
- Ordered gates, skipped/repeated entries, initial finish rejection, backwards checkpoints and backwards finish, bounded width/height, transformed planes and high-speed sweeps.
- Exactly three laps and correct final results through the real scene's gate processing.
- Latest-checkpoint manual/fall recovery, residual velocity clearing, cooldown, completed-lap/progress/timing preservation, camera snapping and crossing-baseline resampling.
- A real grounded wall jam triggering exactly one recovery, using an accelerated detector threshold for the test rather than waiting the production five seconds.
- Results/restart/return-to-ready buttons, debug checkpoint visibility and track rebuilding without stale gate references.
- Shared barrier mesh across four colour batches, instance counts and box-only barrier collision.

The integration tests use actual CharacterBody3D motion for acceleration, reverse, static collision and wall recovery. Gate race-completion tests feed known directed segments through the scene's real checkpoint detector. They are automated scenarios, not human-driven races or physical keyboard/gamepad tests.

## Rendering and scene loading

Final editor import/script registration completed with **exit 0**, without script/scene parse errors. Configured main-scene startup with `--headless --path . --quit-after 240` also completed with **exit 0**, without script/scene/physics errors. The pre-existing certificate-store warning was the only engine error message emitted by those final runs.

`tests/capture_race_preview.gd` rendered successfully on **NVIDIA GeForce RTX 3070 Ti Laptop GPU / OpenGL 3.3**. Captured and inspected images under `artifacts/` include READY, 3 countdown, GO, driving HUD, results, 1024×576 results, overhead route/infield and a barrier close-up. Standard captures are 1280×720. The results were generated with synthetic timed gate crossings for UI inspection, not obtained by manual driving. The screenshots exposed a telemetry/panel overlap, fixed by hiding normal telemetry during READY/results and using a separate darker card style.

The overhead confirms the preserved circuit centerline with a reference-shaped grass footprint; the close-up confirms original faceted X-face red/blue/yellow/green barrier blocks. These are visual observations, not a driving-feel or full-route collision certification.

## Remaining review and environment limits

- A developer must drive all three laps, test a physical gamepad and exercise R near gates/finish. Keyboard/gamepad device hardware, human handling feel and packaged Windows export remain unverified.
- Timing uses active physics delta and is quantized to a physics tick; no persistent records or wall-clock compensation is provided.
- Tight/self-intersecting replacement curves, grass footprint changes and unsupported external teleports require author care; see architecture and changelog limitations.
- The validation commands redirect child-process APPDATA to `.godot/sandbox_appdata` to avoid restricted normal user-directory writes. Godot prints the existing certificate-store warning in this environment; it did not prevent tests, scene import or rendering. The game performs no network requests.
- No staging, commits, pushes, tags, releases or GitHub actions were performed by Codex for this patch.

---

# Historical v0.1.0 validation

Validated on 2026-11-08 using Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer. The rendered preview run used an NVIDIA GeForce RTX 3070 Ti Laptop GPU / OpenGL 3.3.

## Automated results

- Editor import and script-class registration: **exit 0**, no script or scene parse errors in the final import.
- `tests/run_tests.gd`: **58 checks, 0 failures**, exit 0.
- Configured main scene startup with `--headless --path . --quit-after 120`: **exit 0**, no script/scene/physics errors.
- Rendered `tests/capture_preview.gd`: **exit 0**, captured gameplay and overhead views for inspection.

The checks cover clamping/nonfinite inputs and preservation of analogue values; acceleration, braking, reverse transitions, pedal priority and coasting; forward/reverse caps and exponential damping at 30/60/144 Hz; stationary/forward/reverse steering signs; closed curve and road seams; finite vertices, valid indices, consistent width/elevation, nondegenerate triangles and clockwise upward-facing collision geometry; road collider generation and deterministic replacement of generated nodes; actual main-scene loading, asphalt grounding, idle stability, input registration, world displacement under acceleration, forward/reverse speed bounds, reverse braking, reset velocity/transform, camera reset and static barrier response.

The integration test drives a real CharacterBody3D through the real PlayerInput provider using `Input.action_press/release`. It is not a manual playtest or hardware input test. The loop waits for physics frames; the mathematical multi-rate tests exercise the shared pure dynamics functions.

## Rendered inspection

`artifacts/first_drive.png` shows the actual starting camera, HUD, kart, road, checkered line, barriers, gantry and environment. `artifacts/circuit_overview.png` shows the closed reference-inspired circuit and scenery. Both were captured from Godot's rendered viewport and visually inspected. Road bend handles were adjusted to remove narrow offset folds, and the road collision winding was corrected after an integration test exposed grounding on the sand below the road. Regression checks now require asphalt-height grounding and the correct face winding.

## Environment note

The restricted execution environment prevented writes to the normal roaming AppData directory. Validation commands redirected the child process's `APPDATA` into `.godot/sandbox_appdata` within this project. This temporary environment change was local to the validation command, not a project setting or system change.

Godot also printed `Failed to read the root certificate store` in the sandbox. It did not prevent import, scene loading, physics tests or rendering. The game makes no network requests. Normal interactive editor launch outside this sandbox has not been checked.

## Limits and review work

- **Manual driving feel and physical keyboard/gamepad hardware have not been tested.** Check responsiveness, trigger mapping, camera readability and corner speeds in the editor.
- The circuit is an adapted centerline reconstruction, not an exact trace of every road edge or infield barrier. Scenery uses the supplied palette with simple original primitives.
- The builder assumes a flat, nonintersecting curve with adequate bend radii. It does not automatically repair invalid user edits, crossing roads or overlapping offset edges. Width-only edits require an Environment rebuild to refresh scenery clearance.
- No camera obstacle avoidance, suspension, off-road penalty, lap validation, race results, audio or Windows exported executable is included/tested. Race foundations belong to v0.2.0.
- Matching Windows export templates must be installed before using the supplied export preset. Other Godot versions and GPUs have not been exercised.
