#!/bin/sh
set -e
set -o pipefail

xcode-select --install

echo "installing oh my zsh"

sh -c "$(curl -fsSL
https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "cloning in dotfiles"

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
git clone git@github.com:yakschuss/dotfiles.git

config config --local status.showUntrackedFiles no

echo "installing apps"

./bootstrap

echo "generating ssh key"

ssh-keygen -t rsa -b 4096 -C "jackschuss@gmail.com"

echo "starting ssh agent"

eval "$(ssh-agent -s)"

cat << EOF >> ~/.ssh/config
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
EOF

ssh-add -K ~/.ssh/id_rsa

echo "please copy ssh key to github, in your clipboard"

cat ~/.ssh/id_rsa.pub | pbcopy

if [ ! -d ~/.asdf ];then
  echo "-----> Install asdf-vm"
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf
  cd ~/.asdf
  git checkout "$(git describe --abbrev=0 --tags)"

  source ~/.asdf/asdf.sh

  # Install node
  asdf plugin-add nodejs
  bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
  asdf install nodejs 8.12.0

  # Install ruby
  asdf plugin-add ruby
  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(/usr/local/bin/brew --prefix openssl) --with-readline-dir=$(/usr/local/bin/brew --prefix readline)"
  arch -x86_64 asdf install ruby 2.7.2
  asdf global ruby 2.6.6
fi

# Install vim plugins
vim -c ':silent !echo' -c ':PackUpdate' -c ':qa!'

echo 'All done!'


