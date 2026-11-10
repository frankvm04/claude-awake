# Changelog

All notable changes to claude-awake. Versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- New look. At startup, a banner and a checklist of what's active; while
  running, a dashboard pinned at the bottom of the window and updated every
  second (awake time, lid and screen, battery gauge, a 2-minute heat graph with
  the heat guard's countdown, Claude, displays, limits). With `-v`, events
  scroll above it as a timeline with a symbol per kind.
- Narrower than 64 columns, the dashboard becomes one status line that always
  fits; resizing the window redraws it. Piped output gets plain lines with no
  colors or redraws. `NO_COLOR` turns colors off.

### Added

- `--log FILE`: append every event to FILE as plain, dated text while the
  dashboard stays on screen (with or without `-v`).

### Fixed

- While running, claude-awake no longer waits on a sudo password prompt (for
  example to switch Low Power Mode with the lid closed after the sudo session
  expired). Such a wait could block the heat guard; the change is now just
  logged as failed. Prompts are still allowed at startup and exit.

## [1.3.0] - 2026-11-10

### Added

- `claude-awake diagnose`: prints what a bug report needs (versions, `status`,
  sleep and Low Power Mode settings, lid sensor, thermal pressure, battery
  temperature keys, displays, `setup-sudo` state). Read-only, no password, and
  safe to paste: no username, computer name, or serial numbers. Runs on any Mac.
- Issue templates: a bug report form that asks for the `diagnose` output, and a
  feature request form.

## [1.2.0] - 2026-11-10

### Added

- Low Power Mode: with the lid closed, on battery, at 35% or below (`-L N`,
  `0` = off), claude-awake turns on Low Power Mode. Opening the lid or plugging
  in puts the setting back the way it was; it's also restored on exit and by
  `claude-awake stop` after a crash. Only the battery setting is changed.
  Supports both `lowpowermode` and `powermode` (Macs with High Power Mode).
- `status` shows the Low Power Mode battery setting; the status line shows `LPM`
  while it's on; `-v` logs each change.
- `setup-sudo` also allows the Low Power Mode commands. Run it again if you set
  it up before.

### Changed

- MacBook only: on a Mac without a lid, `claude-awake` (start and `status`) and
  the installer stop with a clear message. `stop`, `remove-sudo`, and
  `install.sh --uninstall` still work, so cleanup is never blocked.
- The battery level is read every 10 seconds (was 30), so plugging in is
  noticed sooner; the status line's power text refreshes with it.
- `install.sh --uninstall` also restores Low Power Mode left changed by a crash.

## [1.1.0] - 2026-11-10

### Added

- Heat guard: if the battery temperature or macOS's thermal pressure stays over
  its limit (default 45 °C or `heavy`, for 2 minutes), claude-awake re-enables
  sleep and puts the Mac to sleep. It sleeps immediately at `trapping` or above.
  Options `-T/--max-temp`, `-P/--max-pressure`, and `-H/--heat-minutes`. Works
  without a password on Apple Silicon and Intel Macs, with or without a battery.
- `status`, the status line, and `-v` show battery temperature and thermal
  pressure. On a MacBook that doesn't report battery temperature (such as
  macOS 27 on Apple Silicon), `status` and the startup message say the heat
  guard is using thermal pressure only.

### Fixed

- The exit message no longer says the lid will sleep normally when sleep was
  already disabled before claude-awake started.

## [1.0.0] - 2026-11-09

First release.

### Keeping the Mac awake

- Keeps a MacBook awake with the lid closed (`pmset -a disablesleep 1`) while it
  runs, plus `caffeinate -ims` for idle, disk and system sleep.
- Restores the original sleep setting when it stops: Ctrl-C, `kill`, a closed
  Terminal window, or a limit being reached.
- `claude-awake stop` recovers after a force-kill or crash. `claude-awake status`
  warns when a run ended without restoring sleep.
- Stop conditions: a battery guard (default 20%, `-b`), a time limit (`-t`), and
  stop-when-Claude-quits (`-c`). `-l` opens the Claude desktop app first.

### Screens

- Turns the built-in screen off when the lid closes, and every 30 seconds while
  it stays closed. With `disablesleep` on, macOS can otherwise leave the screen lit
  under the lid.
- Leaves screens alone while an external display is connected, including when
  started with the lid already closed on a monitor (clamshell mode). If the
  monitor is unplugged while the lid is closed, the built-in screen is turned off.

### Visibility

- A live status line: elapsed time, power, lid and screen state, Claude.
- `-v` / `--verbose`: a timestamped log of lid, external display, power, battery,
  and Claude events, sleep-setting resets, and gaps that mean the Mac slept anyway.
- `claude-awake status` shows the sleep setting, whether a run is active, Claude,
  the lid, external displays, and power.

### Install

- One-line installer (`install.sh`): clones to `~/src/claude-awake` and links into
  `~/bin`, or downloads the script on a Mac without the Command Line Tools. Adds
  `~/bin` to PATH once. Running it again updates.
- `install.sh --uninstall` restores sleep if needed, removes the `setup-sudo`
  rule, the command, the clone (unless it has local changes), the state folder,
  and the PATH line.
- Optional `claude-awake setup-sudo` adds a sudoers rule for
  `pmset -a disablesleep 0|1` only, so no password prompt is needed.

[Unreleased]: https://github.com/frankvm04/claude-awake/compare/v1.3.0...main
[1.3.0]: https://github.com/frankvm04/claude-awake/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/frankvm04/claude-awake/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/frankvm04/claude-awake/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/frankvm04/claude-awake/releases/tag/v1.0.0
