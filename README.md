# <img src="assets/icon.svg" alt="" height="64" align="absmiddle"> claude-awake

A terminal tool for macOS that keeps your MacBook awake with the lid closed, so
the Claude desktop app or Claude Code keeps working. When you stop it, the normal
sleep setting comes back.

## Why not just `caffeinate`?

`caffeinate` blocks *idle* sleep only. Closing the lid still puts the Mac to sleep,
unless an external display and power are connected (clamshell mode). The only
built-in setting that stops lid-close sleep in every case is
`sudo pmset -a disablesleep 1`. claude-awake turns that on, turns the screen off
under the closed lid, watches battery, heat and time limits, and turns the setting
back off when it exits.

## Requirements

- A MacBook (Air or Pro), Apple Silicon or Intel. claude-awake is for MacBooks
  only: on a Mac without a lid, it and the installer stop with a message.
- macOS. It runs on the stock `/bin/bash` (3.2), with no other dependencies.
- An administrator account: changing the sleep setting uses `sudo`. To avoid the
  password prompt, see [Skip the password prompt](#skip-the-password-prompt-optional).

## Install

One line in Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/main/install.sh | bash
```

This clones the repo to `~/src/claude-awake`, links the command into `~/bin`, and
adds `~/bin` to your PATH if needed. Without git (a new Mac with no Command Line
Tools), it downloads the script instead. Then open a new Terminal window and run
`claude-awake status`. You can [read the installer](install.sh) before running it.

To use other folders, set them in front of `bash`:

```bash
curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/main/install.sh | CLAUDE_AWAKE_DIR=~/code/claude-awake CLAUDE_AWAKE_BIN=~/.local/bin bash
```

### Manual install

Clone the repo:

```bash
git clone https://github.com/frankvm04/claude-awake.git ~/src/claude-awake
```

Link the script into a folder on your PATH:

```bash
mkdir -p ~/bin && ln -sf ~/src/claude-awake/claude-awake ~/bin/claude-awake
```

If `~/bin` is not on your PATH yet (zsh is the default shell on macOS):

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Check that it works:

```bash
claude-awake status
```

`git` is not installed on a new Mac. The first `git` command offers to install the
Command Line Tools; accept, then run the clone again.

### Update

Run the one-line installer again, or pull. Because `~/bin/claude-awake` links to
the clone, pulling updates the command:

```bash
git -C ~/src/claude-awake pull
```

Stop a running `claude-awake` (Ctrl-C) before updating, then start it again.

### Without git

Download [`claude-awake`](https://raw.githubusercontent.com/frankvm04/claude-awake/main/claude-awake)
and install it directly:

```bash
mkdir -p ~/bin && curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/main/claude-awake -o ~/bin/claude-awake && chmod +x ~/bin/claude-awake
```

### Install a specific version

Each release is tagged (see [Releases](https://github.com/frankvm04/claude-awake/releases)
and the [changelog](CHANGELOG.md)). To use a tagged version from a clone:

```bash
git -C ~/src/claude-awake fetch --tags && git -C ~/src/claude-awake checkout v1.3.0
```

Or download that version's script directly:

```bash
mkdir -p ~/bin && curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/v1.3.0/claude-awake -o ~/bin/claude-awake && chmod +x ~/bin/claude-awake
```

### Skip the password prompt (optional)

This adds a sudoers rule that allows only these commands without a password:
`pmset -a disablesleep 0|1` (the sleep setting) and `pmset -b lowpowermode 0|1`
/ `pmset -b powermode 0|1|2` (Low Power Mode on battery):

```bash
claude-awake setup-sudo
```

Undo it with `claude-awake remove-sudo`. If you ran `setup-sudo` before version
1.2.0, run it again to add the Low Power Mode commands.

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/main/install.sh | bash -s -- --uninstall
```

Or, from the clone: `~/src/claude-awake/install.sh --uninstall`. This:

- restores normal sleep and Low Power Mode, if a run is active or a crashed run
  left them changed
- removes the `setup-sudo` rule, if there is one
- removes `~/bin/claude-awake`, the clone, `~/.claude-awake/`, and the PATH line
  the installer added

It may ask for your password (to restore sleep or remove the sudo rule). It leaves
anything it doesn't recognize alone, and keeps the clone if it has uncommitted
changes. If you installed into other folders, set the same `CLAUDE_AWAKE_DIR` /
`CLAUDE_AWAKE_BIN` when uninstalling.

## Use

```bash
claude-awake                 # awake until Ctrl-C
claude-awake -l -c           # open Claude, stay awake until Claude quits
claude-awake -t 3 -b 30      # at most 3 hours; stop if battery drops to 30%
claude-awake -v -c           # log events; stop when Claude quits
claude-awake -T 40           # sleep the Mac if the battery stays at 40 °C or more
claude-awake status          # what's the current state?
claude-awake stop            # restore normal sleep (e.g. after a force-kill)
claude-awake diagnose        # details to paste into a bug report
```

| Option | Meaning |
|---|---|
| `-c`, `--until-claude-exits` | Stop once Claude (desktop app or CLI) is no longer running |
| `-l`, `--launch` | Open the Claude desktop app first |
| `-b N`, `--battery-min N` | On battery, stop at N% or below (default 20, `0` = off) |
| `-t H`, `--hours H` | Stop after H hours (decimals OK) |
| `-i S`, `--interval S` | Seconds between checks (default 30) |
| `-v`, `--verbose` | Print a timestamped line for each event (see below) |
| `-T C`, `--max-temp C` | Heat guard: battery temperature limit in °C (default 45, `0` = off) |
| `-P L`, `--max-pressure L` | Heat guard: thermal pressure limit, `moderate`, `heavy`, `trapping`, or `off` (default `heavy`) |
| `-H M`, `--heat-minutes M` | Heat guard: how long it must stay too hot before sleeping (default 2) |
| `-L N`, `--low-power-at N` | With the lid closed on battery at N% or below, turn on Low Power Mode (default 35, `0` = off) |
| `--log FILE` | Also append every event to FILE as plain text (even without `-v`) |

Start it in a Terminal window, then close the lid. It keeps running. You can also
start it with the lid already closed on an external monitor (clamshell mode); the
monitor stays on.

### What you see

At startup, a banner and a checklist of what's active:

```
  ✓ lid-close sleep disabled              ✓ Low Power Mode at 35%
  ✓ screen off under the lid              ✓ stop on battery at 20%
  ✓ heat guard: pressure ≥ heavy, 2 min   ○ time limit (none)
```

Then a dashboard, pinned at the bottom of the window and updated every second:

```
╭─ claude-awake ─────────────────────────────────── 1.3.0 ─╮
│ ⠹ AWAKE  0h 42m 10s              lid closed · screen off │
│                                                          │
│ Battery   ▰▰▰▰▱▱▱▱▱▱▱▱  34% on battery  ▾ LPM            │
│ Heat      ▁▁▁▁▃▃▃▁▁▁▁▁  nominal                          │
│ Claude    ● running                                      │
│ Display   ○ built-in only                                │
│ stop 20% · heat: heavy 2m · LPM 35%                      │
╰──────────────────────────────────────────────────────────╯
```

- **Heat** shows the last 2 minutes (one bar per 10 seconds): battery temperature
  if your Mac reports it, otherwise thermal pressure. When the heat guard is
  counting down, it says so and shows how long until it sleeps the Mac.
- In a window narrower than 64 columns, the dashboard becomes one status line.
  Resizing the window redraws it to fit.
- When the output isn't a terminal (for example piped to another command), it
  prints plain lines with no colors or redraws.
- Set `NO_COLOR=1` to turn colors off.

`claude-awake status` shows the current state at any time:

```
claude-awake status
  Lid-close sleep : disabled (Mac stays awake with lid closed)
  claude-awake    : running (pid 1284)
  Claude          : running
  Lid             : closed
  External display: 1 connected (screens are left on)
  Temperature     : battery 34.2 °C, pressure nominal
  Power           : AC, battery 92%
  Low Power Mode  : off (battery setting)
```

## Heat guard

If the Mac stays too hot, claude-awake turns normal sleep back on and puts the Mac
to sleep (`pmset sleepnow`). Sleeping stops the heat, and your apps resume where
they left off when you wake the Mac. claude-awake itself stops; start it again
after waking.

It watches two readings. Neither needs a password, and both work on Apple
Silicon and Intel Macs:

- **Battery temperature**, from `ioreg -r -n AppleSmartBattery`. The default
  limit is 45 °C. Recent macOS versions (for example macOS 27 on Apple Silicon)
  no longer publish it. Then the heat guard uses thermal pressure only, and
  `status` and the startup message say so.
- **Thermal pressure**, the level macOS itself uses to decide when to slow the
  processor: nominal, moderate, heavy, trapping, sleeping. It is read with
  `notifyutil -g com.apple.system.thermalpressurelevel`. The default limit is
  `heavy`.

A reading must stay over its limit for 2 minutes (`-H`), so a short spike
doesn't stop your work. At `trapping` or above it sleeps immediately. If neither
reading is available, claude-awake says so at startup and runs without the heat
guard.

macOS still protects the hardware on its own: it slows the processor when it's
hot and shuts down at critical temperatures. The heat guard acts earlier, before
sustained heat under a closed lid wears the battery. Run with `-v` once to see
your Mac's usual readings, then adjust `-T` or `-P` if needed.

## Low Power Mode

With the lid closed, on battery, at 35% or below (`-L`), claude-awake turns on
macOS Low Power Mode. It makes the battery last longer and the Mac run cooler.
As soon as you open the lid or plug in, it puts the setting back the way it was;
if you close the lid again, or unplug again, while still at or below the level,
it turns on again. It's also put back when claude-awake exits, and
`claude-awake stop` puts it back after a crash.

- It changes only the battery setting (`pmset -b`), so your plugged-in settings
  are never touched. If Low Power Mode was already on, it's left alone.
- Most Macs use the `lowpowermode` setting; MacBook Pros that also offer High
  Power Mode use `powermode`. claude-awake detects which, and puts High Power
  Mode or automatic back as it was. If a Mac has neither, it says so at startup.
- Changing it needs `sudo`. claude-awake keeps its sudo session fresh while it
  runs, and [`setup-sudo`](#skip-the-password-prompt-optional) allows it without
  a password.
- The dashboard shows `LPM` while it's on, `-v` logs each change, and `status`
  shows the current battery setting. A notification appears the first time it
  turns on in a run.
- Set the level above the battery stop (`-b`, default 20%): for example Low
  Power Mode at 35%, stop at 20%.

## Event log (`-v`)

With `-v`, events scroll above the dashboard as a timeline:

```
  15:10:12 ┬ ◆ claude-awake started
  15:10:12 ├ ◆ Claude is running
  15:10:15 ├ ▣ Lid closed — screen turned off
  15:10:22 ├ ↯ On battery — 36%
  15:10:28 ├ ▾ Low Power Mode on — battery 34%, lid closed
  15:10:32 ├ ≈ Thermal pressure moderate
  15:10:42 ├ ↯ Plugged in — 34%
  15:10:43 ├ ▾ Low Power Mode back to off — plugged in
  15:10:45 ├ □ Lid opened — was closed 0h00m30s
```

What gets logged:

- The lid opening and closing, including how long it was closed.
- External displays connecting and disconnecting.
- Low Power Mode turning on, and going back when the lid opens or you plug in.
- Thermal pressure changes, and the heat guard warning, cooling down, or sleeping
  the Mac.
- The power source changing, and each 5% drop in battery while on battery.
- Claude starting and quitting.
- Anything that resets the sleep setting, and an expired sudo session.
- Gaps where the script stopped running. A gap usually means the Mac slept anyway,
  which helps you check that keeping it awake really worked.

To keep a copy of the events in a file, with dates, while the dashboard stays on
screen (this works with or without `-v`):

```bash
claude-awake -v --log ~/claude-awake.log
```

## Restoring sleep

The setting is restored on Ctrl-C, on `kill`, when a limit is reached, after the
heat guard's sleep, and when the Terminal window is closed. If the process is force-killed (`kill -9`, crash,
power loss), sleep stays disabled. `claude-awake status` warns you about this, and
`claude-awake stop` fixes it. You can also fix it by hand:

```bash
sudo pmset -a disablesleep 0
```

## Notes

- **Heat:** with the lid closed the Mac cools less well. Leave it on a hard
  surface, never in a bag or sleeve while it runs.
- **Power:** being plugged in is best for long jobs. The battery guard is on by
  default.
- **Screen with the lid closed:** with `disablesleep` on, macOS can leave the
  built-in screen lit under a closed lid. claude-awake checks the lid sensor every
  2 seconds. When the lid closes it turns the screen off (`pmset displaysleepnow`),
  and repeats that every 30 seconds while the lid stays closed. Wi-Fi stays
  connected. If the screen still glows, run `pmset displaysleepnow` by hand.
- **External monitors:** `pmset displaysleepnow` turns off *every* display, so
  claude-awake skips it while an external display is connected. With the lid
  closed (clamshell mode), macOS turns the built-in screen off by itself and the
  external monitor stays on. claude-awake checks for external displays every 10
  seconds and whenever the lid closes. If you unplug the monitor while the lid is
  closed, it turns the built-in screen off within about 10 seconds. This also
  holds when you start claude-awake with the lid already closed on a monitor. The
  external monitor still dims after your usual display-sleep time, as normal.
- To uninstall, see [Uninstall](#uninstall).

## Reporting a problem

[Open an issue](https://github.com/frankvm04/claude-awake/issues/new/choose) and
choose **Bug report**. It asks for the output of:

```bash
claude-awake diagnose
```

That prints your claude-awake and macOS versions, `status`, and the readings
claude-awake relies on: the sleep and Low Power Mode settings, the lid sensor,
thermal pressure, battery temperature, displays, and whether `setup-sudo` is in
place. It only reads information, needs no password, and leaves out your
username, computer name, and serial numbers. Look it over before posting.

## Changes

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).
