# Task: Set up Brave NTP Theme Sync on an Omarchy machine

## What this is

Synchronizes Omarchy desktop wallpaper to Brave's New Tab Page background,
cropped per-window to match the desktop region visible behind each Brave window.

Supports multiple monitors, HiDPI scaling, multiple NTP windows, and live
updates via CDP injection. Runs as a systemd user service.

## Steps

### 1. Install prerequisites

```bash
sudo pacman -S brave-origin-beta python-websockets imagemagick inotify-tools
pip install websockets
```

### 2. Clone and install

```bash
git clone <repo-url> ~/brave-ntp-theme-sync
cd ~/brave-ntp-theme-sync
./install.sh
```

### 3. Set up Brave

Make sure Brave is launched with `--remote-debugging-port=9222`. The install
script creates `~/.config/brave-origin-beta-flags.conf` with:

```
--load-extension=/home/<username>/.local/share/omarchy/default/chromium/extensions/copy-url
--remote-debugging-port=9222
--remote-allow-origins=*
```

The system wrapper at `/usr/bin/brave-origin-beta` passes flags wrong.
Make sure `~/.local/bin/brave-origin-beta` (the fixed wrapper) is used instead
— the install script places it there.

### 4. Verify

```bash
# Open an NTP tab in Brave
omarchy-brave-wallpaper-sync
```

You should see output like:
```
Syncing Omarchy wallpaper: /home/.../background.png
Found 2 Brave window(s)
Generated crop for window 0x55e2e5...
Found 2 NTP tab(s) and 2 Brave window(s)
  window at [0, 26] (1 tab(s))
  window at [1920, 26] (1 tab(s))
  Restored eDP-2 to workspace 1
  Injected into tab 9E2E9678...
```

### 5. Calibrate alignment

If the NTP wallpaper doesn't line up with the desktop behind the window,
adjust the chrome height:

```bash
omarchy-brave-tune height 86   # image too HIGH → increase
omarchy-brave-tune height 82   # image too LOW → decrease
```

Values are in logical pixels. The default (84) was measured via
`window.outerHeight - window.innerHeight` on a 1.6x scaled system.

Fine vertical offset:
```bash
omarchy-brave-tune offset 5    # shift image down
omarchy-brave-tune offset -3   # shift image up
```

## Files installed

| Path | Purpose |
|------|---------|
| `~/.local/bin/omarchy-brave-ntp-crop` | Crop calculator |
| `~/.local/bin/omarchy-brave-wallpaper-sync` | Orchestrator |
| `~/.local/bin/omarchy-brave-ntp-refresh` | CDP injection |
| `~/.local/bin/omarchy-brave-wallpaper-watch` | Geometry poller |
| `~/.local/bin/omarchy-brave-tune` | Calibration tool |
| `~/.local/bin/brave-origin-beta` | Fixed Brave wrapper |
| `~/.config/systemd/user/omarchy-brave-wallpaper-sync.service` | Systemd service |
| `~/.config/omarchy/hooks/theme-set` | Theme change hook |
| `~/.config/brave-origin-beta-flags.conf` | Brave flags |

## How it works

1. **Systemd service** runs `omarchy-brave-wallpaper-watch`
2. Every 200ms it polls Brave window geometry (address + position + size)
3. When geometry stays stable for 1 second (5 polls), it triggers a sync
4. **Sync** generates a unique crop per Brave window using ImageMagick
5. **CDP refresh** maps NTP tabs to windows via `Target.activateTarget`
   and injects the correct crop as a data URL into each tab's DOM
6. Original workspaces per monitor are restored after the focus cycle
7. The theme hook runs the sync whenever Omarchy changes the wallpaper

## Key technical details

- `monitor["width"]` from `hyprctl -j monitors` is **physical pixels**
- Window `at`/`size` is **logical pixels** (multiply by scale for physical)
- swaybg renders wallpaper in `cover` mode on the physical monitor buffer
- Data URLs bypass Brave's file cache (chrome://custom-wallpaper/ caches aggressively)
- Scratchpad (`special:scratchpad`) windows are tracked by address and restored
- Window addresses are NOT used as filenames — size-keyed filenames avoid stale crops

## Troubleshooting

**"Failed to list tabs: Connection refused"** → Brave not running with CDP port.
Verify the wrapper is being used and port 9222 is listening:
`ss -tlnp | grep 9222`

**Extension loading error** → The `~` in `--load-extension=~/.local/...` is
NOT expanded by Brave. The install script puts the absolute path.

**Walls look glitched/grayscale** → The `-define png:color-type=6` flag in
the crop script forces sRGB output. Verify with `identify /tmp/omarchy-brave-crops/*.png`.

**Multiple NTP windows show the same crop** → Only happens when windows
have identical sizes on the same monitor. The focus cycle distinguishes
different-sized windows reliably.
