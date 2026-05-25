# Claude Code Bootstrap — Design Spec

**Date:** 2026-05-25
**Status:** Approved

## Goal

Replicate the current Claude Code setup from a Linux (Tuxedo) machine onto a macOS machine where:
- Claude Code is already installed system-wide by an admin (no install needed)
- The user has no `sudo` access
- Config is sourced from the `~/dotfiles` git repo

## What Gets Committed to Dotfiles

Files live under `~/dotfiles/claude/`:

```
~/dotfiles/claude/
├── CLAUDE.md
├── RTK.md
├── settings.json
├── settings.local.json
├── mcp.json
├── scripts/
│   ├── bash-guard.sh
│   └── agent-tmux-pane.sh
└── statusline-command.sh
```

**Excluded (never committed):**
- `.credentials.json` — auth token, machine-specific
- `plugins/cache/` — reinstalled fresh on new machine
- `history.jsonl`, `cache/`, `sessions/`, `projects/`, `tasks/`, `telemetry/` — ephemeral state

**Path portability:** The export script replaces all `/home/lalit/` occurrences with `$HOME/` via `sed`. All hardcoded paths appear inside shell command strings (JSON hook values and shell scripts), so `$HOME` expands correctly at runtime on both Linux and macOS.

## Script 1: `export-to-dotfiles.sh` (runs on this Linux machine, once)

**Location:** `~/dotfiles/claude/export-to-dotfiles.sh`

Steps:
1. Create `~/dotfiles/claude/` directory structure
2. Copy the 8 config files from `~/.claude/` preserving relative paths
3. Run `sed 's|/home/lalit/|$HOME/|g'` on all copied files
4. Commit to dotfiles repo: `chore: add claude code config`

## Script 2: `install-claude.sh` (runs on the macOS machine)

**Location:** `~/dotfiles/claude/install-claude.sh`

Steps in order:
1. **Detect macOS** — exit with clear message if not on macOS
2. **Verify Claude Code** — check `claude` is on PATH; exit with message if not (admin must install first)
3. **Install RTK** — download RTK 0.37.1 macOS binary from GitHub releases to `~/.local/bin/rtk`, set executable
4. **Clone/pull dotfiles** — clone `~/dotfiles` if not present, otherwise `git pull`
5. **Copy config files** — create `~/.claude/scripts/` if needed; copy all 8 files from `~/dotfiles/claude/` to `~/.claude/`
6. **Install plugins** — run `claude plugin install` for each of the 10 marketplace plugins:
   - code-review, commit-commands, security-guidance, pr-review-toolkit, typescript-lsp
   - superpowers, github, skill-creator, frontend-design, pyright-lsp
7. **Shell aliases** — append `claude`, `cc`, `cdb` aliases to `~/.zshrc` if not already present (idempotent check)
8. **Print summary** — list what was done and any manual steps remaining

## Constraints

- All installs are user-space only (no `sudo`)
- Claude Code already present — not installed by the script
- RTK is the only binary the script fetches; everything else is config or plugin data
- Shell alias injection is idempotent (safe to run the install script more than once)

## Manual Steps (post-install)

- Authenticate Claude Code: `claude` → follow login prompt
- Verify RTK hook works: `rtk gain`
- Confirm tmux is installed (script does not install it — assumed present or separately handled)
- Source `~/.zshrc` or open a new shell to pick up aliases

## Files Produced

| File | Purpose |
|------|---------|
| `~/dotfiles/claude/export-to-dotfiles.sh` | One-time export from this Linux machine |
| `~/dotfiles/claude/install-claude.sh` | Reusable installer for any new macOS machine |
| `~/dotfiles/claude/{config files}` | Portable Claude Code configuration |
