#!/bin/bash
#
# Minimal dotfiles setup - one command, plug and play
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
brew "neovim"
brew "tmux"
brew "fzf"
brew "ripgrep"
brew "jq"
brew "reattach-to-user-namespace"

# Shell enhancements
brew "zsh-autosuggestions"
brew "zsh-vi-mode"

# Version management
brew "asdf"

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
echo "==> Done!"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal (or run: source ~/.zshrc)"
echo "  2. In tmux, press 'C-s I' to install tmux plugins"
echo "  3. Generate SSH key:"
echo "     ssh-keygen -t ed25519 -C \"jackschuss@gmail.com\""
echo "     cat ~/.ssh/id_ed25519.pub | pbcopy"
echo "     # Then add to GitHub: https://github.com/settings/keys"
