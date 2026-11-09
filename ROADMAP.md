# Turbo Riot roadmap

**Current development milestone: v0.4.0-dev — Racing Competitors.** Latest released baseline: **v0.3.2**, as identified by the developer. v0.4.0 remains Unreleased and pending developer acceptance. Earlier milestones and cumulative regressions are preserved; see [the repository audit](docs/v0.4.0-audit.md) for the untagged/stale-metadata baseline record.

| Milestone | Scope |
| --- | --- |
| **v0.1.0 — First Drive** | Existing baseline: arcade kart, independent input/camera, editable reference circuit, environment, HUD, tests and docs. |
| **v0.2.0 — Race Foundations** | Developer-accepted baseline: single-player time trial, READY/countdown/racing/results, ordered directional checkpoints, three laps, timing, checkpoint-based recovery, restart, reference environment refinement. Preserve its ten manual checks as regression requirements. |
| **v0.3.0-dev — Arcade Handling** | Implemented in the v0.3.x baseline: independent segment-specific barriers/runoff, optional openings and outer perimeter; surface-dependent acceleration/grip/speed; controlled drifting and three mini-turbo tiers; shared temporary boosts and pads; an optional runoff ramp, airborne momentum/steering and stable landing; feedback, tuning and cumulative regressions. The geometry prerequisite is implemented before physics. Original development/acceptance history is preserved in the changelog and checklist. |
| **v0.4.0 — Racing Competitors** | Current development: one human/six configurable AI, shared kart physics, cached racing-line pursuit, curvature braking, three difficulty profiles, traffic passing, independent progress/recovery, staggered grid, live positions/results/DNF and optional AI-only/debug validation. Manual acceptance pending. |
| **v0.5.0 — Power-Up Mayhem** | Original power-ups, pickups, interactions, readable effects and balance. |
| **v0.6.0 — Playable Alpha** | Cohesive race loop, menus, sound, original circuits and broader device testing. |
| **v0.7.0 — Game Identity** | Original characters, karts, visual identity, original environments and audio. Replace the educational reference circuit for distribution. |
| **v0.8.0 — Multiplayer Foundations** | Networking approach, synchronization and multiplayer prototype. |
| **v0.9.0 — Beta & Balancing** | Performance, stability, accessibility, content polish and competitive balance. |
| **v1.0.0 — First Release** | Release-ready original content, tested builds, onboarding and packaging. |

The v0.4.0 implementation remains within Racing Competitors. The source circuit, surfaces, drifting, boosts, jumps and v0.3.2 presentation fixes are preserved. Power-up items/weapons, networking, split-screen, new full circuits, kart-selection menus, persistent leaderboards, advanced rubber-banding and neural-network AI remain excluded. All future milestone rows above retain their agreed scope.

Historical v0.3.0 handling and v0.3.1 reference/corridor/pad/trunk corrections remain recorded in CHANGELOG.md. The developer-reported v0.3.2 baseline is not silently retagged or assigned a new historical build identifier.

## Acceptance and regression policy

Keep the exact v0.2.0 ten-check baseline in [docs/testing/ACCEPTANCE_CHECKLIST.md](docs/testing/ACCEPTANCE_CHECKLIST.md) and rerun it for every subsequent patch. The prior [runoff procedures](docs/acceptance.md) are retained. Extend the canonical checklist with stable new criteria for each patch; do not replace or silently delete existing checks. Record developer-reported manual results separately from automated results and Codex inspection. Each subsequent patch requires its baseline regressions plus its new criteria to pass before developer acceptance. Never mark a new patch as released before that acceptance.

Actual implementation changes belong in CHANGELOG.md under Unreleased; future work belongs here. Version conventions belong in VERSIONING.md. Change this roadmap only when scope, priorities or testing policy change. All Git restrictions remain in force: no staging, commits, pushes, tags, releases or GitHub actions by Codex.
