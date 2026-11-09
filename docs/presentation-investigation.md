# v0.3.0 — persistent visual oscillation, second investigation

**Unreleased; developer acceptance remains pending.** The developer reports the original high-speed visual porpoising is still present after the first contact correction, at about 80 km/h on ordinary straights with `Ground true`. That report supersedes any suggestion that stable physics Y establishes visual acceptance. The validated shoulder correction remains in place. Project version is still `0.3.0-dev`; the separate v0.3.1 documentation history is preserved.

## Read-only history comparison

Compared `d83d0d1` (v0.2.0), `9c63889` (v0.2.1), `281c1f6` (v0.3.0-dev) and `ddf2573` (v0.3.1), using only Git log/show/diff:

- v0.3.0 introduced KartVisuals: cosmetic pitch/roll, wheel steering/spin, dust and exhaust. The physical body still only yaws during normal driving; cosmetic transforms live on a separate child.
- v0.3.0 added the camera obstruction ray and the existing low-ground safeguard. The camera's render-frame exponential position lerp, rotational slerp and raw physics-target sampling already existed in v0.2.0. No obstruction or height safeguard was implicated by the straight trace.
- Physics runs at 60 Hz. Engine render interpolation was disabled. Both old and current cameras read discrete `global_position`/`global_basis` in `_process()`. At 120 FPS, a physics pose repeats across render frames while the camera continues moving. Camera-to-kart distance and the kart's projected screen height therefore oscillate even with constant body Y.
- Endpoint-only position lerp also varies its steady following distance with frame duration. The repeated changes in distance affect apparent pitch/size. This is a separate timing error from body contact and does not require cosmetic pitch to be active.

The historical comparison **does not prove this timing defect was introduced by v0.3.0**, since its underlying camera pattern predates that patch. It reproduces a visual oscillation mechanism in the current build. The reason the developer first noticed the symptom in v0.3.0, and whether every part of their reported symptom is now eliminated, remain subject to the A/B manual test. Cosmetic pitch stayed essentially zero on the measured straight, and disabling cosmetics did not remove the measured screen motion.

## Fix

1. Explicitly enable `physics/common/physics_interpolation` for rendering the kart between physics ticks. Physics equations, collision, input, race rules and tick frequency are unchanged.
2. Sample `get_global_transform_interpolated()` **once per camera render update** and use that same pose for camera position, obstruction focus and look point. The child visuals inherit the body's interpolated placement.
3. Disable automatic local interpolation on the independent camera and render-updated Visual child. Their local transforms already update each rendered frame, so they must not be interpolated again.
4. Keep the existing position smoothing rate (8/s) but integrate an assumed linearly moving target over each frame, rather than repeatedly treating the newest endpoint as stationary. For decay `e = exp(-rate * delta)`, the update is `target_now + (camera_before - target_before) * e - (target_now - target_before) * (1-e)/(rate * delta)`. Deterministic tests verify the same constant-speed following distance at 60, 120 and 720 FPS and alternating short/long frames. Rotational smoothing remains 10/s; no stronger smoothing or new height clamp was added.
5. Preserve reset snapping/interpolation resets, drift lean, wheel animation, real ramp launches and the previous shoulder fix. No kart controller or ramp change was needed in this second investigation.

This follows [Godot's manual camera interpolation guidance](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/advanced_physics_interpolation.html): render-frame cameras should follow the rendered target pose and avoid a second automatic camera interpolation pass.

## Developer A/B controls

Focus the game window. **F3** shows diagnostics. **F4** cycles modes and makes the diagnostic panel visible. Normal mode is restored on every application launch.

| Mode | Cosmetics | Camera | Purpose |
| --- | --- | --- | --- |
| **A — Normal** | All enabled, including drift lean, pitch and wheels | Smooth corrected chase with obstruction handling | Acceptance mode; stable presentation at about 80 km/h is required here |
| **B — Static visuals** | Root pitch/roll and wheel spin/particles/exhaust disabled; front-wheel steering retained | Same chase as A | Isolate cosmetic animation while preserving driving |
| **C — Fixed camera orientation** | All enabled | Position still follows; world rotation frozen at mode entry | Isolate rotational smoothing/look effects; use on a straight, since turns can leave the frame |
| **D — Minimal rendering** | Same static visuals as B | Direct follow of the shared interpolated physics-body pose; no chase smoothing or obstruction response | Reference presentation without cosmetic or chase effects; use in clear space |

No mode changes velocity, handling config, driving inputs or race progress. Diagnostic modes are intentionally not normal camera safety/feel presets.

**F6** starts/stops optional per-render-frame CSV capture. The exact path is printed in Godot's Output panel; files are under `user://presentation_*.csv` (normally `%APPDATA%/Godot/app_userdata/Turbo Riot/`). Capture contains timestamp/tick, measured physics/render rates, grounded state, physical position/rotation, cosmetic local/global transforms, rendered body/visual transforms, camera position/rotation, relative world position/pitch and projected helmet/nose screen Y. The distinction between physical and rendered transforms is intentional. Logging is off by default; HUD sampling is optional, and files flush once a second.

**F7** cycles 60 → 120 → uncapped render limits and disables VSync for this diagnostic session. Physics remains 60 Hz. Restart the game to restore normal settings. CSV capture has overhead; compare with recording off as well. Debug actions never save these settings to project metadata.

To confirm: drive the same long straight at approximately 79–80 km/h in **A**, then compare **B**, **C** and **D**, without changing driving inputs. Repeat at 60, 120 and uncapped rendering rates where hardware permits. Return to **A** for acceptance. If A still porpoises, record which other modes remove it and capture a short F6 trace. Grounded state or body Y alone is not the criterion.

## Rendered evidence

`tests/capture_presentation_probe.gd` uses the actual source circuit's long upper straight, real kart/controller and native Compatibility renderer at 1280×720 on an RTX 3070 Ti Laptop GPU. The optional pads/ramp are removed **only from the probe scene** so speed stays 22 m/s (79.2 km/h), without changing controller equations. Timed samples are taken after `frame_post_draw`, after visual/camera updates, not from `process_frame` before those updates. The window begins after 0.7 seconds of chase settling and lasts 1.5 seconds.

The `--legacy` option uses a preserved test fixture of the committed v0.3.1 camera update, with the body's render interpolation disabled to reproduce the previous presentation. The mode-A physical trajectories are unchanged; all samples stay grounded and body-Y range is approximately 3.25e-6 m.

| Render rate | Historical camera: screen-Y range | Corrected A: screen-Y range | Actual measured rate, corrected A |
| --- | ---: | ---: | ---: |
| 60 cap | 0.232 px | 0.307 px | 60.0 FPS |
| 120 cap | 3.332 px | 0.211 px | 120.2 FPS |
| Uncapped | 6.465 px | 0.218 px | 299.6 FPS (historical run: 325.6 FPS) |

Before the fix, the initial A/B pass also measured about 3.19 px at 120 FPS in both A and B, about 3.20 px in C, and under 0.001 px in D. That isolates movement between a stepped body and a continuously updated follow camera; freezing pitch alone was insufficient. The initial A/B window used the right straight; the final historical/fixed table above uses the longer upper straight to keep later screenshots clear of bends.

All **12 corrected mode/rate combinations** pass the probe's one-pixel screen-Y range limit. B/C are below 0.22 px and D below 0.001 px in the final run. Minor residual settling is included in the ranges rather than removed from the data.

As a separate rendered-pixel check, a small unshaded magenta marker above the helmet is visible in eight saved frames. Its pixel centroid varies from Y=389 to 392 with the historical camera (3 px); the corrected frames all have 50 matching pixels and identical centroid Y=384.36. The absolute Y differs because the corrected follow integration preserves a slightly different steady lag; **variation**, rather than absolute placement, is the comparison. Synchronous screenshot readback is excluded from timed FPS windows because it stalls the GPU. Marker creation exists only in the probe.

Artifacts: `artifacts/presentation_legacy.csv`, `presentation_probe.csv`, `presentation_legacy_pixel_*.png` and `presentation_fixed_pixel_*.png`. Run:

```powershell
godot --path . --script tests/capture_presentation_probe.gd -- --legacy
godot --path . --script tests/capture_presentation_probe.gd
```

For a shorter corrected screenshot pass, append `-- --pixels-only`. Historical comparison intentionally reports its oscillation and does not fail the corrected-build threshold. These fixtures never replace the normal game's camera.

`tests/presentation_tests.gd` adds **28 assertions** for frame-rate/pacing-invariant follow, interpolation ownership, A/B isolation without physics mutation, fixed orientation, shared rendered projection, reset snapping, optional CSV and the HUD controls. See [validation](validation.md) for the full suite results. Manual checks 46–49 extend [the cumulative checklist](testing/ACCEPTANCE_CHECKLIST.md).

## Acceptance limit

This is measured improvement of a reproduced visual presentation defect, including rendered pixels; it is not developer acceptance of the original reported symptom. Other GPUs, controller hardware, pacing/VSync combinations, long play sessions and the exact route where the developer sees the issue remain unverified. The A/B tools remain available until acceptance. Roadmap and version identifiers remain unchanged; no staging, commits, pushes, tags or GitHub actions were performed.
