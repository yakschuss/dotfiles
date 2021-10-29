export ZSH=/Users/jackschuss/.oh-my-zsh

ZSH_THEME="home-screen"

plugins=(zsh-autosuggestions git vi-mode osx colored-man-pages cp)

#vi-mode timeout is 1 ms
export KEYTIMEOUT=1

source $ZSH/oh-my-zsh.sh

_not_inside_tmux() { [[ -z "$TMUX" ]] }

ensure_tmux_is_running() {
  if _not_inside_tmux; then
    tat
  fi
}

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'

alias vim='nvim'
alias v='nvim'
alias grmerged='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -d'
alias grremote="git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -d"
alias gct='git checkout'
alias vlvl='nvim $(fzf)'
alias config='/usr/bin/git --git-dir=/Users/jackschuss/.dotfiles/ --work-tree=/Users/jackschuss'
alias gcplast='git log -1 --pretty=format:"%H" | pbcopy'
alias fixconflicts='nvim +Conflicted'
alias rdm='rake db:migrate'
alias rdr='rake db:rollback'
alias socks='ssh socks -D 2001 -N &'
alias xbrew='arch -x86_64 /usr/local/bin/brew'
alias abrew='arch -arm64 /opt/homebrew/bin/brew'
alias git='/opt/homebrew/bin/git'

source ~/zsh-git-prompt/zshrc.sh

eval "$(rbenv init -)"
# doesn't work with aliases
# eval "$(hub alias -s)"

export PATH="$HOME/.rbenv/bin/.bin:/usr/local/opt/go/libexec/bin:$(yarn global bin):$PATH"
# . $HOME/.asdf/asdf.sh

export PATH="$HOME/usr/local/opt/go/libexec/bin:$(yarn global bin):$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
#
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

ensure_tmux_is_running
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

