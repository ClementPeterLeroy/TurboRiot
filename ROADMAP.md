# Turbo Riot roadmap

**Current development milestone: v0.6.0-dev - Playable Alpha.** Latest developer-reported released baseline remains v0.3.2. v0.4/v0.5 acceptance is not inferred from commit titles. v0.6.0 is Unreleased pending developer acceptance; see [Playable Alpha](docs/playable-alpha.md).

| Milestone | Scope |
| --- | --- |
| **v0.1.0 — First Drive** | Existing baseline: arcade kart, independent input/camera, editable reference circuit, environment, HUD, tests and docs. |
| **v0.2.0 — Race Foundations** | Developer-accepted baseline: single-player time trial, READY/countdown/racing/results, ordered directional checkpoints, three laps, timing, checkpoint-based recovery, restart, reference environment refinement. Preserve its ten manual checks as regression requirements. |
| **v0.3.0-dev — Arcade Handling** | Implemented in the v0.3.x baseline: independent segment-specific barriers/runoff, optional openings and outer perimeter; surface-dependent acceleration/grip/speed; controlled drifting and three mini-turbo tiers; shared temporary boosts and pads; an optional runoff ramp, airborne momentum/steering and stable landing; feedback, tuning and cumulative regressions. The geometry prerequisite is implemented before physics. Original development/acceptance history is preserved in the changelog and checklist. |
| **v0.4.0 — Racing Competitors** | Implemented competitor baseline: one human/six configurable AI, shared kart physics, cached racing-line pursuit, curvature braking, three difficulty profiles, traffic passing, independent progress/recovery, staggered grid, live positions/results/DNF and optional AI-only/debug validation. Manual acceptance pending. |
| **v0.5.0 — Power-Up Mayhem** | Implemented power-up baseline: controlled kart-to-kart momentum exchange; boost-pad initial impulse without control lock; Mushroom (5A), Red Shell (5B), Green Shell (5C), Banana (5D); shared player/AI inventory; exactly three blue-marker rows of four loot boxes. **5E reserved/deferred.** Manual acceptance pending. |
| **v0.6.0 — Playable Alpha** | Current development: complete single-player menu/race flow, Quick Race/Time Trial configuration, pause/results/settings, modular audio and broader device/display testing. **No new circuits or track-framework redesign.** Manual acceptance pending. |
| **v0.6.1 - Testing Grounds & Circuit Framework** | Reusable circuit framework, original circuit development, Figure-8 Circuit, GCN Baby Park, GCN Yoshi Circuit, Wario Stadium (DS), Delfino Square (DS); reference-based geometry/collision/checkpoints/AI navigation. The five Mario Kart-inspired circuits are private educational test environments, not distributed original game content. No implementation in v0.6.0. |
| **v0.7.0 — Game Identity** | Original characters, karts, visual identity, original environments and audio. Replace the educational reference circuit for distribution. Includes Graffiti Speed logo/TR icon and Graffiti Impact paint-splash startup animation. |
| **v0.8.0 — Multiplayer Foundations** | Networking approach, synchronization and multiplayer prototype. |
| **v0.9.0 — Beta & Balancing** | Performance, stability, accessibility, content polish and competitive balance. |
| **v1.0.0 — First Release** | Release-ready original content, tested builds, onboarding and packaging. |

The approved scope amendment moves all new circuit/framework work from v0.6.0 to v0.6.1. v0.6.0 integrates the existing circuit and preserves handling, ground/presentation fixes, AI, power-ups and race rules. Item 5E, extra power-ups, shields/shockwaves, networking, split-screen, kart selection, persistent records/item statistics and full v0.7 visual branding remain excluded. Unrelated future milestones retain their scope.

Historical v0.3.0 handling and v0.3.1 reference/corridor/pad/trunk corrections remain recorded in CHANGELOG.md. The developer-reported v0.3.2 baseline is not silently retagged or assigned a new historical build identifier.

## Acceptance and regression policy

Keep the exact v0.2.0 ten-check baseline in [docs/testing/ACCEPTANCE_CHECKLIST.md](docs/testing/ACCEPTANCE_CHECKLIST.md) and rerun it for every subsequent patch. The prior [runoff procedures](docs/acceptance.md) are retained. Extend the canonical checklist with stable new criteria for each patch; do not replace or silently delete existing checks. Record developer-reported manual results separately from automated results and Codex inspection. Each subsequent patch requires its baseline regressions plus its new criteria to pass before developer acceptance. Never mark a new patch as released before that acceptance.

Actual implementation changes belong in CHANGELOG.md under Unreleased; future work belongs here. Version conventions belong in VERSIONING.md. Change this roadmap only when scope, priorities or testing policy change. All Git restrictions remain in force: no staging, commits, pushes, tags, releases or GitHub actions by Codex.
