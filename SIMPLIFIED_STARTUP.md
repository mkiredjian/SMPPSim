# SMPPSim Simplified Startup Guide

## ✨ New Feature: No Arguments Required!

SMPPSim now supports running without command-line arguments. It will automatically use configuration files from the `conf/` directory.

---

## 🚀 Quick Start (Recommended)

### Option 1: Using the Startup Script (Easiest)

```bash
cd /home/user/SMPPSim
bash run.sh
```

**What it does:**
- Kills any old SMPPSim processes
- Starts SMPPSim with default configuration
- Uses `conf/logback.xml` and `conf/smppsim.props`

---

### Option 2: Direct Java Command

```bash
cd /home/user/SMPPSim
java -jar target/smppsim.jar
```

**Output:**
```
SMPPSim is starting....
Using configuration files:
  Logback: conf/logback.xml
  Properties: conf/smppsim.props
INFO  - MySQL connection pool initialized successfully
INFO  - SMPPSim ready to accept connections on port 5555
```

---

## 📂 Configuration Files (Defaults)

When running without arguments, SMPPSim looks for:

| File | Location | Purpose |
|------|----------|---------|
| **logback.xml** | `conf/logback.xml` | Logging configuration |
| **smppsim.props** | `conf/smppsim.props` | SMPP server settings |

Make sure these files exist in the `conf/` directory before starting.

---

## ⚙️ Advanced: Custom Configuration Paths

If you need to use configuration files from a different location:

```bash
java -jar target/smppsim.jar /path/to/logback.xml /path/to/smppsim.props
```

**Example:**
```bash
java -jar target/smppsim.jar /etc/smpp/logback.xml /etc/smpp/smppsim.props
```

---

## 🎯 All Usage Options

### 1. Default Configuration (No Arguments) ⭐ Recommended

```bash
# From project root
java -jar target/smppsim.jar

# Or use the script
bash run.sh
```

### 2. Custom Configuration (2 Arguments)

```bash
java -jar target/smppsim.jar <logback.xml> <smppsim.props>
```

### 3. From Any Directory

```bash
# Using absolute path to JAR
java -jar /home/user/SMPPSim/target/smppsim.jar

# SMPPSim will look for conf/ relative to current directory
# Or use absolute paths to configs:
java -jar /home/user/SMPPSim/target/smppsim.jar \
  /home/user/SMPPSim/conf/logback.xml \
  /home/user/SMPPSim/conf/smppsim.props
```

---

## 🔧 Running from Different Locations

### Scenario 1: From Project Root (Recommended)

```bash
cd /home/user/SMPPSim
java -jar target/smppsim.jar
# ✅ Works! Finds conf/logback.xml and conf/smppsim.props
```

### Scenario 2: From Another Directory

```bash
cd /tmp
java -jar /home/user/SMPPSim/target/smppsim.jar
# ❌ Fails! Can't find conf/ directory

# Solution: Use full paths
java -jar /home/user/SMPPSim/target/smppsim.jar \
  /home/user/SMPPSim/conf/logback.xml \
  /home/user/SMPPSim/conf/smppsim.props
```

### Scenario 3: Create Symbolic Links

```bash
# From anywhere
cd /opt/smppsim
ln -s /home/user/SMPPSim/conf conf
java -jar /home/user/SMPPSim/target/smppsim.jar
# ✅ Works! Follows the symlink to find config files
```

---

## 🐳 Docker / Systemd Service

### Docker Example

```dockerfile
FROM openjdk:11-jre
WORKDIR /app
COPY target/smppsim.jar .
COPY conf/ conf/
CMD ["java", "-jar", "smppsim.jar"]
```

No need to specify arguments!

### Systemd Service

```ini
[Unit]
Description=SMPPSim SMPP Simulator
After=network.target mysql.service

[Service]
Type=simple
User=smpp
WorkingDirectory=/opt/SMPPSim
ExecStart=/usr/bin/java -jar /opt/SMPPSim/target/smppsim.jar
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Place `conf/` directory at `/opt/SMPPSim/conf/`

---

## 📝 Windows Batch Script

**run.bat:**
```batch
@echo off
cd C:\SMPPSim
echo Starting SMPPSim...
java -jar target\smppsim.jar
pause
```

---

## 🔍 Troubleshooting

### Error: "Unable to access jarfile"

```bash
# Make sure you're in the right directory
cd /home/user/SMPPSim

# Or use absolute path
java -jar /home/user/SMPPSim/target/smppsim.jar
```

### Error: "FileNotFoundException: conf/smppsim.props"

```bash
# Check if conf/ directory exists
ls -la conf/

# Make sure you're running from project root
cd /home/user/SMPPSim
java -jar target/smppsim.jar
```

### Error: "Invalid number of arguments!"

```bash
# You provided 1 argument (invalid)
# Either use 0 arguments OR 2 arguments

# Wrong:
java -jar target/smppsim.jar conf/smppsim.props

# Right:
java -jar target/smppsim.jar
# OR
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

---

## 💡 Best Practices

### Development

```bash
cd /home/user/SMPPSim
bash run.sh
```

Simple and clean!

### Production

```bash
# Use systemd service or supervisor
# Place configs in /etc/smpp/
java -jar /opt/smppsim/smppsim.jar /etc/smpp/logback.xml /etc/smpp/smppsim.props
```

### Testing Multiple Configurations

```bash
# Dev config
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props

# Test config
java -jar target/smppsim.jar conf/logback.xml conf/smppsim-test.props

# Production config
java -jar target/smppsim.jar /etc/smpp/logback.xml /etc/smpp/smppsim-prod.props
```

---

## 📊 Summary

| Method | Command | Best For |
|--------|---------|----------|
| **Script** | `bash run.sh` | Daily development |
| **No Args** | `java -jar target/smppsim.jar` | Quick testing |
| **Full Paths** | `java -jar target/smppsim.jar <log> <props>` | Production deployment |

---

## 🎉 Benefits of This Change

✅ **Simpler to run** - Just `java -jar target/smppsim.jar`
✅ **Less typing** - No need to type config paths every time
✅ **Fewer errors** - Can't typo the config file paths
✅ **Better DX** - Developer experience improved
✅ **Backwards compatible** - Old method still works
✅ **Docker-friendly** - Easier containerization

---

## 🔄 Migration from Old Method

**Old way:**
```bash
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

**New way:**
```bash
java -jar target/smppsim.jar
```

Both still work! The new way is just simpler. 🚀
