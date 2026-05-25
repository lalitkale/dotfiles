#!/usr/bin/env bash
set -euo pipefail

PASS=0; FAIL=0
pass() { echo "PASS: $1"; ((PASS++)); }
fail() { echo "FAIL: $1 — $2"; ((FAIL++)); }

TMPDIR=$(mktemp -d)
FAKE_CLAUDE="$TMPDIR/claude"
FAKE_DOTFILES="$TMPDIR/dotfiles"

# Fake ~/.claude source tree
mkdir -p "$FAKE_CLAUDE/scripts"
echo "# CLAUDE"  > "$FAKE_CLAUDE/CLAUDE.md"
echo "# RTK"     > "$FAKE_CLAUDE/RTK.md"
cat > "$FAKE_CLAUDE/settings.json" << 'JSON'
{"hooks":{"PreToolUse":[{"hooks":[{"command":"bash /home/lalit/.claude/scripts/bash-guard.sh"}]}]}}
JSON
echo '{"outputStyle":"caveman"}' > "$FAKE_CLAUDE/settings.local.json"
echo '{"mcpServers":{}}'         > "$FAKE_CLAUDE/mcp.json"
echo '#!/bin/bash'               > "$FAKE_CLAUDE/scripts/bash-guard.sh"
echo '#!/bin/bash'               > "$FAKE_CLAUDE/scripts/agent-tmux-pane.sh"
echo '#!/bin/bash'               > "$FAKE_CLAUDE/statusline-command.sh"
echo "SECRET"                    > "$FAKE_CLAUDE/.credentials.json"

# Fake dotfiles git repo
mkdir -p "$FAKE_DOTFILES"
git -C "$FAKE_DOTFILES" init -q
git -C "$FAKE_DOTFILES" config user.email "test@test.com"
git -C "$FAKE_DOTFILES" config user.name "Test"
touch "$FAKE_DOTFILES/.gitkeep"
git -C "$FAKE_DOTFILES" add .
git -C "$FAKE_DOTFILES" commit -q -m "init"

# Run export script
CLAUDE_DIR="$FAKE_CLAUDE" DOTFILES_DIR="$FAKE_DOTFILES" \
  bash "$(dirname "$0")/../export-to-dotfiles.sh" 2>/dev/null

# ── Tests ────────────────────────────────────────────────────────────────────

test_creates_all_config_files() {
  local dest="$FAKE_DOTFILES/claude"
  local files=(CLAUDE.md RTK.md settings.json settings.local.json mcp.json
               scripts/bash-guard.sh scripts/agent-tmux-pane.sh statusline-command.sh)
  for f in "${files[@]}"; do
    [[ -f "$dest/$f" ]] || { fail "creates_all_config_files" "missing: $f"; return; }
  done
  pass "creates_all_config_files"
}

test_no_hardcoded_paths() {
  if grep -r '/home/lalit/' "$FAKE_DOTFILES/claude/" 2>/dev/null | grep -q .; then
    fail "no_hardcoded_paths" "found /home/lalit/ in exported files"
  else
    pass "no_hardcoded_paths"
  fi
}

test_excludes_credentials() {
  if [[ -f "$FAKE_DOTFILES/claude/.credentials.json" ]]; then
    fail "excludes_credentials" ".credentials.json was copied — must not be"
  else
    pass "excludes_credentials"
  fi
}

test_git_commit_made() {
  if git -C "$FAKE_DOTFILES" log --oneline 2>/dev/null | grep -qi "claude"; then
    pass "git_commit_made"
  else
    fail "git_commit_made" "no commit with 'claude' in message found"
  fi
}

test_creates_all_config_files
test_no_hardcoded_paths
test_excludes_credentials
test_git_commit_made

rm -rf "$TMPDIR"
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
