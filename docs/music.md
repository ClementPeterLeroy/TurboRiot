# Menu and music system

2026-11-27. **0.6.1-dev, Unreleased, pending developer acceptance.** No runtime version or roadmap milestone changes. Historical version entries and acceptance checks remain intact; a Git commit title does not establish a released version.

## Ownership and playback

`MusicManager` is an Autoload (`scripts/audio/music_controller.gd`), independent of circuit scenes. It processes while the SceneTree is paused. Two lightweight AudioStreamPlayers share the existing Music bus, with at most one audible transport. The app-owned AudioDirector retains engine, drift and event cues on Effects, and no longer creates synthesized placeholder music. Existing AppSettings controls persistent Master/Music/Effects levels; the music manager does not overwrite bus volume.

| State | Music |
| --- | --- |
| Home, mode/race configuration, circuit gallery, credits, settings, READY/countdown | `assets/music/main_menu_first.wav` |
| GO through ordinary racing laps | `assets/music/racing_general.wav` |
| Local player enters final lap | `assets/music/racing_final_lap.wav` |
| One-lap race | Final theme immediately at GO |
| Pause and pause settings | Menu theme; race decoder suspended |
| Resume | Same suspended race decoder and musical position |
| Local finish/results | Menu theme |
| Abandon paused race | Existing menu playback continues |

Only the bound local `RaceSession` state and validated lap signals determine progression. There is no parallel lap counter. AI models cannot change the selected theme. The final selection is latched once per race; the completion lap signal is excluded because RaceSession emits it before FINISHED. Reverse/duplicate crossings remain subject to existing checkpoint validation. READY/countdown and a newly bound session reset the transport epoch, preventing previous races or pending fades from leaking into the next race. Late teardown from an older session cannot disconnect a newer session.

Pause immediately sets `stream_paused`, retaining the AudioStreamPlayback rather than stopping/recreating it or approximating its position with a timer. **Godot reports `playing == false` while suspended**: an explicit suspension flag is essential to distinguish a retained decoder from stopped audio. Native mixer tests verify decoder identity and unchanged start counts. A mixer buffer already in flight can advance about 11.6 ms immediately after pause; playback then holds and resumes from that retained position.

Transitions fade the outgoing transport to silence, stop it, then fade the incoming transport in. This prevents audible overlap. `transition_seconds` defaults to 0.18 seconds per fade leg; `final_lap_fade_seconds` is 0.07 per leg. `gain_db` defaults to -9 dB relative to the user-controlled Music bus. No camera/physics/SFX effects were added. Normal application quit retires stopped decoders before engine shutdown.

## Assets and future circuit themes

All five existing WAV files and their import settings remain unchanged. Only the requested first menu theme is used; second/third remain available. The three active files are stereo 44.1 kHz: menu 120 seconds, racing/final 91 seconds each. Runtime resource copies enable full-range sample looping without changing source imports or duplicating files. Listen to confirm the artistic seam quality of the supplied recordings; looping transport alone cannot guarantee a seamless musical edit.

TrackDefinition exposes optional `racing_music` and `final_lap_music` AudioStream fields in the Inspector. Leave them empty for global defaults. They do not alter the circuit scene, route or geometry. WAV, Ogg Vorbis and MP3 overrides are supported. Missing/empty/unsupported override streams warn once and fall back globally; missing final music retains the general loop, while a missing required menu/general asset produces safe silence in that state. Diagnostics are available through `MusicManager.asset_issues` and warnings. No fallback synthesized soundtrack is introduced.

Current product modes are Quick Race and Time Trial. Character/kart selection and Grand Prix selection/sequence do not exist, so no new screens were added and no actual Grand Prix run is claimed. Binding each new race resets independently; a future Grand Prix should use that existing entry point.

## Validation

- Full existing-plus-new Godot suite: **1,985 assertions, zero failures**, including **302 music assertions**. Coverage includes local versus AI authority, lap counts 1/2/3/5/20, invalid crossings, duplicate events, restart, new sessions, stale teardown, repeated pause, settings persistence, missing assets and optional themes.
- Real-time native viewport with Dummy audio driver: **1,976 checks, zero failures**. AudioEffectCapture measured nonzero PCM on Music for all three themes and their loop boundaries. Every sampled render frame has at most one audible transport. Normal/final pause preserved the same decoder with no extra play invocation. This probe deliberately runs without `--fixed-fps`.
- Physical local Time Trial races, driven through real checkpoints by AI input: three laps 31.767 / 30.900 / 30.900 seconds; final selection at completed lap 2, race time 62.667. One lap 31.767 seconds; final selection at GO, no general-theme start. Both finish without recovery. These simulations use fixed 60 Hz and are separate from real-time decoder validation.
- Blender City locality and roof audits: **115 / 114 checks, zero failures**. Godot headless editor import passes. Windows sandbox emits the existing certificate-store warning, unrelated to music.
- Original WAV hashes, kart/race/camera scripts and circuit scene/resource hashes are checked against the task baseline. Historical City freeze JSONs remain unchanged; `tests/fixtures/music_update.json` explicitly supersedes only five authorized integration files in those audits. New audit reports have music-specific filenames, preserving historical reports.

Reports: [state checks](../artifacts/music_state_validation.json), [real mixer](../artifacts/music_playback_validation.json), [three-lap race](../artifacts/music_physical_race_3.json), [single lap](../artifacts/music_physical_race_1.json), [City locality](../artifacts/music_city_locality_audit.json), [City roofs](../artifacts/music_city_roof_audit.json). Human listening, real audio output hardware, controller/exported-build acceptance and eventual actual Grand Prix integration remain pending. Checklist **263-276** extends the retained cumulative baseline.

Run after headless editor import, substituting your Godot executable:

```powershell
Godot --headless --path . --fixed-fps 60 --script tests/run_tests.gd
Godot --path . --audio-driver Dummy --script tests/validate_music_playback.gd
Godot --headless --path . --fixed-fps 60 --script tests/validate_race_music.gd -- --laps=3
Godot --headless --path . --fixed-fps 60 --script tests/validate_race_music.gd -- --laps=1
blender --factory-startup --disable-autoexec --background --python tests/audit_city_transitions.py
blender --factory-startup --disable-autoexec --background --python tests/audit_city_architecture.py
```

## Changed files

Product integration: `project.godot`, `scripts/audio/music_controller.gd`, `scripts/audio/audio_director.gd`, `scripts/app/application.gd`, `scripts/main.gd`, `scripts/track/track_definition.gd`. New GDScript files have Godot-generated `.uid` companions.

Tests: `tests/music_tests.gd`, `tests/music_scope.gd`, `tests/fixtures/music_update.json`, `tests/validate_music_playback.gd`, `tests/validate_race_music.gd`, `tests/run_tests.gd`, `tests/city_square_architecture_tests.gd`, `tests/city_square_transition_tests.gd`, `tests/audit_city_architecture.py`, `tests/audit_city_transitions.py`.

Documentation: `README.md`, `CHANGELOG.md`, `docs/music.md`, `docs/validation.md`, `docs/testing/ACCEPTANCE_CHECKLIST.md`. Validation adds the music-specific reports linked above and a fresh City contact regression report. Existing roadmap, release history, assets, circuit geometry and driving rules are preserved. No staging, commits, pushes, tags, releases or GitHub operations.
