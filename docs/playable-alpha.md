# v0.6.0-dev — Playable Alpha

Unreleased, pending developer acceptance. Launch the project with **F5** to open `scenes/app.tscn`. The existing `scenes/main.tscn` remains a standalone race/authoring fixture; its direct-run shortcuts are retained for earlier tests. v0.4/v0.5 are not retrospectively accepted or released.

## Play

Choose **Quick Race**, configure 0–6 opponents, Casual/Standard/Challenging difficulty, 1–20 laps (default 3), and player controls. Choose **Time Trial** for one human, no AI, no loot/projectiles/competitive items, and lap/total results. Pads and drift mini-turbos remain usable. Both modes use only the existing circuit; there is no track/kart selection, ghost or persistent record system.

Start Race shows initialization, then READY. Enter/Space/Pad A starts the shared 3–2–1–GO countdown. Normal driving, ordered checkpoints, drift, mushroom immunity, physical spin-outs, collisions, ramps and recovery remain. Quick Race defaults retain six opponents and Challenging from the saved scene; the race script's standalone default remains Standard. Per-mode configuration copies prevent Time Trial's zero opponents from leaking into Quick Race.

**Escape / Pad Start** pauses READY/countdown/racing. Resume, Restart Race, Settings and Main Menu remain responsive while all world physics, race/AI decisions, item timers, boosts and spin reactions stop. Focus loss also pauses; focus return requires explicit Resume. A selected controller disconnect pauses and offers reconnection or returning to configure controls. A closing Back/item button must be released before it can use an item after resume.

**F5 / Pad X** restarts a fresh session during gameplay or pause. Results offer Restart Race and Main Menu; Escape/B from results returns home. Player results retain the existing policy allowing other racers to finish/DNF. Once everyone is finished, race/item timers are sealed and actors cleared while results and camera remain usable. Gravity can settle finished bodies normally. Results details accept keyboard/controller focus and scrolling. Restart/return removes the whole old race subtree, disconnects audio and clears all prior world state.

Menu controls: mouse, arrows/left stick/D-pad, Enter/Space/A confirm, Escape/B back. A/B UI actions are explicitly registered because this engine build's defaults contain only keyboard Confirm/Back. Controls remain single-player: Keyboard + any controller, Keyboard only, or one detected controller for driving. Menu navigation and global keyboard shortcuts remain available. Physical gamepad behavior still needs developer testing.

## Settings

Settings are available from home and pause. Apply saves and applies; Back cancels unsaved changes, including live audio preview. `ConfigFile` stores local `user://settings.cfg` values. Missing, unrecognized or invalid values safely retain/default/clamp supported values. A failed save is reported without blocking navigation.

- Windowed/fullscreen; window presets 960×540, 1280×720, 1600×900, 1920×1080 and 1024×768. Fullscreen uses the current display mode; the preset controls windowed size.
- VSync and UI scale 85–125%. Canvas expansion/anchors and scrolling support different aspect ratios. Minimum window size is 960×540.
- Independent Master, Music and Effects levels/mutes. Defaults: 80% / 35% / 70%. Sliders preview audio; Apply persists it.
- Read-only keyboard/controller mapping reference; no full rebinding interface.

Window dragging resizes live; saving a resolution means choosing a preset and Apply. Race-local F7 diagnostics are temporary; restart/return restores saved VSync and clears the diagnostic FPS cap. No graphics-quality presets or physical-device matrix is claimed.

## Architecture and files

`TurboApplication` owns one menu, one AudioDirector, settings, validated RaceSetup copies and at most one race under its world slot. Menus/audio use ALWAYS processing; each gameplay root explicitly uses PAUSABLE processing. This keeps all inherited physics/effect processes frozen together while the menu stays active. No autoload or track framework is introduced.

`start_session()` renders initialization before procedural construction, validates/assigns existing RaceManager properties before `_ready`, and uses a generation token to cancel stale launches. Restart creates a fresh scene/model rather than resetting only some fields. The managed race root yields shortcuts to the application, while the existing raw scene API remains compatible. Overall completion uses a one-shot field-completed signal to clear competitive world effects and stop race/item timers. Late focus callbacks verify their controls remain in the tree.

| Files | Purpose |
| --- | --- |
| `scenes/app.tscn`, `scripts/app/application.gd` | Application flow, initialization, pause, fresh restart, disposal, focus/controller loss. |
| `scripts/app/race_setup.gd` | Coherent validated per-mode/per-session parameters, menu six-AI cap. |
| `scripts/app/app_settings.gd` | ConfigFile persistence, validation and live audio/display application. |
| `scenes/ui/alpha_menu.tscn`, `scripts/ui/alpha_menu.gd` | Responsive reusable page, scroll/focus graph, consistent buttons and mapping display. |
| `scripts/audio/audio_director.gd`, `riot_sounds.gd` | Buses, bounded cue pool, music/engine/drift loops and generated placeholder audio. |
| Existing main/input/HUD/race/items/controller/boost scripts | Small managed-mode, assignment, result, completion and audio-event integrations. |
| `tests/alpha_tests.gd`, `capture_alpha_preview.gd` | Automated lifecycle/settings/input/audio assertions and native application captures. |

The menu caps opponents at six; the underlying authoring/test RaceManager retains its previous larger limit. Overall timeout retains the 480-second floor and allows at least 120 seconds per configured lap; finish-grace/DNF behavior remains. No KartConfig/handling, collision dimensions, camera math, track geometry, surface/drift/spin or projectile algorithms are rewritten.

## Audio

AudioDirector creates Music/Effects buses feeding Master, one persistent engine loop modulated by speed/throttle, one drift loop, one music loop, a 12-voice race-effects pool and three UI voices. Separate UI voices let Confirm/Back finish naturally when the old race audio is disposed. Navigate/confirm/back, countdown/GO, drift, accepted mini-turbo/pad/mushroom activations, collision, pickup/use/impact, lap and finish have hooks. Cooldowns, conservative sample gains, distance attenuation and voice reuse limit overlap/clipping; no engine restart occurs per frame. ItemSystem delegates cues to the director in managed races while keeping world feedback; raw scenes retain their original spatial placeholder cues.

Pause stops race one-shots, pauses engine/drift streams and ducks music. Resume restores streams; restart/return unbinds old signals and stops race voices without cutting the UI confirmation/back cue. Engine pause state is explicitly reset before a new race. Master/music/effects and mutes persist independently.

All new audio is original, simple synthesized placeholder PCM. No game music/samples were downloaded. The short music loop and engine/cues are engineering placeholders, not the v0.7 soundtrack or final mix. Subjective sound quality, perceived timing, volume balance and controller feel remain manual acceptance work.

## Tests and developer acceptance

Baseline before edits: **842 checks, zero failures**. Expanded suite: **925 checks, zero failures**. New tests cover invalid configuration, mode isolation, persistence/fallback, bus isolation, waveform/loop validity, keyboard/mouse/injected controller UI routing, assigned input, loading cancellation, pause clocks/physics/items/AI, same-source boost cues, fresh cleanup, results/finish deduplication, focus loss and repeated sessions.

Native `tests/capture_alpha_preview.gd` checks home/config/settings/credits, READY/countdown/racing/pause/results, 720p/1080p, 1024×768 at 125% UI scale, fullscreen/windowed transitions, actual engine-stream pause/restart and real physical Quick Race/Time Trial completion. The helper supplies AI commands to the player for automation, not manual or hardware playtesting; it disables automatic focus-loss pause only within that controlled capture. Product focus-loss pause remains enabled. Captures are `artifacts/alpha_*.png`. See [validation](validation.md) for actual executed results/limitations.

Run the cumulative **1–119** checklist. The new **105–119** are unchecked. Test both modes, all supported UI devices, held controls before GO, pause during countdown/spin/projectiles, settings/back/Apply, full results and DNF, restart from pause/results, focus loss and unplug/reconnect, repeated launches, volume relaunch persistence and display changes. Physical controllers, real typing/driving feel, audio mix, DPI/multiple-monitor setups and exported builds still require developer acceptance.

## Deferred v0.6.1 and v0.7 work

No circuit is added here. The existing scene bundles circuit-specific environment footprints, boost/ramp placement, loot pixel anchors, checkpoints and racing-line assumptions. v0.6.1 must package these coherently per circuit while retaining ordered gate validation, legal runoff, grid clearance, real collision and AI completion tests. It owns the reusable framework, original circuits and five private educational test circuits listed in [ROADMAP](../ROADMAP.md). Keep private reference content separate from distributable original content.

v0.7 retains original characters/karts/environments/audio and the Graffiti Speed logo/TR icon/Graffiti Impact startup identity. None is started here. Local HEAD at audit was `e22a2f2` titled v0.5.1; its runtime metadata still said 0.5.0-dev. Commit titles do not supply developer acceptance, so earlier history remains unchanged and v0.3.2 remains the latest developer-reported released baseline. No staging, commits, pushes, tags, releases or remote actions are performed by Codex.
