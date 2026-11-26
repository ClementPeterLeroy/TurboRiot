# v0.6.1-dev — Circuit Selection & First Testing Grounds validation

2026-11-11. **Unreleased, pending developer acceptance.** Audit baseline was clean `1d97794` (v0.6.0). Earlier validation sections below remain unchanged. Current metadata is `0.6.1-dev` / Windows `0.6.1.0`. Full architecture, reference evidence, comparison limitations and commands are in [Testing Grounds](testing-grounds.md).

## City Square feedback correction — current results

2026-11-27. [Diagnosis, changed files and developer procedures](city-square-feedback.md). House designs are developer-approved; circuit/correction acceptance remains pending. Version stays **0.6.1-dev**, Unreleased. Earlier construction results below retain their original scope.

- Final regression suite: **1,300 checks, zero failures**, headless at fixed 60 Hz. The additional 26 assertions exercise 20 m stair-street support, actual house clearance, joined frontage lots, full-width avenue crossings, both garden gates on real grass, material re-entry, two queued rebuilds and six physical finish/plaza traversals. The original start-line fixture reproduced **4.415 m motion / about 4.4 m sideways** in one physics frame; current maximum is about **0.367 m** with negligible lateral movement. [Current contact report](../artifacts/v061_city_feedback_contact.json). Existing circuits, contact, presentation, AI and item regressions remain enabled.
- Native full-scene editor opening: **three runs, exit 0**, no unexpected errors. [Report](../artifacts/v061_city_feedback_editor.json). Initial investigation reproduced a native signal-11 crash once, while later unmodified full/isolated openings passed. Deferred editor helper generation, queue reset and idempotent overrides harden this path, but do **not** prove the root cause of that intermittent engine fault. Developer-session reopening remains criterion 222.
- Native 1920×1080 Time Trial on the corrected assembly: **74.567 s**, **zero recoveries**, **zero camera obstructions across 4,655 samples**. [Current report](../artifacts/v061_city_native_lap.json). The injected AI now uses the same directed route construction as real AI competitors, rather than the human line that also projects alternatives. An earlier attempt with that unsuitable fixture was interrupted; it is not counted as a passing native run.
- Final 135-house assembly: **all seven racers finish three item-enabled laps**, Challenging, seed 42, **211.70–227.53 s**, 34 pickups / 30 uses. Moxie and Comet each recover once; the other five have zero recoveries, no DNF. [Final report](../artifacts/v061_city_feedback_ai_race_2_7_3_all_ai_items.json). An intermediate 125-house assembly completed the same race without recovery; that result does not replace this final assembly's measurements or establish zero-recovery traffic reliability.
- Three-lane physics runs keep normal driving velocity across the finish/plaza; avenue support probes no longer drop into terrain or hit a raised plateau edge. Both garden checkpoint tests cross real grass beyond paved bounds and pass legal-progress checks without removing ordered/directional validation. **All six house GLBs and six source masters remain identical**: [hashes](../artifacts/v061_city_feedback_house_preservation.json). Site placement is now 135 instances, with continuous party-wall positions inside each terrace block; junctions remain open.
- Isolated stair-sector fixture after widening/contact correction: **9.3667 / 9.4000 s**, both complete with zero recovery. [Current](../artifacts/v061_city_stair_times.json), [initial](../artifacts/v061_city_initial_stair_times.json). Both approximately 120.1593 m routes still descend 5.4 m. A near-equal automated profile does not accept manual handling/fairness.
- Same-process native 1080p, Compatibility, uncapped/VSync off, seven racers, Challenging, items seed 42: Circuit 8 **127.11 FPS**, City Square **96.52 FPS**; mean frame **7.87 / 10.36 ms**, P95 **14.73 / 18.36 ms**, P99 **16.52 / 35.88 ms**. **1,306 / 174** collision shapes, about **1,238 / 943** draw calls and **567k / 161k** rendered primitives. [Current comparison](../artifacts/v061_city_feedback_performance.json). Same RTX 3070 Ti Laptop GPU / Ryzen 7 6800H. Average FPS exceeds 60 here, but City spikes exceed the 16.67 ms budget; this is not a sustained minimum-60 claim. Do not compare percentages against the earlier 59.8 FPS run conducted under different load conditions.

Godot headless editor import passes. Current logs are `.godot/city_feedback_*.log`; known Windows certificate-store warnings persist. Native sector/structural captures show the current assembly. Prior test runs had temporary fixture parse errors, corrected before the passing complete suite; no such errors remain in final logs. Manual criteria **222–228** append to unchanged 1–221, with no release acceptance or Git/GitHub operations.

## City Square initial construction — preceding results

2026-11-27. [Implementation, scene hierarchy, editable sources, sector captures and limitations](city-square.md). Still **0.6.1-dev**, Unreleased pending developer acceptance. The initial two-beta-circuit delivery and historical validation below remain unchanged; City Square is now the fourth gallery circuit.

- Final complete automated suite: **1,274 checks, zero failures**, including the final recovery/preview assertions, timer-test correction and decorative stair cleanup. Existing road/handling/presentation/race/item tests remain enabled; City coverage adds authored loading, four physically supported route combinations, equal street length/drop, common stations and gate rounding, upright selected-branch recovery, direct authoritative preview resources, exposed dock edges and real water-fall recovery without awarded progress. A separate final three-lane audit tested **6,756 support rays**, all hitting stone/wood on all four route variants. Python authoring sources parse successfully; all **221 unique manual-check IDs** remain contiguous with no missing IDs. Automated success does not mark them manually accepted.
- Native 1920×1080 application Time Trial: **75.483 s**, **zero recoveries**, **zero camera obstructions across 4,710 physics samples**. [Report](../artifacts/v061_city_initial_native_lap.json). This uses physical AI commands and the normal player chase camera; it is not human playtesting. Six sector and structural captures plus both stair streets were inspected. Stair meshes were subsequently joined along actual cross-sections to remove midpoint-box intersections; their driving collision stays smooth and unchanged.
- A seven-racer, three-lap item-enabled diagnostic rerun, Challenging, seed 42, finished all seven in **213.8–253.35 s**, with **0–4 recoveries each**, **41 pickups / 35 uses**. [Passing report](../artifacts/v061_city_diag_ai_race_2_7_3_all_ai_items.json). An earlier run had six finishers and **one DNF**, with up to 15 recoveries: [failed report](../artifacts/v061_city_ai_race_2_7_3_all_ai_items.json). Branch-entry float32 tolerance and route-aware upright recovery corrected reproduced progress/heading problems. Traffic reliability remains a beta tuning limitation; a passing seed is not a robust no-recovery certification.
- Physical isolated stair runs, identical profile and 17 m/s initial speed, no traffic: outer **10.7667 s**, inner **9.4167 s**, both complete without recovery. Timing includes 12 m before/after the junctions. Both routes measure **120.1596 m** and descend **5.4 m**; equal geometry length does not establish balanced time. [Report](../artifacts/v061_city_initial_stair_times.json). Further geometry/line balance and manual driving review remain required; no artificial speed penalty masks this difference.
- Same-process native **1920×1080**, Compatibility, VSync off/uncapped, seven racers, Challenging, items seed 42: Circuit 8 **56.81 FPS**, City Square **59.80 FPS**; mean **17.60 / 16.72 ms**, P95 **20.71 / 17.43 ms**, P99 **36.26 / 17.97 ms**. Approximately 60 Hz physics; **1,306 / 245** collision shapes, roughly **1,465 / 1,308** draw calls and **604k / 204k** rendered primitives. RTX 3070 Ti Laptop GPU / Ryzen 7 6800H. [Complete report](../artifacts/v061_city_performance.json). This short comparison predates the final decorative tread-only adjustment. Different route/view timing and run conditions prevent comparison with earlier 130+ FPS historical samples. It approaches the target on this run, not a sustained minimum-60 guarantee.
- Godot 4.7.2 headless editor import and application runtime smoke exit 0. Local logs: `.godot/city_final_import.log`, `.godot/city_runtime.log`, `.godot/city_suite.log`, `.godot/city_surface_audit.log`, `.godot/city_final_capture.log`; earlier native/AI/performance logs and JSON reports remain available. The known Windows certificate-store warning persists. A render-frame-based analog-repeat assertion failed under concurrent capture load; the test now awaits the actual timer and verifies its configured initial delay rather than equating render-frame count with elapsed time.

No existing circuit meshes/scenery, driving constants or version metadata changed. Broader gameplay feel, both stair visuals/seams, full building/coast inspection, traffic reliability, route time balance, sustained performance, controller hardware and exported builds remain manual work. Criteria **214–221** append to the unchanged cumulative 1–213 history. No staging, commits, pushes, tags or GitHub operations.

## Circuit selection gallery — preceding results

2026-11-26. [Design, metadata, captures and file scope](circuit-gallery.md). Version remains **0.6.1-dev**, Unreleased pending developer acceptance. No gameplay/geometry changes or Git mutations.

- Full suite: **1,224 checks, zero failures**, preserving 1,183 and adding 41 gallery assertions. All six display names, three original playable IDs/scene references, deferred entry filtering, actual source samples, uniform projection, cache invalidation, elevated crossing, absence of visible developer labels, selection versus launch, remembered choices and teardown pass. The existing three-circuit/two-mode launch tests remain enabled; their navigation keys now match the horizontal layout.
- Mouse, keyboard, D-pad and A/B interaction tests pass. Analog-axis injection verifies navigation, 0.55 deadzone, 0.4 s initial repeat delay, subsequent repeat and release stopping. A separate Start action loads the selected existing scene; card confirmation never launches by itself.
- Native captures at **1920×1080, 1280×720, 960×540 and 1024×768 / 125% UI** were inspected. Names, distinct actual outlines, selection/focus, single description and footer remain readable without vertical scrolling or clipping. Automated bounds/scroll checks include 960×540 at 150% UI and a six-card growth fixture: added cards follow focus horizontally while footer actions remain visible.
- Godot 4.7.2 headless editor import and application smoke exit 0. Final logs: `.godot/gallery_import.log`, `.godot/gallery_runtime.log`, `.godot/gallery_suite.log`, `.godot/gallery_capture.log`. The inherited Windows certificate-store warning remains the only expected engine error/warning.

Only three circuits currently have authoritative race integration. Legend Park is a standalone authoring fixture; Riot Arena and Sunhaven Square are deferred catalog entries. They have no invented public previews/launch cards. Physical controller hardware and exported builds remain manual acceptance items **208–213**. Previous texture-import edits remain local; engine validation can refresh their derived metadata. Existing kart/camera/track/model source files are unchanged. Earlier results below retain their historical scope and names.

## Circuit 8 final logo/pad polish — preceding results

2026-11-26. The developer approved the existing stadium/environment reconstruction and artistic direction. [Final polish file scope, screenshots and behavior](figure8-final-polish.md). Only the official two-sided gantry artwork and two functional pads are added; version remains **0.6.1-dev**, Unreleased pending final acceptance.

- Full suite: **1,183 checks, zero failures**, retaining 1,154 plus 29 polish assertions. Exact supplied-art hash/aspect/alpha/centering/outward orientation, absent font wordmark, pad placement/tuning, real Area3D crossings, speed limits, zero approach airborne frames, expiry, occupied/reset latching and a fresh physical AI lap activating both pads pass. Other stadium materials still require opacity. Existing geometry/contact/handling/presentation/race/item tests remain active.
- Seven physical AI racers, three item-enabled laps, seed 42: all finish with **zero recoveries/DNF**, 34 pickups and 33 uses. Bound-entry trace records six racers on the bridge pad and all seven on the corner-exit pad; accepted AI activations are separately verified by the permanent AI-lap regression. Native 1920×1080 lap: **33.283 s**, zero recoveries and zero camera obstructions across **2,178 physics samples**.
- All previously approved model/module files remain byte-identical except `start_gantry.blend`, its GLB and native wrapper. The circuit scene gains only the pad reference/instance; exact curve/width/elevation/handle regressions pass. The logo reference PNG remains unchanged; runtime copy has the same SHA-256. [Preservation evidence](../artifacts/v061_final_polish_preservation.json).
- Isolated same-process 1080p seven-racer comparison, Compatibility, VSync off/uncapped, 60 Hz physics: new pads/logo disabled **118.91 FPS**, enabled **134.80 FPS**; P99 **17.02 / 15.20 ms**. [Report](../artifacts/v061_final_polish_performance.json). Both cases already omit the old font wordmark, so this isolates enabling the new features rather than reproducing the historical approved image. Boosts change race/view timing and sampled geometry; the improved average is not an optimization claim. This short run shows no material regression here, not a sustained minimum-FPS guarantee. Reproduce with `tests/benchmark_figure8_polish.gd` without `--fixed-fps`.
- Godot 4.7.2 headless editor import/runtime smoke pass, alongside the native captures and Blender's localized gantry re-export. Final `.godot/final_polish_*.log` files contain no unexpected engine errors/warnings; the inherited Windows certificate-store warning remains.

Both logo faces and both pad approaches were inspected using normal chase-camera captures. The logo intentionally occupies 3.84 × 1.638 m inside the much wider existing beam to preserve its ratio. No arch geometry, stadium design, lighting, camera, kart physics, original pad tuning or unrelated gameplay was changed. Manual criteria **203–207**, sustained target-device review and exported builds remain pending. No Git mutations or GitHub actions; all earlier history and owner edits remain preserved.

## Circuit 8 stadium environment — preceding results

2026-11-26. [Asset/editing guide, six chase-camera sites and limitations](figure8-stadium.md). The developer authorized the full environment after reviewing the road stage. Bridge/approach infrastructure, curved stands, pit/control architecture, safety/perimeter and material/signage stages are implemented within **0.6.1-dev**, Unreleased pending developer acceptance.

- Full suite: **1,154 checks, zero failures**, preserving 1,133 and adding 21 stadium assertions. Exact road positions/handles/width/sampling are retained. All metre-spaced, three-lane road-support rays hit the original asphalt; approach banks face upward and the underpass leaves **6.738 m** of physical headroom. Shared model instances, complete architecture, opaque materials and road-rebuild preservation pass. Existing 52 crossing assertions and all prior contact, handling, presentation, race and item regressions pass.
- Seven real AI racers, three item-enabled laps, seed 42: all finish, **zero recoveries/DNF**, 32 pickups / 31 uses. Native 1080p application Time Trial: **33.383 s**, zero recoveries, **zero camera obstructions in 2,184 physics-frame rays**. Native lap report includes resolution and obstruction data. Static six-site captures use the actual shared chase camera; overview, top and structural-side images are also inspected.
- Isolated same-process 1920×1080, Compatibility, VSync off/uncapped, seven racers, Challenging, items seed 42: road study **172.67 FPS**, stadium **132.92 FPS**. P95 frame **12.94 → 14.10 ms**, P99 **15.04 → 16.59 ms**, approximately 60 Hz physics. Mean draw calls **683 → 1,287**, rendered primitives **225k → 574k**, collision shapes **1,142 → 1,304**. Hardware: RTX 3070 Ti Laptop GPU / Ryzen 7 6800H. [Complete report](../artifacts/v061_stadium_performance.json). This short sample supports the 60 FPS target in this configuration; it is not a guaranteed minimum or long-session certification. The baseline is the exact archived road study, not the rejected earlier stadium.
- Blender model/export, Godot 4.7.2 headless editor import and application runtime smoke pass. Final logs: `.godot/stadium_blender.log`, `.godot/stadium_import.log`, `.godot/stadium_runtime.log`, `.godot/stadium_suite.log`, `.godot/stadium_capture.log`, `.godot/stadium_ai.log`, `.godot/stadium_native_lap.log`, `.godot/stadium_performance.log`. Only the existing Windows root-certificate-store warning appears in the final engine logs.

Spectators, gantry lights and timing board are decorative/static; glass is opaque, masts add no dynamic lights, the pit apron adds no racing route, and outside terrain remains the original test floor. Thin fences can alias. Read the full visual limitations before acceptance. Manual criteria **193–202** are appended, preserving 1–192. No kart/camera/controller or version metadata changes, no Git mutations; the owner's pre-existing banana edit is retained.

## Circuit 8 reconstruction — Milestone A, preceding results

2026-11-26. [Audit, editable sources, screenshots and remaining defects](figure8-road-reconstruction.md). Road reconstruction only; version remains **0.6.1-dev**, Unreleased pending developer acceptance.

- Full suite: **1,133 checks, zero failures**, retaining 1,116 plus 17 road contracts. Closure, derivative continuity, width, triangle validity, approximately 8 m rise, maximum grade below 8%, crossing separation and archive preservation pass. Existing 52 crossing assertions and all handling/contact/presentation, race and item suites remain enabled. The old environment's 13 checks run on its archived scene.
- Seven physical AI racers, three item-enabled laps, seed 42: all finish without DNF or recovery; 32 pickups and 31 uses. Native application Time Trial completes one lap in 33.383 s with zero recoveries and correct results. Top, overview and actual chase-camera captures were inspected, including a native driven-lap image.
- Half-metre audit: maximum grade **12.55% → 7.69%**, minimum sampled horizontal radius **21.22 → 24.40 m**, length **663.56 → 663.43 m**, width unchanged at 15 m. All horizontal interpolation positions are retained; approaches extend into the loops.
- Same-process native 1080p full-field sample: archived scene **144.5 FPS**, road study **175.6 FPS**; P99 **14.12 / 14.60 ms**, respectively. Scenery is omitted and kerbs batched: this is a road-stage budget observation, not a finished-art comparison or universal FPS guarantee.
- Godot 4.7.2 headless editor import and application smoke exit 0. Final logs: `.godot/reconstruction_import.log`, `.godot/reconstruction_runtime.log`, `.godot/reconstruction_suite.log`, `.godot/reconstruction_ai.log`, `.godot/reconstruction_native_session.log`, `.godot/reconstruction_performance.log`. The existing Windows root-certificate-store warning remains the only engine error/warning in final engine logs.

Raised approaches still float above placeholder ground. Bridge thickness/supports, final barriers, curved stadium/pits, materials and lighting await B–D. Developer driving/artistic review remains pending checks **188–192**. No changes to kart physics/camera or version metadata; no Git mutations. The pre-existing banana resource edit is untouched. Earlier results preserve their original scope and dates.

## Banana spin direction correction — preceding results

2026-11-21. The 540° configured banana spin finished half a turn away from its incoming heading, then restored traction toward that reversed heading. Changed only `resources/items/banana.tres` rotation to **360°**. Existing physical rotation/inertia/control recovery code, 1.65-second disruption, 0.5 momentum retention/speed multiplier, 0.2 grip, 0.35-second control recovery and shell tuning remain unchanged. Legitimate steering still applies normally; there is no heading teleport, route alignment or duplicated movement branch.

- Before the resource change, focused tests reported **153 checks, three failures**: the updated rotation contract and both new physical-body heading/travel regressions. Old banana body rotation measured 540°.
- Final full suite: **1,116 checks, zero failures**, retaining the prior 1,114 checks and adding two physical integration assertions. Real human and AI victims complete 360° and resume forward travel on a straight. Existing multirate rotation, slowdown, grounding, wall separation, airborne behavior, smooth control recovery, overlapping hits and recovery/restart/finish cleanup tests pass. The generic 540° wall-contact fixture remains as shared-effect stress coverage; normal banana gameplay now uses the resource's 360° setting.
- Godot 4.7.2 headless editor import and application runtime exit 0. Final logs: `.godot/banana_heading_import.log`, `.godot/banana_heading_suite.log`, `.godot/banana_heading_runtime.log`; the existing certificate-store warning remains the only engine warning/error. Original failing evidence is `.godot/banana_heading_before.log`.

Manual feel/steering/camera review remains pending checks **185–187**. Prior 540° development/changelog/test history is preserved. No version increment, staging, commits, pushes, tags, releases or GitHub actions.

## Yoshi coastal environment — preceding results

2026-11-21. [Assets, artist workflow and screenshots](yoshi-environment.md).

- **1,114 checks, zero failures**: 1,103 retained plus 11 new support, tunnel, source-road identity, shared-instance, sea-floor and rebuild assertions. Original handling, presentation, race, item and other-circuit regressions remain enabled.
- Sampled arch clearance across each tunnel's driving width is at least **9.768 m**. The native grass island supports the road and both shoulders; water beyond its outline has no hidden grass floor. Road Curve3D/trace, TrackBuilder, shared loader, controller, camera, Circuit 8 scene and owner Baby Park source hashes remain unchanged.
- Controlled native benchmark, same process/GPU, 1920 × 1080, VSync off/uncapped, seven AI, Challenging, items seed 42, 60 Hz physics: **130.89 → 126.68 FPS**, mean frame **7.64 → 7.89 ms**, P95 **13.68 → 12.21 ms**, P99 **15.91 → 15.02 ms**. Physics mean **7.69 → 7.11 ms**, render CPU **3.18 → 3.39 ms**, GPU **0.92 → 0.92 ms**. Timing variation does not establish a physics optimization. Complete GPU/CPU, draw, memory, collision and cache-influenced load data are in `artifacts/v061_yoshi_environment_comparison.json`. The run supports the 60 FPS target in this configuration; it does not guarantee whole-lap minimum FPS or lower-end hardware performance.
- Native views use `artifacts/v061_yoshi_environment_{overview,top,paddock,tunnel,gardens}.png`; full physical race report and application-flow captures use the same prefix. See the environment guide for actual race completion and remaining manual acceptance.
- Final physical seven-racer, three-lap item race passes with **zero recoveries / DNF**, times 227.800–232.033 s. Native 1080p Time Trial completes in **77.633 s**, zero recovery. Godot 4.7.2 headless import, application smoke and native captures pass; final logs contain only the existing Windows certificate-store warning.

Logs are local under `.godot/yoshi_*`. No version/export metadata or Git mutations. Developer checks 177–184 remain pending, including real input/camera feel, artistic review, all difficulties, exported builds and prolonged play.

## Circuit 8 environment assembly — preceding results

2026-11-14. [Full audit, assets, editing instructions, screenshots and measurement limits](figure8-environment.md).

- Complete suite **1,103 checks, zero failures**: retained 1,090 plus 13 environment assertions. The existing 52 crossing regressions pass without changed tolerances. New support/grass/material/resource-sharing/corridor/loading/rebuild tests pass; sampled physical underpass headroom is at least **4.641 m**.
- Godot 4.7.2 headless editor import, native multi-view capture and native application Time Trial pass. The latter completes a full 1080p physical lap in **33.533 s**, zero recovery. No source-road, controller, camera or other-circuit environment changes.
- Seven AI / Challenging / three laps / items seed 42: all finish, no DNF, 28 pickups / 26 uses, one recovery total, times 98.317–105.683 s. Report: `artifacts/v061_figure8_environment_ai_race_2_7_3_all_ai_items.json`.
- Controlled same-process native before/after benchmark, RTX 3070 Ti Laptop GPU / Ryzen 7 6800H, 1920 × 1080, VSync off/uncapped, 60 Hz physics, seven AI and items: **170.4 → 164.5 FPS**; P95 frame 11.29 → 11.54 ms; P99 12.63 → 12.63 ms. Draw calls 1,185 → 1,205; collision shapes 1,142 → 1,194. CPU/GPU time, primitives, objects, memory and cache-influenced load timings are in `artifacts/v061_figure8_environment_comparison.json`. The short run supports the 60 FPS target in this case, not a universal minimum or sustained 120 FPS guarantee.
- Five inspected geometry captures use `artifacts/v061_figure8_environment_{overview,bridge,underpass,grandstand,top}.png`; native flow captures use `v061_figure8_environment_flow_*`. Blender sources are retained under the assets' import-excluded `sources/` folder.
- Final logs `.godot/figure8_environment_{import,suite_final,crossing,ai_race,captures,native_flow,comparison}.log` contain only the known certificate-store warning, with no script/runtime errors. Protected road/kart/other-circuit source hashes and Curve3D/configuration are unchanged.

Developer/artistic checks 167–176 remain pending, including real controls, edge-case camera views, all AI difficulties, exported builds and prolonged performance. No version/roadmap milestone changes, staging, commits, pushes, tags, releases or GitHub actions.

## Bikini Bottom test_v2 recovery wiring — preceding results

2026-11-13. `Bikini_bottom_test_v2.tscn` was a separate scene without the original sandbox's recovery script/bindings. It therefore used (178,158) m horizontal half-extents and the −8 m fall threshold. Running the shared physical recovery regressions against both scenes before the fix produced **28 checks, four failures**, all in v2: insufficient fall clearance, road outside the envelope and false recovery during both low/outer-road contact scenarios.

The v2 root now uses the existing `imported_test_recovery.gd`, bound to `bikini_bottom_test_track/BikiniBottom_test_v1` and `Kart`. Its computed half-extents are **236.544 / 151.069 m** and fall threshold **−22.004 m**. Road/model/collision/spawn/camera and the shared recovery implementation remain unchanged. Reimported geometry is measured on each fresh scene start.

- Complete suite: **1,090 checks, zero failures**, retaining 1,076 and adding the same 14 assertions for v2. Both actual sandboxes retain support for 120 ticks at each low/outer sample, reject the legacy reset limits and retain fall/bounds/manual recovery and cooldown behavior.
- Godot 4.7.2 headless editor import and a 180-frame direct v2 runtime both exit 0. Local logs: `.godot/bikini_v2_before.log` (expected failures), `.godot/bikini_v2_import.log`, `.godot/bikini_v2_tests.log`, `.godot/bikini_v2_runtime.log`.
- Stop the running game, open `scenes/tracks/Bikini_bottom_test_v2.tscn` and launch with F6. Manual full-lap checks 165–166 remain pending; no race integration or performance acceptance is implied. Future sandbox copies must retain the root script and bind their own road/kart. Version unchanged; no Git mutations.

## Bikini Bottom sandbox recovery correction — preceding results

2026-11-12. The imported test road exceeded the shared KartRecovery defaults in both depth and horizontal extent. A script attached only to `scenes/tracks/Bikini_bottom_test.tscn` now calculates the world-space road AABB at startup and configures that kart's existing Recovery component. For the current GLB/transform: X/Z half-extents **236.544 / 151.069 m**, fall threshold **−22.004 m**. Margins are exported on the test-scene root. The authored spawn remains in place and is verified to have road support. Shared recovery/handling/geometry and other circuit settings are unchanged.

- Godot 4.7.2 complete suite: **1,076 checks, zero failures** (1,062 retained + 14 new).
- Tests exercise the real imported scene/collider. Both legacy limits reproduce a reset on actual road triangle locations; after configuration the real kart remains grounded for 120 physics ticks at each of the low/outer locations, without recovery.
- Every collision triangle centroid is inside the configured envelope. Escaping the X/Z bounds or falling below the new threshold still returns to the authored safe spawn; manual recovery and cooldown also pass. Shared defaults remain −8 m and (178,158) for existing consumers.
- Headless editor import and a 180-frame direct sandbox runtime both exit 0. Logs: ignored `.godot/bikini_recovery_import.log`, `.godot/bikini_recovery_tests.log`, `.godot/bikini_recovery_runtime.log`.

Stop/relaunch the sandbox with F6 to apply the startup configuration. Bounds recalculate after a reimport and fresh scene start; they do not update continuously while a running model is edited. This correction does not regenerate the sandbox's saved collision snapshot or add race/AI integration. Human full-lap checks 162–164 remain pending; it is not a claim that every possible recovery cause is eliminated. No version increment or Git mutations.

## Circuit racing performance correction — preceding results

See [diagnosis, implementation and benchmark procedure](circuit-performance.md). Flat-road collision now uses exact-top convex sections; elevated/banked roads retain the prior triangle collision. Minimap routes use cached display-resolution paths and independent live marker drawing. No handling, camera, AI difficulty, scenery or version change.

- Final suite: **1,062 checks, zero failures** (1,041 retained + 21 collision/minimap assertions), with all Figure-8 crossing and prior stability regressions intact.
- Godot 4.7.2 headless editor import, complete suite and configured-application runtime all exit 0. Only the existing Windows certificate-store warning remains.
- Controlled native A/B, same process/GPU (AMD Radeon(TM) Graphics), 1280 × 720, seven AI, Challenging, items seed 42, uncapped rendering, 60 Hz physics: **Yoshi 10.5 → 77.4 FPS**, reference **48.4 → 116.9 FPS**. Yoshi 95th-percentile frame time falls from 129.97 to 18.37 ms. Hardware-specific short-run results, not a universal performance guarantee. Full report: `artifacts/v061_circuit_performance.json`; reproducible fixture: `tests/benchmark_circuits.gd`.
- **Yoshi, seven AI, three laps, Challenging, items seed 42:** all finish, no DNF or recovery; 30 pickups / 30 uses; times 227.917–232.383 s. Report: `artifacts/v061_performance_yoshi_ai_race_2_7_3_all_ai_items.json`.
- **Reference, seven AI, one lap, Challenging, items seed 42:** all finish, no DNF or recovery; 10 pickups / 10 uses; times 30.617–35.650 s. Report: `artifacts/v061_performance_reference_ai_race_2_7_1_all_ai_items.json`.
- Native application Time Trials pass: Figure-8 33.533 s, Yoshi 77.633 s; no recoveries. Selection/READY/live-map/results captures use `artifacts/v061_performance_*.png`, preserving previous captures.

Logs: ignored `.godot/performance_*.log`, `.godot/circuit_performance_final.log`. Manual criteria 157–161 extend retained 1–156. Developer hardware, human driving, exported builds and prolonged-play performance remain pending acceptance. No staging, commits, pushes, tags, releases or GitHub actions performed.

## Figure-8 crossing correction — preceding validation

The [collision investigation](figure-8-crossing-fix.md) reproduced a sharp kart-box underside catching a triangle seam and producing a secondary opposing wall normal. The final change is confined to the shared kart collision hull: an upper native box and two native lower spheres, retaining the original combined dimensions. Road/trace/barrier, controller/handling, surface and camera code remain unchanged. Experimental road replacements and beveled/capsule hulls were rejected and removed.

- Full suite: **1,041 checks, zero failures** (989 retained + 52 crossing assertions), without removed checks or relaxed existing tolerances.
- All 12 targeted physical traversals complete with zero airborne frames and zero false wall contacts. Lowest measured horizontal motion is 21.814 m/s at the 22 m/s normal speed and 30.551 m/s under a 30.8 m/s mushroom boost. Tests include three lanes on the upper approach, the opposite direction and the lower underpass. Replacing only the new hull with `--legacy-box` fails 13/52 assertions, as expected.
- Unmodified road collision differs from the sampled visual surface by at most 3.35 mm across the measured lanes. Actual kart-contact, wall, drift, ramp/jump, recovery/restart, original ground/presentation and item regressions pass. Shell/banana flat-spin body-height variation stays below 0.0000004 m.
- Godot 4.7.2 headless import and configured-application runtime both exit 0. Final logs contain the existing Windows certificate-store warning, with no script/runtime errors.
- **Figure-8, 7 AI, 3 laps, Challenging, items, seed 42:** all seven finish; no DNF; 28 pickups / 26 uses; one recovery total; finishing times 98.317–105.683 s. Report: `artifacts/v061_crossing_fix_figure_ai_race_2_7_3_all_ai_items.json`.
- **Original reference circuit and Yoshi DS, 7 AI, 1 lap, Challenging, items, seed 42:** all seven finish on each circuit; no DNF or recovery. Reports use `v061_crossing_fix_reference_*` and `v061_crossing_fix_yoshi_ds_*` prefixes, preserving earlier evidence.
- Native application Time Trials also complete without recovery: Figure-8 33.533 s and Yoshi DS 77.633 s. New captures use `artifacts/v061_crossing_fix_*.png`; earlier captures remain preserved.

Quantitative summary: `artifacts/v061_crossing_fix_validation.json`. Logs: ignored `.godot/crossing_*.log`. These are automated/native checks, not developer acceptance or physical-controller testing. New manual criteria 152–156 extend the retained 1–151. No version increment, staging, commits, pushes, tags, releases or GitHub actions were performed for this correction.

## Initial v0.6.1 delivery results

| Check | Actual result |
| --- | --- |
| Original automated baseline | 925 checks, 0 failures |
| Expanded permanent suite | **989 checks, 0 failures**; all original checks retained |
| Godot 4.7.2 headless editor import | Exit 0; no script/import errors |
| Configured application headless smoke | Exit 0, 60 frames; no script/runtime errors |
| Figure-8 geometry | Closed seam, full 15 m width, 1328 finite/correctly wound road triangles; 663.56 m loop |
| Yoshi DS geometry | Closed seam, full 19.5 m width, 2378 finite/correctly wound road triangles; 1188.52 m loop |
| Route topology | No at-grade centerline intersections; exactly one separated Figure-8 projected crossing with over 4 m clearance |
| New regression coverage | Grid separation, directional/adjacent-route gate rejection, circuit-local pickups, recovery, opt-in tilt frame, shared previews/minimap, mouse/keyboard/injected pad selection, rapid Back, both modes, six switch/restart/disposal cycles |
| Figure-8 final Challenging / 7 AI / 3 laps / items / seed 42 | All finish, no DNF, 36 pickups / 35 uses, 2 recoveries total; times 102.883–162.433 s |
| Yoshi DS Challenging / 7 AI / 3 laps / items / seed 42 | All finish, no DNF, 30 pickups / 30 uses, zero recoveries; times 227.700–233.367 s |
| Native application Time Trial, Figure-8 | One lap, one kart, no competitive items; 34.867 s, zero recoveries |
| Native application Time Trial, Yoshi DS | One lap, one kart, no competitive items; 77.633 s, zero recoveries |
| Native menu/display captures | Circuit cards/selection, 1280×720 and 1024×768 at 125% UI scale, both READY/minimap/results screens; inspected captures |
| Source comparison | Native orthographic maps aligned to source dimensions; ignored private annotations/overlays/side-by-sides generated; fit/mask measurements in `artifacts/v061_trace_comparison.json` |

Final reports: `artifacts/v061_figure_final_ai_race_2_7_3_all_ai_items.json`, `artifacts/v061_yoshi_ai_race_2_7_3_all_ai_items.json`. Earlier initial Figure-8 validation is preserved separately and passed before Yoshi geometry began. Source-comparison bitmaps stay private in ignored `references/analysis/`; native geometry-only captures use `artifacts/v061_*.png`. Logs are local under ignored `.godot/v061_*.log`, with process-local APPDATA redirected inside the workspace. Windows continues to emit the existing unavailable root-certificate-store warning; scans found no other engine/script errors in final runs.

These are automated/native-render checks, not developer acceptance, physical-controller testing or human handling assessment. Review cumulative checks **1–151**, including source silhouette/width comparisons, Figure-8 bridge/camera clearance, high-speed visual presentation, all AI difficulty profiles and real devices. Curvature fitting, constant widths and crossing elevations are documented approximations. Broad hardware performance, long-duration allocation profiling and exported builds remain unverified. No stage/commit/push/tag/release/GitHub/remote actions were performed.

# v0.6.0-dev — Playable Alpha validation

2026-11-10. **Unreleased, pending developer acceptance.** Baseline source audit found HEAD `e22a2f2` titled v0.5.1, earlier v0.5.0 commit `a31ff9f`, and runtime metadata still `0.5.0-dev`. Commit labels do not supply acceptance or retroactively rename earlier history. Target identity is `0.6.0-dev` / Windows `0.6.0.0`; latest developer-reported released baseline remains v0.3.2. Earlier validation reports below remain verbatim.

## Automated suite

Godot **4.7.2.stable.official.ed1daf0bf**, Windows, Compatibility renderer. Before code changes: **842 checks, zero failures**. Expanded suite: **925 checks, zero failures**, retaining all earlier assertions and adding 83 alpha checks. No existing test is removed or skipped. Headless editor import and configured-application runtime smoke validation pass. Logs are local under ignored `.godot/`; process-local APPDATA points inside `.godot/sandbox_appdata`.

`tests/alpha_tests.gd` covers configuration limits/defaults and mode copies; Time Trial isolation; ConfigFile round-trip, invalid/unrecognized values and save failure; independent volume/mute UI callbacks and audio buses; valid shared generated waveforms/loops/headroom; actual GUI keyboard/mouse/injected D-pad/A/B routing and focus; physical-key-event keyboard-only input and unavailable-device isolation; cancellable initialization; READY/countdown/GO; pause settings/resume; held-item release guard; exact freeze of race time, human/AI transforms, projectiles, boosts/spins and box respawn; same-source mini-turbo audio; fresh restart and old-node disposal; ordered model completion/results/finish deduplication; overall timer/effect sealing; focusable results; repeated sessions without stale signals/audio; and focus-loss pause.

All 842 earlier checks still run, including kart dynamics, real item collisions, 360°/540° spins, mushroom terrain restoration, ramp/landing, shoulder contact, live positions/DNF, AI passing and camera/shared-render-pose regressions. Actual post-correction spin measurements remain 360.000° / 540.000°, body Y ranges at most 0.00000286 m on the flat fixture, and zero measured wall overlap. This is not a substitute for subjective high-speed presentation acceptance.

The tests exposed and corrected deferred focus targeting removed nodes, missing A/B default UI mappings in this engine, and UI cue cut-off during race audio disposal. Separate UI voices preserve Confirm/Back tails; focus callbacks check live/in-tree controls. Settings parsing permits unrecognized content to act like missing keys and use defaults; no fabricated parse rejection is claimed.

## Native application and display

`tests/capture_alpha_preview.gd` uses the actual application scene, menu/pages and gameplay subtree. On NVIDIA RTX 3070 Ti Laptop GPU / OpenGL Compatibility it captures and directly supports inspection of:

- Main menu, Quick Race configuration, Credits, Settings and scrolled mapping/Apply controls.
- READY, synchronized countdown, racing, pause, pause settings, full results and Time Trial pages.
- 1280×720, 1920×1080, 1024×768 with UI scale 125%, actual fullscreen entry and return to windowed mode.
- A single persistent engine stream, paused engine/race clock, restart-from-pause restoring engine audio, and UI cues surviving race-audio reset.
- A complete one-lap seven-racer Quick Race and a complete one-lap Time Trial, using real physics, checkpoints and AI driving commands attached to the player for automation. No checkpoint injection is used in these native races. All seven Quick Race competitors finish without DNF; Time Trial has one competitor and competitive items disabled.

Native assertions report **zero failures**. Captures: `artifacts/alpha_*.png`. The capture temporarily disables automatic focus-loss pause because automation manages the window; product default remains enabled and the notification/pause state is separately tested. Fixed-step captures run faster than real time, so they do not establish perceived audio timing or hardware-driver/controller feel. They are not developer manual acceptance. No new performance benchmark claim is made; pools and draw complexity remain bounded.

Headless validations omit audio playback to avoid artificial-time mixer backlog, while waveform data and bus configuration are tested. Native validation exercises real playback/stream state; audible mix quality and a physical listening/controller session remain manual. The existing Windows sandbox root-certificate-store warning is still emitted; it does not prevent the offline tests or engine startup. No other script/runtime errors or leaks are accepted in the final logs.

## Reproduce

```powershell
godot --headless --editor --path . --quit
godot --headless --fixed-fps 60 --path . --script tests/run_tests.gd
godot --headless --fixed-fps 60 --path . --quit-after 180
godot --path . --fixed-fps 60 --script tests/capture_alpha_preview.gd
```

Use editor F5 for normal-speed manual play, starting at the application main menu. Re-run cumulative checks **1–119**; new alpha checks **105–119** remain unchecked. Follow [Playable Alpha](playable-alpha.md) for controls, settings, device loss and deferred work. Test physical keyboard/gamepad driving and menu feel, actual listening/mix, window dragging, focus loss/refocus, device unplug/reconnect, DPI/multiple monitors, relaunch persistence and Windows exports. No physical controller or exported build is claimed tested here.

## Scope and prerequisites

No new circuit or framework is implemented. ROADMAP explicitly moves that scope to v0.6.1, including the original circuit pipeline and five private educational reference circuits; v0.7 identity/soundtrack and future milestones remain. The existing scene still owns circuit-specific environment, feature/loot anchors, gates and AI line assumptions; these need encapsulation/validation in v0.6.1. The application/session boundary is ready to host that work without redesigning current driving physics. All v0.4/v0.5 acceptance remains pending unless the developer explicitly confirms it.

No staging, commits, pushes, tags, releases or remote actions by Codex. Earlier reports follow unchanged.

---

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
