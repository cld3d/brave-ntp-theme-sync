#!/bin/bash
# Install Brave NTP Theme Sync for Omarchy
# Run: ./install.sh
# This symlinks scripts into ~/.local/bin and installs systemd service.

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USERNAME="${USER:-$(whoami)}"
HOME_DIR="$HOME"

echo "Installing Brave NTP Theme Sync for Omarchy..."

# 1. Create directories
mkdir -p "$HOME_DIR/.local/bin"
mkdir -p "$HOME_DIR/.config/omarchy/hooks"
mkdir -p "$HOME_DIR/.config/systemd/user"

# 2. Symlink scripts into ~/.local/bin
for script in "$REPO_DIR/bin/"*; do
    name=$(basename "$script")
    dest="$HOME_DIR/.local/bin/$name"
    if [[ -f $dest && ! -L $dest ]]; then
        echo "  WARNING: $dest exists and is not a symlink. Backing up to ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi
    ln -sf "$script" "$dest"
    chmod +x "$script"
    echo "  Installed $name"
done

# 3. Copy systemd service (must be regular file, not symlink)
cp "$REPO_DIR/systemd/omarchy-brave-wallpaper-sync.service" "$HOME_DIR/.config/systemd/user/"
echo "  Installed systemd service"

# 4. Install theme hook
HOOK_SRC="$REPO_DIR/omarchy-hooks/theme-set"
HOOK_DEST="$HOME_DIR/.config/omarchy/hooks/theme-set"
if [[ ! -f $HOOK_DEST ]]; then
    cp "$HOOK_SRC" "$HOOK_DEST"
    chmod +x "$HOOK_DEST"
    echo "  Installed theme hook"
else
    echo "  Theme hook exists at $HOOK_DEST (skipped, merge manually from $HOOK_SRC)"
fi

# 5. Copy flags config template
FLAGS_DEST="$HOME_DIR/.config/brave-origin-beta-flags.conf"
if [[ ! -f $FLAGS_DEST ]]; then
    # Replace placeholder username
    sed "s|YOUR_USERNAME|$USERNAME|g" "$REPO_DIR/config/brave-origin-beta-flags.conf" > "$FLAGS_DEST"
    echo "  Created $FLAGS_DEST"
else
    echo "  $FLAGS_DEST exists (skipped)"
fi

# 6. Enable and start the service
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now omarchy-brave-wallpaper-sync.service 2>/dev/null || \
    systemctl --user enable omarchy-brave-wallpaper-sync.service
echo "  Enabled systemd service"

# 7. Verify
echo ""
echo "Installation complete!"
echo ""
echo "To verify:"
echo "  systemctl --user status omarchy-brave-wallpaper-sync.service"
echo ""
echo "To calibrate the wallpaper alignment:"
echo "  omarchy-brave-tune height 84"
echo ""
echo "To check logs:"
echo "  journalctl --user -u omarchy-brave-wallpaper-sync -n 20 --no-pager"
