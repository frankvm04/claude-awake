#!/bin/bash
#
# Checks to run before pushing or releasing claude-awake.
#
#   scripts/check.sh           code checks
#   scripts/check.sh 1.4.0     code checks, plus: the script, CHANGELOG and README
#                              all agree on version 1.4.0
#
# Works on macOS and Linux; needs only bash, grep and perl.

cd "$(dirname "$0")/.." || exit 2
FILES="claude-awake install.sh"
fail=0
pass() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; fail=1; }

echo "claude-awake checks"

# 1. Syntax
for f in $FILES; do
  if bash -n "$f" 2>/tmp/check-syntax.$$; then pass "$f: syntax"
  else bad "$f: syntax error"; sed 's/^/      /' /tmp/check-syntax.$$; fi
  rm -f /tmp/check-syntax.$$
done

# 2. The macOS bash (3.2) reads the bytes of a non-ASCII character right after
#    $name as part of the name ("$C_GRY—" becomes an unknown variable). Write
#    ${name} instead.
out="$(perl -ne 'print "      $ARGV:$.: $_" if /\$[A-Za-z_][A-Za-z0-9_]*(?=[^\x00-\x7F])/; close ARGV if eof' $FILES)"
if [ -z "$out" ]; then pass "no \$name directly before a non-ASCII character"
else bad "\$name directly before a non-ASCII character (write \${name}):"; printf '%s\n' "$out"; fi

# 3. Features newer than the bash 3.2 that macOS ships.
out="$(grep -n -E 'declare -A|local -A|mapfile|readarray|\$\{[A-Za-z_]+(,,|\^\^|,|\^)\}|\|&|&>>|;;&|coproc|printf .%\(|\[\[ -v|declare -g|local -n|wait -n|\$EPOCHSECONDS|\$BASHPID' $FILES | sed 's/^/      /')"
if [ -z "$out" ]; then pass "no features newer than bash 3.2"
else bad "features newer than bash 3.2:"; printf '%s\n' "$out"; fi

# 4. The script runs its version and help commands (these work on any OS).
if v="$(bash claude-awake version 2>&1)" && bash claude-awake help >/dev/null 2>&1; then pass "runs: $v"
else bad "claude-awake version/help failed: $v"; fi

# 5. Optional: shellcheck, if installed (errors only).
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -s bash -S error $FILES >/tmp/check-sc.$$ 2>&1; then pass "shellcheck: no errors"
  else bad "shellcheck errors:"; sed 's/^/      /' /tmp/check-sc.$$; fi
  rm -f /tmp/check-sc.$$
fi

# 6. Release: version numbers agree.
if [ -n "${1:-}" ]; then
  want="$1"
  grep -q "^VERSION=\"$want\"$" claude-awake && pass "claude-awake VERSION is $want" || bad "claude-awake VERSION is not $want"
  grep -q "^## \[$want\] - [0-9]\{4\}-[0-9][0-9]-[0-9][0-9]$" CHANGELOG.md && pass "CHANGELOG has a dated [$want] entry" || bad "CHANGELOG has no dated [$want] entry"
  grep -q "^\[$want\]: " CHANGELOG.md && pass "CHANGELOG links [$want]" || bad "CHANGELOG has no [$want] link"
  if sed -n '/^## \[Unreleased\]/,/^## \[/p' CHANGELOG.md | grep -q '^### '; then bad "CHANGELOG Unreleased section isn't empty"
  else pass "CHANGELOG Unreleased section is empty"; fi
  others="$(grep -n -E 'v[0-9]+\.[0-9]+\.[0-9]+' README.md | grep -v "v$want" | sed 's/^/      /')"
  [ -z "$others" ] && pass "README pins v$want" || { bad "README mentions another version:"; printf '%s\n' "$others"; }
fi

if [ "$fail" = 0 ]; then echo "All checks passed."; else echo "Some checks failed."; exit 1; fi
