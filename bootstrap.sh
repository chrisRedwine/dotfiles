#!/bin/bash
set -euo pipefail

echo "==> Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

export PATH="$HOME/.local/bin:$PATH"

# Check if chezmoi is already initialized with THIS repo
if [ -d "$HOME/.local/share/chezmoi" ]; then
    # Check if it's pointed at the correct repo
    if chezmoi git remote get-url origin 2>/dev/null | grep -q "chrisRedwine/dotfiles"; then
        echo "==> Updating existing dotfiles..."
        chezmoi update
    else
        echo "==> WARNING: chezmoi already initialized with a different repo"
        echo "    Found: $(chezmoi git remote get-url origin 2>/dev/null || echo 'unknown')"
        echo "    Expected: chrisRedwine/dotfiles"
        echo ""
        echo "Choose an option:"
        echo "  1) Remove existing chezmoi and start fresh"
        echo "  2) Force reinitialize with this repo (keeps existing but switches)"
        echo "  3) Cancel"
        echo ""
        read -rp "Enter choice [1-3]: " choice

        case $choice in
            1)
                echo "==> Removing existing chezmoi..."
                rm -rf "$HOME/.local/share/chezmoi"
                echo "==> Initializing dotfiles..."
                chezmoi init --apply https://github.com/chrisRedwine/dotfiles.git
                ;;
            2)
                echo "==> Force reinitializing with this repo..."
                chezmoi init --apply https://github.com/chrisRedwine/dotfiles.git --force
                ;;
            3|*)
                echo "Cancelled."
                exit 0
                ;;
        esac
    fi
else
    echo "==> Initializing dotfiles..."
    chezmoi init --apply https://github.com/chrisRedwine/dotfiles.git
fi

echo "==> Done! Dotfiles applied."
