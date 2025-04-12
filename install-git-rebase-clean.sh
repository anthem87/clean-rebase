#!/usr/bin/env bash

set -e

GIT_TOOLS_DIR="$HOME/.git-tools"
SCRIPT_PATH="$GIT_TOOLS_DIR/git-rebase-clean"
SCRIPT_SOURCE="$(dirname "$0")/git-rebase-clean"

echo "=== Installing git-rebase-clean (Bash version) ==="

# 1. Create ~/.git-tools if it doesn't exist
if [ ! -d "$GIT_TOOLS_DIR" ]; then
    mkdir -p "$GIT_TOOLS_DIR"
    echo "Created directory: $GIT_TOOLS_DIR"
else
    echo "Directory already exists: $GIT_TOOLS_DIR"
fi

# 2. Read bash script from external file
if [ ! -f "$SCRIPT_SOURCE" ]; then
    echo "ERROR: Could not find $SCRIPT_SOURCE"
    exit 1
fi

cp "$SCRIPT_SOURCE" "$SCRIPT_PATH"
echo "Script copied to: $SCRIPT_PATH"

# 3. Make it executable
chmod +x "$SCRIPT_PATH"
echo "Marked as executable."

# 4. Add to PATH in ~/.bashrc if not already present
if ! grep -Fxq 'export PATH="$HOME/.git-tools:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.git-tools:$PATH"' >> "$HOME/.bashrc"
    echo "$GIT_TOOLS_DIR added to PATH in ~/.bashrc."

    if [[ "$0" == "bash" || "$0" == "-bash" ]]; then
        echo "Sourcing ~/.bashrc to update PATH..."
        source "$HOME/.bashrc"
    else
        echo "⚠️  Run 'source ~/.bashrc' or restart your terminal to apply changes."
    fi
else
    echo "$GIT_TOOLS_DIR is already in PATH in ~/.bashrc."
fi

echo ""
echo "Installation complete!"
echo "You can now run: git rebase-clean"
