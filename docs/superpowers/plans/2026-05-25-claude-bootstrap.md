# Claude Code Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `export-to-dotfiles.sh` (Linux) and `install-claude.sh` (macOS) to snapshot and replicate a Claude Code setup across machines via a dotfiles git repo.

**Architecture:** `export-to-dotfiles.sh` copies `~/.claude/` config into `~/dotfiles/claude/`, replaces hardcoded `/home/lalit/` paths with `$HOME/`, and commits. `install-claude.sh` is a standalone macOS installer: verifies prerequisites, installs RTK via curl, copies config from dotfiles, installs 10 plugins, and appends shell aliases idempotently. Both scripts guard their `main()` call so they can be sourced for unit testing.

**Tech Stack:** bash, git, `claude plugin install`, `curl` (RTK install)

---

## File Map

| Path | Action |
|------|--------|
| `~/dotfiles/claude/export-to-dotfiles.sh` | Create |
| `~/dotfiles/claude/install-claude.sh` | Create |
| `~/dotfiles/claude/tests/test_export.sh` | Create |
| `~/dotfiles/claude/tests/test_install.sh` | Create |
| `~/dotfiles/claude/{8 config files}` | Copied by export script in Task 7 |

---

### Task 1: Write failing tests for export-to-dotfiles.sh

**Files:**
- Create: `~/dotfiles/claude/tests/test_export.sh`

- [ ] **Step 1: Create the test file**

```bash
cat > ~/dotfiles/claude/tests/test_export.sh << 'EOF'
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
EOF
chmod +x ~/dotfiles/claude/tests/test_export.sh
```

- [ ] **Step 2: Run tests — verify they FAIL**

```bash
bash ~/dotfiles/claude/tests/test_export.sh
```

Expected: script errors out because `export-to-dotfiles.sh` does not exist yet.

---

### Task 2: Implement export-to-dotfiles.sh

**Files:**
- Create: `~/dotfiles/claude/export-to-dotfiles.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/dotfiles/claude/export-to-dotfiles.sh << 'EOF'
#!/usr/bin/env bash
# Copies ~/.claude config to ~/dotfiles/claude/ with portable paths, then commits.
# Env overrides for testing: CLAUDE_DIR, DOTFILES_DIR

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DEST="$DOTFILES_DIR/claude"

SOURCE_FILES=(
  CLAUDE.md
  RTK.md
  settings.json
  settings.local.json
  mcp.json
  scripts/bash-guard.sh
  scripts/agent-tmux-pane.sh
  statusline-command.sh
)

check_source_files() {
  for f in "${SOURCE_FILES[@]}"; do
    [[ -f "$CLAUDE_DIR/$f" ]] || { echo "ERROR: missing source file: $CLAUDE_DIR/$f"; exit 1; }
  done
}

copy_files() {
  mkdir -p "$DEST/scripts"
  for f in "${SOURCE_FILES[@]}"; do
    cp "$CLAUDE_DIR/$f" "$DEST/$f"
  done
}

make_portable() {
  # Replace /home/lalit/ with literal $HOME/ so paths expand at runtime on any machine.
  # Using \$HOME (escaped) so sed writes the string "$HOME/" not the expanded value.
  find "$DEST" -type f -exec sed -i "s|/home/lalit/|\$HOME/|g" {} +
}

commit() {
  git -C "$DOTFILES_DIR" add claude/
  if git -C "$DOTFILES_DIR" diff --cached --quiet; then
    echo "Nothing new to commit."
  else
    git -C "$DOTFILES_DIR" commit -m "chore: add claude code config"
  fi
}

main() {
  echo "Exporting Claude Code config from $CLAUDE_DIR to $DEST ..."
  check_source_files
  copy_files
  make_portable
  commit
  echo "Done. Review ~/dotfiles/claude/ and push when ready."
}

main "$@"
EOF
chmod +x ~/dotfiles/claude/export-to-dotfiles.sh
```

- [ ] **Step 2: Run tests — verify they PASS**

```bash
bash ~/dotfiles/claude/tests/test_export.sh
```

Expected output:
```
PASS: creates_all_config_files
PASS: no_hardcoded_paths
PASS: excludes_credentials
PASS: git_commit_made

Results: 4 passed, 0 failed
```

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add claude/export-to-dotfiles.sh claude/tests/test_export.sh
git commit -m "feat: add claude code export script with tests"
```

---

### Task 3: Write failing tests for install-claude.sh

**Files:**
- Create: `~/dotfiles/claude/tests/test_install.sh`

- [ ] **Step 1: Create the test file**

```bash
cat > ~/dotfiles/claude/tests/test_install.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

PASS=0; FAIL=0
pass() { echo "PASS: $1"; ((PASS++)); }
fail() { echo "FAIL: $1 — $2"; ((FAIL++)); }

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/install-claude.sh"
TMPDIR=$(mktemp -d)

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
  local fake_dotfiles="$TMPDIR/dotfiles"
  local dest="$TMPDIR/claude_dest"
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
  local fake_zshrc="$TMPDIR/.zshrc"
  touch "$fake_zshrc"
  ZSHRC="$fake_zshrc" bash -c "source '$SCRIPT'; setup_aliases"
  ZSHRC="$fake_zshrc" bash -c "source '$SCRIPT'; setup_aliases"
  local count
  count=$(grep -c "alias claude=" "$fake_zshrc" 2>/dev/null || true)
  [[ "$count" -eq 1 ]] && pass "alias_idempotent" \
    || fail "alias_idempotent" "alias appeared $count times (expected 1)"
}

# ── Run ───────────────────────────────────────────────────────────────────────
test_rejects_non_macos
test_requires_claude_binary
test_rtk_install_command
test_copies_config_files
test_installs_all_plugins
test_alias_idempotent

rm -rf "$TMPDIR"
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
EOF
chmod +x ~/dotfiles/claude/tests/test_install.sh
```

- [ ] **Step 2: Run tests — verify they FAIL**

```bash
bash ~/dotfiles/claude/tests/test_install.sh
```

Expected: errors out because `install-claude.sh` does not exist yet.

---

### Task 4: Implement install-claude.sh

**Files:**
- Create: `~/dotfiles/claude/install-claude.sh`

- [ ] **Step 1: Write the script**

```bash
cat > ~/dotfiles/claude/install-claude.sh << 'EOF'
#!/usr/bin/env bash
# Sets up Claude Code config on a new macOS machine (no sudo required).
# Usage: bash install-claude.sh [DOTFILES_REPO_URL]
# Requires: claude (admin-installed), curl, git

set -euo pipefail

DOTFILES_REPO="${1:-git@github.com:lalitkale/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CLAUDE_DEST="${CLAUDE_DEST:-$HOME/.claude}"
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
DRY_RUN="${DRY_RUN:-0}"

PLUGINS=(
  code-review
  commit-commands
  security-guidance
  pr-review-toolkit
  typescript-lsp
  superpowers
  github
  skill-creator
  frontend-design
  pyright-lsp
)

check_macos() {
  [[ "$(uname)" == "Darwin" ]] || {
    echo "ERROR: macOS required (detected: $(uname))"
    exit 1
  }
}

check_claude() {
  command -v claude >/dev/null || {
    echo "ERROR: 'claude' not found on PATH."
    echo "       Ask your admin to install Claude Code, then re-run this script."
    exit 1
  }
}

install_rtk() {
  echo "Installing RTK..."
  mkdir -p "$HOME/.local/bin"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[DRY_RUN] curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh"
  else
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh
  fi
}

pull_dotfiles() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    echo "Updating dotfiles..."
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[DRY_RUN] git -C $DOTFILES_DIR pull"
    else
      git -C "$DOTFILES_DIR" pull
    fi
  else
    echo "Cloning dotfiles..."
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[DRY_RUN] git clone $DOTFILES_REPO $DOTFILES_DIR"
    else
      git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
  fi
}

copy_config() {
  echo "Copying Claude config..."
  local src="$DOTFILES_DIR/claude"
  mkdir -p "$CLAUDE_DEST/scripts"
  local files=(CLAUDE.md RTK.md settings.json settings.local.json mcp.json statusline-command.sh)
  for f in "${files[@]}"; do
    cp "$src/$f" "$CLAUDE_DEST/$f"
  done
  cp "$src/scripts/bash-guard.sh"      "$CLAUDE_DEST/scripts/bash-guard.sh"
  cp "$src/scripts/agent-tmux-pane.sh" "$CLAUDE_DEST/scripts/agent-tmux-pane.sh"
  chmod +x "$CLAUDE_DEST/scripts/"*.sh "$CLAUDE_DEST/statusline-command.sh"
}

install_plugins() {
  echo "Installing Claude plugins..."
  for plugin in "${PLUGINS[@]}"; do
    echo "  Installing $plugin..."
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[DRY_RUN] claude plugin install $plugin"
    else
      claude plugin install "$plugin"
    fi
  done
}

setup_aliases() {
  if grep -q "alias claude=" "$ZSHRC" 2>/dev/null; then
    echo "Claude aliases already in $ZSHRC — skipping."
    return
  fi
  echo "Adding aliases to $ZSHRC..."
  cat >> "$ZSHRC" << 'ALIASES'

# Claude Code aliases
alias claude='echo "$PWD" > ~/.claude_last_dir && command claude --dangerously-skip-permissions'
alias cc='echo "$PWD" > ~/.claude_last_dir && command claude --continue --dangerously-skip-permissions'
alias cdb='cd "$(cat ~/.claude_last_dir)"'
ALIASES
}

print_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Claude Code bootstrap complete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " ✓ RTK installed"
  echo " ✓ Config copied to $CLAUDE_DEST"
  echo " ✓ ${#PLUGINS[@]} plugins installed"
  echo " ✓ Shell aliases added to $ZSHRC"
  echo ""
  echo " Manual steps:"
  echo "   1. source ~/.zshrc  (or open a new shell)"
  echo "   2. claude           (follow the login prompt)"
  echo "   3. rtk gain         (verify RTK is working)"
  echo "   4. tmux -V          (verify tmux is present)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main() {
  check_macos
  check_claude
  install_rtk
  pull_dotfiles
  copy_config
  install_plugins
  setup_aliases
  print_summary
}

# Guard: allow sourcing for tests without executing main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
EOF
chmod +x ~/dotfiles/claude/install-claude.sh
```

- [ ] **Step 2: Run tests — verify they PASS**

```bash
bash ~/dotfiles/claude/tests/test_install.sh
```

Expected output:
```
PASS: rejects_non_macos
PASS: requires_claude_binary
PASS: rtk_install_command
PASS: copies_config_files
PASS: installs_all_plugins
PASS: alias_idempotent

Results: 6 passed, 0 failed
```

- [ ] **Step 3: Commit**

```bash
cd ~/dotfiles
git add claude/install-claude.sh claude/tests/test_install.sh
git commit -m "feat: add claude code install script with tests"
```

---

### Task 5: Run export-to-dotfiles.sh to populate actual config files

**Files:**
- Copies: `~/dotfiles/claude/{8 config files}`

- [ ] **Step 1: Run the export script**

```bash
bash ~/dotfiles/claude/export-to-dotfiles.sh
```

Expected output:
```
Exporting Claude Code config from /home/lalit/.claude to /home/lalit/dotfiles/claude ...
Done. Review ~/dotfiles/claude/ and push when ready.
```

- [ ] **Step 2: Verify no hardcoded paths remain**

```bash
grep -r '/home/lalit/' ~/dotfiles/claude/ && echo "FAIL: hardcoded paths found" || echo "PASS: no hardcoded paths"
```

Expected: `PASS: no hardcoded paths`

- [ ] **Step 3: Verify credentials were excluded**

```bash
ls ~/dotfiles/claude/.credentials.json 2>/dev/null && echo "FAIL: credentials present" || echo "PASS: credentials excluded"
```

Expected: `PASS: credentials excluded`

- [ ] **Step 4: Push to remote**

```bash
cd ~/dotfiles && git push
```

---

### Task 6: End-to-end dry run verification

- [ ] **Step 1: Verify export test suite still passes after real config files are present**

```bash
bash ~/dotfiles/claude/tests/test_export.sh
```

Expected: 4 passed, 0 failed

- [ ] **Step 2: Dry-run the install script**

```bash
DRY_RUN=1 bash ~/dotfiles/claude/install-claude.sh
```

Expected: script exits at `check_macos` (we're on Linux) with message:
```
ERROR: macOS required (detected: Linux)
```

This is correct — the macOS guard works. The script is ready for use on the target machine.

- [ ] **Step 3: Print the on-boarding instructions to share with the new machine**

```bash
echo "
On the new macOS machine, open a terminal and run:

  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh
  # (Only if RTK is not already present)

  git clone git@github.com:lalitkale/dotfiles.git ~/dotfiles
  bash ~/dotfiles/claude/install-claude.sh
"
```
