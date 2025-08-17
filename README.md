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

## Networking

Outside the scope of this repository, we should already have a VPN setup and connected, and a firewall set of rules functioning as a kill-switch such that no traffic can reach outside our network via the LAN, thus forcing the traffic to transit the VPN.
