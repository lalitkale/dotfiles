#!/usr/bin/env bash
set -euo pipefail

PASS=0; FAIL=0
pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/install-claude.sh"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# ── Test: rejects non-macOS ───────────────────────────────────────────────────
test_rejects_non_macos() {
  local rc=0
  (
    uname() { echo "Linux"; }
    export -f uname
    source "$SCRIPT"
    check_macos 2>/dev/null
  ) || rc=$?
  [[ $rc -ne 0 ]] && pass "rejects_non_macos" \
    || fail "rejects_non_macos" "should exit non-zero on non-macOS"
}

# ── Test: requires claude binary ──────────────────────────────────────────────
test_requires_claude_binary() {
  local rc=0
  (
    source "$SCRIPT"
    PATH=/nonexistent check_claude 2>/dev/null
  ) || rc=$?
  [[ $rc -ne 0 ]] && pass "requires_claude_binary" \
    || fail "requires_claude_binary" "should exit non-zero when claude not found"
}

# ── Test: rtk install references correct project ──────────────────────────────
test_rtk_install_command() {
  local output
  output=$(DRY_RUN=1 bash -c "source '$SCRIPT'; install_rtk" 2>&1)
  if echo "$output" | grep -q "rtk-ai/rtk"; then
    pass "rtk_install_command"
  else
    fail "rtk_install_command" "expected rtk-ai/rtk in output, got: $output"
  fi
}

# ── Test: copy_config places all 8 files ──────────────────────────────────────
test_copies_config_files() {
  local fake_dotfiles="$TEST_DIR/dotfiles"
  local dest="$TEST_DIR/claude_dest"
  mkdir -p "$fake_dotfiles/claude/scripts"
  for f in CLAUDE.md RTK.md settings.json settings.local.json mcp.json statusline-command.sh; do
    touch "$fake_dotfiles/claude/$f"
  done
  touch "$fake_dotfiles/claude/scripts/bash-guard.sh"
  touch "$fake_dotfiles/claude/scripts/agent-tmux-pane.sh"

  DOTFILES_DIR="$fake_dotfiles" CLAUDE_DEST="$dest" \
    bash -c "source '$SCRIPT'; copy_config" 2>/dev/null

  local missing=0
  for f in CLAUDE.md RTK.md settings.json settings.local.json mcp.json statusline-command.sh \
            scripts/bash-guard.sh scripts/agent-tmux-pane.sh; do
    [[ -f "$dest/$f" ]] || { echo "  missing: $f"; missing=1; }
  done
  [[ $missing -eq 0 ]] && pass "copies_config_files" \
    || fail "copies_config_files" "one or more files not copied"
}

# ── Test: all 10 plugins listed in DRY_RUN output ────────────────────────────
test_installs_all_plugins() {
  local output
  output=$(DRY_RUN=1 bash -c "source '$SCRIPT'; install_plugins" 2>&1)
  local plugins=(code-review commit-commands security-guidance pr-review-toolkit
    typescript-lsp superpowers github skill-creator frontend-design pyright-lsp)
  local missing=0
  for p in "${plugins[@]}"; do
    echo "$output" | grep -q "$p" || { echo "  missing: $p"; missing=1; }
  done
  [[ $missing -eq 0 ]] && pass "installs_all_plugins" \
    || fail "installs_all_plugins" "some plugins missing from DRY_RUN output"
}

# ── Test: alias injection is idempotent ───────────────────────────────────────
test_alias_idempotent() {
  local fake_zshrc="$TEST_DIR/.zshrc"
  touch "$fake_zshrc"
  ZSHRC="$fake_zshrc" bash -c "source '$SCRIPT'; setup_aliases"
  ZSHRC="$fake_zshrc" bash -c "source '$SCRIPT'; setup_aliases"
  local count
  count=$(grep -c 'local/bin' "$fake_zshrc" 2>/dev/null || true)
  [[ "$count" -eq 1 ]] && pass "alias_idempotent" \
    || fail "alias_idempotent" "PATH export appeared $count times (expected 1)"
}

# ── Run ───────────────────────────────────────────────────────────────────────
test_rejects_non_macos
test_requires_claude_binary
test_rtk_install_command
test_copies_config_files
test_installs_all_plugins
test_alias_idempotent

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
