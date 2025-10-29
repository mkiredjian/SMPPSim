# SMPPSim MySQL Database Setup

This directory contains database schema and setup instructions for SMPPSim message logging.

## Prerequisites

- MySQL Server 5.7+ or MySQL 8.0+
- MySQL client tools

## Setup Instructions

### 1. Create Database

```bash
mysql -u root -p
```

```sql
CREATE DATABASE smppsim_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. Create Database User (Recommended)

```sql
CREATE USER 'smppsim'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT SELECT, INSERT, UPDATE ON smppsim_db.* TO 'smppsim'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Load Schema

```bash
mysql -u smppsim -p smppsim_db < db/schema.sql
```

Or if using root:

```bash
mysql -u root -p smppsim_db < db/schema.sql
```

### 4. Verify Tables

```sql
USE smppsim_db;
SHOW TABLES;

-- Should show:
-- +-------------------------+
-- | Tables_in_smppsim_db    |
-- +-------------------------+
-- | message_lifecycle       |
-- | message_tlv_parameters  |
-- | received_messages       |
-- +-------------------------+
```

### 5. Configure SMPPSim

Edit `conf/smppsim.props` and add:

```properties
# MySQL Database Configuration
MYSQL_ENABLED=true
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=smppsim_db
MYSQL_USERNAME=smppsim
MYSQL_PASSWORD=your_secure_password
MYSQL_POOL_SIZE=10
```

## Database Schema

### Tables

1. **received_messages** - Stores all incoming SUBMIT_SM messages
   - Primary key: `id` (auto-increment)
   - Unique key: `message_id` (SMPP message ID)
   - Indexed fields: `source_addr`, `destination_addr`, `received_time`

2. **message_lifecycle** - Tracks message state transitions
   - Records state changes: ENROUTE → DELIVERED/UNDELIVERABLE/etc.
   - Linked to `received_messages` via `message_id`

3. **message_tlv_parameters** - Stores optional TLV parameters
   - For advanced SMPP features (USSD, SAR, etc.)

### Views

- **message_status_view** - Shows latest status for each message

## Querying Messages

### Get all messages from today

```sql
SELECT * FROM received_messages
WHERE DATE(received_time) = CURDATE()
ORDER BY received_time DESC;
```

### Get message delivery status

```sql
SELECT * FROM message_status_view
WHERE message_id = 'your_message_id';
```

### Count messages by state

```sql
SELECT state, COUNT(*) as count
FROM message_lifecycle
WHERE DATE(state_changed_time) = CURDATE()
GROUP BY state;
```

### Failed deliveries

```sql
SELECT rm.message_id, rm.source_addr, rm.destination_addr,
       rm.short_message, ml.error_code, ml.state_changed_time
FROM received_messages rm
JOIN message_lifecycle ml ON rm.message_id = ml.message_id
WHERE ml.state = 'UNDELIVERABLE'
ORDER BY ml.state_changed_time DESC
LIMIT 100;
```

## Maintenance

### Cleanup old messages (older than 30 days)

```sql
DELETE FROM received_messages
WHERE received_time < DATE_SUB(NOW(), INTERVAL 30 DAY);
```

### Archive before cleanup

```bash
mysqldump -u smppsim -p smppsim_db received_messages \
  --where="received_time < DATE_SUB(NOW(), INTERVAL 30 DAY)" \
  > archive_$(date +%Y%m%d).sql
```

## Troubleshooting

### Connection Refused

Check if MySQL is running:
```bash
sudo systemctl status mysql
```

### Access Denied

Verify credentials in `conf/smppsim.props` match database user.

### Slow Performance

Add indexes if querying by custom fields:
```sql
CREATE INDEX idx_custom_field ON received_messages(your_field);
```
