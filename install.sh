#!/bin/bash
#
# Install, update, or uninstall claude-awake.
#
#   Install / update:
#     curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/main/install.sh | bash
#   Uninstall:
#     curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/main/install.sh | bash -s -- --uninstall
#
# Install:
#   1. Clones the repo to ~/src/claude-awake, or pulls if it is already there.
#      Without git (no Command Line Tools), downloads the script instead.
#   2. Links (or copies) the command to ~/bin/claude-awake.
#   3. Adds ~/bin to PATH in your shell profile if it is not there yet.
#
# Uninstall reverses all of that, plus anything claude-awake itself set up:
#   restores normal sleep if a run is active or crashed, removes the optional
#   sudoers rule, the command, the clone (only if it has no local changes),
#   the ~/.claude-awake state folder, and the PATH line this installer added.
#
# Settings (environment variables, same for install and uninstall):
#   CLAUDE_AWAKE_DIR  where to clone      (default: ~/src/claude-awake)
#   CLAUDE_AWAKE_BIN  where to put it     (default: ~/bin)
#
# Written for the stock macOS bash 3.2. Only `main "$@"` at the very end runs
# anything, so a partly downloaded script does nothing.

REPO_URL="https://github.com/frankvm04/claude-awake.git"
RAW_URL="https://raw.githubusercontent.com/frankvm04/claude-awake/main/claude-awake"
SUDOERS_FILE="/etc/sudoers.d/claude-awake"
MARKER="# added by claude-awake installer"

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: install.sh [--uninstall | --help]

  (no option)   Install claude-awake, or update an existing install
  --uninstall   Remove claude-awake and everything it set up
  --help        Show this help

Folders: CLAUDE_AWAKE_DIR (default ~/src/claude-awake), CLAUDE_AWAKE_BIN (default ~/bin)
EOF
}

# Run a command with the keyboard as input. Under `curl | bash` stdin is the
# script itself, so anything that may ask for a password needs /dev/tty.
with_tty() {
  if [ -r /dev/tty ] && { : </dev/tty; } 2>/dev/null; then "$@" </dev/tty; else "$@"; fi
}

do_install() {
  mkdir -p "$BIN"

  # On a new Mac /usr/bin/git is a stub that opens an installer dialog,
  # so check for the Command Line Tools rather than just for `git`.
  if command -v git >/dev/null 2>&1 && xcode-select -p >/dev/null 2>&1; then
    if [ -d "$DIR/.git" ]; then
      say "Updating $DIR"
      git -C "$DIR" pull --ff-only --quiet
    elif [ -e "$DIR" ]; then
      die "$DIR exists but is not a git clone. Move it, or set CLAUDE_AWAKE_DIR."
    else
      say "Cloning into $DIR"
      mkdir -p "$(dirname "$DIR")"
      git clone --quiet "$REPO_URL" "$DIR"
    fi
    chmod +x "$DIR/claude-awake"
    rm -f "$TARGET"
    ln -s "$DIR/claude-awake" "$TARGET"
    ok "Linked $TARGET -> $DIR/claude-awake"
  else
    say "git not available (no Command Line Tools); downloading the script instead"
    local tmp
    tmp="$(mktemp)"
    curl -fsSL "$RAW_URL" -o "$tmp" || { rm -f "$tmp"; die "download failed."; }
    head -n1 "$tmp" | grep -q '^#!/bin/bash' || { rm -f "$tmp"; die "download did not look like the script."; }
    rm -f "$TARGET"
    mv "$tmp" "$TARGET"
    chmod 755 "$TARGET"
    ok "Installed $TARGET (run this installer again to update)"
  fi

  # Add the bin folder to PATH for future terminals, once.
  case ":$PATH:" in
    *":$BIN:"*) ;;
    *)
      local profile
      case "${SHELL:-}" in
        */bash) profile="$HOME/.bash_profile" ;;
        *)      profile="$HOME/.zshrc" ;;   # zsh is the macOS default
      esac
      # Write $HOME literally when possible so the profile stays portable.
      local bin_expr="$BIN"
      [ "$BIN" = "$HOME/bin" ] && bin_expr='$HOME/bin'
      if ! grep -qs "$MARKER" "$profile"; then
        printf '\nexport PATH="%s:$PATH"  %s\n' "$bin_expr" "$MARKER" >>"$profile"
        ok "Added $BIN to PATH in $profile"
      fi
      say "Open a new terminal window (or run: source $profile) to use claude-awake."
      ;;
  esac

  ok "Done. Try: claude-awake status"
}

# True if $1 is the claude-awake command (our symlink, or a copy of the script).
is_our_command() {
  [ -L "$1" ] && case "$(readlink "$1")" in */claude-awake) return 0 ;; esac
  [ -f "$1" ] && head -n 5 "$1" 2>/dev/null | grep -q "claude-awake"
}

do_uninstall() {
  local state="$HOME/.claude-awake" kept=0 removed=0

  # 1. Put sleep back to normal if a run is active or a crashed run left it off.
  if [ -f "$state/pid" ] || [ -f "$state/original-sleep-disabled" ]; then
    if [ -x "$TARGET" ]; then
      say "Restoring normal sleep (may ask for your password)"
      with_tty "$TARGET" stop || warn "Could not restore sleep. Run: sudo pmset -a disablesleep 0"
    else
      warn "claude-awake state found but no command to run. If needed: sudo pmset -a disablesleep 0"
    fi
  fi

  # 2. The optional passwordless-sudo rule from `claude-awake setup-sudo`.
  if [ -e "$SUDOERS_FILE" ]; then
    say "Removing $SUDOERS_FILE (may ask for your password)"
    if with_tty sudo rm -f "$SUDOERS_FILE"; then ok "Removed $SUDOERS_FILE"; removed=1
    else warn "Could not remove $SUDOERS_FILE. Run: sudo rm $SUDOERS_FILE"; kept=1; fi
  fi

  # 3. The command.
  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    if is_our_command "$TARGET"; then
      rm -f "$TARGET"; ok "Removed $TARGET"; removed=1
    else
      warn "Left $TARGET alone: it does not look like claude-awake."; kept=1
    fi
  fi

  # 4. The clone: only if it is this repo and has nothing uncommitted.
  if [ -d "$DIR" ]; then
    if [ ! -d "$DIR/.git" ]; then
      warn "Left $DIR alone: not a git clone."; kept=1
    elif ! git -C "$DIR" remote get-url origin 2>/dev/null | grep -q "frankvm04/claude-awake"; then
      warn "Left $DIR alone: it is not a clone of claude-awake."; kept=1
    elif [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
      warn "Left $DIR alone: it has uncommitted changes. Delete it yourself if you don't need them."; kept=1
    else
      rm -rf "$DIR"; ok "Removed $DIR"; removed=1
    fi
  fi

  # 5. claude-awake's state folder.
  if [ -d "$state" ]; then rm -rf "$state"; ok "Removed $state"; removed=1; fi

  # 6. The PATH line the installer added (identified by its marker comment).
  local profile tmp
  for profile in "$HOME/.zshrc" "$HOME/.bash_profile"; do
    if grep -qs "$MARKER" "$profile"; then
      tmp="$(mktemp)"
      grep -v "$MARKER" "$profile" >"$tmp" || true
      cat "$tmp" >"$profile"   # keeps the file's permissions and any symlink
      rm -f "$tmp"
      ok "Removed the PATH line from $profile"; removed=1
    fi
  done

  # Tidy up folders the installer may have created, only if now empty.
  rmdir "$BIN" "$(dirname "$DIR")" 2>/dev/null || true

  if [ "$kept" = "1" ]; then
    ok "Uninstalled, except for the items noted above."
  elif [ "$removed" = "0" ]; then
    ok "Nothing to remove: claude-awake is not installed."
  else
    ok "claude-awake is uninstalled."
  fi
}

main() {
  set -eu
  DIR="${CLAUDE_AWAKE_DIR:-$HOME/src/claude-awake}"
  BIN="${CLAUDE_AWAKE_BIN:-$HOME/bin}"
  TARGET="$BIN/claude-awake"

  case "${1:-}" in
    -h|--help) usage; return 0 ;;
    ""|--install|--update) ;;
    --uninstall|uninstall) ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac

  [ "$(uname -s)" = "Darwin" ] || die "claude-awake only works on macOS."

  case "${1:-}" in
    --uninstall|uninstall) do_uninstall ;;
    *) do_install ;;
  esac
}

main "$@"
