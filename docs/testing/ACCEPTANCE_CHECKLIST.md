# Turbo Riot cumulative acceptance checklist

## History and status

- **v0.3.2:** Latest released baseline as reported by the developer in the v0.4.0 brief; local commit `96934a4`, no local tags, old runtime metadata `0.3.0-dev`. Earlier checkbox wording/status remains historical; detailed manual results are not reconstructed from a release label.
- **v0.4.0-dev:** Unreleased, pending developer testing of all retained regressions plus new checks 50–65. High-speed visible stability remains required.

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

## v0.4.0 — Racing Competitors, manual verification pending

- [ ] **50. Seven karts appear on the starting grid.**
- [ ] **51. All racers respect the countdown.**
- [ ] **52. AI completes full laps without skipping checkpoints.**
- [ ] **53. AI brakes appropriately before corners.**
- [ ] **54. AI follows smooth racing lines.**
- [ ] **55. AI can recover from collisions or getting stuck.**
- [ ] **56. AI can overtake slower competitors.**
- [ ] **57. AI does not repeatedly oscillate between passing targets.**
- [ ] **58. Difficulty profiles produce observable differences.**
- [ ] **59. Live positions update correctly.**
- [ ] **60. Race rankings remain valid during off-road driving.**
- [ ] **61. AI and human competitors share physical handling rules.**
- [ ] **62. Finishing order and results are correct.**
- [ ] **63. Restart resets every competitor correctly.**
- [ ] **64. Player kart remains visually stable at high speed.**
- [ ] **65. Existing drifting, boosts, jumps and recovery still work.**

For 50–57 inspect grid clearance, hold controls before GO, drive/block slowly on a straight, force one AI off-road and compare F3/F8 commands and held passing side. For 58 rerun the same field with Casual/Standard/Challenging; compare braking/drift/traffic competence without changing KartConfig. For 59–62 try legal runoff, missed/reversed gates, AI-first and human-first finishes, plus an idle driver/DNF deadline; compare the live table against actual crossings. For 63 restart during countdown/racing/results and after recovery; verify every competitor. For 64 rerun retained presentation checks 46–49 at 60/120/uncapped where possible in A Normal; stable body Y alone is not acceptance. For 65 exercise drift/mini-turbos, pads, the optional ramp, R and F5 with opponents present. Record real device/feel issues and results separately from automation. See [play and debugging procedures](../racing-competitors.md).

## v0.5.0 — Power-Up Mayhem, manual verification pending

- [ ] **66. Kart-to-kart collisions no longer cause unjustified full stops.**
- [ ] **67. Rear-end impacts produce controlled momentum exchange.**
- [ ] **68. Side impacts preserve reasonable forward movement.**
- [ ] **69. Karts do not become stuck inside one another.**
- [ ] **70. Speed pads boost without locking steering.**
- [ ] **71. Braking and drifting remain available during boosts.**
- [ ] **72. Reverse entry onto speed pads works correctly.**
- [ ] **73. Mushroom visual matches the reference.**
- [ ] **74. Red shell visual matches the reference.**
- [ ] **75. Green shell visual matches the reference.**
- [ ] **76. Banana visual matches the reference.**
- [ ] **77. Loot boxes match the supplied reference.**
- [ ] **78. Exactly three loot-box rows appear at the blue map markers.**
- [ ] **79. Each row contains four evenly spaced loot boxes.**
- [ ] **80. All twelve loot boxes are reachable.**
- [ ] **81. Loot boxes disappear and respawn correctly.**
- [ ] **82. Mushroom boosts correctly.**
- [ ] **83. Red shell homes toward opponents.**
- [ ] **84. Green shell travels straight and ricochets.**
- [ ] **85. Banana causes a temporary handling disturbance.**
- [ ] **86. AI collects and uses items.**
- [ ] **87. Item effects do not break race progression.**
- [ ] **88. Restart clears temporary items and projectiles.**
- [ ] **89. High-speed kart visual stability remains correct.**
- [ ] **90. Existing AI racing, drifting, jumping and recovery still work.**

Checks 1-65 and their history remain verbatim. Historical pad-direction lock/full-stop expectations are superseded by the v0.5 requirements for immediate controls and controlled momentum exchange; all other baseline checks remain required. Use [item procedures](../power-up-mayhem.md) for controls, models, placement, tuning and diagnostic comparisons. Automated success does not mark any manual check passed.

## v0.5.0 development correction - Power-Up Balancing & Feedback

Unreleased, pending developer acceptance; no v0.5.1 release is introduced. All prior checks remain unchanged.

- [ ] **91. Mushroom ignores sand speed penalties.**
- [ ] **92. Mushroom ignores grass speed penalties.**
- [ ] **93. Normal off-road penalties return after mushroom expiration.**
- [ ] **94. Red shell causes a visible 360-degree spin.**
- [ ] **95. Green shell causes a visible 360-degree spin.**
- [ ] **96. Banana causes a longer spin-out.**
- [ ] **97. Spin-outs meaningfully reduce racing speed.**
- [ ] **98. Karts recover control smoothly.**
- [ ] **99. AI and human racers receive identical effects.**
- [ ] **100. Mushroom activates radial speed lines.**
- [ ] **101. Speed pads activate radial speed lines.**
- [ ] **102. Speed lines fade correctly and do not obscure gameplay.**
- [ ] **103. High-speed visual stability remains intact.**
- [ ] **104. Existing races, checkpoints, drifting, collisions and items still work.**

Use [the balancing procedures](../power-up-balancing.md) for both terrains, actual body spins, control recovery, speed-line intensity/fade and retained high-speed presentation diagnostics. Automated success does not mark these checks manually passed.

## v0.6.0 - Playable Alpha, manual verification pending

The application now starts at Main Menu; apply prior READY/startup/controls criteria inside a launched session. The raw race scene remains available for exact legacy fixtures. Managed Escape/Start pauses and results return to Main Menu; the new milestone intentionally replaces those raw-scene navigation controls without deleting their historical wording. No old check is marked accepted by this patch.

- [ ] **105. Main menu navigation with keyboard and mouse.**
- [ ] **106. Main menu navigation with a controller.**
- [ ] **107. Quick Race configuration and launch.**
- [ ] **108. Time Trial configuration and launch.**
- [ ] **109. Correct READY/countdown/race progression.**
- [ ] **110. Full race completion and results.**
- [ ] **111. Pause/resume without timer or physics progression.**
- [ ] **112. Restart without stale race state.**
- [ ] **113. Return to main menu from gameplay and results.**
- [ ] **114. Audio feedback and independent volume settings.**
- [ ] **115. Settings persistence after relaunch.**
- [ ] **116. Windowed/fullscreen and resolution behavior.**
- [ ] **117. Gamepad driving and UI interaction.**
- [ ] **118. No critical regressions in AI, drifting, boosts or items.**
- [ ] **119. Repeated races without crashes, duplicated entities or stale signals.**

Record real keyboard/controller, audio/display/DPI and repeated-session results using [Playable Alpha procedures](../playable-alpha.md). Injected events and automated captures are not physical-device or developer acceptance.

## v0.6.1-dev — Circuit Selection & First Testing Grounds

**Pending developer acceptance.** Rerun baseline checks 1–119, then check both new circuits below. Automated evidence and private-source comparison procedures: [Testing Grounds](../testing-grounds.md). No physical-device or human-play result is inferred.

- [ ] **120. All three implemented circuits appear with correct names and availability.**
- [ ] **121. Each circuit card shows the matching geometry-derived preview, category and description.**
- [ ] **122. Mouse selects circuits and launches the chosen race.**
- [ ] **123. Keyboard focus/navigation selects circuits and reaches Start Race and Back.**
- [ ] **124. Controller D-pad/A/B navigation works on real hardware.**
- [ ] **125. Back preserves race configuration and selected circuit.**
- [ ] **126. Each selected circuit loads the correct world and minimap.**
- [ ] **127. Restart preserves circuit selection.**
- [ ] **128. Quick Race and Time Trial both work on Figure-8 and Yoshi DS.**
- [ ] **129. Both new circuits form continuous closed loops.**
- [ ] **130. Road meshes have no gaps or inverted normals.**
- [ ] **131. Road/shoulder joins and crossing approaches have no critical collision seams.**
- [ ] **132. No unintended at-grade intersections; Figure-8 crossing decks remain separate.**
- [ ] **133. No disconnected road segments.**
- [ ] **134. No unplanned shortcuts, especially near Yoshi close sections.**
- [ ] **135. All seven grid spawns are on road and clear of barriers/other racers.**
- [ ] **136. Road width remains usable without severe distortion at tight corners.**
- [ ] **137. Compare both native top views with private annotated sources; no major silhouette, start or width discrepancy.**
- [ ] **138. Three-lap races count and complete correctly on both circuits.**
- [ ] **139. Directional checkpoints accept only the intended route and direction.**
- [ ] **140. Reverse finish-line crossing does not award a lap.**
- [ ] **141. Skipping a checkpoint does not award a lap.**
- [ ] **142. AI can complete both circuits; review Casual, Standard and Challenging.**
- [ ] **143. Recovery returns to a valid checkpoint pose without advancing progress.**
- [ ] **144. Restart clears temporary boosts, spins, inventory, projectiles and race state.**
- [ ] **145. Items, drifting, mini-turbos, collisions, pause and results retain prior behavior.**
- [ ] **146. Repeated circuit changes leave no old race state or timers.**
- [ ] **147. No duplicated racers after switch/restart/menu cycles.**
- [ ] **148. AI uses the newly selected route, without stale path data.**
- [ ] **149. No orphaned projectiles after leaving or restarting a race.**
- [ ] **150. No duplicated audio loops or stale race bindings.**
- [ ] **151. No critical runtime errors; high-speed visual stability remains intact.**

## v0.6.1-dev — Figure-8 false-wall correction

Preserve checks 1–151. The [crossing diagnosis and physical regression evidence](../figure-8-crossing-fix.md) records automated results separately; developer acceptance remains pending.

- [ ] **152. Upper crossing stays clear across the driving lanes.** Traverse the upper Figure-8 road at about 80 km/h in the center and both passing lanes; no invisible collision or sudden stop.
- [ ] **153. Boosted and opposite-direction crossing traversal stays supported.** Repeat with a mushroom and in the opposite direction; no phantom walls, contact flicker or unexpected launch.
- [ ] **154. Lower road remains clear beneath the crossing.** Drive under the upper road across all three lanes; no collisions with geometry above or unrelated barrier blocks.
- [ ] **155. Rounded lower contacts preserve existing behavior.** Check genuine walls/kart collisions, drifting, shell/banana spins, stable presentation and the original runoff ramp/jump on the reference circuit; repeat ordinary driving on Yoshi.
- [ ] **156. Recovery and restart remain correct on the crossing.** Recover before/on/after the grade and restart during the race; retain the selected circuit, legal checkpoint progress and clean temporary state.

## v0.6.1-dev — circuit racing performance correction

Preserve checks 1–156. Automated timing and geometry results are recorded in the [performance investigation](../circuit-performance.md); these manual checks remain pending.

- [ ] **157. Yoshi racing performance improves with normal gameplay enabled.** Compare reference and Yoshi using the same opponent count, resolution and VSync, with debug overlays/collision shapes off; record FPS during a full race rather than only READY.
- [ ] **158. Cached minimaps retain the route and live markers.** Confirm start position, recognizable circuit shape, player marker and moving AI markers on every circuit, in both race modes and selection cards.
- [ ] **159. Map projection remains correct after display changes.** Resize/change resolution and UI scale, including 4:3; route and markers remain aligned without stretching or clipping.
- [ ] **160. Optimized road support preserves handling.** Drive Yoshi/reference straights and tight corners, cross asphalt/runoff boundaries, drift, boost and receive spin-outs; retain stable contact and presentation. Recheck the reference ramp and both Figure-8 decks.
- [ ] **161. Repeated sessions retain performance and clean state.** Switch circuits, restart and return to menu repeatedly; no stale minimap, duplicated markers, runtime errors or progressive slowdown.

## v0.6.1-dev — Bikini Bottom sandbox recovery correction

Preserve checks 1–161. The new scene-specific recovery envelope is described in [validation](../validation.md); this is a sandbox fix, not completed imported-circuit race integration.

- [ ] **162. Valid Bikini Bottom road does not cause boundary/fall resets.** Stop/relaunch `scenes/tracks/Bikini_bottom_test.tscn` with F6; drive a complete loop, including the deepest descent and far left/right sections, without unexpected teleportation.
- [ ] **163. Genuine escape/fall still recovers safely.** Leave the configured safety envelope or fall below the road's fall threshold; return to the authored supported spawn without repeated resets. Shared circuits retain their previous recovery behavior.
- [ ] **164. Fresh scene starts recalculate imported-road limits.** After owner-authored model changes and reimport, relaunch the scene; check the root's road/kart references still resolve, new road extents are covered and the collision/spawn still match the model. No Blender geometry is automatically modified.

## v0.6.1-dev — Bikini Bottom test_v2 recovery wiring

Preserve checks 1–164. The same road-derived recovery setup now covers the separate v2 scene.

- [ ] **165. V2 covers the full road without false boundary/fall resets.** Stop/relaunch `Bikini_bottom_test_v2.tscn` with F6; drive the lowest descent and outermost road sections, then a full loop. Confirm no unexpected teleportation. Repeat after a reimport and fresh scene start.
- [ ] **166. V2 retains genuine recovery and its authored spawn.** Exit the safety envelope or fall below its configured threshold; recover to a supported spawn with cooldown intact. Recheck the original Bikini Bottom sandbox.

## v0.6.1-dev — Circuit 8 environment completion

Preserve checks 1–166. Automated and native results are documented separately; environment assembly remains pending developer/artistic acceptance.

- [ ] **167. Complete an uninterrupted Circuit 8 lap.** Drive the full Figure-8 in Time Trial with the new environment, without unexpected collisions, jumps or resets.
- [ ] **168. Bridge approaches and upper deck stay clear.** Test center and passing lanes, normal/mushroom speeds and an opposite-direction inspection; no snagging or new contact flicker.
- [ ] **169. Underpass clears kart and chase camera.** Traverse the lower road across its usable width; no pier, deck or camera intersection. Existing colored barriers retain their intended behavior.
- [ ] **170. AI still completes the circuit.** Review the seven-racer field over multiple laps with items and all difficulty profiles; inspect any recovery rather than assuming it is harmless.
- [ ] **171. Scenery respects the driving corridor.** Grandstands, flags, bridge fascia and approach verges do not block racing/recovery space; reachable structures have sensible simple collision.
- [ ] **172. New objects remain artist-editable.** Select, reposition, hide and restore each grandstand/flag in Godot; reopen/rebuild the procedural circuit and confirm authored additions survive. Inspect the separate bridge, terrain and collision helpers.
- [ ] **173. Assets load without missing meshes/materials.** Reopen the scene and test a fresh import/exported build; no duplicate environment, missing assets or unexpected import of Blender source files.
- [ ] **174. Review native 1080p performance.** Compare identical GPU/settings/full-field runs before/after; record frame-time percentiles, CPU/GPU/physics time, draw calls, primitives, memory and load time. Target stable 60 FPS; 120 FPS remains a stretch rather than an acceptance claim from average FPS alone.
- [ ] **175. Race integration and regressions remain intact.** Quick Race, Time Trial, checkpoints, items, drifting, recovery, restart and menu returns work; the other circuit environments retain prior behavior.
- [ ] **176. Artistic review against supplied references.** Review overall/bridge/underpass/grandstand captures and in-game views. Accept or adjust original gold bridge treatment, canopy proportions, restrained decoration and two straight stand placements; these intentionally approximate the reference's more extensive stadium.

## v0.6.1-dev — Yoshi coastal environment

Preserve checks 1–176; artistic/developer acceptance remains pending.

- [ ] **177. Full Yoshi lap and race remain valid.** Complete Time Trial and item-enabled Quick Race; checkpoints, laps, finish, drift, items, restart and recovery retain previous behavior.
- [ ] **178. Coastline supports the whole racing corridor.** Road edges and runoff meet grass without missing floors; sea outside the island has no hidden support. Falling off the coast still recovers correctly.
- [ ] **179. Both tunnels clear all lanes.** Drive normal/boosted speeds through each passage, including both sides; no snagging, artificial jumps or camera clipping.
- [ ] **180. Start-area architecture stays outside gameplay.** Houses, tower, stands, trees and flowers do not obstruct racing or safe recovery; inspect the pedestrian square and stand orientation.
- [ ] **181. Assets remain editable and reusable.** Move/hide a tree, bed, tunnel, house and each stand independently; inspect their separate Blender sources and collision wrappers. Road rebuild preserves placements.
- [ ] **182. Review the coastal garden art direction.** Check trees, flower visibility, shoreline, tunnel proportions, start-area composition and subtle water animation in motion; no missing materials or visual seams.
- [ ] **183. Verify 1080p performance on the intended GPU.** Compare warmed-up full-field laps with the same settings, overlays off; target 60 FPS and review frame-time spikes, memory and long-session behavior.
- [ ] **184. Import, session changes and exported builds stay clean.** Reimport changed model copies, switch circuits/restart/menu repeatedly and verify no stale colliders, missing models, duplicate instances or lost placements.

## v0.6.1-dev — banana spin direction correction

Preserve checks 1–184; the new banana behavior supersedes its original half-turn finish.

- [ ] **185. Banana ends facing the incoming direction.** Take a banana on a straight while holding throttle: one visible full turn, temporary slowdown, then forward driving without needing to turn around. Repeat with AI victims.
- [ ] **186. Legitimate steering and other hit reactions remain intact.** Steer during/after a banana; inspect drifting, walls, jumps, shell spins and camera stability. The correction must not teleport heading or force a route direction.
- [ ] **187. Banana cleanup and repeat-hit protection remain correct.** Recover/restart/finish during the effect and test overlapping hits; regain control normally without a stuck or repeatedly extended spin.

## v0.6.1-dev — Circuit 8 reconstruction, Milestone A

Preserve checks 1–187. Previous Figure-8 architecture checks 167–176 retain their history against the archived scene; they are not evidence that the reconstructed stadium exists. Final environment acceptance requires them to pass again when B–D are implemented.

- [ ] **188. Approve the reconstructed road silhouette.** Compare top, perspective and actual chase-camera views; inspect both loops, seam, consistent width and gradual approaches, without visible road cracks, inverted faces or abrupt heading/height changes.
- [ ] **189. Both crossing decks drive cleanly.** Drive center and side lanes on both decks, normal and boosted; inspect approach/crest camera clearance, contact stability and absence of false wall impacts. Temporary floating approaches and missing structure remain documented B work.
- [ ] **190. Complete a full Time Trial and Quick Race.** Verify all checkpoints/laps, AI progress, items, drift, normal jump/contact behavior and results without unexpected resets or geometry snags.
- [ ] **191. Recovery, restart and circuit switching remain valid.** Recover on each raised approach and lower road; restart and switch to/from other circuits. Confirm safe road placement and no duplicated/archived scenery in the active study.
- [ ] **192. Accept A before starting B.** Review temporary materials, saved editable curve, preserved old assembly and documented defects. Check 1080p performance in motion on the developer's PC; approve the road before terrain, bridge structure and stadium work.

## v0.6.1-dev — Circuit 8 stadium environment

Preserve checks 1–192. The developer approved proceeding from the road study via the stadium brief; this does not reconstruct individual historical check results or accept a release. Earlier architecture checks retain their archived evidence; verify the replacement environment below.

- [ ] **193. Grandstands read as a stadium from the kart.** Inspect both sweeping corners and finish stands; distinguish curved seating tiers, stairs, concrete support, closed backs, roofs, columns and restrained crowd colors. Review joins and intentional aisle breaks.
- [ ] **194. Pit complex is complete and grounded.** Inspect eight framed/numbered garages, service doors/equipment, upper glazing/balconies, parapets and control tower; no floating or road-intruding structures. The apron remains non-drivable.
- [ ] **195. Bridge and approaches are structurally coherent.** Inspect continuous deck, girders, caps, four piers, footings, abutments, grass banks and retaining toes from upper, lower and side views; no floating raised road or supports in driving lanes.
- [ ] **196. Both decks preserve gameplay and camera clearance.** Drive boosted and normally in every lane, drift through approaches, inspect the underpass and crest, and recover on both levels without false hits or camera clipping.
- [ ] **197. Rails, catch fences and enclosure are continuous.** Inspect corners, elevations and closure; no major gaps, overlapping road obstructions or empty ground horizon in the six documented chase views. Review fence aliasing on the intended display.
- [ ] **198. Original materials and signage remain readable.** Check garage numbers, gantry, lamps, signs, tower, concrete, seating, glass treatment, metal and turf under normal lighting. Decorative timing/lamps do not replace HUD information.
- [ ] **199. Complete Time Trial and item-enabled Quick Race.** Full laps retain gates, lap timing, AI, items, collisions, boosts, drift and results without scenery-related recovery or jams; restart/menu/circuit switching remain clean.
- [ ] **200. Reusable authoring survives iteration.** Edit/move one stand, garage, sign and mast, then reimport a model copy. Rebuild the road; stadium instances, materials and placement survive without duplicate visuals. Preserve manual edits before running authoring tools.
- [ ] **201. Verify sustained target-PC performance.** Run warmed-up seven-racer laps at 1080p, overlays off; target 60 FPS and review frame spikes, memory, fence/crowd detail and longer sessions using identical comparison settings.
- [ ] **202. Approve the stadium presentation.** Review all six kart-camera sites, top/overview and bridge side; report remaining art/visibility issues. Inspect an exported build and broader devices before release acceptance. All architectural systems are implemented, but automated checks alone do not grant artistic acceptance.

## v0.6.1-dev — Circuit 8 final polish

Preserve checks 1–202. The developer approved the stadium/environment reconstruction and artistic direction in the final-polish brief; no individual gameplay/device results or release acceptance are inferred.

- [ ] **203. Official artwork replaces arch branding on both sides.** Inspect normal and reverse approaches: supplied colors/transparency/proportions, centered logo, no old text, stretching, mirroring or clipping; pillars, header, lights and approved surroundings remain unchanged.
- [ ] **204. Exactly two pads fit their road sections.** Inspect centered bridge-approach and corner-exit pads: readable forward chevrons, flush elevation/orientation, no gaps, bumps, edge placement or checkpoint obstruction.
- [ ] **205. Human and AI boost behavior remains controlled.** Drive both pads; observe a brief acceleration/feedback with steering and drift available. Test standing occupancy, re-entry, overlapping stronger boosts, restart/recovery and expiry without repeated stacking or unintended launches. Observe AI activation too.
- [ ] **206. Full racing and approved environment remain intact.** Complete Time Trial and item-enabled Quick Race, crossing both decks and all gates; check AI, collisions, laps/results, camera stability and zero scenery changes beyond the logo/pads.
- [ ] **207. Final performance and build review.** Run sustained seven-racer 1080p laps on the target PC, compare identical settings, inspect texture/fence aliasing and test an exported build. Approve final pad feel and logo visibility before release acceptance.

## v0.6.1-dev — visual circuit gallery

Preserve checks 1–207 and their recorded history. Circuit display names are metadata; existing IDs and geometry remain unchanged.

- [ ] **208. Names and player-facing information.** Verify Desert Run, Circuit 8 and Serpent Coast in the playable gallery, with no internal/reference/implementation labels. Deferred Legend Park, Riot Arena and Sunhaven Square remain metadata-only until race-ready; no fake preview or launch card appears.
- [ ] **209. Accurate recognizable previews.** Compare outlines to the actual three circuits: correct proportions, centered scale, consistent stroke, start markers and clear upper crossing on Circuit 8. Reopen selection and inspect resize without stutter or stale previews.
- [ ] **210. Mouse and keyboard selection are predictable.** Click/confirm cards without starting a race. Inspect distinct selected/focused states, arrows, Tab, Down to Start, Enter to launch and Escape/Back to return. Rapidly open/close the gallery without focus loss.
- [ ] **211. Controller navigation is complete.** Verify D-pad, both stick axes, deadzone, held-direction repeat and release on real hardware; A selects/starts only the focused action, B returns, and focus remains visible. Avoid accidental selection from stick drift.
- [ ] **212. Layout adapts to the intended displays.** Inspect 1080p, 720p, 960×540 and 4:3/125% UI: all three cards and footer visible, readable names/description, no overlap/clipping or vertical scroll. Verify more cards scroll horizontally to follow focus when added.
- [ ] **213. Existing races and remembered choices work.** Launch every playable circuit through Quick Race and Time Trial; confirm the correct unchanged scene, items/opponents and race flow. Return/reopen/restart and check per-mode selection/configuration persistence. Review an exported build before acceptance.

## Review record

| Build | Date/tester | Controls/hardware/resolution | Checks/results | Acceptance |
| --- | --- | --- | --- | --- |
| v0.2.0 | Developer, confirmed 2026-11-08 | Original device details not recorded | Original 1–10 reported passed | Accepted baseline |
| v0.3.0-dev — Arcade Handling | Pending | Pending | Handling 1–26, retained corrections/regressions and vertical checks 37–45 and presentation checks 46–49 pending | Not accepted/released |
| v0.3.1 — Corrective Patch | Pending | Pending | 1–36 plus retained runoff regressions pending; runtime identity currently 0.3.0-dev | Not accepted/released |
| v0.3.2 | Developer-reported released baseline | Historical device details not supplied | Prior detailed checkbox results not reconstructed | Released baseline per developer |
| v0.4.0-dev | Pending | Pending | Retained 1–49 plus new 50–65 pending | Unreleased / not accepted |
| v0.5.0-dev | Pending | Pending | Retained 1-65 plus new 66-90 pending | Unreleased / not accepted |
| v0.5.0-dev balancing correction | Pending | Pending | Retained 1-90 plus new 91-104 pending | Unreleased / not accepted |
| v0.6.0-dev | Pending | Pending | Retained 1-104 plus alpha 105-119 pending | Unreleased / not accepted |
| v0.6.1-dev | Pending | Pending | Retained 1–119 plus circuits 120–151 pending | Unreleased / not accepted |
| v0.6.1-dev crossing correction | Pending | Pending | Retained 1–151 plus crossing 152–156 pending | Unreleased / not accepted |
| v0.6.1-dev performance correction | Pending | Pending | Retained 1–156 plus performance 157–161 pending | Unreleased / not accepted |
| v0.6.1-dev Bikini Bottom recovery correction | Pending | Pending | Retained 1–161 plus sandbox 162–164 pending | Unreleased / not accepted |
| v0.6.1-dev Bikini Bottom v2 recovery wiring | Pending | Pending | Retained 1–164 plus v2 165–166 pending | Unreleased / not accepted |
| v0.6.1-dev Circuit 8 environment | Pending | Pending | Retained 1–166 plus environment 167–176 pending | Unreleased / not accepted |
| v0.6.1-dev Yoshi environment | Pending | Pending | Retained 1–176 plus coastal environment 177–184 pending | Unreleased / not accepted |
| v0.6.1-dev banana heading correction | Pending | Pending | Retained 1–184 plus banana 185–187 pending | Unreleased / not accepted |
| v0.6.1-dev Circuit 8 reconstruction A | Pending | Pending | Retained regressions plus road 188–192 pending; earlier architecture retained in archive | Unreleased / not accepted |
| v0.6.1-dev Circuit 8 stadium | Developer approval, 2026-11-26 final-polish brief | Individual device details not provided | Environment reconstruction/artistic direction approved; granular 193–202 gameplay/device results not supplied | Art direction approved; not released |
| v0.6.1-dev Circuit 8 final polish | Pending | Pending | Retained regressions plus polish 203–207 pending | Unreleased / not accepted |

| v0.6.1-dev circuit gallery | Pending | Pending | Retained regressions plus gallery 208–213 pending | Unreleased / not accepted |

Automation is documented separately in [validation](../validation.md). A checkbox is a human verification result, not a unit-test result. Codex must never stage, commit, push, tag, publish a release or perform GitHub actions.
