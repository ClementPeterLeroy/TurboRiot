# Versioning

The existing project used three-part milestone versions (`0.1.0`) and four-part numeric Windows resource versions (`0.1.0.0`). There was no VERSIONING.md before this patch. Those formats are retained, with an explicit development suffix to distinguish unaccepted work.

| Location | Current value | Meaning |
| --- | --- | --- |
| `project.godot`, `application/config/version` | `0.3.0-dev` | Current unaccepted development milestone |
| Race HUD footer | `v0.3.0-dev` | Same development build identity |
| Windows file/product resource version | `0.3.0.0` | Numeric format required by the export metadata |
| Windows file description | `Arcade Handling (Development)` | Preserves development status where numeric fields cannot |
| ROADMAP.md | v0.3.0 current development | Scope and priorities |
| CHANGELOG.md | Unreleased | Actual changes pending review |

The developer confirmed acceptance of all ten v0.2.0 manual checks on 2026-11-08. Preserve that baseline and historical build identifiers. This does not accept v0.3.0 or imply publication/tagging. The full handling patch retains `0.3.0-dev`, building on the prerequisite runoff correction. Its surfaces, drifting, mini-turbos, pads and jumps require the new manual criteria in [docs/testing/ACCEPTANCE_CHECKLIST.md](docs/testing/ACCEPTANCE_CHECKLIST.md); no current-version manual retest is inferred from past approval.

Versions use MAJOR.MINOR.PATCH. The agreed 0.x milestones are preserved through v1.0.0. Keep unfinished milestone work under **Unreleased** with `-dev` in the project/HUD. Only developer approval can accept a release and remove that suffix. Future corrections can use the patch component without silently advancing milestone scope.

Keep metadata, HUD, export preset, README and changelog consistent when changing versions. Historical validation reports and baseline descriptions retain the version they actually tested. A successful automated run or completed implementation does not mean the developer has accepted or published a release.

Codex must not stage, commit, push, tag, create releases or perform GitHub actions for this patch. The developer handles Git through VS Code.
