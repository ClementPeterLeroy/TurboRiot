# Versioning

The established MAJOR.MINOR.PATCH convention, development suffix and numeric four-part Windows format are preserved.

| Location | Current value | Meaning |
| --- | --- | --- |
| `project.godot`, application config/version | `0.4.0-dev` | Current unaccepted development milestone |
| Race HUD footer | `v0.4.0-dev — Racing Competitors` | Same development identity |
| Windows file/product resource version | `0.4.0.0` | Numeric export metadata, not release acceptance |
| Windows file description | `Racing Competitors (Development)` | Explicit development status |
| ROADMAP.md | v0.4.0 current development | Preserved milestone sequence/scope |
| CHANGELOG.md | v0.4.0-dev under Unreleased | Actual changes pending developer review |

The developer identifies **v0.3.2** as the latest released baseline. Read-only repository inspection found HEAD `96934a4` named v0.3.2, earlier v0.3.1/v0.3.0-dev commits, and no local tags. Baseline metadata still used `0.3.0-dev` / `0.3.0.0`; those actual historical identifiers and prior changelog wording remain documented. This patch adds a v0.3.2 baseline note without fabricating a tag, release date or retroactive numeric version. See [the audit](docs/v0.4.0-audit.md).

The accepted v0.2.0 ten-check history remains preserved. A later release label does not reconstruct granular manual check results. All prior regression checks, including v0.3.2 high-speed presentation, remain required for v0.4.0, followed by the new competitor criteria. No current-version manual acceptance is inferred from automated completion.

Versions use MAJOR.MINOR.PATCH. The agreed 0.x milestones are preserved through v1.0.0. Keep unfinished milestone work under **Unreleased** with `-dev` in the project/HUD. Only developer approval can accept a release and remove that suffix. Future corrections can use the patch component without silently advancing milestone scope.

Keep metadata, HUD, export preset, README and changelog consistent when changing versions. Historical validation reports and baseline descriptions retain the version they actually tested. A successful automated run or completed implementation does not mean the developer has accepted or published a release.

Codex must not stage, commit, push, tag, create releases or perform GitHub actions for this patch. The developer handles Git through VS Code.
