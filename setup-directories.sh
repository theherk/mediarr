#!/usr/bin/env bash

set -e

mkdir -p ~/.config/{sonarr,radarr,bazarr,lidarr,audiobookshelf,homarr,prowlarr,qbittorrent,jellyfin,jellyseerr}
mkdir -p ~/.config/homarr/{configs,icons,data}
mkdir -p ~/.config/audiobookshelf/metadata
sudo mkdir -p /volume1/the-seas/media/{audiobooks,movies,music,tv}
sudo mkdir -p /volume1/the-seas/torrents/{audiobooks,movies,music,tv}
sudo chown -R 1028:100 /volume1/the-seas
chown -R 1028:100 ~/.config/{sonarr,radarr,bazarr,lidarr,audiobookshelf,homarr,prowlarr,qbittorrent,jellyfin,jellyseerr}
