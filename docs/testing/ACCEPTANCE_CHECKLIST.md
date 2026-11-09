# Turbo Riot cumulative acceptance checklist

## History and status

- **v0.2.0:** All ten original checks were manually accepted by the developer (confirmed 2026-11-08). Their exact wording below was supplied in the v0.3.0 brief on 2026-11-09.
- **v0.3.0-dev:** Manual acceptance is pending. Every checkbox below records a fresh v0.3.0 manual run; none is marked passed merely because automation or rendering succeeded. No manual v0.3.0 gameplay/feel/hardware validation is claimed by Codex.
- Preserve checks and append new ones for later patches. Record build, date, tester, controls/hardware, resolution, result and issue links. Historical acceptance does not automatically accept changed behavior.
- The earlier [runoff checklist](../acceptance.md) remains preserved with stable V02/V03-R IDs. Its access, re-entry, collision and race-integrity checks remain regressions. The correction-only expectation of unchanged surface behavior is superseded by checks 14–15 in this full handling patch. No earlier pending correction check is silently marked accepted.

## v0.2.0 regressions — previously manually accepted; current v0.3.0 run pending

- [ ] **1. Track layout follows the overhead reference.** Check the overhead, corner order/proportions and normal chase view.
- [ ] **2. Coloured faceted barriers render correctly.** Inspect red/blue/yellow/green faces and collision placement, including the outer perimeter/open section.
- [ ] **3. Countdown prevents early movement.** Try gas/steer/drift during READY and 3/2/1; movement starts at GO.
- [ ] **4. Checkpoints validate the correct route.** Skip a gate, then test a finish. Progress requires every numbered gate in order.
- [ ] **5. Reverse finish-line crossing does not count.** Test after a valid checkpoint sequence as well as near the initial spawn.
- [ ] **6. Three completed laps finish the race.** Exactly three valid forward finishes produce results.
- [ ] **7. Lap and total timers behave correctly.** Check active-only timing and current/last/best/per-lap/final data.
- [ ] **8. Recovery works without granting extra progress.** Recover from road/runoff near a gate and the finish. Preserve valid progress and keep active timing running.
- [ ] **9. Restart clears the entire race state.** Try during countdown, racing and results; verify one fresh countdown, grid spawn, empty laps/zero clocks.
- [ ] **10. Camera, driving and collisions remain functional.** Test keyboard and available gamepad, reverse/brake, walls and reset snapping. Record devices actually used.

## New v0.3.0 checks — manual verification pending

- [ ] **11. Kart can leave asphalt and drive onto sand.** Cross the kerb on both sides of the early straight; drive back via the sloped shoulder without R.
- [ ] **12. Kart can drive onto grass where intended.** Cross the sand strip into the infield from the early right straight or long left straight.
- [ ] **13. Barriers correctly define outer boundaries.** Compare narrow/wide profiles and the outside opening on the upper diagonal (82–88% of lap length, left side). The opening has no invisible collider; the perimeter at X ±170/Z ±150 contains the wider environment.
- [ ] **14. Sand and grass apply different handling penalties.** Watch F3 surface/speed and feel reduced acceleration/grip/sustainable speed, with sand stronger than grass. Entry must decelerate smoothly, without an instant speed clamp.
- [ ] **15. Returning to asphalt restores normal handling.** Cross the same boundaries repeatedly; multipliers restore smoothly without unstable flickering.
- [ ] **16. Drift activates only under valid conditions.** Hold Left Shift/LB with steering at forward speed above the configured minimum. Test stationary, low-speed, straight and airborne rejection.
- [ ] **17. Kart can counter-steer during a drift.** Change steering direction while held; no fixed-curve steering or orientation snap.
- [ ] **18. Drift charge increases under valid conditions.** Check lateral movement, steering engagement and tiers 1/2/3. Holding the button without valid activity must not charge.
- [ ] **19. Releasing a charged drift activates a mini-turbo.** Release while still grounded/engaged/sliding. Check charge clears and temporary boost/exhaust/HUD feedback appears, with stronger tiers lasting longer.
- [ ] **20. Invalid or interrupted drifts do not grant boosts.** Test low speed, severe wall impact, takeoff, recovery, and release without valid lateral/steering activity.
- [ ] **21. Boosts expire correctly.** Watch source/time in F3. Top speed returns smoothly; base resource values remain unchanged. Check configured strongest-wins or replacement overlap behavior.
- [ ] **22. Boost pads activate reliably.** Drive through the cyan arrows on the long left straight and upper diagonal. Remaining on one pad cannot repeatedly trigger it; exit/re-entry after cooldown can. Reset/restart must not immediately reaward an occupied pad.
- [ ] **23. Kart can launch from a ramp and land safely.** Use the amber ramp in the outside sand of the long left straight (56% lap fraction). Approach along its length at speed. Check one coherent takeoff, momentum, gravity and stable landing without repeated impulses or falling through terrain.
- [ ] **24. Camera behaves correctly during jumps.** Check ascent/landing smoothing, ramp obstruction handling and reset snapping.
- [ ] **25. Recovery and restart clear temporary movement states.** Clear drift/charge/boost on R, automatic fall/upright/bounds recovery, restart and race finish. No leftover acceleration, charge or orientation from the previous run.
- [ ] **26. Existing race progression remains functional.** Complete three laps with surfaces/drifts/pads mixed in. Optional ramp/runoff exploration must not bypass required checkpoints. Results/restart/Return to Ready still work.

## Review record

| Build | Date/tester | Controls/hardware/resolution | Checks/results | Acceptance |
| --- | --- | --- | --- | --- |
| v0.2.0 | Developer, confirmed 2026-11-08 | Original device details not recorded | Original 1–10 reported passed | Accepted baseline |
| v0.3.0-dev | Pending | Pending | 1–26 plus retained runoff regressions pending | Not accepted/released |

Automation is documented separately in [validation](../validation.md). A checkbox is a human verification result, not a unit-test result. Codex must never stage, commit, push, tag, publish a release or perform GitHub actions.
