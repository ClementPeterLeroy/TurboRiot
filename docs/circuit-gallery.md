# Circuit selection gallery — v0.6.1-dev

2026-11-26. Implemented within the existing Unreleased version; developer acceptance remains pending. This changes circuit metadata and menus only. Track scene paths, meshes, collision, physics, scenery and race loading remain unchanged.

## Player experience

Three large cards are visible together: **Desert Run**, **Circuit 8** and **Serpent Coast**. Each shows its actual circuit outline and name. Gold indicates selection; a cyan outer ring indicates keyboard/controller focus. One short description appears below the selected circuit. The official existing logo and navy/cyan/magenta/gold palette carry the game's identity. Category/debug/reference/implementation information is absent from the visible gallery.

Mouse click or Enter/controller A selects a card; it does not start a race. Left/right and D-pad browse the row. Down moves to **Start Race**; Back and Start have explicit navigation links. Confirm Start to load the selected race through the existing application. Escape/controller B returns to configuration. Tab order also traverses cards and actions. Analog navigation uses a 0.55 deadzone, a 0.4 s initial repeat delay and 0.16 s repeats, stopping on release. Existing menu cues remain.

Quick Race and Time Trial retain separate selections/configuration. Returning from a race and reopening circuit selection restores the chosen card and focus. The three current cards require no scrolling at tested sizes. Future additional playable cards continue horizontally; keyboard/controller focus scrolls them into view rather than growing a vertical list.

## Names and availability

| Internal ID | Display name | Current state |
| --- | --- | --- |
| `reference` | Desert Run | Existing playable circuit; original default scene |
| `figure_8` | Circuit 8 | Existing playable circuit; same scene path |
| `yoshi_ds` | Serpent Coast | Existing playable circuit; provisional name |
| `baby_park` | Legend Park | Reserved catalog ID; existing standalone authoring scene retained |
| `wario_stadium_ds` | Riot Arena | Reserved catalog ID; provisional name, race integration deferred |
| `delfino_square_ds` | Sunhaven Square | Reserved catalog ID; provisional name, race integration deferred |

Only the first three already had registered race IDs; those IDs are unchanged. The other three are metadata entries, not newly enabled races. `Baby_park.tscn` is a standalone model/kart test scene without the registry's authoritative race centerline and race framework. No arbitrary preview or launch route was invented for it. Deferred entries have `available = false`, `internal_only = true` and no preview curve; they stay out of the normal gallery. Their names can be inspected via `TrackRegistry.catalog_entries()`. Internal categories remain available in definitions, outside the player UI.

## Architecture and outline accuracy

- `TrackDefinition` separates stable identity, display name/description, availability/internal flags, optional authoring scene path, accent and optional authoritative `preview_source` Curve3D. Existing scene-based preview resolution remains the default.
- `TrackRegistry.IDS` still contains exactly the three race-ready IDs and drives existing validation/loading. `CATALOG_IDS` and `catalog_entries()` also describe deferred entries. To expose another track, first integrate its actual race scene/centerline, then register it as available; do not simply expose an authoring fixture.
- `scenes/ui/circuit_card.tscn` / `CircuitCard` is the reusable focusable button component. It draws card/selection/focus treatment, contains the name and a `CircuitOutline`, and inherits the existing menu theme. It contains no track-specific layout logic or descriptions.
- `CircuitGallery` arranges cards and separate footer actions. `AlphaMenu.show_gallery()` temporarily replaces its narrow scrolling column; leaving the gallery restores the previous menu implementation and focus lifecycle. Selection updates the current draft in place, avoiding recreation and focus jumps on every click.
- `CircuitOutline` samples the actual Curve3D every approximately 2 m, maps world XZ into a normalized centered preview and uses one uniform scale on both axes. The original circuit proportions are retained. Stroke width is constant in logical UI pixels, independent of track extent. A small gold start marker indicates route offset zero.
- Raised route spans are redrawn above the base path with a dark separation stroke, making Circuit 8's grade-separated crossing readable. No road geometry or elevation is modified. The existing HUD minimap is unchanged.
- Preview snapshots are cached by Curve3D resource identity; a source `changed` signal invalidates its entry. Projection is recalculated only on configuration/resize. There is no per-frame route sampling or preview process callback. A Timer runs only while an analog direction is held; it navigates focus, not preview geometry.

Adding more cards uses the same metadata/component and horizontal focus links. Unavailable/internal records are filtered centrally by the gallery. Other gameplay controls, settings and menu pages keep their existing flow.

## Captures and verification

[1920×1080](../artifacts/v061_gallery_1920_1080_1.0.png) · [1280×720](../artifacts/v061_gallery_1280_720_1.0.png) · [960×540](../artifacts/v061_gallery_960_540_1.0.png) · [1024×768, 125% UI](../artifacts/v061_gallery_1024_768_1.25.png)

All four native captures were inspected: distinct correct outlines, visible selection/focus, readable names, no vertical scroll, clipped text or overlapping footer. They use the application's existing canvas scaling; 1080p scales the established logical viewport rather than changing global display/camera settings.

Reproduce with `godot --path . --script tests/capture_circuit_gallery.gd`. Full automated validation is in [validation](validation.md); manual checks **208–213** extend the existing cumulative checklist.

New gallery assertions cover all six names, unavailable filtering, stable launch paths, sampled-curve correspondence, uniform projection scale, cache invalidation, crossing rendering, absence of internal visible labels, selection versus launch, mouse/keyboard/controller behavior, analog deadzone/repeat/release, persistence, responsive bounds/scroll behavior, horizontal growth and safe teardown. Existing circuit tests still launch all three playable circuits in both race modes; their arrow/D-pad navigation expectations are adapted to the new horizontal layout. No gameplay assertions were removed.

## Files changed

- Metadata: `scripts/track/track_definition.gd`, `scripts/track/track_registry.gd`.
- Integration: `scripts/app/application.gd`, `scripts/ui/alpha_menu.gd`.
- New components: `scripts/ui/circuit_gallery.gd`, `scripts/ui/circuit_card.gd`, `scripts/ui/circuit_outline.gd`, `scenes/ui/circuit_card.tscn` and script UID companions.
- Tests/captures: `tests/gallery_tests.gd`, `tests/capture_circuit_gallery.gd`, `tests/circuit_tests.gd`, `tests/run_tests.gd`, four `artifacts/v061_gallery_*.png` captures.
- Documentation: this guide, README, changelog, validation, versioning checklist count and cumulative acceptance checklist.

The previously uncommitted texture-import settings remain local; Godot may refresh their derived import paths/metadata during validation. No original image, model, track scene, architectural material source, physics or camera file was edited for this task. No Git staging, commits, pushes, tags or GitHub operations. Physical controller hardware, longer localized names, and exported-build/display review remain manual acceptance items. The deferred circuits need real race integration before appearing in this menu; they have no fabricated playable cards.
