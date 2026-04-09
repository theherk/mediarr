#!/usr/bin/env bash

set -e

DEMO_ROOT="$(cd "$(dirname "$0")" && pwd)/demo"

echo "Creating demo directory tree under ${DEMO_ROOT} ..."

mkdir -p "${DEMO_ROOT}/config"/{bazarr,jellyfin,seerr,prowlarr,qbittorrent,radarr,recyclarr,sonarr}
mkdir -p "${DEMO_ROOT}/config/homarr"/{configs,icons,data}
mkdir -p "${DEMO_ROOT}/data/torrents"/{movies,tv}
mkdir -p "${DEMO_ROOT}/media"/{movies,tv}

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "${DEMO_ROOT}/config/recyclarr/recyclarr.yml" ]; then
	cat >"${DEMO_ROOT}/config/recyclarr/recyclarr.yml" <<'EOF'
sonarr:
  web-1080p:
    base_url: !secret sonarr_base_url
    api_key: !secret sonarr_api_key
    quality_definition:
      type: series
    quality_profiles:
      - trash_id: 72dae194fc92bf828f32cde7744e51a1
        reset_unmatched_scores:
          enabled: true
    custom_format_groups:
      add:
        - trash_id: 158188097a58d7687dee647e04af0da3

radarr:
  hd-bluray-web:
    base_url: !secret radarr_base_url
    api_key: !secret radarr_api_key
    quality_definition:
      type: movie
    quality_profiles:
      - trash_id: d1d67249d3890e49bc12e275d989a7e9
        reset_unmatched_scores:
          enabled: true
    custom_format_groups:
      add:
        - trash_id: f8bf8eab4617f12dfdbd16303d8da245
EOF
fi

if [ ! -f "${DEMO_ROOT}/config/recyclarr/secrets.yml" ]; then
	cat >"${DEMO_ROOT}/config/recyclarr/secrets.yml" <<'EOF'
sonarr_base_url: http://sonarr:8989
sonarr_apikey: PASTE_SONARR_API_KEY_HERE
radarr_base_url: http://radarr:7878
radarr_apikey: PASTE_RADARR_API_KEY_HERE
EOF
	echo "Created ${DEMO_ROOT}/config/recyclarr/secrets.yml — edit with your API keys."
fi

echo "Done. Start the demo stack with:"
echo "  podman-compose --env-file .env.demo -f docker-compose.demo.yml up -d"
