# Brave NTP Wallpaper Sync for Omarchy

Synchronizes Omarchy desktop wallpaper to Brave's New Tab Page background,
cropped to match the desktop region visible behind each Brave window.

**Features:**
- Each Brave window gets its own crop based on its position + monitor
- Multiple simultaneous NTP windows supported via per-tab CDP injection
- Multi-monitor with different scale factors (1.0x, 1.5x, 1.6x)
- Live updates when you move/resize a window
- Scratchpad workspace restored after sync
- Runs as a systemd user service — auto-starts with your session

## Quick Start

```bash
git clone https://github.com/your-username/brave-ntp-theme-sync ~/brave-ntp-theme-sync
cd ~/brave-ntp-theme-sync
./install.sh
```

Then open an NTP tab in Brave and test:

```bash
~/.local/bin/omarchy-brave-wallpaper-sync
```

## How It Works

```
Theme changes → hook → omarchy-brave-wallpaper-watch (systemd)
                                       │
                          polls geometry every 200ms (1s debounce)
                                       │
                          omarchy-brave-wallpaper-sync
                            ├─ generates crop per Brave window
                            └─ runs omarchy-brave-ntp-refresh
                                       │
                          omarchy-brave-ntp-refresh (CDP)
                            ├─ maps each NTP tab → Hyprland window
                            ├─ reads crop files from /tmp/
                            └─ injects data URLs via CDP JS eval
```

## Files

| File | Purpose |
|------|---------|
| `bin/omarchy-brave-ntp-crop` | Crop calculator (position → image region) |
| `bin/omarchy-brave-wallpaper-sync` | Orchestrator: crops + CDP |
| `bin/omarchy-brave-ntp-refresh` | CDP per-tab injection |
| `bin/omarchy-brave-wallpaper-watch` | Geometry poller + wallpaper watcher |
| `bin/omarchy-brave-tune` | Calibration tool for chrome height / offset |
| `bin/brave-origin-beta` | Fixed Brave wrapper (reads flags line-by-line) |
| `systemd/omarchy-brave-wallpaper-sync.service` | Systemd user service |
| `config/brave-origin-beta-flags.conf` | Brave flags (CDP port, extension) |
| `omarchy-hooks/theme-set` | Hook for omarchy theme changes |
| `install.sh` | One-command installer |

## Prerequisites

- **Omarchy** (Arch Linux + Hyprland)
- **Brave Origin Beta** (`brave-origin-beta` package)
- **CDP port 9222** enabled via `--remote-debugging-port=9222`
- **Python 3** with `websockets` package (`pip install websockets`)
- **ImageMagick** (`magick` or `convert` command)
- **inotifywait** (usually part of `inotify-tools`)

## Calibration

The chrome height (tab bar + address bar) is ~84px on a 1.6x system.
Tune it on yours:

```bash
# Measure chrome height:
omarchy-brave-tune height 84   # start here
omarchy-brave-tune height 86   # if wallpaper is too HIGH in NTP
omarchy-brave-tune height 82   # if too LOW

# Fine-tune position:
omarchy-brave-tune offset 5    # shift image down 5px
omarchy-brave-tune offset -3   # shift image up 3px
```

Values are **logical pixels** (automatically scaled by DPR).

## Architecture Notes

### Physical vs logical pixels
- `monitor["width"]` from `hyprctl -j monitors` is **physical** (confirmed by grim)
- Window `at`/`size` from `hyprctl -j clients` is **logical** (scaled by monitor scale)
- swaybg renders wallpaper at **physical** resolution using `cover` mode

### Brave preference fights
Brave holds Preferences in memory and periodically overwrites the file on disk.
The system works around this by:
1. Using a **static filename** for Preferences fallback
2. Injecting **data URLs** via CDP (bypasses file caching entirely)

### Limitations
- NTP tab reloads require a manual trigger (move/resize window)
- Windows of identical size on the same monitor get the same crop
- Requires `--remote-debugging-port=9222` flag at Brave startup

## License

MIT
