# modify the prompt to contain git branch name if applicable
# function battery_charge() {
#   ~/.bin/batcharge.py
# }

MODE_INDICATOR="VI-MODE"

PS1='% 🤔 😂 %~%b $(git_super_status) $(vi_mode_prompt_info)
% %{$fg[blue]%} (Jack)→ '

# RPROMPT=$(battery_charge)

