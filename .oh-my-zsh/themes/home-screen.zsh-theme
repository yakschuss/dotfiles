# modify the prompt to contain git branch name if applicable
function battery_charge() {
  ~/.bin/batcharge.py
}

MODE_INDICATOR="NORMAL"

PS1='% 🤔 😂 %~%b $(git_super_status) $(vi_mode_prompt_info)
% %{$fg[blue]%} → '

RPROMPT=$(battery_charge)

