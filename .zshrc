_not_inside_tmux() { [[ -z "$TMUX" ]] }

ensure_tmux_is_running() {
  if _not_inside_tmux; then
    tat
  fi
}

rg_vim() { rg -l "$1" | xargs -o nvim; }
#
# rg_vim() {
#   rg --files | fzf --preview 'bat --style=numbers --color=always {}' | xargs -o nvim
# }

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*" --glob "!node_modules/*"'

export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

alias vim='nvim'
alias v='nvim'
alias grmerged='git branch --merged | egrep -v "(^\*|master|dev|main)" | xargs git branch -d'
alias grremote="git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -d"
alias gct='git checkout'
alias vlvl='nvim $(fzf)'
alias config='/usr/bin/git --git-dir=/Users/jschuss/.dotfiles/ --work-tree=/Users/jschuss'
alias gcplast='git log -1 --pretty=format:"%H" | pbcopy'
alias fixconflicts='nvim +Conflicted'
alias rdm='rake db:migrate'
alias rdms='rake db:migrate:status'
alias rdr='rake db:rollback'
alias git='/opt/homebrew/bin/git'
alias linter='bundle exec rubocop -A && bundle exec rspec --format documentation --exclude "spec/features/**/*" && bundle exec rspec spec/features --format documentation'
alias byeconnect='overmind connect web'
alias noted='~/noted/noted'
alias n='~/noted/noted'
alias icloud='~/Library/Mobile\ Documents/com~apple~CloudDocs/'
alias python="/opt/homebrew/bin/python3"
alias reef="cd ~/Brightline/reef"
alias rgvim="rg_vim"
alias ss='pngpaste "./screenshot_$(date +%Y%m%d_%H%M%S).png"'
alias openall="vim -o $(git status --porcelain | awk '/^ M|^??/ {print $2}')"

export BROWSER="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"

source ~/zsh-git-prompt/zshrc.sh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

PROMPT='% 🤔 😂 %~%b $(git_super_status)
% %{$fg[blue]%} (Jack)→ '

export PATH="$HOME/.asdf/shims:$HOME/bin:$HOME/.bin:$HOME/usr/local/opt/go/libexec/bin:$(yarn global bin):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin"

ensure_tmux_is_running
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


. /opt/homebrew/opt/asdf/libexec/asdf.sh


. "$HOME/.local/bin/env"
