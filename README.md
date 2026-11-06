# claude-awake

A terminal tool for macOS that keeps your MacBook awake with the lid closed, so
the Claude desktop app or Claude Code keeps working. When you stop it, the normal
sleep setting comes back.

## Why not just `caffeinate`?

`caffeinate` blocks *idle* sleep only. Closing the lid still puts the Mac to sleep.
The only built-in setting that stops lid-close sleep (without an external monitor)
is `sudo pmset -a disablesleep 1`. claude-awake turns that on, watches battery and
time limits, and turns it back off when it exits.

## Install

```bash
mkdir -p ~/bin && cp claude-awake ~/bin/ && chmod +x ~/bin/claude-awake
```

If `~/bin` is not on your PATH yet (zsh is the default shell on macOS):

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Optional: skip the password prompt. This adds a sudoers rule that allows only
`pmset -a disablesleep 0|1`:

```bash
claude-awake setup-sudo
```

## Use

```bash
claude-awake                 # awake until Ctrl-C
claude-awake -l -c           # open Claude, stay awake until Claude quits
claude-awake -t 3 -b 30      # at most 3 hours; stop if battery drops to 30%
claude-awake -v -c            # log events; stop when Claude quits
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
status line (elapsed time, power, whether Claude is running).

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
- Works on Apple Silicon and Intel Macs, using the stock macOS `/bin/bash` (3.2).
- To uninstall: `claude-awake remove-sudo` (if you ran setup-sudo), then delete
  `~/bin/claude-awake` and `~/.claude-awake/`.

## License

MIT. See [LICENSE](LICENSE).
