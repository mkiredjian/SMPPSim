#!/bin/bash
#
# SMPPSim CentOS Uninstall Script
#
# This script removes SMPPSim from the system
# Run with sudo: sudo bash uninstall.sh
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/smppsim"
SERVICE_USER="smppsim"
SERVICE_NAME="smppsim"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}SMPPSim Uninstall Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Confirmation prompt
echo -e "${RED}WARNING: This will remove SMPPSim and all its data!${NC}"
echo -e "Installation directory: $INSTALL_DIR"
echo -e "Service user: $SERVICE_USER"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${GREEN}Uninstall cancelled.${NC}"
    exit 0
fi

echo ""

# Step 1: Stop and disable service
echo -e "${YELLOW}[1/5] Stopping and disabling service...${NC}"
if systemctl is-active --quiet $SERVICE_NAME; then
    systemctl stop $SERVICE_NAME
    echo -e "${GREEN}✓ Service stopped${NC}"
fi

if systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
    systemctl disable $SERVICE_NAME
    echo -e "${GREEN}✓ Service disabled${NC}"
fi

# Step 2: Remove systemd service file
echo -e "${YELLOW}[2/5] Removing systemd service file...${NC}"
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    rm -f "/etc/systemd/system/$SERVICE_NAME.service"
    systemctl daemon-reload
    echo -e "${GREEN}✓ Service file removed${NC}"
else
    echo -e "${YELLOW}Note: Service file not found${NC}"
fi

# Step 3: Remove installation directory
echo -e "${YELLOW}[3/5] Removing installation directory...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    # Ask about log backup
    if [ -d "$INSTALL_DIR/logs" ] && [ "$(ls -A $INSTALL_DIR/logs)" ]; then
        echo -e "${YELLOW}Log files exist. Do you want to backup logs before deletion?${NC}"
        read -p "Backup logs to /tmp/smppsim-logs-backup? (yes/no): " BACKUP_LOGS
        if [ "$BACKUP_LOGS" = "yes" ]; then
            mkdir -p /tmp/smppsim-logs-backup
            cp -r "$INSTALL_DIR/logs/"* /tmp/smppsim-logs-backup/
            echo -e "${GREEN}✓ Logs backed up to /tmp/smppsim-logs-backup/${NC}"
        fi
    fi

    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓ Installation directory removed${NC}"
else
    echo -e "${YELLOW}Note: Installation directory not found${NC}"
fi

# Step 4: Remove service user
echo -e "${YELLOW}[4/5] Removing service user...${NC}"
if id "$SERVICE_USER" &>/dev/null; then
    userdel "$SERVICE_USER" 2>/dev/null || true
    echo -e "${GREEN}✓ Service user removed${NC}"
else
    echo -e "${YELLOW}Note: Service user not found${NC}"
fi

# Step 5: Remove firewall rules (optional)
echo -e "${YELLOW}[5/5] Removing firewall rules...${NC}"
if systemctl is-active --quiet firewalld; then
    read -p "Remove firewall rules for ports 2775 and 8989? (yes/no): " REMOVE_FW
    if [ "$REMOVE_FW" = "yes" ]; then
        firewall-cmd --permanent --remove-port=2775/tcp 2>/dev/null || true
        firewall-cmd --permanent --remove-port=8989/tcp 2>/dev/null || true
        firewall-cmd --reload
        echo -e "${GREEN}✓ Firewall rules removed${NC}"
    else
        echo -e "${YELLOW}Firewall rules kept${NC}"
    fi
else
    echo -e "${YELLOW}Note: Firewalld is not active${NC}"
fi

# Print summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Uninstall Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}SMPPSim has been removed from the system.${NC}"
echo ""
