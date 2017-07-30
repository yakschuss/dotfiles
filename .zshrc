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


alias vim='nvim'
alias v='nvim'
alias imgresize="convert -strip -interlace Plane -gaussian-blur 0.05 -quality 85%"
alias grmerged='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -d'
alias grremote="git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -d"
alias att='tmux a -t'
alias rake='bundle exec rake'
alias gct='git checkout'
alias be='bundle exec'
alias vlvl='nvim $(fzf)'
alias t="todolist"
alias tp="todolist list by project"
alias config='/usr/bin/git --git-dir=/Users/jackschuss/.dotfiles/ --work-tree=/Users/jackschuss'
alias gcplast='git log -1 --pretty=format:"%H" | pbcopy'
alias fzt='nvim $(fzf-tmux)'
alias rspec='bundle exec rspec'
alias fixconflicts='nvim +Conflicted'
alias rdm='rake db:migrate'
alias rdms='rake db:migrate:status'
alias rdr='rake db:rollback'

source ~/zsh-git-prompt/zshrc.sh

eval "$(rbenv init -)"
# doesn't work with aliases
# eval "$(hub alias -s)"

export PATH="$HOME/.bin:/usr/local/opt/go/libexec/bin:/Users/jackschuss/.gem/ruby/2.3.0/bin:/Users/jackschuss/.gem/ruby/2.4.0/bin:$(yarn global bin):$PATH"

ensure_tmux_is_running
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
