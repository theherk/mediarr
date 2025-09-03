# mediarr

Setup a tailored set of services including the following on a Synology NAS.

- [Sonarr](https://sonarr.tv/)
- [Radarr](https://radarr.video/)
- [Bazarr](https://www.bazarr.media/)
- [Lidarr](https://lidarr.audio/)
- [Audiobookshelf](https://www.audiobookshelf.org/)
- [Homarr](https://homarr.dev/)
- [Prowlarr](https://wiki.servarr.com/prowlarr)
- [qBittorrent](https://www.qbittorrent.org/)
- [Jellyfin](https://jellyfin.org/)
- [Jellyseerr](https://github.com/Fallenbagel/jellyseerr)
- [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr)

This is done with a single user, whose ID is given in [.env](.env). All services, use their expected default ports. Use bridge networking so we can reach other containers given there name.

## File Structure

```
~arr
├── .config
│   ├── sonarr
│   ├── radarr
│   ├── etc
│   └── ...
├── mediarr (this repository)
│   ├── .env
│   └── docker-compose.yml
/volume1/the-seas
├── torrents
│   ├── audiobooks
│   ├── books
│   ├── movies
│   ├── music
│   └── tv
└── media
    ├── audiobooks
    ├── books
    ├── movies
    ├── music
    └── tv
```

Each container uses this structure in a way that doesn't require remote path mapping. Use the following commands to create these directories and change the ownership.

    ./setup-directories.sh

We will use the hardlink pattern in our services to dimish some load on storage and traffic but moreso that torrents can remain in location and seeded indefinitely even after hardlinked into the media access locations.

The compose file is meant to be a simple as possible. We can assume that this user, `arr`, exists and has rights to the docker.sock.

## Configuration Backup and Restore

Two scripts are provided to backup and restore all service configurations:

### Backup Script (`backup-configs.sh`)

Creates timestamped tarballs of all service configurations:

```bash
./backup-configs.sh
```

**Features:**

- Backs up all service configs from `~/.config/`
- Includes `docker-compose.yml` and `.env` files (if present)
- Creates timestamped backups: `mediarr-configs_YYYYMMDD_HHMMSS.tar.gz`
- Automatically keeps only the 5 most recent backups
- Shows backup size and contents for verification

### Restore Script (`restore-configs.sh`)

Restores configurations from backup tarballs:

```bash
# List available backups
./restore-configs.sh --list

# Preview what would be restored (dry run)
./restore-configs.sh backups/mediarr-configs_20241215_143022.tar.gz --dry-run

# Restore from backup
./restore-configs.sh backups/mediarr-configs_20241215_143022.tar.gz
```

**Features:**

- Lists available backup files with timestamps and sizes
- Dry-run mode to preview changes without making them
- Safety confirmations before overwriting existing configs
- Warns if Docker services are running during restore
- Sets proper file ownership after restoration

**Best Practices:**

- Run backup before making major configuration changes
- Stop services (`docker-compose down`) before restoring
- Use dry-run mode first to verify restore contents
- Consider adding backup script to cron for regular backups

## inotify Configuration for Jellyfin

Jellyfin's real-time monitoring requires increased inotify limits on Synology NAS to prevent directory watcher errors. Create these scheduled tasks in DSM:

### Task 1: Increase max_user_watches

- **Task**: `inotify_watches`
- **User**: `root`
- **Command**: `sh -c '(sleep 90 && echo 204800 > /proc/sys/fs/inotify/max_user_watches)&'`
- **Schedule**: Run on boot

### Task 2: Increase max_user_instances

- **Task**: `inotify_instances`
- **User**: `root`
- **Command**: `sh -c '(sleep 90 && echo 512 > /proc/sys/fs/inotify/max_user_instances)&'`
- **Schedule**: Run on boot

These tasks increase the kernel limits needed for Jellyfin to monitor large media directories and detect new files in real-time.

## Synology Startup Configuration

For the `arr` user to have SSH access and services to start automatically on boot, create these scheduled tasks in DSM:

### Task 1: Enable SSH for arr user

- **Task**: `enable_ssh_arr`
- **User**: `root`
- **Command**: `sh -c '(sleep 30 && sed -i "s|arr:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):/sbin/nologin|arr:\1:\2:\3:\4:\5:/bin/sh|" /etc/passwd)&'`
- **Schedule**: Run on boot

### Task 2: Start mediarr services

- **Task**: `start_mediarr_services`
- **User**: `arr`
- **Command**: `sh -c '(sleep 60 && cd /var/services/homes/arr/mediarr && docker compose up -d)&'`
- **Schedule**: Run on boot

The first task enables SSH access by changing the shell from `/sbin/nologin` to `/bin/sh` for the `arr` user. The second task starts all Docker services after a delay to ensure the system is fully initialized.

## Quality Profile Management with Recyclarr

Recyclarr automatically syncs TRaSH Guide quality profiles and custom formats to Sonarr and Radarr:

### Setup

1. **Get API keys** from Sonarr (Settings → General → Security) and Radarr (Settings → General → Security)
2. **Add to `config/recyclarr/secrets.yml`**:
   ```yaml
   sonarr_base_url: http://sonarr:8989
   sonarr_apikey: your_sonarr_api_key
   radarr_base_url: http://radarr:7878
   radarr_apikey: your_radarr_api_key
   ```

### Load Profiles

```bash
# Start services first
docker compose up -d sonarr radarr

# Sync TRaSH Guide profiles (run once, then monthly)
docker compose run --rm recyclarr sync
```

This creates optimized quality profiles:
- **Sonarr**: WEB-1080p (prioritizes web releases, good audio, blocks low quality)
- **Radarr**: HD Bluray + WEB (prioritizes Bluray > WEB, comprehensive quality scoring)

## WireGuard Kernel Module Installation (Synology Required)

Synology NAS devices require a custom WireGuard kernel module for proper VPN container functionality:

### Install WireGuard SPK:

1. **Download the correct module** for your Synology model from [BlackVoid Club](https://www.blackvoid.club/wireguard-spk-for-your-synology-nas/)
2. **Follow their installation instructions** carefully for your specific DSM version and CPU architecture
3. **Reboot your NAS** after installation
4. **SSH as root** and run the startup script as instructed on their page
5. **Verify installation** by checking if WireGuard module is loaded:
   ```bash
   lsmod | grep wireguard
   ```

### TUN Module Startup Script:

VPN containers also require the TUN kernel module. Create a scheduled task in DSM:

- **Task**: `load_tun_module`
- **User**: `root`
- **Command**: `sh -c '(sleep 15 && insmod /lib/modules/tun.ko)&'`
- **Schedule**: Run on boot

This loads the TUN module needed for VPN tunnel functionality.

**Important Notes:**
- **Must reboot AND run startup script** - installation alone is not sufficient
- If upgrading DSM versions, **uninstall and reinstall** the WireGuard module
- Without this kernel module, Gluetun will cause system hangs and container management issues

## VPN Kill Switch Configuration

For secure torrenting with private trackers, the main Docker compose file includes VPN configuration that routes qBittorrent and Prowlarr through the VPN container:

```bash
echo "WIREGUARD_PRIVATE_KEY=your_private_key_here" >> .env
```

### How the Kill Switch Works

The VPN kill switch is built into the Docker configuration and doesn't require additional firewall rules:

#### Automatic Protection:
- **qBittorrent uses `network_mode: "service:gluetun"`** - all traffic must go through the VPN container
- **If Gluetun stops, qBittorrent loses internet access** - complete network isolation
- **Gluetun has internal firewall** (`FIREWALL=on`) that blocks non-VPN traffic
- **Other services use direct connections** - not affected by VPN issues

#### Verification:
```bash
# Check qBittorrent uses VPN IP (should show ProtonVPN IP)
docker exec qbittorrent  wget -qO- https://ipinfo.io/ip
docker exec gluetun wget -qO- https://ipinfo.io/ip

# Check host uses real IP (should show your real IP)
curl -s https://ipinfo.io/ip

# Test kill switch - stop VPN and verify qBittorrent loses internet
docker stop gluetun
docker exec qbittorrent  wget -qO- https://ipinfo.io/ip
docker start gluetun
```

## Troubleshooting

This troubleshooting guide was written in panicky haste, so it maybe incorrect in places.

### Synology DSM "System is getting ready" Hung on Boot

If DSM shows "System is getting ready" for extended periods (30+ minutes) after a reboot, especially following Docker/qBittorrent I/O issues:

#### Symptoms:
- DSM web interface shows "System is getting ready" indefinitely
- SSH access works but web UI won't load
- `docker compose logs` or `docker inspect` commands hang
- System logs show messages like:
  ```
  INFO: task qbittorrent-nox:19976 blocked for more than 120 seconds
  ```

#### Solution:
1. **SSH into the Synology** (this usually works even when web UI doesn't)
2. **Force complete the boot sequence**:
   ```bash
   sudo synobootseq --set-boot-done
   sudo synobootseq --is-ready  # Should now show "Boot done"
   ```
3. **Web interface should immediately become accessible**

#### Root Cause:
This occurs when:
- Docker containers (especially qBittorrent) create I/O deadlock
- System crashes or is force-rebooted during heavy I/O operations
- Boot state file doesn't get written properly during shutdown
- System remains stuck in "shutting down" state after reboot

### Preventing qBittorrent I/O Deadlock

To avoid system hangs caused by excessive torrent I/O on Synology with BTRFS:

#### Configure qBittorrent limits:
1. **Access qBittorrent Web UI** (port 8080)
2. **Options → Downloads**:
   - Global maximum number of connections: **100-200** (not unlimited)
   - Maximum active downloads: **3-5**
   - Maximum active torrents: **10**
3. **Options → Advanced**:
   - Disk cache: **32-64 MB**
   - Disk cache expiry: **60 seconds**

#### Add Docker resource limits to `docker-compose.yml`:
```yaml
qbittorrent:
  # ... existing configuration ...
  mem_limit: 1g
  cpus: '0.5'
  ulimits:
    nofile:
      soft: 4096
      hard: 8192
```

#### Consider filesystem alternatives:
- **BTRFS**: Poor performance with torrents due to Copy-on-Write overhead
- **EXT4**: Much better for heavy I/O workloads, faster recovery after crashes

### If Docker Commands Hang

When `docker ps`, `docker compose logs`, or similar commands hang indefinitely:

1. **Check for I/O wait**:
   ```bash
   uptime  # Look for high I/O wait percentages
   dmesg | tail -50  # Check for hung task warnings
   ```

2. **Force restart Docker/Container Manager**:
   ```bash
   sudo synopkg restart ContainerManager
   # If that hangs:
   sudo killall -9 dockerd containerd
   sudo synoservice --restart pkgctl-ContainerManager
   ```

3. **Last resort - Force reboot**:
   - Hold physical power button for 4 seconds (controlled shutdown)
   - If no response after 2 minutes, hold for 10+ seconds (force power off)
   - Wait 60 seconds before powering back on
   - After reboot, run `sudo synobootseq --set-boot-done` if needed

```bash
sudo cat /proc/flashcache/*/flashcache_stats
sudo dmsetup status | grep -i cache
```
