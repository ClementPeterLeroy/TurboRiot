# Turbo Riot cumulative acceptance checklist

## History and status

- **v0.2.0:** All ten original checks were manually accepted by the developer (confirmed 2026-11-08). Their exact wording below was supplied in the v0.3.0 brief on 2026-11-09.
- **v0.3.0-dev — Arcade Handling:** Checks 11–26 and baseline regressions remain pending manual acceptance.
- **v0.3.1 — Corrective Patch:** Checks 27–36 plus all earlier regressions remain pending. No checkbox is marked passed merely because automation or rendering succeeded. No current gameplay/feel/hardware acceptance is claimed by Codex. Record the actual runtime build identity alongside the patch label; see [versioning](../../VERSIONING.md).
- **v0.3.0 vertical-contact correction:** Checks 37–45 and all prior regressions remain pending; runtime version is unchanged.
- Preserve checks and append new ones for later patches. Record build, date, tester, controls/hardware, resolution, result and issue links. Historical acceptance does not automatically accept changed behavior.
- The earlier [runoff checklist](../acceptance.md) remains preserved with stable V02/V03-R IDs. Its access, re-entry, collision and race-integrity checks remain regressions. The correction-only expectation of unchanged surface behavior is superseded by checks 14–15 in this full handling patch. No earlier pending correction check is silently marked accepted.

## v0.2.0 regressions — previously manually accepted; current v0.3.1 regression run pending

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

## v0.3.0-dev — Arcade Handling checks — manual verification pending

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

## v0.3.1 — Corrective Patch checks — manual verification pending

Checks 1–26 above are retained verbatim as history/regressions. For the corrected source circuit, check 13’s former profile/opening/perimeter coordinates are superseded by the stepped outer fence and two infield openings described in [track-reference.md](../track-reference.md). Legal runoff now counts at checkpoints; any older road-only expectation is superseded by check 31. No checkbox below is pre-accepted.

- [ ] **27. Circuit geometry closely matches the overhead reference.**
- [ ] **28. Barrier locations match the intended circuit layout.**
- [ ] **29. Barrier colours repeat in groups of five.**
- [ ] **30. Kart can access intended sand and grass runoff.**
- [ ] **31. Checkpoints register valid off-road racing lines.**
- [ ] **32. Invalid shortcuts still fail lap validation.**
- [ ] **33. Reverse entry onto boost pads produces forward propulsion.**
- [ ] **34. Normal forward entry onto boost pads still works.**
- [ ] **35. Kart collides with tree trunks.**
- [ ] **36. Kart can pass beneath or beside foliage without oversized invisible collisions.**

For 27–30 compare the overhead and chase views, inspect both grass openings, and try colour group size three then restore five. For 31–32 test both sides of corners, grass at finish, reverse/order violations and large infield cuts. For 33–34 enter each pad forward, backward and facing away; check smooth acceleration/yaw, cooldown and expiry, plus drift mini-turbos. For 35–36 drive into a trunk and through adjacent crown space. Rerun earlier race, drift, recovery and camera checks and record actual hardware.

## v0.3.0 development patch — vertical-contact correction, manual verification pending

This is an additional correction within the existing v0.3.0 patch, with no project version advance. Earlier v0.3.0-dev handling and v0.3.1 corrective history/checks remain preserved. Rerun all prior regressions with these new checks; no automated result marks a manual checkbox accepted.

- [ ] **37. Kart remains vertically stable on flat asphalt.**
- [ ] **38. Kart remains stable while accelerating and braking.**
- [ ] **39. Kart remains stable during normal steering.**
- [ ] **40. Kart remains stable during drifting.**
- [ ] **41. Kart transitions smoothly between asphalt and sand.**
- [ ] **42. Kart can still jump and land normally.**
- [ ] **43. Camera remains stable without artificial bobbing.**
- [ ] **44. Grounded state does not flicker on flat terrain.**
- [ ] **45. Recovery and restart work correctly.**

Test the right and left straights in both directions, coast/stop/brake, countersteer and drift, then cross each sloping shoulder out and back repeatedly. In F3, inspect floor contact while comparing the body and chase view. Use the optional ramp for a genuine takeoff and landing; it must not be pulled down by snapping. Exercise R and F5 before and after a jump. Record real keyboard/gamepad hardware, frame rate and any reproducible remaining bounce. See [diagnosis](../vertical-stability.md).

## v0.3.0 — high-speed visual presentation, manual verification pending

The developer reports the original visual symptom remained after the contact correction. Retain the shoulder fix and all earlier checklist wording/history. The following checks verify visible presentation, including camera angle and rendered screen position; stable body Y or `Ground true` alone cannot pass them.

- [ ] **46. Normal mode remains visually stable at about 80 km/h on a straight.** In A, inspect chassis, helmet, wheels and the road/camera relationship continuously while accelerating, coasting and holding speed. Confirm no periodic apparent pitching or vertical screen movement.
- [ ] **47. A/B modes isolate presentation without changing driving.** F4 cycles A/B/C/D; active mode is visible in F3. Compare the same straight and inputs. B removes cosmetic motion, C freezes orientation, and D uses direct shared-pose follow. Return to A afterward and record which modes still show any symptom.
- [ ] **48. Presentation stays stable across rendering rates.** Use F7 for 60/120/uncapped where supported, with and without F6 recording. Record actual render/physics rates, VSync/device details and relative angle/screen behavior. Capture a short CSV if the symptom remains.
- [ ] **49. Full presentation and existing mechanics survive the fix.** In A, confirm drift lean/wheel animation, a real ramp jump/landing, smooth chase/obstruction behavior, R recovery and F5 restart with immediate camera reset and no old pose trail.

See [diagnosis, capture instructions and measured evidence](../presentation-investigation.md). These remain developer acceptance checks, not automated checkboxes.

## Review record

| Build | Date/tester | Controls/hardware/resolution | Checks/results | Acceptance |
| --- | --- | --- | --- | --- |
| v0.2.0 | Developer, confirmed 2026-11-08 | Original device details not recorded | Original 1–10 reported passed | Accepted baseline |
| v0.3.0-dev — Arcade Handling | Pending | Pending | Handling 1–26, retained corrections/regressions and vertical checks 37–45 and presentation checks 46–49 pending | Not accepted/released |
| v0.3.1 — Corrective Patch | Pending | Pending | 1–36 plus retained runoff regressions pending; runtime identity currently 0.3.0-dev | Not accepted/released |

Automation is documented separately in [validation](../validation.md). A checkbox is a human verification result, not a unit-test result. Codex must never stage, commit, push, tag, publish a release or perform GitHub actions.
