#!/bin/bash
#
# SMPPSim Connectivity Fix Script
#
# This script fixes common connectivity issues
# Run with sudo: sudo bash fix-connectivity.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SMPPSim Connectivity Fix${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# 1. Open firewall ports
echo -e "${YELLOW}[1/3] Opening firewall ports...${NC}"
if systemctl is-active --quiet firewalld; then
    echo "Opening port 2775 (SMPP)..."
    firewall-cmd --permanent --add-port=2775/tcp

    echo "Opening port 8989 (HTTP)..."
    firewall-cmd --permanent --add-port=8989/tcp

    echo "Reloading firewall..."
    firewall-cmd --reload

    echo -e "${GREEN}✓ Firewall configured${NC}"

    echo "Current open ports:"
    firewall-cmd --list-ports
else
    echo -e "${YELLOW}Firewalld is not active, skipping...${NC}"
fi
echo ""

# 2. Set SELinux to permissive (if enforcing)
echo -e "${YELLOW}[2/3] Checking SELinux...${NC}"
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce)
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        echo -e "${YELLOW}SELinux is in Enforcing mode. Setting to Permissive for testing...${NC}"
        setenforce 0
        echo -e "${GREEN}✓ SELinux set to Permissive (temporary until reboot)${NC}"
        echo -e "${YELLOW}To make permanent, edit /etc/selinux/config and set SELINUX=permissive${NC}"
    else
        echo -e "${GREEN}✓ SELinux is not blocking ($SELINUX_STATUS)${NC}"
    fi
else
    echo -e "${YELLOW}SELinux not available${NC}"
fi
echo ""

# 3. Restart service
echo -e "${YELLOW}[3/3] Restarting SMPPSim service...${NC}"
systemctl restart smppsim

# Wait for service to start
sleep 3

if systemctl is-active --quiet smppsim; then
    echo -e "${GREEN}✓ Service is running${NC}"
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo "Check logs with: journalctl -u smppsim -n 50"
    exit 1
fi
echo ""

# Test connectivity
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Testing Connectivity${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "Server IP: ${GREEN}$SERVER_IP${NC}"
echo ""

# Test ports locally
echo "Testing SMPP port 2775..."
if timeout 2 bash -c "</dev/tcp/localhost/2775" 2>/dev/null; then
    echo -e "${GREEN}✓ Port 2775 is accessible locally${NC}"
else
    echo -e "${RED}✗ Port 2775 is NOT accessible locally${NC}"
fi

echo "Testing HTTP port 8989..."
if timeout 2 bash -c "</dev/tcp/localhost/8989" 2>/dev/null; then
    echo -e "${GREEN}✓ Port 8989 is accessible locally${NC}"
else
    echo -e "${RED}✗ Port 8989 is NOT accessible locally${NC}"
fi
echo ""

# Show what's listening
echo -e "${YELLOW}Listening ports:${NC}"
netstat -tlnp 2>/dev/null | grep -E ':2775|:8989' || ss -tlnp 2>/dev/null | grep -E ':2775|:8989'
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}NEXT STEPS${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${YELLOW}1. Test from your Windows machine:${NC}"
echo ""
echo -e "   ${GREEN}Test with telnet:${NC}"
echo -e "   telnet $SERVER_IP 2775"
echo -e "   telnet $SERVER_IP 8989"
echo ""
echo -e "   ${GREEN}Test with browser:${NC}"
echo -e "   http://$SERVER_IP:8989"
echo ""
echo -e "   ${GREEN}Test with your Python script:${NC}"
echo -e "   Update your script with: host='$SERVER_IP', port=2775"
echo ""

echo -e "${YELLOW}2. If still not accessible, check Cloud Provider Security Groups:${NC}"
echo ""
echo -e "   ${GREEN}AWS EC2:${NC}"
echo -e "   - Go to EC2 Console → Instances"
echo -e "   - Select your instance"
echo -e "   - Click Security tab → Security groups"
echo -e "   - Edit inbound rules → Add:"
echo -e "     • Type: Custom TCP, Port: 2775, Source: 0.0.0.0/0"
echo -e "     • Type: Custom TCP, Port: 8989, Source: 0.0.0.0/0"
echo ""
echo -e "   ${GREEN}Google Cloud:${NC}"
echo -e "   - VPC Network → Firewall → Create Firewall Rule"
echo -e "   - Targets: All instances"
echo -e "   - Source: 0.0.0.0/0"
echo -e "   - Ports: tcp:2775,8989"
echo ""
echo -e "   ${GREEN}Azure:${NC}"
echo -e "   - Virtual Machines → Networking → Add inbound port rule"
echo -e "   - Ports: 2775,8989"
echo -e "   - Protocol: TCP"
echo ""

echo -e "${YELLOW}3. Run diagnostics:${NC}"
echo -e "   sudo bash diagnose.sh"
echo ""
