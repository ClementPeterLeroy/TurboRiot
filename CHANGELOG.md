# Changelog

## Unreleased — v0.6.1-dev — Circuit Selection & First Testing Grounds

Pending developer acceptance. Project/menu/HUD identify `0.6.1-dev`; Windows numeric metadata uses `0.6.1.0`. Historical entries below remain unchanged; no prior milestone is retrospectively accepted or released.

Version scope: circuit selection, **two new beta test circuits without finished environments or scenery — Figure-8 Circuit and GCN Yoshi Circuit (DS)** — and corrections for racing FPS drops and Figure-8 crossing collisions. The existing reference circuit remains available. These circuits are playable greybox testing layouts; no beta release or developer acceptance is implied.

### Bikini Bottom test_v2 recovery wiring — 2026-11-13

- The new `Bikini_bottom_test_v2.tscn` lacked the original sandbox's recovery setup and reverted to shared limits, reproducing low/outer-road resets. Attached the existing imported-road recovery script and explicitly bound the v2 road/kart. Bounds now derive from that scene's road at startup; no model, collision, spawn, camera or shared controller changes.
- Extended the same physical regression tests to both test scenes. Before wiring, v2 fails four assertions; afterward all **1,090 checks pass**. Headless import and a direct v2 runtime smoke also pass. Manual checks 165–166 added; version remains 0.6.1-dev, pending developer acceptance.

### Bikini Bottom evaluated-road export — 2026-11-13

- Diagnosed the missing road in the owner's new environment exports: the Curve/Geometry Nodes road node had no mesh reference in GLB, while buildings and seabed exported normally. Created a separate `bikini_bottom_test_track_mesh.glb` using in-memory evaluated road conversion, preserving the saved Blender source and earlier exports. Godot headless import and mesh-surface verification pass.
- Documented the repeatable non-destructive export procedure in [Blender road export](docs/blender-road-export.md). This does not replace the existing driving-test model/collision, add race integration or establish full-environment performance acceptance. Runtime version remains 0.6.1-dev.

### Bikini Bottom sandbox recovery correction — 2026-11-12

- Reproduced valid-road resets caused by the shared fall threshold of −8 m and X bounds of ±178 m: the imported blockout reaches about −12 m elevation and extends beyond ±178 m. The Bikini Bottom test scene now computes its own world-space recovery envelope from the imported road on startup, with configurable 12 m horizontal margin and 10 m fall clearance. Shared recovery defaults, kart physics, model geometry/placement and the authored safe spawn remain unchanged.
- Added 14 regressions: both original reset paths reproduced, real kart contact retained at low/outer road locations, every road collision triangle inside the envelope, out-of-bounds/fall/manual recovery, spawn support, cooldown and unchanged shared defaults. Full suite: **1,076 checks, zero failures**. Permanent manual criteria 162–164 extend the existing checklist. This is a sandbox correction, not completed Blender race integration or developer acceptance; version remains 0.6.1-dev.

### Circuit racing performance correction — 2026-11-11

- Reproduced Yoshi's racing-only slowdown with overlays off. Profiling localized expensive kart motion queries against the full concave asphalt mesh and unnecessary per-frame rebuilding/drawing of the 8,927-point minimap route.
- Flat, unbanked asphalt now uses convex sections with the same top vertices and road footprint. Elevated/banked roads retain their triangle collision, including Figure-8's crossing. Cached display-sized minimap paths redraw on configuration/resize; a separate layer keeps racer markers live. Handling, camera, AI difficulty, items and scenery remain unchanged.
- Same-process, same-GPU native seven-racer A/B at 1280 × 720 measured Yoshi **10.5 → 77.4 FPS**, reference **48.4 → 116.9 FPS**. These are hardware-specific results, not guarantees. Added 21 collision/minimap assertions and manual criteria 157–161; full suite **1,062 checks, zero failures**. See [performance diagnosis and benchmark](docs/circuit-performance.md). Version remains 0.6.1-dev, Unreleased pending developer acceptance.

### Figure-8 crossing collision correction — 2026-11-11

- Reproduced the upper-road stop as an opposing false wall contact inside the inclined asphalt collision, caused by the kart's sharp box underside catching a triangle edge. Disabling barriers did not remove it; the original box still fails the new regressions.
- Replaced the single kart box with an upper box and two native spherical lower contacts, retaining the combined 1.25 × 0.75 × 2.1 m bounds and broad side-contact surfaces. Shared human/AI scene; no controller constants, road geometry/elevation, barriers, surfaces, camera or jump/contact corrections changed.
- Added 52 physical crossing/contact assertions and manual criteria 152–156. Full suite: **1,041 checks, zero failures**, retaining all prior tests without relaxed tolerances. Tests cover normal/boosted/opposite-direction upper traversal, lower underpass, multiple lanes, complete collision-contact reports, terrain detection and dimensions. Restoring only the original box fails 13/52 crossing checks. See [diagnosis and validation](docs/figure-8-crossing-fix.md).

### Initial circuit delivery

- Added Circuit Selection after Quick Race/Time Trial configuration, three selectable entries, geometry-derived previews, selected/availability state and keyboard/mouse/controller navigation. RaceSetup carries the circuit ID through Back, loading, fresh restart and per-mode preferences.
- Added reusable TrackDefinition/TrackRegistry and two original greybox track scenes traced from the directly inspected private DS overhead maps: Figure-8 Circuit and GCN Yoshi Circuit (DS). Shared grid, ordered gates/finish, cached AI route, surfaces, recovery bounds and circuit-local pickup fractions feed the existing race controller. The original reference circuit and its exact three item rows/pads/ramp/runoff remain preserved.
- Extended the road mesher with opt-in authored elevation/banking, normalized cross-sections and slope normals. The developer approved a simple raised Figure-8 crossing; conservative heights are documented assumptions. Yoshi remains flat. Curvature-constrained trace fitting fixes initially detected inner-edge folds without changing driving physics. Height-aware AI route acquisition distinguishes crossing decks.
- Added the same curve-derived minimap to menu previews and the race HUD, with player/AI indicators. Private annotated source traces, overlays and side-by-side comparisons remain ignored under `references/analysis/`; native geometry-only renders and numerical comparison reports are in `artifacts/`. No Nintendo artwork or source assets enter runtime resources.
- Added geometry/topology/grid/gate/recovery/navigation/mode/switch/restart regressions, native menu/Time Trial captures and cumulative manual criteria 120–151, preserving 1–119. Seven AI completed item-enabled three-lap races on both new circuits; native Time Trials also complete. Detailed test results, scale assumptions, source-fitting limitations and manual review procedures are in [Testing Grounds](docs/testing-grounds.md) and [validation](docs/validation.md).
- Updated current metadata, README, architecture, controls, versioning and roadmap. Original circuit development remains within Testing Grounds; Baby Park, Wario Stadium (DS) and Delfino Square (DS) are deferred. v0.7+ scope is preserved. No staging, commits, pushes, tags, releases, GitHub actions or remote mutations performed.

## Unreleased — v0.6.0-dev — Playable Alpha

Pending developer acceptance. Current project/menu/HUD use `0.6.0-dev`; Windows numeric metadata uses `0.6.0.0`. Local commit labels v0.5.0/v0.5.1 do not establish acceptance; all earlier entries below and the developer-reported v0.3.2 baseline remain preserved.

### Added

- Application entry scene with Main Menu, Quick Race, Time Trial, Settings, Credits and Exit; responsive scrollable pages, consistent focus/hover states, keyboard/mouse/controller navigation and explicit A/B UI bindings.
- Central validated RaceSetup, per-mode preferences, existing-circuit initialization/READY/countdown/results flow, fresh-scene restart and complete disposal. Quick Race supports 0–6 AI, three existing difficulty profiles, laps defaulting to three and available controller assignment. Time Trial has one human, no AI/competitive items, lap/total results and the same fresh restart/menu flow.
- Pause overlay with Resume/Restart/Settings/Main Menu. PAUSABLE gameplay stops physics, AI, race/item/boost/spin timers together while UI/audio remain responsive. Focus loss and assigned-controller disconnect pause; resume guards held item input. Overall completion clears competitive effects and seals timers; results remain interactive while existing DNF/other-racer policy is preserved.
- ConfigFile display/audio persistence and safe defaults/range validation: window/fullscreen, common resolutions, VSync, UI scale, independent Master/Music/Effects volumes/mutes. Live audio preview can be cancelled; controls reference is included. Canvas expansion and menu scrolling support different aspect ratios.
- Modular audio director, separate bounded UI/race voice pools, persistent speed-modulated engine/drift/music loops and original synthesized placeholder cues for required menu/race/item/lap/finish events. Managed item sound delegates centrally; raw race fixtures retain compatibility. No external music or samples downloaded.
- Alpha lifecycle/settings/audio/input tests, native menu/display/pause/race/Time Trial captures and permanent manual criteria 105–119, preserving all previous checks.

### Integration and scope

- Existing race scene remains the raw authoring/test fixture, wrapped by the new application. Small changes add managed shortcut/result routing, device assignment, safe deferred focus, overall-completion and wall/item/accepted-boost audio hooks. Handling, source geometry, camera/interpolation, surface/drift/spin and projectile mechanics are retained.
- Approved roadmap amendment: v0.6.0 contains no new circuits; v0.6.1 owns Testing Grounds & Circuit Framework and original/private educational circuit development. v0.7 retains Graffiti Speed / Graffiti Impact and full identity/audio work; unrelated future milestones are preserved. Canonical and documentation roadmap pointers are synchronized.
- Metadata, README, controls, architecture, version table, cumulative checklist and validation updated. v0.4/v0.5 are not retrospectively accepted or released.

### Validation and limitations

- Baseline **842 checks, 0 failures**; expanded suite **925 checks, 0 failures**. Headless import/runtime validation and native application/display checks pass; actual results and procedures are recorded in `docs/validation.md` and `docs/playable-alpha.md`.
- Native validation includes 720p/1080p, 4:3 at 125% UI scale, window/fullscreen transitions, engine pause/restart and complete physical Quick Race/Time Trial flows driven by test AI commands. These are not physical-controller, human driving, audio-mix or developer acceptance claims. Exported builds, DPI/multiple-monitor coverage and real devices remain manual work. Audio/visual menus are temporary, not v0.7 branding or soundtrack.
- No staging, commits, pushes, tags, releases or GitHub/remote actions by Codex.

## Unreleased — v0.5.0-dev — Power-Up Mayhem

Pending developer testing/acceptance. Project/HUD identity is `0.5.0-dev`; Windows numeric versions are `0.5.0.0`. This is not a release. The v0.4.0 Unreleased record and all earlier history below are preserved.

### Power-Up Balancing & Feedback correction — 2026-11-10

This correction remains inside **v0.5.0-dev**. Read-only local history showed HEAD `0d69490` (v0.4.0), no tags and v0.5.0 explicitly Unreleased; no v0.5.1 version or release is introduced. Earlier entries below are preserved.

- Mushroom-only sand/grass acceleration, speed-cap and grip immunity now composes through BoostController/SurfaceDetector. Detection/name/resistance remain live; expiry smoothly restores terrain penalties. Independent source timers prevent retained pad caps from extending immunity. Pads and mini-turbos alone retain their previous terrain behavior.
- Reusable KartEffects spin/recovery state now rotates the actual CharacterBody/collider: red/green shells turn 360° over 1.35 seconds; bananas turn 540° over 1.65 seconds. One bounded planar hit reduces momentum substantially, impairs input and then restores traction/control over 0.35 seconds. Inertial sliding avoids scripted circles, while final physical heading affects driving. Configurable tuning, whole-reaction overlap protection and recovery/restart/finish cleanup are shared by human/AI.
- A physics-interpolated traction-heading child keeps the chase view steady while the kart spins visibly. Existing camera moving-target integration, vertical contact, ramp/jump rules, visual animation and collision geometry remain. No vertical bob, shake, teleport or artificial zero-speed reset is added.
- Reusable screen-space speed lines for mushroom/pad activation: brief burst, subtle sustained radial edge streaks, strength-scaled intensity and smooth fade. Camera/canvas projection supports different resolutions/follow positions; lines stay behind the HUD and avoid the central kart area. Mini-turbos alone do not activate them. F3 adds immunity/spin/control telemetry.
- Added permanent checks 91–104 without changing checks 1–90, balancing/state/real-body tests, native 720p/1080p previews, distinct seeded AI reports and prefixed native presentation traces. Current implementation/controls/architecture/validation docs are updated; ROADMAP and version metadata retain their scope/values.
- Validation: baseline **691 checks**, expanded **842 checks, 0 failures**; all 12 native presentation scenarios pass at 60/120/uncapped rendering. Seven AI finish item-enabled races on all three difficulties, including a three-lap Challenging run with 29 pickups, 28 uses and one ordinary recovery. Details and limits are in `docs/validation.md` and `docs/power-up-balancing.md`.
- Developer acceptance remains pending, including real controller feel, spin recovery/motion comfort and line intensity. No staging, commits, pushes, tags, releases or GitHub actions performed by Codex.


### Added

- Shared data-driven ItemDefinition/catalog, one-slot KartInventory and DrivingCommand item activation for human and AI. Space / Pad B activates on a new press; full inventory cannot consume/replace a pickup. Weighted pool contains only 5A–5D; 5E is reserved.
- Mushroom acceleration/speed boost, bounded-turn red-shell homing with forward fallback, non-homing green shells with swept thin-wall ricochets, and settling banana traps. Bounded hit impulses/speed/grip penalties, owner grace, repeat-hit protection, lifetimes and active-object caps preserve driving controls and race rules.
- Four reusable original low-poly item models, native SVG HUD icons, jewel-panel/question-mark loot-box scene, float/rotation, atomic Area pickup and configurable five-second respawn. Private reference PNGs remain ignored and unused at runtime.
- Exactly three editor-visible rows of four boxes, projected from inspected blue-map anchors and spaced across the existing road. Reusable row resources expose anchor/count/spacing/respawn; no circuit geometry changes.
- Contextual AI box-lane selection and item use through the same inventory/command/physics rules. Item HUD name/icon/readiness, bounded feedback rings and pooled synthesized spatial cues.
- Permanent manual checks 66–90, item/momentum/real-pickup/projectile/lifecycle tests, item-enabled AI race reports, native model/row/HUD captures and a sustained seven-item rendering benchmark.

### Changed and fixed

- Kart contacts no longer receive the static-wall speed-retention penalty. A common post-movement solver deduplicates actual pairs and exchanges mass-weighted normal momentum from relative closing speed, preserving tangential motion and avoiding additive contact energy. Existing world-wall sliding/retention remains.
- Pads now apply one initial arrow-aligned impulse and temporary bonuses. Removed the continuous propulsion/yaw authority branch; steering, braking and drift are available immediately, including reverse entry. Pad/mushroom overlap retains stronger caps/longer timers under default policy without additive stacking; mini-turbo rules remain.
- Recovery clears inventory/combat effects/pending impulses; restart/Return to Ready clear all inventories, actors, traps, box timers, feedback and AI item state. No item effect can grant checkpoints or race progress.
- Metadata, roadmap, architecture, controls, README, audit and validation describe v0.5 development. Prior ground/ramp and camera/render-pose corrections, source circuit and saved Challenging difficulty remain.
- Updated explicitly superseded regression assumptions: pad tests measure the initial impulse and immediate control rather than a prolonged lock; kart collision retains nonpenetration coverage and gains moving-pair momentum tests rather than requiring a full stop. Pre-item fixtures disable ItemSystem; new integration tests and real item races enable it.

### Validation and limits

- Baseline **568 checks, 0 failures**; expanded suite **691 checks, 0 failures**. Headless import/runtime validation and native review captures pass; details and real AI race/performance evidence are in `docs/validation.md`.
- Seven AI completed a three-lap item-enabled race, with 30 pickups, 27 uses, zero recoveries/DNFs. Manual art/feel/controller/high-speed visual acceptance remains pending. Homing is bounded pursuit, not obstacle navigation; dense contacts use a simple sequential solver. Performance observations cover one Windows/GPU setup.
- No staging, commits, pushes, tags, releases or GitHub actions performed by Codex.


## Unreleased — v0.4.0-dev — Racing Competitors

Pending developer testing/acceptance. Project/HUD use `0.4.0-dev`; Windows numeric fields use `0.4.0.0`. No v0.4.0 release, tag or publication is claimed.

### Added

- Default seven-kart field (one human/six AI), configurable opponent count, three difficulty resources, curve-following staggered grid, per-driver colours/names and simultaneous countdown/GO.
- AIInput implements the existing DrivingInput/DrivingCommand contract and reuses the shared kart controller/config. Cached circuit-derived pursuit, curvature/braking-horizon speed planning, bounded steering, drift/mini-turbo decisions and shared-API recovery for stalls/off-road/missed gates. No AI transform driving, physics advantages or rubber-banding.
- Straight-line traffic passing with lane occupancy checks, retained side/target, smooth lane transitions, close-traffic braking and return to the line. Lane interpolation initializes at the actual grid/recovery offset to prevent an initial inward swerve.
- Independent CompetitorState/RaceSession data per kart; legal route/travel-constrained live ranking, subtick ordering of simultaneous finishes, continued AI racing after human results and configurable finish grace/timeout DNF. Finishers become nonblocking until restart.
- Position/lap/time HUD, live result standings with names/times/RACING/DNF, optional F3 line/waypoints/targets and selected-driver telemetry; F8 cycles AI debug selection. Presentation A/B controls remain available.
- Competitor unit/integration tests, physical overtake and kart collision checks, real AI-only/mixed races, rendered race capture and one/seven-kart native benchmark. Manual acceptance checks 50–65 appended; all previous checks and v0.3.2 visual-stability coverage retained.

### Changed

- RaceManager coordinates the whole field while preserving its player `session`/movement API. Kart collision mask now includes other kart bodies; all competitors share identical movement/handling rules.
- Restart/Return to Ready reset the entire field; recovery/finish/reset samples remain competitor-local. Cached line data rebuilds with track geometry without duplicating opponents.
- Current roadmap/README/versioning/architecture/controls/validation updated for v0.4.0 development. Source circuit geometry, controller dynamics, camera and visual-oscillation corrections are preserved.

### Validation and limits

- Before implementation: 519 checks, 0 failures. Final expanded suite: **568 checks, 0 failures**. Physical race/render/performance results are recorded in `docs/validation.md` and `docs/racing-competitors.md`; automation does not claim manual acceptance.
- Passing is basic and primarily on straights; hard blocking can require shared recovery. Performance observations cover one Windows/RTX 3070 Ti Laptop GPU configuration. Real devices/feel/controller/export testing remains pending. No networking, split-screen, items, weapons, new circuit, selection menu or persistent leaderboard.
- No staging, commits, pushes, tags, release creation or GitHub actions by Codex.

## v0.3.2 — Persistent Visual Oscillation fix — developer-reported released baseline

The v0.4.0 brief identifies v0.3.2 as the latest released baseline. Local history contains commit `96934a4` with that title, including the shoulder-contact correction, camera/shared-render-pose interpolation and moving-target follow, retained A/B diagnostics and 519 passing automated checks. No local tags are present. That commit's project/HUD/export metadata still read `0.3.0-dev` / `0.3.0.0`; no release date, tag or corrected historical metadata is invented here. See `docs/v0.4.0-audit.md`.

The earlier v0.3.0/v0.3.1 entries below are preserved as originally recorded. Their development/pending wording is historical, rather than a new assertion about the developer-reported v0.3.2 release. Granular manual checkbox results are not reconstructed from a release label.

## Historical development record — formerly Unreleased

### v0.3.1 — Corrective Patch

Corrects v0.3.0-dev — Arcade Handling. Implementation and automated validation are complete; developer manual acceptance and release remain pending.

#### Fixed and changed

- Reinspected all three private references at their actual `references/` location. Re-proportioned the closed source curve and 14.4 m road from the overhead; authored the stepped outer fence and T-shaped infield fence independently at 0.18 m/pixel. Smoothed corner tangents to keep road/shoulder triangles valid. Added two intentional infield grass openings, matching grass footprints and more distant hills. The optional generic rectangle is disabled for this circuit.
- Added editable BarrierRun points/gaps and configurable five-block red/blue/yellow/green groups, continuous around corners and resource seams. Blocks and colliders use identical endpoints; closed runs preserve complete colour cycles.
- Repositioned twelve gates after corners and widened them asymmetrically to enabled physical boundaries and connected route sectors. Legal sand/grass lines now count. Finite height/outer polygon/route-window checks, expected order/direction, minimum interval travel and oversized-sweep rejection preserve route validation; recovery resamples the guards.
- Directional pad entries now accelerate toward pad forward, including reverse/wrong-heading entries, with bounded acceleration/yaw during a configurable redirect phase. Pad duration/latch/cooldown remain; strongest-wins preserves a stronger active cap/longer timer while always applying pad direction. Mini-turbos retain normal kart-forward movement.
- Added one reused lightweight cylinder shape for procedural trunk obstacles; foliage remains non-solid. Moved the optional sand ramp outward to clear the wider road.
- Added a short obstacle-verifying ray for sustained wall jams that report floor-only slide contacts, preserving existing recovery gates/cooldown.
- Appended manual checks 27–36 and added corrective geometry, gate coverage/off-road laps, directional pad and real trunk/foliage scenarios. Updated earlier synthetic race fixtures to feed continuous movement; retained the accepted v0.2.0 checklist and all earlier scenarios. Actual results are recorded in `docs/validation.md`.
- Recorded as v0.3.1 — Corrective Patch following v0.3.0-dev — Arcade Handling. Unreleased and awaiting developer acceptance. This documentation update leaves project/HUD/export build metadata unchanged; no Git mutations or GitHub actions.

#### Known limitations

- The new runoff correction still needs developer manual acceptance. Automated/visual validation does not carry forward manual acceptance to new geometry.
- Profile edits must avoid intersecting neighboring roads or creating tight/overlapping outer contours; arbitrary edits are not automatically repaired.
- Legal runoff is included in route-owned checkpoint corridors; large or irregular custom layouts require reauthoring fractions/windows and validating coverage. Recovery remains at the latest valid road checkpoint.
- Human driving feel, real controller hardware, manual checks 1–49 and packaged Windows export remain unverified for this new build. Automated/visual checks are reported separately.
- Surface regions assume the current flat sand/grass terrain; banked or layered original circuits need authoring review. Grass is a tagged polygonal region over the continuous sand support collider, avoiding a new collision step.
- The ramp is an optional test feature in runoff, not a route shortcut. Keep authored ramp inclines below the body's floor-angle limit.
- Camera obstruction uses a ray rather than a swept camera volume; very tight geometry/corner clipping still needs manual review. Small barrier shadows may show aliasing.

### v0.3.0-dev — Arcade Handling

Full handling development patch, pending developer acceptance. Metadata remains `0.3.0-dev`; this is not an accepted/released v0.3.0 build. The geometry correction was implemented and its 203 checks passed before adding surface/drift/boost/jump physics.


#### Persistent visual oscillation — second investigation, same version

- Recorded the developer's manual report that high-speed visual porpoising remains despite `Ground true`; retained the validated shoulder-contact fix. Compared v0.2.0 through v0.3.1 history read-only. Cosmetic pitch/roll and wheel animation were new in v0.3.0, while raw-target render-loop chase smoothing predates it; the straight A/B trace did not implicate cosmetic pitch or camera obstruction.
- Reproduced camera-to-kart screen-space oscillation at mismatched render/physics rates. Enabled physics render interpolation, made the camera position/focus/look point use one shared interpolated target pose, and excluded the camera/render-updated Visual local transforms from double interpolation. Replaced endpoint-only position lerp with exact exponential follow of a moving target at the same smoothing rate; orientation smoothing and driving physics remain unchanged.
- Added retained A/B diagnostics: F4 cycles Normal / Static visuals / Fixed camera orientation / Minimal rendering, F6 toggles optional transform/screen-position CSV, and F7 tests 60/120/uncapped rendering. F3 shows the active mode and measured rates. Diagnostic modes never change kart motion/configuration.
- Added 28 presentation assertions, a native multi-rate renderer probe, committed-camera comparison fixture and rendered-pixel inspection. Final straight probe reduces Normal-mode screen-Y range from 3.332 to 0.211 px at 120 FPS and 6.465 to 0.218 px uncapped; saved marker centroid variation drops from 3 px to zero in the sampled frames. Appended pending manual checks 46–49. Full results and limits are in `docs/presentation-investigation.md` and `docs/validation.md`.
- Original symptom acceptance remains pending on developer hardware; stable body Y alone is insufficient. No version advance, roadmap change or Git actions.

#### Vertical-contact corrective pass — same development version

- Diagnosed physics-body false takeoffs at asphalt/shoulder joins using body Y, vertical velocity, floor state/normal/distance, visual-child height and camera Y traces. Straight flat asphalt was stable; the circuit trace reproduced 56 airborne frames in 6,000 ticks before correction. Upward tangent velocity disabled automatic floor snapping, and cached ground motion then amplified those false takeoffs.
- Ordinary grounded movement now requests horizontal velocity with the existing downward contact speed, allowing CharacterBody3D to resolve slopes and snap to connected ground. Upward tangent/takeoff momentum is limited to actual floor contact with an authored launch ramp; ramp colliders carry an explicit launch marker separate from asphalt surface identity. No gravity, collider sizes/margins, road geometry, visual bobbing or camera smoothing constants were changed.
- Added quantitative flat-floor idle/acceleration/braking/steering/drift and real asphalt/sand join regressions, plus recovery/restart assertions. Appended pending manual checks 37–45. Existing ramp takeoff/landing, pad, race and camera scenarios remain required. See `docs/vertical-stability.md` and `docs/validation.md` for measurements and actual results.
- Remains within the existing v0.3.0 development patch, Unreleased and pending developer acceptance. Existing v0.3.1 documentation history, roadmap milestones and project/HUD/export version metadata are preserved; no version advance or Git actions.


#### Added

- SurfaceConfig resources for asphalt, grass, sand and boost pads; tagged physical ground plus procedural surface-region queries; debounced, exponentially smoothed handling multipliers and gradual excess-speed removal.
- Normalized drift commands on Shift/LB, grounded/speed/steering activation, reduced grip and steering response, countersteering, activity-based three-tier mini-turbo charge and valid-release-only rewards.
- Temporary BoostController with configurable strongest-wins/replace policy, expiry, smooth cap restoration and no mutation of base KartConfig.
- Reusable editor-visible cyan directional BoostPad scene, grounded Area activation, per-kart entry latch/cooldown and two source-curve-positioned pads.
- Reusable configurable amber ramp scene, placed in the wide outside sand of the long left straight. Ramp tangent movement supplies launch momentum; airborne movement retains inertia with reduced yaw authority, gravity and stable landing.
- Wheel pivots/steering/spin, body lean/pitch, procedural tyre dust/smoke, coloured charge feedback, boost exhaust, normal HUD charge indicator and expanded hidden debug information.
- Additional tuning for surfaces, drift, turbo tiers, boost policy, air steering, landing and probe/snap behavior. Original base speed/acceleration/braking/coasting/steering/gravity values are retained.
- BarrierSection resources with side selection, enabled/disabled intervals and optional clearance override; one outside opening on the upper diagonal and a faceted playable perimeter. Recovery has independent world bounds and upright checks.
- Exact cumulative manual checklist at `docs/testing/ACCEPTANCE_CHECKLIST.md`, preserving previously accepted 1–10 and adding pending 11–26 without claiming a new manual retest.
- Handling unit/integration tests for surface penalties/transitions, drift validity/countersteer/charge/release/interruption, boost overlap/expiry, real pad entry, ramp takeoff/landing, air restrictions, cleanup and barrier openings/perimeter.
- Independent editable left/right clearance Curve resources for segment-specific physical barrier placement along the closed circuit. Selected straights have sand/grass runoff; start and inner tight bends retain narrow containment.
- Separate closed outer-boundary polylines, with blocks spaced along their own arc length and box colliders at the same visible block positions.
- Sloped sand shoulders joining asphalt to the existing lower sand floor, allowing road re-entry without recovery.
- Decorative tree placement now respects each side's outer runoff envelope with a margin instead of populating the newly accessible aprons.
- Automated runoff checks covering side/segment variation, closed paths, asphalt clearance, block spacing, collider/visual source alignment, profile edits and actual kart exit/re-entry through sand and grass.
- A durable manual acceptance/regression document, preserving the v0.2.0 baseline and adding the current correction criteria and an append-only policy for future patches.

#### Changed

- KartController composes surface, drift and boost models. Its grounded motion follows floor tangents and air movement no longer manufactures speed from throttle. Recovery, restart, race finish and pre-GO locks clear temporary states.
- Camera retains its chase architecture with a terrain obstruction ray and height floor for jump/landing follow.
- Runoff drive-test durations account for the new speed penalties while preserving wall/access/re-entry assertions.
- Coloured barriers no longer universally follow kerbs at a fixed distance. This prerequisite separated road and fence geometry; the subsequent v0.3.1 corrective patch above reauthors the source road proportions and gates.
- Barrier collider segments now follow individual visual block endpoints, including transitions, so no kerb-side collision wall is left in widened areas.
- Updated milestone/version metadata, README, architecture and testing policy for v0.3.0 development.

#### Fixed

- Grounded ramp motion presses into the floor normal so an ascending tangent does not prematurely detach the kart before the launch edge. The later vertical-contact correction restricts this path to authored launch-ramp contact; ordinary ground uses downward movement and automatic snapping.
- Recovery/restart/finish no longer leave temporary drift charge, boost or launch motion; pad reset guards prevent immediate boost farming while remaining on a pad.
- Surface/boost cap reductions remove excess speed gradually rather than snapping velocity when a multiplier changes.

## v0.2.0 — Race Foundations — Developer-accepted baseline

On 2026-11-08 the developer confirmed all ten manual acceptance checks passed. This records acceptance, not a Git tag, publication or release action. The following entries describe the actual earlier patch. Its automated/rendered results remain historical records.

### Added

- RaceManager orchestration and a deterministic RaceSession model with explicit READY, COUNTDOWN, RACING and FINISHED states.
- Three-second 3/2/1/GO countdown, pre-GO/post-finish driving lock and configurable default three-lap race length.
- Reusable directed checkpoint planes, 12 gates generated from the saved circuit, swept bounded crossing detection, ordered progression and finish validation.
- Total/current/last/best/final times, per-lap results, Restart Race, Return to Ready and Exit buttons.
- Enter/Space/Pad A to start; F5/Pad X to restart. R/Pad Y now recovers without clearing race progress or timing.
- KartRecovery with latest-validated recovery transforms, camera synchronization, configurable fall threshold, cooldown and conservative sustained-wall-jam recovery.
- Race tests for invalid order, repeated entries, reversed crossings, timing/state transitions, three-lap completion, restart, recovery and UI orchestration.
- Root ROADMAP.md, CHANGELOG.md and VERSIONING.md, previously absent. The prior milestone list is preserved.

### Changed

- Preserved the reference-based centerline and its corner sequence/width; moved the spawn 4 m behind the start/finish plane and added grid marks.
- Replaced rectangular barrier visuals with a reusable faceted X-face mesh, four shared colour batches and separate simple colliders.
- Neutral grey asphalt, an editable reference-shaped grass infield, sand, rounded polygonal trees and hills. Existing reference files remain private/ignored.
- Environment rebuilding now follows track geometry changes, including width changes, and coalesces queued rebuild requests.
- Existing physics tests now explicitly enter RACING before testing movement. The underlying handling defaults are unchanged.
- Version metadata and development HUD updated for the current milestone; Windows numeric version fields use `0.2.0.0`.

### Fixed

- Recovery teleports reset the checkpoint sweep baseline instead of creating crossings across the map.
- Repeated start/restart uses one countdown value rather than overlapping timers/coroutines.
- READY/results panels no longer overlap normal race telemetry.

### Known limitations

- The developer subsequently confirmed all ten manual acceptance checks passed. The exact checklist, absent at that review, was supplied in the full v0.3.0 brief and is now stored in the canonical checklist. Original device details are still not recorded; automation does not establish packaged Windows export validation.
- Timing uses active physics ticks, with finish/checkpoint times quantized to one tick; no sub-tick or real-time wall-clock timing.
- Swept gates assume continuous kart motion except through the supported reset/recovery API. Arbitrary external transform changes must also resample the baseline.
- No persistent records, penalties, pause/menu system, camera obstacle avoidance, off-road speed changes or network racing.
- Wall-jam recovery intentionally triggers only under sustained throttle, near-zero speed, ground and wall contact, without braking/steering; it is not a general stuck detector.
- Very tight/self-intersecting source curves still require author correction. The reference grass footprint must be edited separately for replacement layouts.
- Godot reports a certificate-store warning in the restricted validation environment; it did not block the checks.
- Small faceted blocks can show shadow-map aliasing at some camera angles; target-hardware lighting polish remains for developer review.

## v0.1.0 — Existing baseline

First Drive: CharacterBody3D kart, normalized keyboard/gamepad provider, KartConfig, chase camera, procedural reference circuit, primitive scenery, basic HUD and 58 automated checks. This entry records the pre-patch baseline rather than asserting release acceptance.
