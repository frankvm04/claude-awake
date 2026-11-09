# <img src="assets/icon.svg" alt="" height="64" align="absmiddle"> claude-awake

A terminal tool for macOS that keeps your MacBook awake with the lid closed, so
the Claude desktop app or Claude Code keeps working. When you stop it, the normal
sleep setting comes back.

## Why not just `caffeinate`?

`caffeinate` blocks *idle* sleep only. Closing the lid still puts the Mac to sleep,
unless an external display and power are connected (clamshell mode). The only
built-in setting that stops lid-close sleep in every case is
`sudo pmset -a disablesleep 1`. claude-awake turns that on, turns the screen off
under the closed lid, watches battery and time limits, and turns the setting back
off when it exits.

## Requirements

- macOS on Apple Silicon or Intel. It runs on the stock `/bin/bash` (3.2), with no
  other dependencies.
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
git -C ~/src/claude-awake fetch --tags && git -C ~/src/claude-awake checkout v1.0.0
```

Or download that version's script directly:

```bash
mkdir -p ~/bin && curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/v1.0.0/claude-awake -o ~/bin/claude-awake && chmod +x ~/bin/claude-awake
```

### Skip the password prompt (optional)

This adds a sudoers rule that allows only `pmset -a disablesleep 0|1` without a
password:

```bash
claude-awake setup-sudo
```

Undo it with `claude-awake remove-sudo`.

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/main/install.sh | bash -s -- --uninstall
```

Or, from the clone: `~/src/claude-awake/install.sh --uninstall`. This:

- restores normal sleep, if a run is active or a crashed run left sleep turned off
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
claude-awake status          # what's the current state?
claude-awake stop            # restore normal sleep (e.g. after a force-kill)
```

| Option | Meaning |
|---|---|
| `-c`, `--until-claude-exits` | Stop once Claude (desktop app or CLI) is no longer running |
| `-l`, `--launch` | Open the Claude desktop app first |
| `-b N`, `--battery-min N` | On battery, stop at N% or below (default 20, `0` = off) |
| `-t H`, `--hours H` | Stop after H hours (decimals OK) |
| `-i S`, `--interval S` | Seconds between checks (default 30) |
| `-v`, `--verbose` | Print a timestamped line for each event (see below) |

Start it in a Terminal window, then close the lid. It keeps running and shows a
status line: elapsed time, power, the lid and screen state, and whether Claude is
running. You can also start it with the lid already closed on an external monitor
(clamshell mode); the monitor stays on.

`claude-awake status` shows the current state at any time:

```
claude-awake status
  Lid-close sleep : disabled (Mac stays awake with lid closed)
  claude-awake    : running (pid 1284)
  Claude          : running
  Lid             : closed
  External display: 1 connected (screens are left on)
  Power           : AC, battery 92%
```

## Event log (`-v`)

With `-v`, events print above the live status line:

```
13:07:16  Lid-close sleep disabled (was SleepDisabled=0)
13:07:21  Claude is running
13:07:23  Lid closed — screen turned off
13:07:27  Power: running on battery (80%)
13:07:29  Battery 74%
13:07:56  No activity for 0h00m25s — the Mac appears to have slept
13:08:01  Lid opened (was closed 0h00m38s)
13:08:03  Claude quit
```

What gets logged:

- The lid opening and closing, including how long it was closed.
- External displays connecting and disconnecting.
- The power source changing, and each 5% drop in battery while on battery.
- Claude starting and quitting.
- Anything that resets the sleep setting, and an expired sudo session.
- Gaps where the script stopped running. A gap usually means the Mac slept anyway,
  which helps you check that keeping it awake really worked.

To keep a copy of the log as well (the file also gets the status-line refreshes):

```bash
claude-awake -v | tee ~/claude-awake.log
```

## Restoring sleep

The setting is restored on Ctrl-C, on `kill`, when a limit is reached, and when
the Terminal window is closed. If the process is force-killed (`kill -9`, crash,
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

## Changes

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).
