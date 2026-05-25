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
