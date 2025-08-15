#!/bin/bash

# Restore script for mediarr configurations
# Restores configurations from a backup tarball

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo -e "${YELLOW}Usage: $0 <backup_file.tar.gz> [--dry-run]${NC}"
    echo -e "${YELLOW}       $0 --list${NC}"
    echo ""
    echo "Options:"
    echo "  <backup_file.tar.gz>  Path to the backup file to restore"
    echo "  --dry-run            Show what would be restored without making changes"
    echo "  --list               List available backup files"
    echo ""
    echo "Examples:"
    echo "  $0 backups/mediarr-configs_20241215_143022.tar.gz"
    echo "  $0 backups/mediarr-configs_20241215_143022.tar.gz --dry-run"
    echo "  $0 --list"
}

# Function to list available backups
list_backups() {
    echo -e "${GREEN}📋 Available backup files:${NC}"
    if ls backups/mediarr-configs_*.tar.gz 1> /dev/null 2>&1; then
        for backup in backups/mediarr-configs_*.tar.gz; do
            if [ -f "$backup" ]; then
                SIZE=$(du -h "$backup" | cut -f1)
                DATE=$(basename "$backup" | sed 's/mediarr-configs_\([0-9]\{8\}\)_\([0-9]\{6\}\)\.tar\.gz/\1 \2/' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\) \([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
                echo -e "  📦 ${backup} (${SIZE}) - ${DATE}"
            fi
        done
    else
        echo -e "${YELLOW}  No backup files found in backups/ directory${NC}"
    fi
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

# Handle --list option
if [ "$1" = "--list" ]; then
    list_backups
    exit 0
fi

# Get backup file and options
BACKUP_FILE="$1"
DRY_RUN=false

if [ "$2" = "--dry-run" ]; then
    DRY_RUN=true
fi

# Validate backup file
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Error: Backup file '$BACKUP_FILE' not found${NC}"
    echo ""
    list_backups
    exit 1
fi

# Verify it's a valid tar.gz file
if ! tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: '$BACKUP_FILE' is not a valid tar.gz file${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting mediarr configuration restore...${NC}"
echo -e "${YELLOW}📦 Backup file: $BACKUP_FILE${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
fi

# Show backup contents
echo -e "\n${YELLOW}📋 Backup contents:${NC}"
tar -tzf "$BACKUP_FILE" | head -20
TOTAL_FILES=$(tar -tzf "$BACKUP_FILE" | wc -l)
if [ "$TOTAL_FILES" -gt 20 ]; then
    echo -e "  ... and $((TOTAL_FILES - 20)) more files"
fi

# Ask for confirmation unless dry run
if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${YELLOW}⚠️  This will overwrite existing configuration files!${NC}"
    echo -e "${YELLOW}💡 It's recommended to stop services first: docker-compose down${NC}"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Restore cancelled${NC}"
        exit 0
    fi
fi

# Check if services are running
RUNNING_SERVICES=$(docker-compose ps -q 2>/dev/null | wc -l)
if [ "$RUNNING_SERVICES" -gt 0 ] && [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}⚠️  Warning: Docker services are currently running${NC}"
    echo -e "${YELLOW}💡 Consider stopping them first: docker-compose down${NC}"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Restore cancelled${NC}"
        exit 0
    fi
fi

# Perform the restore
echo -e "\n${GREEN}🔄 Restoring configurations...${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 Files that would be restored:${NC}"
    tar -tvf "$BACKUP_FILE"
else
    # Change to root directory for absolute path restoration
    cd /

    # Extract the backup
    if tar -xzf "$(realpath "$BACKUP_FILE")" 2>/dev/null; then
        echo -e "${GREEN}✅ Configurations restored successfully!${NC}"

        # Set proper ownership
        echo -e "${GREEN}🔐 Setting proper ownership...${NC}"
        if [ -d "${HOME}/.config" ]; then
            chown -R $(id -u):$(id -g) "${HOME}/.config"
        fi

        echo -e "\n${GREEN}🎉 Restore completed successfully!${NC}"
        echo -e "\n${YELLOW}📖 Next steps:${NC}"
        echo -e "   1. Review restored configurations"
        echo -e "   2. Start services: ${GREEN}docker-compose up -d${NC}"
        echo -e "   3. Check service logs: ${GREEN}docker-compose logs${NC}"

    else
        echo -e "${RED}❌ Error during restore${NC}"
        exit 1
    fi
fi

echo -e "\n${GREEN}✨ Restore process finished!${NC}"
