# SMPPSim Quick Start Guide

## Current Situation

You're trying to run SMPPSim but getting "Invalid or missing arguments" because **the JAR file hasn't been built yet**.

---

## Step-by-Step Build and Run

### Step 1: Build the Project (REQUIRED)

```bash
cd /home/user/SMPPSim

# Build with Maven (requires internet access)
mvn clean package
```

**Expected output:**
```
[INFO] Building jar: /home/user/SMPPSim/target/smppsim.jar
[INFO] BUILD SUCCESS
```

This creates: `target/smppsim.jar`

---

### Step 2: Verify JAR Exists

```bash
ls -lh target/smppsim.jar
```

You should see something like:
```
-rw-r--r-- 1 root root 15M Oct 29 14:30 target/smppsim.jar
```

---

### Step 3: Run SMPPSim

```bash
cd /home/user/SMPPSim
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

**Expected output:**
```
SMPPSim is starting....
INFO  - ==============================================================
INFO  - =  SMPPSim Copyright (C) 2006 Selenium Software Ltd
...
INFO  - =  SMPP_PORT                               :5555
INFO  - =  MySQL database integration is disabled
INFO  - ==============================================================
INFO  - SMPPSim ready to accept connections on port 5555
```

---

## If Build Fails (No Internet Access)

If `mvn clean package` fails due to network issues, you have several options:

### Option A: Enable Internet Temporarily
The easiest solution - enable internet access, run `mvn clean package`, then disable it again.

### Option B: Use Offline Maven Repository
If you have access to another machine:

```bash
# On machine WITH internet:
cd /path/to/SMPPSim
mvn dependency:go-offline
tar -czf m2-repo.tar.gz ~/.m2/repository

# Transfer m2-repo.tar.gz to your machine

# On machine WITHOUT internet:
tar -xzf m2-repo.tar.gz -C ~/
cd /home/user/SMPPSim
mvn -o package
```

### Option C: Download Dependencies Manually
```bash
cd /home/user/SMPPSim
bash download-dependencies.sh
```

See `BUILD_INSTRUCTIONS.md` for detailed help.

---

## Common Mistakes

### ❌ Running without building first
```bash
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
# Error: Unable to access jarfile target/smppsim.jar
```

**Solution:** Run `mvn clean package` first!

### ❌ Wrong directory
```bash
cd /
java -jar smppsim.jar conf/logback.xml conf/smppsim.props
# Error: Unable to access jarfile
```

**Solution:** Always run from `/home/user/SMPPSim` directory

### ❌ Using relative paths incorrectly
```bash
java -jar ../target/smppsim.jar logback.xml smppsim.props
# Error: Invalid or missing arguments
```

**Solution:** Use paths relative to current directory:
```bash
cd /home/user/SMPPSim
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

---

## Enable MySQL Integration (Optional)

After SMPPSim starts successfully:

1. **Setup MySQL database:**
```bash
mysql -u root -p
CREATE DATABASE smppsim_db;
CREATE USER 'smppsim'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL ON smppsim_db.* TO 'smppsim'@'localhost';
FLUSH PRIVILEGES;
EXIT;

mysql -u smppsim -p smppsim_db < db/schema.sql
```

2. **Configure SMPPSim:**
Edit `conf/smppsim.props`:
```properties
MYSQL_ENABLED=true
MYSQL_USERNAME=smppsim
MYSQL_PASSWORD=your_password
```

3. **Restart SMPPSim:**
```bash
# Stop current instance (Ctrl+C)
# Restart:
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

Look for:
```
INFO  - MySQL connection pool initialized successfully
INFO  - MySQL database integration initialized
```

---

## Testing SMPPSim

Once running, test with an SMPP client:

```python
# Example Python client (requires smpplib)
import smpplib.client

client = smpplib.client.Client('localhost', 5555)
client.connect()
client.bind_transmitter(system_id='pavel', password='wpsd')

client.send_message(
    source_addr='1234567890',
    destination_addr='0987654321',
    short_message=b'Test message'
)

client.unbind()
```

If MySQL is enabled, check the database:
```sql
SELECT * FROM received_messages ORDER BY received_time DESC LIMIT 10;
```

---

## Summary

1. ✅ **Build:** `mvn clean package`
2. ✅ **Run:** `java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props`
3. ✅ **Test:** Connect SMPP client to `localhost:5555`

That's it! 🎉
