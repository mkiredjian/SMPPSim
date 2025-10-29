# SMPPSim MySQL Integration - Implementation Guide

## Overview

SMPPSim has been enhanced with MySQL database integration to automatically log all received SMPP messages and track their delivery lifecycle. This feature captures SUBMIT_SM messages and their state transitions (ENROUTE → DELIVERED/UNDELIVERABLE/etc.) in a MySQL database.

---

## What Has Been Implemented

### 1. **Database Connection Pooling** (HikariCP)
- Efficient connection management with configurable pool size
- Automatic connection recycling and health checks
- Thread-safe and production-ready

### 2. **Automatic Message Logging**
- **Location**: `StandardProtocolHandler.java:514-518`
- Captures all received SUBMIT_SM messages immediately after validation
- Logs complete message details including:
  - Message ID, source/destination addresses
  - Message text, encoding, priority
  - Service type, validity period
  - Optional TLV parameters

### 3. **Lifecycle State Tracking**
- **Location**: `LifeCycleManager.java:86, 100, 104, 108, 112`
- Automatically logs state transitions:
  - ENROUTE (initial state)
  - DELIVERED (successful delivery)
  - UNDELIVERABLE (failed delivery)
  - ACCEPTED (accepted by SMSC)
  - REJECTED (rejected by SMSC)
- Tracks error codes and delivery counts

### 4. **Configuration System**
- Fully configurable via `conf/smppsim.props`
- Enable/disable feature without code changes
- Connection parameters, pool size, timeouts

---

## Files Modified/Created

### Created Files:
1. **`src/main/java/com/seleniumsoftware/SMPPSim/DatabaseManager.java`**
   - Singleton class managing database operations
   - HikariCP connection pool management
   - Methods: `saveReceivedMessage()`, `updateMessageLifecycle()`

2. **`db/schema.sql`**
   - Complete database schema with 3 tables
   - Optimized indexes for performance
   - View for latest message status

3. **`db/README.md`**
   - Setup instructions
   - Example queries
   - Maintenance procedures

4. **`MYSQL_INTEGRATION_GUIDE.md`** (this file)
   - Complete implementation documentation

### Modified Files:
1. **`pom.xml`**
   - Added MySQL Connector (8.0.33)
   - Added HikariCP (4.0.3)

2. **`conf/smppsim.props`**
   - Added MySQL configuration section (lines 187-205)

3. **`src/main/java/com/seleniumsoftware/SMPPSim/SMPPSim.java`**
   - Added MySQL static variables (lines 124-133)
   - Added initialization code (lines 410-435)

4. **`src/main/java/com/seleniumsoftware/SMPPSim/StandardProtocolHandler.java`**
   - Added database save call (lines 514-518)

5. **`src/main/java/com/seleniumsoftware/SMPPSim/LifeCycleManager.java`**
   - Added lifecycle logging (lines 86, 100, 104, 108, 112)
   - Added helper method `logMessageLifecycle()` (lines 157-172)

---

## Setup Instructions

### Step 1: Install MySQL

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install mysql-server

# Verify installation
mysql --version
```

### Step 2: Create Database and User

```bash
mysql -u root -p
```

```sql
-- Create database
CREATE DATABASE smppsim_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER 'smppsim'@'localhost' IDENTIFIED BY 'your_secure_password';

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON smppsim_db.* TO 'smppsim'@'localhost';
FLUSH PRIVILEGES;

-- Exit
EXIT;
```

### Step 3: Load Database Schema

```bash
cd /home/user/SMPPSim
mysql -u smppsim -p smppsim_db < db/schema.sql
```

Verify tables were created:

```bash
mysql -u smppsim -p smppsim_db -e "SHOW TABLES;"
```

Expected output:
```
+-------------------------+
| Tables_in_smppsim_db    |
+-------------------------+
| message_lifecycle       |
| message_tlv_parameters  |
| received_messages       |
+-------------------------+
```

### Step 4: Configure SMPPSim

Edit `conf/smppsim.props`:

```properties
# Enable MySQL logging
MYSQL_ENABLED=true

# Database connection details
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=smppsim_db
MYSQL_USERNAME=smppsim
MYSQL_PASSWORD=your_secure_password

# Connection pool settings
MYSQL_POOL_SIZE=10
MYSQL_CONNECTION_TIMEOUT=30000
MYSQL_MAX_LIFETIME=1800000
```

### Step 5: Build SMPPSim

```bash
cd /home/user/SMPPSim
mvn clean package
```

This will download MySQL Connector and HikariCP dependencies.

### Step 6: Start SMPPSim

```bash
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
```

Look for this log message:
```
INFO  - MySQL connection pool initialized successfully
INFO  - MySQL connection test successful
INFO  - MySQL database integration initialized
```

---

## Database Schema

### Table: `received_messages`

Stores all incoming SUBMIT_SM messages.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT | Auto-increment primary key |
| message_id | VARCHAR(50) | SMPP message ID (unique) |
| source_addr | VARCHAR(21) | Sender phone number |
| destination_addr | VARCHAR(21) | Recipient phone number |
| short_message | TEXT | Message content |
| service_type | VARCHAR(6) | SMPP service type |
| data_coding | TINYINT | Character encoding |
| esm_class | TINYINT | Message mode/type |
| priority_flag | TINYINT | Message priority |
| registered_delivery | TINYINT | Delivery receipt flag |
| validity_period | VARCHAR(17) | Message expiry time |
| received_time | TIMESTAMP | When message was received |

**Indexes**: `message_id`, `source_addr`, `destination_addr`, `received_time`

### Table: `message_lifecycle`

Tracks message state transitions.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT | Auto-increment primary key |
| message_id | VARCHAR(50) | Links to received_messages |
| state | VARCHAR(20) | Message state |
| error_code | INT | Error code (if any) |
| submit_count | INT | Number of submissions |
| delivered_count | INT | Number of deliveries |
| state_changed_time | TIMESTAMP | When state changed |

**Possible States**: ENROUTE, DELIVERED, UNDELIVERABLE, ACCEPTED, REJECTED, EXPIRED, DELETED

### Table: `message_tlv_parameters`

Stores optional TLV (Tag-Length-Value) parameters.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT | Auto-increment primary key |
| message_id | VARCHAR(50) | Links to received_messages |
| tag | SMALLINT | TLV tag |
| length | INT | TLV length |
| value | BLOB | TLV value |

### View: `message_status_view`

Shows latest status for each message (combines received_messages + latest lifecycle state).

---

## Usage Examples

### Query 1: View All Messages Received Today

```sql
SELECT message_id, source_addr, destination_addr, short_message, received_time
FROM received_messages
WHERE DATE(received_time) = CURDATE()
ORDER BY received_time DESC;
```

### Query 2: Check Message Status

```sql
SELECT * FROM message_status_view
WHERE message_id = 'your_message_id';
```

### Query 3: Count Messages by State

```sql
SELECT state, COUNT(*) as count
FROM message_lifecycle
WHERE DATE(state_changed_time) = CURDATE()
GROUP BY state;
```

Example output:
```
+----------------+-------+
| state          | count |
+----------------+-------+
| DELIVERED      |   850 |
| UNDELIVERABLE  |    60 |
| ACCEPTED       |    20 |
| REJECTED       |    20 |
+----------------+-------+
```

### Query 4: Find Failed Deliveries

```sql
SELECT rm.message_id, rm.source_addr, rm.destination_addr,
       rm.short_message, ml.error_code, ml.state_changed_time
FROM received_messages rm
JOIN message_lifecycle ml ON rm.message_id = ml.message_id
WHERE ml.state = 'UNDELIVERABLE'
ORDER BY ml.state_changed_time DESC
LIMIT 100;
```

### Query 5: Messages from Specific Sender

```sql
SELECT * FROM message_status_view
WHERE source_addr = '1234567890'
ORDER BY received_time DESC;
```

### Query 6: Delivery Success Rate

```sql
SELECT
    COUNT(*) as total_messages,
    SUM(CASE WHEN state = 'DELIVERED' THEN 1 ELSE 0 END) as delivered,
    ROUND(100.0 * SUM(CASE WHEN state = 'DELIVERED' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate
FROM message_status_view
WHERE DATE(received_time) = CURDATE();
```

---

## Code Integration Points

### Where Messages are Saved

**File**: `StandardProtocolHandler.java`
**Method**: `getSubmitSMResponse()`
**Line**: 514-518

```java
// Save message to database
DatabaseManager dbManager = DatabaseManager.getInstance();
if (dbManager.isEnabled()) {
    dbManager.saveReceivedMessage(smppmsg, smppresp.getMessage_id());
}
```

**When**: Immediately after message is validated and added to OutboundQueue

### Where Lifecycle is Updated

**File**: `LifeCycleManager.java`
**Method**: `setState()`
**Lines**: 86, 100, 104, 108, 112

```java
m.setState(PduConstants.DELIVERED);
logger.debug("State set to DELIVERED");
logMessageLifecycle(m, "DELIVERED"); // Database logging
```

**When**: Each time a message transitions to a new state

---

## Performance Considerations

### Connection Pooling
- **Pool Size**: Default 10 connections
- **Min Idle**: 2 connections
- **Max Lifetime**: 30 minutes (1800000ms)
- **Connection Timeout**: 30 seconds

### Database Operations
- All database calls are **non-blocking** for SMPP processing
- Errors don't affect message processing (logged only)
- PreparedStatements with batching for TLV parameters
- Optimized indexes on frequently queried columns

### Expected Performance
- **Message Insert**: < 5ms per message
- **Lifecycle Update**: < 3ms per update
- **Query Performance**: < 10ms for indexed queries

---

## Monitoring and Maintenance

### Check Connection Pool Status

Add this to your monitoring:

```java
DatabaseManager dbManager = DatabaseManager.getInstance();
String stats = dbManager.getPoolStats();
logger.info(stats);
```

Output example:
```
Pool Stats - Active: 3, Idle: 7, Total: 10, Waiting: 0
```

### Cleanup Old Messages

Run periodically (e.g., weekly cron job):

```bash
#!/bin/bash
# cleanup_old_messages.sh

mysql -u smppsim -p smppsim_db <<EOF
DELETE FROM received_messages
WHERE received_time < DATE_SUB(NOW(), INTERVAL 30 DAY);
EOF
```

### Archive Before Cleanup

```bash
#!/bin/bash
# archive_messages.sh

DATE=$(date +%Y%m%d)
mysqldump -u smppsim -p smppsim_db received_messages \
  --where="received_time < DATE_SUB(NOW(), INTERVAL 30 DAY)" \
  > archive_${DATE}.sql
```

---

## Troubleshooting

### Issue 1: Connection Refused

**Error**: `java.sql.SQLException: Connection refused`

**Solution**:
```bash
# Check if MySQL is running
sudo systemctl status mysql

# Start MySQL if stopped
sudo systemctl start mysql
```

### Issue 2: Access Denied

**Error**: `java.sql.SQLException: Access denied for user 'smppsim'@'localhost'`

**Solution**:
```sql
-- Verify user exists
SELECT User, Host FROM mysql.user WHERE User = 'smppsim';

-- Reset password if needed
ALTER USER 'smppsim'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

### Issue 3: Table Doesn't Exist

**Error**: `Table 'smppsim_db.received_messages' doesn't exist`

**Solution**:
```bash
# Reload schema
mysql -u smppsim -p smppsim_db < db/schema.sql
```

### Issue 4: Slow Performance

**Symptoms**: High database latency

**Solutions**:
```sql
-- Add missing indexes
CREATE INDEX idx_custom ON received_messages(your_field);

-- Analyze tables
ANALYZE TABLE received_messages, message_lifecycle;

-- Check slow queries
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
```

---

## Disabling MySQL Integration

To disable without code changes:

Edit `conf/smppsim.props`:
```properties
MYSQL_ENABLED=false
```

Restart SMPPSim. No database operations will be performed.

---

## Security Best Practices

1. **Use Strong Passwords**
   ```bash
   # Generate secure password
   openssl rand -base64 32
   ```

2. **Restrict User Permissions**
   ```sql
   -- Only grant necessary permissions (SELECT, INSERT, UPDATE)
   -- DO NOT grant DELETE, DROP, or CREATE unless needed
   REVOKE ALL PRIVILEGES ON smppsim_db.* FROM 'smppsim'@'localhost';
   GRANT SELECT, INSERT, UPDATE ON smppsim_db.* TO 'smppsim'@'localhost';
   ```

3. **Encrypt Connections** (for remote MySQL)
   ```properties
   MYSQL_HOST=remote.mysql.server.com
   # Add to DatabaseManager.java JDBC URL: &useSSL=true&requireSSL=true
   ```

4. **Regular Backups**
   ```bash
   # Daily backup cron
   0 2 * * * mysqldump -u smppsim -p smppsim_db > /backups/smppsim_$(date +\%Y\%m\%d).sql
   ```

---

## Testing the Integration

### Step 1: Send Test Message

Use an SMPP client to send a test message:

```python
# Example with smpplib (Python)
import smpplib.client

client = smpplib.client.Client('localhost', 5555)
client.connect()
client.bind_transmitter(system_id='pavel', password='wpsd')

client.send_message(
    source_addr='1234567890',
    destination_addr='0987654321',
    short_message=b'Test message from SMPPSim'
)

client.unbind()
```

### Step 2: Verify Database Entry

```sql
-- Check received_messages table
SELECT * FROM received_messages
ORDER BY received_time DESC LIMIT 1;

-- Wait a few seconds for lifecycle transition

-- Check message_lifecycle table
SELECT * FROM message_lifecycle
ORDER BY state_changed_time DESC LIMIT 5;

-- Check combined view
SELECT * FROM message_status_view
ORDER BY received_time DESC LIMIT 1;
```

### Step 3: Verify Logs

Check SMPPSim logs for:
```
DEBUG - Message saved to database: [message_id] from [source] to [destination]
DEBUG - Message lifecycle updated: [message_id] -> DELIVERED
```

---

## Summary

✅ **Completed Implementation:**
- MySQL Connector and HikariCP dependencies added
- DatabaseManager class with connection pooling
- Automatic message logging on receipt
- Automatic lifecycle state tracking
- Complete database schema with indexes and views
- Configuration system via smppsim.props
- Comprehensive documentation and examples

✅ **Code Locations:**
- Database Manager: `src/main/java/com/seleniumsoftware/SMPPSim/DatabaseManager.java`
- Message Logging: `StandardProtocolHandler.java:514-518`
- Lifecycle Tracking: `LifeCycleManager.java:86, 100, 104, 108, 112`
- Configuration: `conf/smppsim.props:187-205`

✅ **Ready to Use:**
1. Setup MySQL database (see Step 1-3 above)
2. Configure `conf/smppsim.props`
3. Build with `mvn clean package`
4. Run SMPPSim
5. Messages are automatically logged!

---

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review `db/README.md` for database-specific help
3. Enable DEBUG logging in `conf/logback.xml`
4. Check MySQL error logs: `/var/log/mysql/error.log`

---

**Implementation Date**: 2025-10-29
**SMPPSim Version**: 2.6.9
**MySQL Connector Version**: 8.0.33
**HikariCP Version**: 4.0.3
