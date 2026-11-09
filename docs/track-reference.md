# Circuit 01: corrected geometry and corridor authoring

This documents **v0.3.1 — Corrective Patch**, following **v0.3.0-dev — Arcade Handling**. Both remain Unreleased, pending developer acceptance. Runtime build identifiers remain unchanged; see [versioning](../VERSIONING.md). All three supplied images were inspected at their actual private `references/` location: `Mario_circuit_1_overhead.png`, `Mario_circuit_1_visual_aid1.png` and `reference_sheet.jpeg`. The suggested `docs/references/circuit_01/` directory is absent. The overhead governs placement; the other two guide primitive appearance/materials. No game resource loads a reference image.

## Coordinate mapping and source files

The 1000-pixel overhead maps to local X/Z using `x = (pixel_x - 500) * 0.18`, `z = (pixel_y - 500) * 0.18`. Asphalt is Y = 0.04; sand/fence bases are Y = -0.08. Road width is 14.4 m (80 pixels), with 1.2 m sloping shoulders. The closed source curve in `scenes/track.tscn` preserves the right finish straight, rounded lower return, central bend, left straight and upper diagonal. Explicit Bézier tangents keep inner road/shoulder edges from folding at joins; maintain radii greater than half-road plus shoulder width when editing.

| Source | Authoritative footprint |
| --- | --- |
| `resources/circuit_01_outer_fence.tres` | Stepped perimeter: pixels (8,8), (725,8), (725,158), (1000,158), (1000,1000), (470,1000), (470,860), (8,860) |
| `resources/circuit_01_infield_fence.tres` | T-shaped infield: 16 vertices, with its left stem, long crossbar, right stem and small lower-left steps |
| `scenes/track.tscn` | Road curve, 14.4 m width, twelve checkpoint fractions and the two assigned fence resources |
| `scripts/world/environment_builder.gd` | Matching editable infield polygon, outer stepped grass patches and seeded scenery |

Fence points are independent from road edges. The source scene disables the optional generic rectangle: its authored stepped outer fence supplies containment. Legacy clearance Curve/BarrierSection resources remain available for other tracks that omit Barrier Runs; they do not drive this circuit.

## Fence runs, colours and access

`BarrierRun` exports local points, closed/open state and normalized fence-arc gaps. Gap fractions refer to fence length, not source-road lap fraction. The infield openings lie on the right stem at pixel X=798, Y=530–650 and the left stem at X=172, Y=270–380. These intentional departures from a fully sealed infield preserve accessible grass beside both long straights. Remaining fence locations follow the traced footprint.

The builder splits exact edges at gaps and never bridges polygon corners diagonally. Block groups are R × 5, B × 5, Y × 5, G × 5 by default. Change Track's Barrier Color Group Size for other group lengths. The cursor continues through corners and the resource seam; a true gap starts a new connected physical run. Open runs finish complete groups; closed runs finish complete four-colour cycles. A few shorter blocks are distributed along edges to preserve exact corners. Visible blocks and simple box colliders share endpoints; four colour MultiMeshes and a shared mesh keep rendering batched.

## Legal checkpoints

The source scene places gates at fractions `0, .065, .205, .285, .35, .495, .575, .67, .745, .82, .9, .975`, selecting clearer corridors after major corners. Clearing or changing the array length relative to Checkpoint Count restores uniform spacing.

For each gate, lateral rays find the nearest enabled physical fence on either side. Extents subtract box half-thickness, then stop at the first point belonging to a neighboring source-route sector. The crossing point must remain inside the stepped outer polygon and the gate's circular source-arc window (48% of the average gate interval to either side). This includes connected sand and reachable grass without accepting another asphalt leg across the infield. F3 displays the same asymmetric bounds; gates remain 4 m high and forward-only.

The manager requires the next gate in order plus actual travel of at least 55% of its source-arc interval, accumulated within the legal polygon and expected sector. Movement sweeps over 8 m are rejected. Supported recovery/restart clears sampled travel and does not award a crossing. These guards reject isolated gate visits/large cuts; they are not a comprehensive anti-cheat system. Recovery still places the kart safely on the road.

When authoring a different course, inspect corridor rays/windows, clear passage, corners and gate fractions together. Do not expand gates through solid fences or into another route leg. Run the complete regression suite and the representative inside/outside runoff and shortcut scenarios, then perform manual checks 1–36. Current legal-line automation includes all gates at both near-kerb and 85%-extent lines and three continuous laps with sand gate crossings and a final grass finish. Manual driving across every possible line remains pending.

## Collision and review

Generated trees reuse one radius-0.18 m, height-1.4 m cylinder inscribed in their visible tapered trunks. Foliage stays non-solid. The optional ramp center is 10.5 m outside the left straight so it clears the widened asphalt. Hills sit beyond the corrected board; outer grass patches match its stepped corners.

Run `godot --path . --script tests/capture_corrective_preview.gd` for `artifacts/corrective_layout.png`. Compare it directly with the private overhead, then inspect normal chase views. This render and automated tests support review; they do not record developer acceptance. References remain ignored and unchanged.
