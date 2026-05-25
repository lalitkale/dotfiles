#!/bin/bash
# agent-tmux-pane.sh
# Called by SubagentStart hook. Opens a new tmux pane and tails the agent output.

INPUT=$(cat)

DESCRIPTION=$(echo "$INPUT" | jq -r '.description // .summary // "Agent"')
OUTPUT_FILE=$(echo "$INPUT" | jq -r '.output_file // empty')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // .task_id // empty')

# If output_file not provided, try to locate it by agent_id
if [ -z "$OUTPUT_FILE" ] && [ -n "$AGENT_ID" ]; then
  OUTPUT_FILE=$(find /tmp/claude-* -name "${AGENT_ID}.output" 2>/dev/null | head -1)
fi

# Nothing to tail — exit silently
if [ -z "$OUTPUT_FILE" ]; then
  exit 0
fi

# Target session: prefer current $TMUX session, fall back to 'ekam'
TARGET_SESSION=""
if [ -n "$TMUX" ]; then
  TARGET_SESSION=$(tmux display-message -p '#S' 2>/dev/null)
else
  tmux has-session -t ekam 2>/dev/null && TARGET_SESSION="ekam"
fi

if [ -z "$TARGET_SESSION" ]; then
  exit 0
fi

# Pane command: wait for file then tail it, keep pane open on completion
PANE_CMD=$(cat <<EOF
printf '\033]2;%s\033\\\\' "$DESCRIPTION"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
printf "│ %-61s │\n" "$DESCRIPTION"
echo "└─────────────────────────────────────────────────────────────┘"
echo "Waiting for output..."
until [ -f "$OUTPUT_FILE" ]; do sleep 0.3; done
echo ""
tail -f "$OUTPUT_FILE"
EOF
)

tmux split-window -d -h -t "$TARGET_SESSION" "bash -c $(printf '%q' "$PANE_CMD")" 2>/dev/null \
  || tmux split-window -d -v -t "$TARGET_SESSION" "bash -c $(printf '%q' "$PANE_CMD")" 2>/dev/null

tmux select-layout -t "$TARGET_SESSION" tiled 2>/dev/null

exit 0
