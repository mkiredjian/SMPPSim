# SMPPSim CentOS/RHEL Deployment Guide

Complete guide for deploying SMPPSim on CentOS/RHEL servers with systemd service, daily log rotation, and automatic compression.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Manual Installation](#manual-installation)
5. [Log Management](#log-management)
6. [Service Management](#service-management)
7. [Configuration](#configuration)
8. [Monitoring](#monitoring)
9. [Troubleshooting](#troubleshooting)
10. [Uninstallation](#uninstallation)

---

## Overview

This deployment includes:
- ✅ **Systemd service** for automatic startup and management
- ✅ **Daily log rotation** with automatic compression (ZIP format)
- ✅ **Date-based log filenames** (e.g., `smppsim-2025-10-30.log.zip`)
- ✅ **30-day log retention** with automatic cleanup
- ✅ **5GB total log size cap** to prevent disk space issues
- ✅ **Dedicated service user** for security
- ✅ **Automatic restart** on failure
- ✅ **Firewall configuration** for SMPP and web interface

---

## Prerequisites

### Required
- **CentOS/RHEL 7 or higher** (works with CentOS 8, Rocky Linux, AlmaLinux)
- **Root or sudo access**
- **Java 8 or higher** (will be installed automatically if missing)
- **Built JAR file** (`target/smppsim.jar`)

### Optional
- **MySQL** (if database integration is enabled in config)
- **Firewalld** (for automatic port configuration)

### Server Requirements
- **CPU**: 1+ cores
- **RAM**: 512MB minimum, 1GB recommended
- **Disk**: 10GB+ for logs and application
- **Network**: Ports 2775 (SMPP) and 8989 (HTTP) accessible

---

## Quick Start

### Step 1: Build the Project

On your **development machine** (not the server):

```bash
# Clone and build
cd /path/to/SMPPSim
mvn clean package

# Verify JAR was created
ls -lh target/smppsim.jar
```

### Step 2: Transfer to Server

```bash
# From your development machine, upload the entire project
scp -r SMPPSim/ user@your-centos-server:/tmp/

# Or just the necessary files
cd SMPPSim
tar czf smppsim-deploy.tar.gz target/smppsim.jar conf/ lib/ deployment/
scp smppsim-deploy.tar.gz user@your-centos-server:/tmp/
```

### Step 3: Deploy on Server

```bash
# SSH to your server
ssh user@your-centos-server

# Extract if you uploaded tar
cd /tmp
tar xzf smppsim-deploy.tar.gz

# Run deployment script
cd /tmp/SMPPSim/deployment/centos
sudo bash deploy.sh
```

That's it! The service is now running.

---

## Manual Installation

If you prefer manual installation or need to customize:

### 1. Install Java (if needed)

```bash
# Check Java version
java -version

# Install OpenJDK 11 if needed
sudo yum install -y java-11-openjdk java-11-openjdk-devel
```

### 2. Create Service User

```bash
sudo useradd -r -s /bin/false -d /opt/smppsim -c "SMPPSim Service User" smppsim
```

### 3. Create Directories

```bash
sudo mkdir -p /opt/smppsim/{conf,lib,logs}
```

### 4. Copy Files

```bash
# Copy JAR
sudo cp target/smppsim.jar /opt/smppsim/

# Copy configuration
sudo cp -r conf/* /opt/smppsim/conf/

# Copy libraries
sudo cp -r lib/* /opt/smppsim/lib/
```

### 5. Set Permissions

```bash
sudo chown -R smppsim:smppsim /opt/smppsim
sudo chmod 755 /opt/smppsim
sudo chmod 644 /opt/smppsim/smppsim.jar
sudo chmod 755 /opt/smppsim/logs
```

### 6. Install Systemd Service

```bash
# Copy service file
sudo cp deployment/centos/smppsim.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable smppsim
sudo systemctl start smppsim
```

### 7. Configure Firewall

```bash
# Open SMPP port
sudo firewall-cmd --permanent --add-port=2775/tcp

# Open web interface port
sudo firewall-cmd --permanent --add-port=8989/tcp

# Reload firewall
sudo firewall-cmd --reload
```

---

## Log Management

### Log Configuration

Logs are configured in `/opt/smppsim/conf/logback.xml`:

```xml
<rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
    <!-- Daily rotation with date-based filename -->
    <fileNamePattern>logs/smppsim-%d{yyyy-MM-dd}.log.zip</fileNamePattern>

    <!-- Keep 30 days of history -->
    <maxHistory>30</maxHistory>

    <!-- Total size cap: 5GB -->
    <totalSizeCap>5GB</totalSizeCap>
</rollingPolicy>
```

### Log Locations

| Location | Description |
|----------|-------------|
| `/opt/smppsim/logs/smppsim.log` | Current day's log file (active) |
| `/opt/smppsim/logs/smppsim-2025-10-30.log.zip` | Previous day's compressed log |
| `/var/log/journal/` | Systemd journal logs |

### Log File Naming

Logs are automatically rotated daily at midnight with date-based naming:

```
smppsim.log                    # Current day (active, uncompressed)
smppsim-2025-10-29.log.zip     # Yesterday (compressed)
smppsim-2025-10-28.log.zip     # 2 days ago (compressed)
...
smppsim-2025-10-01.log.zip     # 30 days ago (will be deleted tomorrow)
```

### Viewing Logs

```bash
# View current log file
sudo tail -f /opt/smppsim/logs/smppsim.log

# View with color and follow
sudo less +F /opt/smppsim/logs/smppsim.log

# View systemd journal
sudo journalctl -u smppsim -f

# View last 100 lines
sudo journalctl -u smppsim -n 100

# View logs for specific date
sudo journalctl -u smppsim --since "2025-10-29" --until "2025-10-30"

# Extract and view compressed log
sudo unzip -p /opt/smppsim/logs/smppsim-2025-10-29.log.zip | less
```

### Log Retention

- **Daily rotation**: Happens at midnight (00:00)
- **Retention period**: 30 days (configurable in logback.xml)
- **Size limit**: 5GB total (oldest logs deleted first)
- **Compression**: Automatic ZIP compression after rotation

### Adjusting Log Settings

Edit `/opt/smppsim/conf/logback.xml`:

**Change retention period:**
```xml
<maxHistory>60</maxHistory>  <!-- Keep 60 days instead of 30 -->
```

**Change size cap:**
```xml
<totalSizeCap>10GB</totalSizeCap>  <!-- Allow 10GB instead of 5GB -->
```

**Change compression format:**
```xml
<!-- ZIP format (default) -->
<fileNamePattern>logs/smppsim-%d{yyyy-MM-dd}.log.zip</fileNamePattern>

<!-- GZIP format -->
<fileNamePattern>logs/smppsim-%d{yyyy-MM-dd}.log.gz</fileNamePattern>

<!-- No compression -->
<fileNamePattern>logs/smppsim-%d{yyyy-MM-dd}.log</fileNamePattern>
```

**Change log level:**
```xml
<root>
    <level value="DEBUG"/>  <!-- Change from INFO to DEBUG -->
    ...
</root>
```

After changes, restart the service:
```bash
sudo systemctl restart smppsim
```

---

## Service Management

### Basic Commands

```bash
# Start the service
sudo systemctl start smppsim

# Stop the service
sudo systemctl stop smppsim

# Restart the service
sudo systemctl restart smppsim

# Check service status
sudo systemctl status smppsim

# Enable auto-start on boot
sudo systemctl enable smppsim

# Disable auto-start on boot
sudo systemctl disable smppsim

# View real-time logs
sudo journalctl -u smppsim -f
```

### Service Status

Check if service is running:

```bash
$ sudo systemctl status smppsim
● smppsim.service - SMPPSim - SMPP Protocol Simulator
   Loaded: loaded (/etc/systemd/system/smppsim.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2025-10-30 10:30:45 UTC; 2h 15min ago
 Main PID: 12345 (java)
   CGroup: /system.slice/smppsim.service
           └─12345 /usr/bin/java -Xmx512m -Xms256m -jar /opt/smppsim/smppsim.jar
```

### Auto-Restart on Failure

The service is configured to automatically restart on failure:

```ini
Restart=on-failure
RestartSec=10s
```

This means if the Java process crashes, systemd will wait 10 seconds and restart it automatically.

---

## Configuration

### Main Configuration

Edit `/opt/smppsim/conf/smppsim.props`:

```properties
# SMPP Port
SMPP_PORT=2775

# HTTP Management Port
HTTP_PORT=8989

# MySQL Configuration (optional)
MYSQL_ENABLED=true
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=smppsim_db
MYSQL_USERNAME=smppsim
MYSQL_PASSWORD=your_password
```

### Logging Configuration

Edit `/opt/smppsim/conf/logback.xml`:

```xml
<configuration>
    <!-- File appender with daily rotation -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/smppsim.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/smppsim-%d{yyyy-MM-dd}.log.zip</fileNamePattern>
            <maxHistory>30</maxHistory>
            <totalSizeCap>5GB</totalSizeCap>
        </rollingPolicy>
    </appender>

    <!-- Log level: INFO, DEBUG, TRACE -->
    <root>
        <level value="INFO"/>
        <appender-ref ref="FILE"/>
        <appender-ref ref="CONSOLE"/>
    </root>
</configuration>
```

### Java Memory Settings

Edit `/etc/systemd/system/smppsim.service` to adjust memory:

```ini
ExecStart=/usr/bin/java -Xmx1024m -Xms512m -jar /opt/smppsim/smppsim.jar
```

After changes:
```bash
sudo systemctl daemon-reload
sudo systemctl restart smppsim
```

### After Configuration Changes

```bash
# Test configuration
sudo -u smppsim java -jar /opt/smppsim/smppsim.jar --help

# Restart service
sudo systemctl restart smppsim

# Check logs for errors
sudo journalctl -u smppsim -n 50
```

---

## Monitoring

### Health Checks

```bash
# Check if service is running
systemctl is-active smppsim

# Check SMPP port
sudo netstat -tlnp | grep 2775
# or
sudo ss -tlnp | grep 2775

# Check HTTP port
curl http://localhost:8989

# Check process
ps aux | grep smppsim
```

### Resource Usage

```bash
# CPU and Memory usage
ps aux | grep smppsim

# Detailed process info
sudo systemctl status smppsim

# Disk space for logs
du -sh /opt/smppsim/logs/
ls -lh /opt/smppsim/logs/
```

### Log Analysis

```bash
# Count errors today
grep -c "ERROR" /opt/smppsim/logs/smppsim.log

# Find specific errors
grep "Exception" /opt/smppsim/logs/smppsim.log

# Analyze yesterday's log
unzip -p /opt/smppsim/logs/smppsim-2025-10-29.log.zip | grep "ERROR"

# Message count
grep -c "Message received" /opt/smppsim/logs/smppsim.log
```

### Setting Up Monitoring Alerts

Example with logwatch or fail2ban for error detection:

```bash
# Monitor for excessive errors
sudo journalctl -u smppsim | grep -i error | tail -20
```

---

## Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status smppsim

# View recent logs
sudo journalctl -u smppsim -n 100 --no-pager

# Check configuration syntax
sudo -u smppsim java -jar /opt/smppsim/smppsim.jar --help

# Check file permissions
ls -la /opt/smppsim/
```

### Port Already in Use

```bash
# Find process using port 2775
sudo netstat -tlnp | grep 2775
# or
sudo lsof -i :2775

# Kill old process
sudo kill -9 <PID>

# Restart service
sudo systemctl restart smppsim
```

### Logs Not Rotating

```bash
# Check logback configuration
cat /opt/smppsim/conf/logback.xml

# Check write permissions
ls -la /opt/smppsim/logs/

# Fix permissions if needed
sudo chown -R smppsim:smppsim /opt/smppsim/logs/
sudo chmod 755 /opt/smppsim/logs/
```

### Out of Memory

```bash
# Check Java heap size
ps aux | grep smppsim | grep Xmx

# Increase memory in service file
sudo vi /etc/systemd/system/smppsim.service
# Change: -Xmx512m to -Xmx1024m

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart smppsim
```

### Database Connection Issues

```bash
# Check MySQL is running
sudo systemctl status mysqld

# Test connection
mysql -h localhost -u smppsim -p smppsim_db

# Disable MySQL in config if not needed
sudo vi /opt/smppsim/conf/smppsim.props
# Set: MYSQL_ENABLED=false

sudo systemctl restart smppsim
```

### High Disk Usage

```bash
# Check log directory size
du -sh /opt/smppsim/logs/

# List large files
ls -lhS /opt/smppsim/logs/

# Reduce retention or size cap in logback.xml
sudo vi /opt/smppsim/conf/logback.xml
# Change maxHistory or totalSizeCap

sudo systemctl restart smppsim
```

### View Debug Logs

```bash
# Enable DEBUG logging
sudo vi /opt/smppsim/conf/logback.xml
# Change: <level value="INFO"/> to <level value="DEBUG"/>

sudo systemctl restart smppsim

# View debug logs
sudo tail -f /opt/smppsim/logs/smppsim.log
```

---

## Uninstallation

### Using Uninstall Script

```bash
cd /tmp/SMPPSim/deployment/centos
sudo bash uninstall.sh
```

The script will:
1. Stop and disable the service
2. Remove systemd service file
3. Offer to backup logs
4. Remove installation directory
5. Remove service user
6. Optionally remove firewall rules

### Manual Uninstallation

```bash
# Stop and disable service
sudo systemctl stop smppsim
sudo systemctl disable smppsim

# Remove service file
sudo rm -f /etc/systemd/system/smppsim.service
sudo systemctl daemon-reload

# Backup logs (optional)
sudo cp -r /opt/smppsim/logs /tmp/smppsim-logs-backup

# Remove installation
sudo rm -rf /opt/smppsim

# Remove user
sudo userdel smppsim

# Remove firewall rules (optional)
sudo firewall-cmd --permanent --remove-port=2775/tcp
sudo firewall-cmd --permanent --remove-port=8989/tcp
sudo firewall-cmd --reload
```

---

## Security Considerations

1. **Dedicated User**: Service runs as non-root user `smppsim`
2. **Restricted Permissions**: Files owned by `smppsim:smppsim`
3. **Firewall**: Only necessary ports exposed (2775, 8989)
4. **SELinux**: May require policy adjustments on enforcing systems
5. **MySQL**: Use strong passwords, consider encrypted connections
6. **Logs**: May contain sensitive data, restrict access

### SELinux Configuration (if enabled)

```bash
# Check SELinux status
getenforce

# If enforcing, you may need to adjust policies
sudo semanage fcontext -a -t bin_t "/opt/smppsim/smppsim.jar"
sudo restorecon -v /opt/smppsim/smppsim.jar
```

---

## Additional Resources

- **Web Interface**: `http://your-server:8989`
- **SMPP Connection**: `your-server:2775`
- **Default Credentials**: See `conf/smppsim.props`
- **Log Files**: `/opt/smppsim/logs/`
- **Configuration**: `/opt/smppsim/conf/`

---

## Support

For issues or questions:
1. Check logs: `sudo journalctl -u smppsim -f`
2. Review configuration: `ls -la /opt/smppsim/conf/`
3. Check service status: `sudo systemctl status smppsim`
4. Verify ports: `sudo netstat -tlnp | grep -E '2775|8989'`

---

**Deployment Version**: 1.0
**Last Updated**: 2025-10-30
**Compatible OS**: CentOS 7+, RHEL 7+, Rocky Linux 8+, AlmaLinux 8+
