#!/bin/bash
#
# Install or update claude-awake.
#
#   curl -fsSL https://raw.githubusercontent.com/frankvm04/claude-awake/main/install.sh | bash
#
# What it does:
#   1. Clones the repo to ~/src/claude-awake, or pulls if it is already there.
#      Without git (no Command Line Tools), downloads the script instead.
#   2. Links (or copies) the command to ~/bin/claude-awake.
#   3. Adds ~/bin to PATH in your shell profile if it is not there yet.
#
# Settings (environment variables):
#   CLAUDE_AWAKE_DIR  where to clone      (default: ~/src/claude-awake)
#   CLAUDE_AWAKE_BIN  where to put it     (default: ~/bin)
#
# Written for the stock macOS bash 3.2.

# Everything is inside main() so a partly downloaded script never runs.
main() {
  set -eu

  local repo_url="https://github.com/frankvm04/claude-awake.git"
  local raw_url="https://raw.githubusercontent.com/frankvm04/claude-awake/main/claude-awake"
  local dir="${CLAUDE_AWAKE_DIR:-$HOME/src/claude-awake}"
  local bin="${CLAUDE_AWAKE_BIN:-$HOME/bin}"
  local target="$bin/claude-awake"

  say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
  ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
  die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

  [ "$(uname -s)" = "Darwin" ] || die "claude-awake only works on macOS."

  mkdir -p "$bin"

  # On a new Mac /usr/bin/git is a stub that opens an installer dialog,
  # so check for the Command Line Tools rather than just for `git`.
  if command -v git >/dev/null 2>&1 && xcode-select -p >/dev/null 2>&1; then
    if [ -d "$dir/.git" ]; then
      say "Updating $dir"
      git -C "$dir" pull --ff-only --quiet
    elif [ -e "$dir" ]; then
      die "$dir exists but is not a git clone. Move it, or set CLAUDE_AWAKE_DIR."
    else
      say "Cloning into $dir"
      mkdir -p "$(dirname "$dir")"
      git clone --quiet "$repo_url" "$dir"
    fi
    chmod +x "$dir/claude-awake"
    rm -f "$target"
    ln -s "$dir/claude-awake" "$target"
    ok "Linked $target -> $dir/claude-awake"
  else
    say "git not available (no Command Line Tools); downloading the script instead"
    local tmp
    tmp="$(mktemp)"
    curl -fsSL "$raw_url" -o "$tmp" || { rm -f "$tmp"; die "download failed."; }
    head -n1 "$tmp" | grep -q '^#!/bin/bash' || { rm -f "$tmp"; die "download did not look like the script."; }
    rm -f "$target"
    mv "$tmp" "$target"
    chmod 755 "$target"
    ok "Installed $target (run this installer again to update)"
  fi

  # Add the bin folder to PATH for future terminals, once.
  case ":$PATH:" in
    *":$bin:"*) ;;
    *)
      local profile
      case "${SHELL:-}" in
        */bash) profile="$HOME/.bash_profile" ;;
        *)      profile="$HOME/.zshrc" ;;   # zsh is the macOS default
      esac
      # Write $HOME literally when possible so the profile stays portable.
      local bin_expr="$bin"
      [ "$bin" = "$HOME/bin" ] && bin_expr='$HOME/bin'
      if ! grep -qs "# added by claude-awake installer" "$profile"; then
        printf '\nexport PATH="%s:$PATH"  # added by claude-awake installer\n' "$bin_expr" >>"$profile"
        ok "Added $bin to PATH in $profile"
      fi
      say "Open a new terminal window (or run: source $profile) to use claude-awake."
      ;;
  esac

  ok "Done. Try: claude-awake status"
}

main "$@"
