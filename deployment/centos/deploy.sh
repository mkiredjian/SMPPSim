#!/bin/bash
#
# SMPPSim CentOS Deployment Script
#
# This script automates the deployment of SMPPSim on CentOS/RHEL servers
# Run with sudo: sudo bash deploy.sh
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
SERVICE_GROUP="smppsim"
LOG_DIR="$INSTALL_DIR/logs"
JAR_FILE="smppsim.jar"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SMPPSim CentOS Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Step 1: Check Java installation
echo -e "${YELLOW}[1/9] Checking Java installation...${NC}"
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    echo -e "${GREEN}✓ Java is installed (version: $(java -version 2>&1 | head -n 1))${NC}"

    if [ "$JAVA_VERSION" -lt 8 ]; then
        echo -e "${RED}Error: Java 8 or higher is required${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Java is not installed. Installing OpenJDK 11...${NC}"
    yum install -y java-11-openjdk java-11-openjdk-devel
    echo -e "${GREEN}✓ Java installed successfully${NC}"
fi

# Step 2: Check if JAR file exists
echo -e "${YELLOW}[2/9] Checking for SMPPSim JAR file...${NC}"
if [ ! -f "../../target/$JAR_FILE" ]; then
    echo -e "${RED}Error: $JAR_FILE not found in ../../target/${NC}"
    echo -e "${YELLOW}Please build the project first: mvn clean package${NC}"
    exit 1
fi
echo -e "${GREEN}✓ JAR file found${NC}"

# Step 3: Create service user and group
echo -e "${YELLOW}[3/9] Creating service user and group...${NC}"
if id "$SERVICE_USER" &>/dev/null; then
    echo -e "${GREEN}✓ User $SERVICE_USER already exists${NC}"
else
    useradd -r -s /bin/false -d "$INSTALL_DIR" -c "SMPPSim Service User" "$SERVICE_USER"
    echo -e "${GREEN}✓ User $SERVICE_USER created${NC}"
fi

# Step 4: Create installation directory
echo -e "${YELLOW}[4/9] Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/conf"
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$LOG_DIR"
echo -e "${GREEN}✓ Directories created${NC}"

# Step 5: Copy application files
echo -e "${YELLOW}[5/9] Copying application files...${NC}"
cp "../../target/$JAR_FILE" "$INSTALL_DIR/"
cp -r ../../conf/* "$INSTALL_DIR/conf/"
cp -r ../../lib/* "$INSTALL_DIR/lib/" 2>/dev/null || echo -e "${YELLOW}Note: No lib directory found (optional)${NC}"
echo -e "${GREEN}✓ Application files copied${NC}"

# Step 6: Set permissions
echo -e "${YELLOW}[6/9] Setting permissions...${NC}"
chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR"
chmod 644 "$INSTALL_DIR/$JAR_FILE"
chmod 755 "$LOG_DIR"
echo -e "${GREEN}✓ Permissions set${NC}"

# Step 7: Install systemd service
echo -e "${YELLOW}[7/9] Installing systemd service...${NC}"
cp smppsim.service /etc/systemd/system/
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd service installed${NC}"

# Step 8: Configure firewall (if firewalld is running)
echo -e "${YELLOW}[8/9] Configuring firewall...${NC}"
if systemctl is-active --quiet firewalld; then
    echo -e "${YELLOW}Firewalld is active. Opening SMPP port 2775 and HTTP port 8989...${NC}"
    firewall-cmd --permanent --add-port=2775/tcp  # SMPP port
    firewall-cmd --permanent --add-port=8989/tcp  # Web interface
    firewall-cmd --reload
    echo -e "${GREEN}✓ Firewall configured${NC}"
else
    echo -e "${YELLOW}Note: Firewalld is not active. Skipping firewall configuration.${NC}"
fi

# Step 9: Enable and start service
echo -e "${YELLOW}[9/9] Enabling and starting service...${NC}"
systemctl enable smppsim.service
systemctl start smppsim.service

# Wait a moment and check status
sleep 2
if systemctl is-active --quiet smppsim.service; then
    echo -e "${GREEN}✓ Service started successfully${NC}"
else
    echo -e "${RED}Warning: Service may have failed to start. Check status with: systemctl status smppsim${NC}"
fi

# Print summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Installation directory: ${GREEN}$INSTALL_DIR${NC}"
echo -e "Log directory: ${GREEN}$LOG_DIR${NC}"
echo -e "Service user: ${GREEN}$SERVICE_USER${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  Start service:    ${GREEN}systemctl start smppsim${NC}"
echo -e "  Stop service:     ${GREEN}systemctl stop smppsim${NC}"
echo -e "  Restart service:  ${GREEN}systemctl restart smppsim${NC}"
echo -e "  View status:      ${GREEN}systemctl status smppsim${NC}"
echo -e "  View logs:        ${GREEN}journalctl -u smppsim -f${NC}"
echo -e "  View log files:   ${GREEN}tail -f $LOG_DIR/smppsim.log${NC}"
echo ""
echo -e "${YELLOW}Configuration files:${NC}"
echo -e "  Properties: ${GREEN}$INSTALL_DIR/conf/smppsim.props${NC}"
echo -e "  Logging:    ${GREEN}$INSTALL_DIR/conf/logback.xml${NC}"
echo ""
echo -e "${YELLOW}Web Interface:${NC}"
echo -e "  URL: ${GREEN}http://$(hostname -I | awk '{print $1}'):8989${NC}"
echo ""
echo -e "${YELLOW}SMPP Connection:${NC}"
echo -e "  Host: ${GREEN}$(hostname -I | awk '{print $1}')${NC}"
echo -e "  Port: ${GREEN}2775${NC}"
echo ""
