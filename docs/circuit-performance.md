# v0.6.1-dev — circuit racing performance correction

2026-11-11. Unreleased, pending developer acceptance. Version remains `0.6.1-dev` / Windows `0.6.1.0`.

## Diagnosis

The developer reported 7–15 FPS on Yoshi while racing, versus 40–55 on the reference circuit, with debug overlays off. A native seven-racer profile measured about 12.6 ms inside Yoshi's kart updates, versus 0.55 ms for AI decisions. Freezing the karts at the same camera pose recovered most of the lost frame rate. Isolated motion queries identified the circuit-wide concave asphalt collider as the main physics cost; removing barriers or other karts did not materially reduce it.

The HUD also rebuilt and antialiased the complete 8,927-point baked Yoshi route every rendered frame. That physics-resolution curve is much denser than the displayed minimap needs. Both costs increased substantially on the longer circuit.

## Implementation

- `TrackBuilder` now uses shallow convex sections for **flat, unbanked** asphalt. Their top vertices and outside footprint come from the existing road mesh. A concave quad falls back to its original two triangles instead of filling its indentation. The 12 cm depth occupies the existing asphalt-to-terrain support interval. Road visuals, curve sampling and track layout are unchanged.
- Elevated or banked roads retain their original triangle collision. In particular, Figure-8's grade-separated crossing and the validated rounded kart hull are preserved.
- `CircuitMap` samples the same route at approximately 2 m intervals: Yoshi uses 596 display points instead of 8,927. Projection, background and route drawing are cached until configuration or resize. A separate child draws live interpolated racer markers at the rendering rate. Selection cards use the same cache.

No kart driving constants, AI difficulty, camera/interpolation, item rules, scenery or resolution were reduced to obtain the improvement. All 1,322 Yoshi kerb meshes remain present.

## Controlled native A/B

`tests/benchmark_circuits.gd` reproduces the preceding asphalt collision and minimap in a legacy fixture, then measures the optimized implementation **in the same process and on the same GPU**. Both retain the current kart hull and handling. Each case warms up for 360 physics ticks and samples another 360, with seven AI racers, Challenging difficulty, items, seed 42, 1280 × 720, VSync off and uncapped rendering. Physics stays at 60 Hz. No `--fixed-fps` is used for timing.

Measured with Godot 4.7.2 Compatibility on AMD Radeon(TM) Graphics:

| Circuit | Previous FPS | Optimized FPS | Previous / optimized mean physics time | Previous / optimized 95th-percentile frame time |
| --- | ---: | ---: | ---: | ---: |
| Reference | 48.4 | 116.9 | 10.45 / 7.03 ms | 29.90 / 14.32 ms |
| Yoshi DS | 10.5 | 77.4 | 14.93 / 8.97 ms | 129.97 / 18.37 ms |

During the measurement window the previous Yoshi route redrew on 63 of 64 frames; the cached route redrew zero times over 464 frames, while markers continued updating. Full results: [native benchmark report](../artifacts/v061_circuit_performance.json). These are short, hardware-specific measurements, not minimum-FPS guarantees. Exploratory runs selected different adapters, so separate-process exploratory FPS values are not used as the controlled comparison.

To reproduce with a native Godot console executable, without running another benchmark concurrently:

```powershell
& $godot --path . --script tests/benchmark_circuits.gd
```

## Regression coverage and developer review

The permanent suite adds 21 assertions to the existing 1,041: exact flat collision top vertices, matching surface area, retained elevated triangle faces, 72 support rays per circuit, bounded minimap detail, subpixel curve fidelity, preserved aspect ratio and static geometry across live marker updates. Existing physics, Figure-8 crossing, drift/spin, off-road, ramp, items, race and application tests remain intact. Timing itself is measured by the native benchmark rather than a hardware-dependent unit-test threshold. Final engine, race and capture results are in [validation](validation.md).

Stop the currently running game, then launch it again from the editor with F5 so regenerated collision and the new minimap child are initialized. Compare both circuits with the same opponent count, display settings and overlays off. Review permanent manual checks **157–161**, including moving markers, resizing, terrain transitions, high-speed presentation and repeated session changes. Developer hardware, exported builds, prolonged play and physical controls still require manual acceptance.

No version increment, staging, commits, pushes, tags, releases or GitHub actions were performed.
