#!/bin/bash
set -euo pipefail

echo "==> Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

export PATH="$HOME/.local/bin:$PATH"

echo "==> Initializing dotfiles..."
chezmoi init --apply https://github.com/chrisRedwine/dotfiles.git

echo "==> Done! Dotfiles applied."
