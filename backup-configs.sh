#!/bin/bash

# Backup script for mediarr configurations
# Creates a timestamped tarball of all service configurations
# Designed to run from home directory where configs are synced

set -e

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mediarr-configs_${TIMESTAMP}.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting mediarr configuration backup...${NC}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

echo -e "${YELLOW}📦 Creating backup: ${BACKUP_NAME}${NC}"

# Create array of files/directories to backup
BACKUP_ITEMS=()

# Add docker files if they exist in current directory
if [ -f "docker-compose.yml" ]; then
    BACKUP_ITEMS+=("docker-compose.yml")
    echo -e "  ✅ Including docker-compose.yml"
fi

if [ -f ".env" ]; then
    BACKUP_ITEMS+=(".env")
    echo -e "  ✅ Including .env"
fi

# Add service configs that exist
SERVICES=(sonarr radarr bazarr lidarr audiobookshelf homarr prowlarr qbittorrent jellyfin jellyseerr cleanuparr)

for service in "${SERVICES[@]}"; do
    CONFIG_PATH=".config/${service}"
    if [ -d "${CONFIG_PATH}" ]; then
        BACKUP_ITEMS+=("${CONFIG_PATH}")
        echo -e "  ✅ Including ${service} config"
    else
        echo -e "  ⚠️  Skipping ${service} (directory not found)"
    fi
done

# Check if we have anything to backup
if [ ${#BACKUP_ITEMS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No files found to backup${NC}"
    exit 1
fi

# Create the backup
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

echo -e "${YELLOW}🔄 Creating tarball...${NC}"

if tar -czf "${BACKUP_PATH}" "${BACKUP_ITEMS[@]}" 2>/dev/null; then
    echo -e "${GREEN}✅ Backup created successfully!${NC}"

    # Get backup size
    BACKUP_SIZE=$(du -h "${BACKUP_PATH}" | cut -f1)

    echo -e "${GREEN}📁 Backup location: ${BACKUP_PATH}${NC}"
    echo -e "${GREEN}📏 Backup size: ${BACKUP_SIZE}${NC}"

    # List contents for verification
    echo -e "\n${YELLOW}📋 Backup contents:${NC}"
    tar -tzf "${BACKUP_PATH}" | head -20

    TOTAL_FILES=$(tar -tzf "${BACKUP_PATH}" | wc -l)
    if [ "${TOTAL_FILES}" -gt 20 ]; then
        echo -e "  ... and $((TOTAL_FILES - 20)) more files"
    fi

else
    echo -e "${RED}❌ Error creating backup${NC}"
    echo -e "${RED}🔍 Backup items that failed:${NC}"
    for item in "${BACKUP_ITEMS[@]}"; do
        if [ ! -e "${item}" ]; then
            echo -e "${RED}  Missing: ${item}${NC}"
        fi
    done
    exit 1
fi

# Optional: Keep only last 5 backups
BACKUP_COUNT=$(find "${BACKUP_DIR}" -name "mediarr-configs_*.tar.gz" 2>/dev/null | wc -l)
if [ "${BACKUP_COUNT}" -gt 5 ]; then
    echo -e "${YELLOW}🧹 Cleaning up old backups (keeping 5 most recent)...${NC}"
    find "${BACKUP_DIR}" -name "mediarr-configs_*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | \
        sort -rn | tail -n +6 | cut -d' ' -f2- | xargs rm -f 2>/dev/null || true
fi

echo -e "${GREEN}🎉 Backup completed successfully!${NC}"

# Show restore instructions
echo -e "\n${YELLOW}📖 To restore from backup:${NC}"
echo -e "   tar -xzf ${BACKUP_PATH}"
echo -e "   # Then restart docker services in the mediarr directory"
