# Versioning

The established MAJOR.MINOR.PATCH convention, development suffix and numeric four-part Windows format are preserved.

## v0.6.1 — Circuit Selection & First Testing Grounds

This version adds circuit selection and **two new beta test circuits: Figure-8 Circuit and GCN Yoshi Circuit (DS)**, alongside the existing reference circuit. Both new circuits are playable greybox layouts **without finished environments or scenery**; their beta status describes the circuits' testing maturity, not a published beta release.

The same v0.6.1 patch includes the **racing FPS-drop correction**, optimizing flat-road collision and minimap rendering, plus the Figure-8 crossing collision correction. See [performance results](docs/circuit-performance.md) and [Testing Grounds](docs/testing-grounds.md). Runtime identity remains **0.6.1-dev**, Windows metadata **0.6.1.0**, Unreleased pending developer acceptance.

## Version conventions and history

| Location | Current value | Meaning |
| --- | --- | --- |
| `project.godot`, application config/version | `0.6.1-dev` | Current unaccepted development milestone |
| Race HUD footer | `v0.6.1-dev — Testing Grounds` | Same development identity |
| Windows file/product resource version | `0.6.1.0` | Numeric export metadata, not release acceptance |
| Windows file description | `Testing Grounds (Development)` | Explicit development status |
| ROADMAP.md | v0.6.1 current development | Preserved milestone sequence/scope |
| CHANGELOG.md | v0.6.1-dev under Unreleased | Actual changes pending developer review |

The developer identifies **v0.3.2** as the latest released baseline. Read-only repository inspection found HEAD `96934a4` named v0.3.2, earlier v0.3.1/v0.3.0-dev commits, and no local tags. Baseline metadata still used `0.3.0-dev` / `0.3.0.0`; those actual historical identifiers and prior changelog wording remain documented. This patch adds a v0.3.2 baseline note without fabricating a tag, release date or retroactive numeric version. See [the audit](docs/v0.4.0-audit.md).

The accepted v0.2.0 ten-check history remains preserved. A later release label does not reconstruct granular manual check results. All prior regression checks, including v0.3.2 high-speed presentation, remain required for v0.5.0, followed by item criteria 66-90. No current-version manual acceptance is inferred from automated completion.

Versions use MAJOR.MINOR.PATCH. The agreed 0.x milestones are preserved through v1.0.0. Keep unfinished milestone work under **Unreleased** with `-dev` in the project/HUD. Only developer approval can accept a release and remove that suffix. Future corrections can use the patch component without silently advancing milestone scope.

Keep metadata, HUD, export preset, README and changelog consistent when changing versions. Historical validation reports and baseline descriptions retain the version they actually tested. A successful automated run or completed implementation does not mean the developer has accepted or published a release.

Codex must not stage, commit, push, tag, create releases or perform GitHub actions for this patch. The developer handles Git through VS Code.

The v0.4.0 implementation and its original Unreleased changelog record are preserved. Local history now includes `0d69490` (v0.4.0); a commit title alone does not establish manual acceptance or publication. Only 5A-5D are active; 5E remains reserved. See [v0.5 audit](docs/v0.5.0-audit.md).

The v0.6.0 patch keeps these conventions unchanged and updates only the current development identity to `0.6.0-dev` / `0.6.0.0`. v0.6.1 is roadmap work only. Local history now includes `a31ff9f` (v0.5.0) and `e22a2f2` (v0.5.1); their runtime metadata remained 0.5.0-dev. These commit labels do not establish acceptance or retroactively rename the recorded development entries. Current regression criteria are 1-119; v0.4/v0.5 and v0.6 acceptance remain pending.

Current patch: **v0.6.1-dev - Circuit Selection & First Testing Grounds**, Windows `0.6.1.0`, Unreleased pending developer acceptance. HEAD at audit was `1d97794` (v0.6.0); commit names do not establish a release. The preceding v0.6.0 paragraph records its historical patch scope. Current cumulative checks are 1-166. See [Testing Grounds](docs/testing-grounds.md).
