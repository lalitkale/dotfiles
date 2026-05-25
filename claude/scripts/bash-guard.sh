#!/usr/bin/env bash
# PreToolUse hook for Bash — blocks irreversibly destructive commands.
# Reads the tool call JSON from stdin, inspects .tool_input.command, exits 2
# (blocking) with a stderr message if the command matches a danger pattern.
#
# This is a deterministic guardrail. Agents/skills are for judgment; hooks
# are for rules that must never be skipped. Per Anthropic Claude Code hook
# design: exit code 2 returns a blocking error to the model.

set -u

# Fail-open on malformed input: better to allow a weird command through than
# to block every bash call because jq had a bad day.
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

block() {
  printf 'bash-guard: BLOCKED\n  reason: %s\n  command: %s\n' "$1" "$cmd" >&2
  printf '  If this is intentional, run it manually outside Claude Code,\n  or temporarily disable the PreToolUse hook in ~/.claude/settings.json.\n' >&2
  exit 2
}

# --- Filesystem destruction ---------------------------------------------------
# Block rm -rf targeting bare root. Allows specific paths like /tmp/foo.
# Matches: rm -rf /   rm -rf /*   rm -rf /**   (optional trailing ws/;/&/|)
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]*[rRfF][a-zA-Z]*[[:space:]]+)+/(\*{1,2})?([[:space:]]|$|;|&|\|)'; then
  block "rm -rf targeting /"
fi
# Block rm -rf targeting bare home. Allows rm -rf ~/specific/subdir.
# Matches: rm -rf ~   rm -rf ~/   rm -rf $HOME   rm -rf $HOME/
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]*[rRfF][a-zA-Z]*[[:space:]]+)+(~|\$HOME)/?([[:space:]]|$|;|&|\|)'; then
  block "rm -rf targeting bare \$HOME"
fi

# --- Git destruction ----------------------------------------------------------
# Block --force but allow --force-with-lease (safer variant)
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]].*(--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$))'; then
  if ! printf '%s' "$cmd" | grep -Eq -- '--force-with-lease'; then
    block "git push --force (use --force-with-lease)"
  fi
fi
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard'; then
  block "git reset --hard"
fi
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*[dx]'; then
  block "git clean -fd/-fx"
fi
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+branch[[:space:]]+-D[[:space:]]'; then
  block "git branch -D (force delete)"
fi
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+checkout[[:space:]]+\.([[:space:]]|$)'; then
  block "git checkout . (discards uncommitted changes)"
fi

# --- Database destruction -----------------------------------------------------
if printf '%s' "$cmd" | grep -Eqi 'DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)'; then
  block "DROP TABLE/DATABASE/SCHEMA"
fi
if printf '%s' "$cmd" | grep -Eqi 'TRUNCATE[[:space:]]+TABLE'; then
  block "TRUNCATE TABLE"
fi

# --- System destruction -------------------------------------------------------
if printf '%s' "$cmd" | grep -Eq 'chmod[[:space:]]+-R[[:space:]]+777'; then
  block "chmod -R 777"
fi
if printf '%s' "$cmd" | grep -Eq 'mkfs\.'; then
  block "mkfs (filesystem creation)"
fi
if printf '%s' "$cmd" | grep -Eq '>[[:space:]]*/dev/(sd[a-z]|nvme|hd[a-z])'; then
  block "redirect to raw block device"
fi
if printf '%s' "$cmd" | grep -Eq 'dd[[:space:]]+.*of=/dev/(sd[a-z]|nvme|hd[a-z])'; then
  block "dd to raw block device"
fi

# --- Fork bomb ----------------------------------------------------------------
if printf '%s' "$cmd" | grep -Eq ':\(\)[[:space:]]*\{'; then
  block "fork bomb"
fi

# --- No match — allow ---------------------------------------------------------
exit 0
