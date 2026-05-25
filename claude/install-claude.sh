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
