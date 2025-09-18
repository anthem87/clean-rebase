#!/usr/bin/env bash

# install-git-rebase-clean.sh
# Installs git-rebase-clean v2.0.0 into ~/.git-tools

set -euo pipefail

GIT_TOOLS_DIR="$HOME/.git-tools"
SCRIPT_PATH="$GIT_TOOLS_DIR/git-rebase-clean"
VERSION="2.0.0"
REPO_URL="https://raw.githubusercontent.com/anthem87/clean-rebase/v${VERSION}"

echo "=== Installing git-rebase-clean v${VERSION} ==="

# Create directory
mkdir -p "$GIT_TOOLS_DIR"

# Download the v2.0.0 script
echo "Downloading git-rebase-clean v${VERSION}..."
if command -v curl &>/dev/null; then
  curl -fsSL "${REPO_URL}/git-rebase-clean" -o "$SCRIPT_PATH" || {
    echo "Error: Failed to download. Check your connection and the URL."
    exit 1
  }
elif command -v wget &>/dev/null; then
  wget -q "${REPO_URL}/git-rebase-clean" -O "$SCRIPT_PATH" || {
    echo "Error: Failed to download. Check your connection and the URL."
    exit 1
  }
else
  echo "Error: Neither curl nor wget found. Please install one of them."
  exit 1
fi

# Make executable
chmod +x "$SCRIPT_PATH"

# Check if PATH needs updating
if [[ ":$PATH:" != *":$GIT_TOOLS_DIR:"* ]]; then
  # Detect shell config file
  if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
  elif [ -n "${BASH_VERSION:-}" ] || [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
  else
    SHELL_CONFIG="$HOME/.profile"
  fi
  
  # Add to PATH
  echo '' >> "$SHELL_CONFIG"
  echo '# Added by git-rebase-clean installer' >> "$SHELL_CONFIG"
  echo 'export PATH="$HOME/.git-tools:$PATH"' >> "$SHELL_CONFIG"
  
  echo ""
  echo "Added $GIT_TOOLS_DIR to PATH in $SHELL_CONFIG"
  echo "Please restart your shell or run: source $SHELL_CONFIG"
else
  echo "$GIT_TOOLS_DIR is already in PATH"
fi

# Verify installation
if [ -f "$SCRIPT_PATH" ]; then
  # Check it's not empty
  if [ -s "$SCRIPT_PATH" ]; then
    echo ""
    echo "✓ Installation complete!"
    echo "✓ Version: $VERSION"
    echo "✓ Location: $SCRIPT_PATH"
    echo ""
    echo "Usage: git rebase-clean --help"
  else
    echo "✗ Error: Downloaded file is empty!"
    exit 1
  fi
else
  echo "✗ Installation failed!"
  exit 1
fi