#!/usr/bin/env bash

set -e

mkdir -p ~/.config/{audiobookshelf,bazarr,cleanuparr,gluetun,jellyfin,jellyseerr,homarr,lidarr,prowlarr,qbittorrent,radarr,recyclarr,sonarr}
mkdir -p ~/.config/homarr/{configs,icons,data}
mkdir -p ~/.config/audiobookshelf/metadata
sudo mkdir -p /volume1/the-seas/media/{audiobooks,books,movies,music,tv}
sudo mkdir -p /volume1/the-seas/torrents/{audiobooks,books,movies,music,tv}
sudo chown -R 1028:100 /volume1/the-seas
chown -R 1028:100 ~/.config/{audiobookshelf,bazarr,gluetun,jellyfin,jellyseerr,homarr,lidarr,prowlarr,qbittorrent,radarr,recyclarr,sonarr}
