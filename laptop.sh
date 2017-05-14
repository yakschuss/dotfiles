echo "running thoughtbot laptop script"

curl --remote-name https://raw.githubusercontent.com/thoughtbot/laptop/master/mac
less mac
sh mac 2>&1 | tee ~/laptop.log


echo "cloning in dotfiles"

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
git clone git@github.com:yakschuss/dotfiles.git

echo "backing up old dotfiles"

mkdir -p .config-backup && \
  config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
  xargs -I{} mv {} .config-backup/{}

config checkout

config config --local status.showUntrackedFiles no

echo "installing apps"

chmod +x ./cask-installs.sh
./cask-installs.sh


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

echo "please copy ssh key to github"

cat ~/.ssh/id_rsa.pub | pbcopy



