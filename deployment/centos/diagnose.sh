#!/bin/bash
#
# SMPPSim Connectivity Diagnostic Script
#
# Run this on your CentOS server to diagnose connectivity issues
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SMPPSim Connectivity Diagnostics${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Check if service is running
echo -e "${YELLOW}[1] Checking if SMPPSim service is running...${NC}"
if systemctl is-active --quiet smppsim; then
    echo -e "${GREEN}✓ Service is running${NC}"
    systemctl status smppsim | grep "Active:"
else
    echo -e "${RED}✗ Service is NOT running${NC}"
    echo -e "${YELLOW}Start it with: sudo systemctl start smppsim${NC}"
    exit 1
fi
echo ""

# 2. Check if ports are listening
echo -e "${YELLOW}[2] Checking if ports are listening...${NC}"
if netstat -tlnp 2>/dev/null | grep -E ':2775|:8989' > /dev/null || ss -tlnp 2>/dev/null | grep -E ':2775|:8989' > /dev/null; then
    echo -e "${GREEN}✓ Ports are listening:${NC}"
    netstat -tlnp 2>/dev/null | grep -E ':2775|:8989' || ss -tlnp 2>/dev/null | grep -E ':2775|:8989'
else
    echo -e "${RED}✗ Ports are NOT listening${NC}"
    echo -e "${YELLOW}Check service logs: sudo journalctl -u smppsim -n 50${NC}"
fi
echo ""

# 3. Check what interface ports are bound to
echo -e "${YELLOW}[3] Checking which interfaces ports are bound to...${NC}"
SMPP_BIND=$(netstat -tlnp 2>/dev/null | grep ':2775' | awk '{print $4}' || ss -tlnp 2>/dev/null | grep ':2775' | awk '{print $5}')
HTTP_BIND=$(netstat -tlnp 2>/dev/null | grep ':8989' | awk '{print $4}' || ss -tlnp 2>/dev/null | grep ':8989' | awk '{print $5}')

if [[ "$SMPP_BIND" == *"0.0.0.0"* ]] || [[ "$SMPP_BIND" == *":::"* ]]; then
    echo -e "${GREEN}✓ SMPP port 2775 is bound to all interfaces (0.0.0.0) - GOOD${NC}"
elif [[ "$SMPP_BIND" == *"127.0.0.1"* ]]; then
    echo -e "${RED}✗ SMPP port 2775 is bound to localhost only (127.0.0.1) - BAD${NC}"
    echo -e "${YELLOW}This means it's only accessible from the server itself, not from outside${NC}"
    echo -e "${YELLOW}Check your smppsim.props configuration${NC}"
else
    echo -e "${YELLOW}SMPP port binding: $SMPP_BIND${NC}"
fi

if [[ "$HTTP_BIND" == *"0.0.0.0"* ]] || [[ "$HTTP_BIND" == *":::"* ]]; then
    echo -e "${GREEN}✓ HTTP port 8989 is bound to all interfaces (0.0.0.0) - GOOD${NC}"
elif [[ "$HTTP_BIND" == *"127.0.0.1"* ]]; then
    echo -e "${RED}✗ HTTP port 8989 is bound to localhost only (127.0.0.1) - BAD${NC}"
    echo -e "${YELLOW}This means it's only accessible from the server itself, not from outside${NC}"
else
    echo -e "${YELLOW}HTTP port binding: $HTTP_BIND${NC}"
fi
echo ""

# 4. Check firewalld
echo -e "${YELLOW}[4] Checking firewalld status...${NC}"
if systemctl is-active --quiet firewalld; then
    echo -e "${GREEN}Firewalld is active${NC}"

    # Check if ports are open
    if firewall-cmd --list-ports 2>/dev/null | grep -E '2775|8989' > /dev/null; then
        echo -e "${GREEN}✓ Ports are open in firewalld:${NC}"
        firewall-cmd --list-ports | grep -E '2775|8989'
    else
        echo -e "${RED}✗ Ports are NOT open in firewalld${NC}"
        echo -e "${YELLOW}Open them with:${NC}"
        echo -e "  sudo firewall-cmd --permanent --add-port=2775/tcp"
        echo -e "  sudo firewall-cmd --permanent --add-port=8989/tcp"
        echo -e "  sudo firewall-cmd --reload"
    fi
else
    echo -e "${YELLOW}Firewalld is not active${NC}"
fi
echo ""

# 5. Check iptables
echo -e "${YELLOW}[5] Checking iptables rules...${NC}"
if command -v iptables &> /dev/null; then
    IPTABLES_RULES=$(iptables -L -n 2>/dev/null | grep -E '2775|8989')
    if [ -n "$IPTABLES_RULES" ]; then
        echo -e "${YELLOW}Found iptables rules for SMPPSim ports:${NC}"
        echo "$IPTABLES_RULES"
    else
        echo -e "${YELLOW}No specific iptables rules found (may use default policy)${NC}"
    fi
else
    echo -e "${YELLOW}iptables not available${NC}"
fi
echo ""

# 6. Check SELinux
echo -e "${YELLOW}[6] Checking SELinux status...${NC}"
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS=$(getenforce 2>/dev/null)
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        echo -e "${RED}SELinux is in Enforcing mode${NC}"
        echo -e "${YELLOW}This might block connections. Check with:${NC}"
        echo -e "  sudo ausearch -m avc -ts recent"
        echo -e "${YELLOW}To temporarily disable (for testing only):${NC}"
        echo -e "  sudo setenforce 0"
    elif [ "$SELINUX_STATUS" = "Permissive" ]; then
        echo -e "${YELLOW}SELinux is in Permissive mode (logs but doesn't block)${NC}"
    else
        echo -e "${GREEN}SELinux is Disabled${NC}"
    fi
else
    echo -e "${YELLOW}SELinux not available${NC}"
fi
echo ""

# 7. Get server IP addresses
echo -e "${YELLOW}[7] Server IP addresses...${NC}"
echo -e "${GREEN}Your server IPs:${NC}"
hostname -I
echo ""

# 8. Test local connectivity
echo -e "${YELLOW}[8] Testing local connectivity...${NC}"

# Test SMPP port
if timeout 2 bash -c "</dev/tcp/localhost/2775" 2>/dev/null; then
    echo -e "${GREEN}✓ SMPP port 2775 is accessible locally${NC}"
else
    echo -e "${RED}✗ SMPP port 2775 is NOT accessible locally${NC}"
fi

# Test HTTP port
if timeout 2 bash -c "</dev/tcp/localhost/8989" 2>/dev/null; then
    echo -e "${GREEN}✓ HTTP port 8989 is accessible locally${NC}"

    # Try to fetch web page
    if command -v curl &> /dev/null; then
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8989 2>/dev/null)
        if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "302" ]; then
            echo -e "${GREEN}✓ HTTP interface is responding (status: $HTTP_STATUS)${NC}"
        else
            echo -e "${YELLOW}HTTP interface returned status: $HTTP_STATUS${NC}"
        fi
    fi
else
    echo -e "${RED}✗ HTTP port 8989 is NOT accessible locally${NC}"
fi
echo ""

# 9. Check configuration
echo -e "${YELLOW}[9] Checking configuration files...${NC}"
if [ -f "/opt/smppsim/conf/smppsim.props" ]; then
    echo -e "${GREEN}Configuration file found${NC}"
    echo -e "${YELLOW}SMPP_PORT setting:${NC}"
    grep "^SMPP_PORT" /opt/smppsim/conf/smppsim.props || echo -e "${RED}SMPP_PORT not found in config${NC}"
    echo -e "${YELLOW}HTTP_PORT setting:${NC}"
    grep "^HTTP_PORT" /opt/smppsim/conf/smppsim.props || echo -e "${RED}HTTP_PORT not found in config${NC}"
else
    echo -e "${RED}Configuration file not found at /opt/smppsim/conf/smppsim.props${NC}"
fi
echo ""

# 10. Recent logs
echo -e "${YELLOW}[10] Recent service logs (last 20 lines)...${NC}"
journalctl -u smppsim -n 20 --no-pager
echo ""

# Summary and recommendations
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}RECOMMENDATIONS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}If you still can't connect from outside:${NC}"
echo ""
echo -e "1. ${GREEN}Cloud Provider Security Groups${NC}"
echo -e "   If you're on AWS/GCP/Azure, you MUST open ports in security groups:"
echo -e "   - AWS: EC2 → Security Groups → Inbound Rules"
echo -e "   - GCP: VPC Network → Firewall Rules"
echo -e "   - Azure: Network Security Groups"
echo ""
echo -e "2. ${GREEN}Test from outside${NC}"
echo -e "   From your local machine, test:"
echo -e "   ${YELLOW}telnet YOUR_SERVER_IP 2775${NC}"
echo -e "   ${YELLOW}telnet YOUR_SERVER_IP 8989${NC}"
echo -e "   ${YELLOW}curl http://YOUR_SERVER_IP:8989${NC}"
echo ""
echo -e "3. ${GREEN}Check binding${NC}"
echo -e "   Make sure ports are bound to 0.0.0.0, not 127.0.0.1"
echo ""
echo -e "4. ${GREEN}Temporary firewall disable (for testing only)${NC}"
echo -e "   ${YELLOW}sudo systemctl stop firewalld${NC}"
echo -e "   Test connection, then re-enable:"
echo -e "   ${YELLOW}sudo systemctl start firewalld${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
