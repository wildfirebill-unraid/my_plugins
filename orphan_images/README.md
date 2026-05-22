# Docker Orphan Images Cleaner

A plugin for Unraid 6.9+ / 7.x that removes unused (orphan) Docker images on a configurable schedule.

## Features

- **Dangling images** — removes `<none>:<none>` images with no repository or tag
- **Unused images** — removes images not referenced by any container (running or stopped)
- **Preserve tagged images** — skip images that still carry a `repo:tag` label
- **Scheduling** — hourly, daily (3 AM), weekly, monthly, custom cron, or manual only
- **Force removal** — uses `docker rmi -f` to override warnings
- **Build cache prune** — cleans the Docker build cache after each run
- **Configurable log retention** — auto-rotate or keep all
- **Web UI** — full settings page under **Settings → Docker Orphan Cleaner**

## Files

| File | Purpose |
|---|---|
| `orphan.images.plg` | Unraid plugin — install via Plugins → Install Plugin |
| `cleanup-orphan-images.sh` | Standalone script — works on any Linux with Docker |

## Installation (Unraid)

1. Go to **Plugins → Install Plugin** → paste the URL below or browse for the file
2. The settings page appears under **Settings → Docker Orphan Cleaner**
3. If it doesn't show up immediately, refresh the browser page or restart the webUI:
   ```
   /etc/rc.d/rc.nginx restart
   ```

Or install directly from URL:
```
https://raw.githubusercontent.com/wildfirebill-unraid/my_plugins/main/orphan_images/orphan.images.plg
```

## Standalone Script Usage

```bash
bash cleanup-orphan-images.sh [options]
```

| Option | Description |
|---|---|
| `--dangling` | Remove `<none>:<none>` images (default: on) |
| `--unused` | Remove images not used by any container |
| `--force` | Use `docker rmi -f` |
| `--leave-tagged` | Skip images with a `repo:tag` |
| `--log FILE` | Log file path (default: `/var/log/orphan-images.log`) |
| `--dry-run` | Preview what would be removed without actually removing |
| `--help` | Show usage |

### Examples

```bash
# Preview what would be cleaned
bash cleanup-orphan-images.sh --dangling --unused --dry-run

# Remove dangling + unused images, force removal
bash cleanup-orphan-images.sh --dangling --unused --force

# Remove dangling images only (default)
bash cleanup-orphan-images.sh

# Remove unused images, keep tagged ones
bash cleanup-orphan-images.sh --unused --leave-tagged
```

## Schedule via cron (standalone mode)

```cron
# Run daily at 3 AM
0 3 * * * /path/to/cleanup-orphan-images.sh --dangling --unused
```

## Configuration File

Settings are stored in `/boot/config/plugins/orphan.images.cfg` and are applied automatically via the web UI.

## Logs

- Plugin: `/var/log/orphan.images.log`
- Standalone: configurable via `--log` (default `/var/log/orphan-images.log`)
