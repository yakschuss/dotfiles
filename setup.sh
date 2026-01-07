#!/bin/bash
#
# Comprehensive Mac setup - one command, plug and play
#
# Usage:
#   ./setup.sh              # run for real
#   ./setup.sh --dry-run    # preview what would happen
#
# On a fresh Mac:
#   curl -fsSL https://raw.githubusercontent.com/yakschuss/dotfiles/master/setup.sh | bash
#

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "==> DRY RUN MODE - nothing will be changed"
  echo ""
fi

run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

# Check if command exists
has() {
  command -v "$1" &> /dev/null
}

# Check if directory exists
has_dir() {
  [[ -d "$1" ]]
}

echo "==> Checking Xcode CLI tools"
if ! xcode-select -p &> /dev/null; then
  echo "    Installing Xcode CLI tools..."
  run xcode-select --install
  echo "    Waiting for Xcode CLI tools installation..."
  if ! $DRY_RUN; then
    until xcode-select -p &> /dev/null; do sleep 5; done
  fi
else
  echo "    Already installed"
fi

echo ""
echo "==> Checking Homebrew"
if ! has brew; then
  echo "    Installing Homebrew..."
  if $DRY_RUN; then
    echo "[dry-run] /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
else
  echo "    Already installed"
fi

# Ensure brew is in path for rest of script
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo ""
echo "==> Installing Homebrew packages"
BREWFILE=$(cat <<'EOF'
# CLI essentials
brew "git"
brew "git-lfs"
brew "gh"
brew "mas"
brew "neovim"
brew "tmux"
brew "fzf"
brew "ripgrep"
brew "the_silver_searcher"
brew "jq"
brew "tree"
brew "reattach-to-user-namespace"

# Shell enhancements
brew "zsh-autosuggestions"
brew "zsh-vi-mode"

# Dev tools
brew "asdf"
brew "overmind"
brew "postgresql@14"
brew "yarn"
brew "imagemagick"

# Apps
cask "1password"
cask "claude"
cask "cursor"
cask "discord"
cask "docker"
cask "figma"
cask "firefox"
cask "google-chrome"
cask "iterm2"
cask "notion"
cask "obsidian"
cask "postgres-app"
cask "postman"
cask "slack"
cask "spotify"
cask "whatsapp"
cask "zoom"
EOF
)

if $DRY_RUN; then
  echo "[dry-run] brew bundle --file=- <<EOF"
  echo "$BREWFILE"
  echo "EOF"
else
  echo "$BREWFILE" | brew bundle --file=-
fi

echo ""
echo "==> Installing Mac App Store apps"
MAS_APPS=(
  "427515976"   # 3Hub
  "847496013"   # Deckset
  "1444383602"  # Goodnotes
  "1532419400"  # MeetingBar
  "419330170"   # Moom Classic
  "967805235"   # Paste
  "904280696"   # Things
  "497799835"   # Xcode
)

for app_id in "${MAS_APPS[@]}"; do
  if $DRY_RUN; then
    echo "[dry-run] mas install $app_id"
  else
    mas install "$app_id" || true
  fi
done

echo ""
echo "==> Setting up dotfiles (bare repo)"
if has_dir "$HOME/.dotfiles"; then
  echo "    Already cloned"
else
  echo "    Cloning dotfiles..."
  run git clone --bare https://github.com/yakschuss/dotfiles.git "$HOME/.dotfiles"
  if ! $DRY_RUN; then
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" checkout -f
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" config --local status.showUntrackedFiles no
  else
    echo "[dry-run] git --git-dir=\"\$HOME/.dotfiles/\" --work-tree=\"\$HOME\" checkout -f"
    echo "[dry-run] git --git-dir=\"\$HOME/.dotfiles/\" --work-tree=\"\$HOME\" config --local status.showUntrackedFiles no"
  fi
fi

echo ""
echo "==> Setting up zsh-git-prompt"
if has_dir "$HOME/zsh-git-prompt"; then
  echo "    Already cloned"
else
  echo "    Cloning zsh-git-prompt..."
  run git clone https://github.com/olivierverdier/zsh-git-prompt.git "$HOME/zsh-git-prompt"
fi

echo ""
echo "==> Setting up tmux plugin manager (tpm)"
if has_dir "$HOME/.tmux/plugins/tpm"; then
  echo "    Already installed"
else
  echo "    Cloning tpm..."
  run mkdir -p "$HOME/.tmux/plugins"
  run git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo ""
echo "==> Setting up vim plugin manager (minpac)"
if has_dir "$HOME/.vim/pack/minpac/opt/minpac"; then
  echo "    Already installed"
else
  echo "    Cloning minpac..."
  run mkdir -p "$HOME/.vim/pack/minpac/opt"
  run git clone https://github.com/k-takata/minpac.git "$HOME/.vim/pack/minpac/opt/minpac"
fi

echo ""
echo "==> Installing vim plugins"
if $DRY_RUN; then
  echo "[dry-run] nvim --headless -c 'PackUpdate' -c 'qa'"
else
  nvim --headless -c 'PackUpdate' -c 'qa' 2>/dev/null || true
fi

echo ""
echo "==> Setting up fzf keybindings"
if [[ -f "$HOME/.fzf.zsh" ]]; then
  echo "    Already configured"
else
  if $DRY_RUN; then
    echo "[dry-run] \$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish"
  else
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
  fi
fi

echo ""
echo "==> Configuring iTerm2 to use dotfiles"
if $DRY_RUN; then
  echo "[dry-run] defaults write com.googlecode.iterm2 PrefsCustomFolder -string '~/.config/iterm2'"
  echo "[dry-run] defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true"
else
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "~/.config/iterm2"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
  echo "    iTerm2 will load settings from ~/.config/iterm2"
fi

echo ""
echo "==> Configuring macOS defaults"
if $DRY_RUN; then
  echo "[dry-run] Setting keyboard, dock, finder preferences..."
else
  # Keyboard: fast key repeat
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Dock: autohide, reasonable size
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock tilesize -int 48

  # Finder: show extensions, path bar
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true

  # Disable press-and-hold for keys (enables key repeat everywhere)
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Save screenshots to Downloads
  defaults write com.apple.screencapture location -string "${HOME}/Downloads"

  # Avoid creating .DS_Store files on network or USB volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  # Restart affected apps
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
fi

echo ""
echo "==> Setting up asdf language versions"
if $DRY_RUN; then
  echo "[dry-run] asdf plugin add ruby"
  echo "[dry-run] asdf plugin add nodejs"
  echo "[dry-run] asdf install ruby latest"
  echo "[dry-run] asdf install nodejs latest"
  echo "[dry-run] asdf global ruby latest"
  echo "[dry-run] asdf global nodejs latest"
else
  # Source asdf for this script
  . "$(brew --prefix asdf)/libexec/asdf.sh"

  # Ruby
  if ! asdf plugin list | grep -q ruby; then
    asdf plugin add ruby
  fi
  if ! asdf list ruby 2>/dev/null | grep -q .; then
    asdf install ruby latest
    asdf global ruby latest
  fi

  # Node.js
  if ! asdf plugin list | grep -q nodejs; then
    asdf plugin add nodejs
  fi
  if ! asdf list nodejs 2>/dev/null | grep -q .; then
    asdf install nodejs latest
    asdf global nodejs latest
  fi
fi

echo ""
echo "==> Setting up SSH key"
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  echo "    SSH key already exists"
else
  if $DRY_RUN; then
    echo "[dry-run] ssh-keygen -t ed25519 -C \"jackschuss@gmail.com\" -N \"\" -f ~/.ssh/id_ed25519"
  else
    echo "    Generating new SSH key..."
    ssh-keygen -t ed25519 -C "jackschuss@gmail.com" -N "" -f "$HOME/.ssh/id_ed25519"
    echo ""
    echo "    Your public key (copied to clipboard):"
    cat "$HOME/.ssh/id_ed25519.pub"
    cat "$HOME/.ssh/id_ed25519.pub" | pbcopy
    echo ""
    echo "    Add it to GitHub: https://github.com/settings/keys"
  fi
fi

echo ""
echo "==> Authenticating with GitHub CLI"
if $DRY_RUN; then
  echo "[dry-run] gh auth login"
else
  if ! gh auth status &>/dev/null; then
    gh auth login
  else
    echo "    Already authenticated"
  fi
fi

echo ""
echo "==> Done!"
echo ""
echo "Final steps:"
echo "  1. Open a new terminal (or run: source ~/.zshrc)"
echo "  2. In tmux, press 'C-s I' to install tmux plugins"
echo "  3. Verify SSH key was added to GitHub"
echo "  4. Log into Mac App Store apps (Things, Paste, etc.)"
