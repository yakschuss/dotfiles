Interactive code review prep - walk through changes as pair programming.

## Setup
1. Check for nvim pane in tmux, create vertical split if needed
2. Get diff (default: last commit, or accept commit range as argument)
3. Parse into logical changes with file:line

## Start Review
State the problem(s) being solved (1-2 max, more is a code smell).
Map each change to which problem it addresses.

## For Each Change
1. Open file at line in nvim pane
2. ALWAYS highlight the changed code using visual mode
3. Focus nvim pane so user can inspect
4. Give ONE line context: "Change X/N - Problem Y. [brief description]"
5. Wait for questions

## Navigation Commands
- `open(file, line)` - open file at line, focus nvim
- `highlight(file, line, pattern)` - open, search pattern, visual select, focus nvim
- `focus_vim()` / `focus_claude()` - switch panes
- "next" / "back" - move between changes
- "done" - wrap up

## Conversation Style
- Short, pithy responses - one or two lines max
- Wait for questions, don't front-load explanation
- Answer directly, then offer: "want to see X?"
- Bounce up/down abstraction layers on request
- If user asks about related code, open it

## Tmux Helpers
```bash
# Find or create nvim pane
NVIM_PANE=$(tmux list-panes -F "#{pane_id} #{pane_current_command}" | grep nvim | awk '{print $1}')
if [ -z "$NVIM_PANE" ]; then
  tmux split-window -h "nvim"
  sleep 0.5
  NVIM_PANE=$(tmux list-panes -F "#{pane_id} #{pane_current_command}" | grep nvim | awk '{print $1}')
fi

# Open file at line and highlight (single line)
tmux send-keys -t $NVIM_PANE Escape ":e +LINE FILE" Enter
tmux send-keys -t $NVIM_PANE "V"  # visual line mode

# Highlight multi-line change (from START_LINE to END_LINE)
tmux send-keys -t $NVIM_PANE Escape ":e +START_LINE FILE" Enter
tmux send-keys -t $NVIM_PANE "V"
tmux send-keys -t $NVIM_PANE "END_LINEgg"

# Highlight by searching for pattern
tmux send-keys -t $NVIM_PANE Escape ":e +LINE FILE" Enter
tmux send-keys -t $NVIM_PANE "/PATTERN" Enter
tmux send-keys -t $NVIM_PANE "v" && tmux send-keys -t $NVIM_PANE "e"  # or f) for parens

# Focus pane
tmux select-pane -t $NVIM_PANE
```

## Code Smell Flags
- More than 2-3 problems per diff
- Change doesn't map to stated problem
- Same pattern repeated without extraction (discuss, don't mandate)
