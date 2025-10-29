# How to Customize Message ID Generation in SMPPSim

## 📍 Current Implementation

**File:** `src/main/java/com/seleniumsoftware/SMPPSim/Smsc.java`
**Line:** 330-334

```java
public synchronized static String getMessageID() {
    long msgID = message_id++;
    String msgIDstr = SMPPSim.getMid_prefix()+Long.toString(msgID);
    return msgIDstr;
}
```

**Current behavior:**
- Simple counter: 1, 2, 3, 4, ...
- Optional prefix from config: `MESSAGE_ID_PREFIX=SMS-` → Results: SMS-1, SMS-2, ...
- Resets to 0 when SMPPSim restarts

---

## 🎯 Quick Implementation Guide

### Step 1: Choose Your Format

See `MESSAGE_ID_EXAMPLES.java` for 9 different implementations. I recommend:

**For Development/Testing:**
- **Option 3** - Human-readable with timestamp
- Easy to understand, sortable, unique within a day

**For Production:**
- **Option 9** - Snowflake-like IDs
- Sortable, globally unique, high-performance

**For Database-Driven:**
- **Option 8** - Auto-increment from database
- Survives restarts, guaranteed unique

---

## Step 2: Edit Smsc.java

### Example: Implementing Human-Readable Format

**1. Open the file:**
```bash
cd /home/user/SMPPSim
nano src/main/java/com/seleniumsoftware/SMPPSim/Smsc.java
```

**2. Find line 330** and replace with:

```java
public synchronized static String getMessageID() {
    // Generate human-readable message ID: MSG-20251029-163045-000001
    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyyMMdd-HHmmss");
    String timestamp = sdf.format(new java.util.Date());
    long msgID = message_id++;

    String prefix = SMPPSim.getMid_prefix();
    if (prefix == null || prefix.isEmpty()) {
        prefix = "MSG";
    }

    return String.format("%s-%s-%06d", prefix, timestamp, msgID);
}
```

**3. Add import at the top of the file** (around line 27-35):
```java
import java.text.SimpleDateFormat;
import java.util.Date;
```

---

## Step 3: Rebuild and Test

```bash
cd /home/user/SMPPSim

# Rebuild (requires internet)
mvn clean package

# Or manually compile just this file
javac -cp "target/classes:lib/*" \
  src/main/java/com/seleniumsoftware/SMPPSim/Smsc.java

# Restart SMPPSim
bash run.sh
```

---

## Step 4: Send Test Message

```python
import smpplib.client

client = smpplib.client.Client('localhost', 5555)
client.connect()
client.bind_transmitter(system_id='pavel', password='wpsd')

response = client.send_message(
    source_addr='1234567890',
    destination_addr='0987654321',
    short_message=b'Test custom message ID'
)

print(f"Message ID: {response}")

client.unbind()
client.disconnect()
```

---

## Step 5: Verify in MySQL

```sql
SELECT message_id, source_addr, destination_addr, short_message
FROM received_messages
ORDER BY received_time DESC
LIMIT 1;
```

**Old format:**
```
message_id: 1
```

**New format (Option 3):**
```
message_id: MSG-20251029-163045-000001
```

---

## 🎨 Configuration Options

### Configure Prefix in smppsim.props

Edit `conf/smppsim.props`:

```properties
# Message ID configuration
MESSAGE_ID_PREFIX=SMS-
START_MESSAGE_ID_AT=1000
```

The code will use this prefix automatically if you keep the `SMPPSim.getMid_prefix()` call.

---

## 🔧 Advanced: Database-Backed IDs

For production systems that need IDs to survive restarts:

### 1. Create sequence table:

```sql
CREATE TABLE message_id_sequence (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
```

### 2. Modify getMessageID():

```java
public synchronized static String getMessageID() {
    DatabaseManager dbManager = DatabaseManager.getInstance();

    if (dbManager.isEnabled()) {
        try {
            // Get next ID from database
            long dbId = dbManager.getNextSequenceId();
            return String.valueOf(dbId);
        } catch (Exception e) {
            logger.warn("Failed to get DB sequence, using counter", e);
        }
    }

    // Fallback
    long msgID = message_id++;
    return SMPPSim.getMid_prefix() + Long.toString(msgID);
}
```

### 3. Add method to DatabaseManager.java:

```java
public long getNextSequenceId() throws SQLException {
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;

    try {
        conn = dataSource.getConnection();
        stmt = conn.createStatement();

        // Insert and get ID
        stmt.executeUpdate("INSERT INTO message_id_sequence VALUES ()");
        rs = stmt.executeQuery("SELECT LAST_INSERT_ID()");

        if (rs.next()) {
            return rs.getLong(1);
        }

        throw new SQLException("Failed to get sequence ID");

    } finally {
        if (rs != null) rs.close();
        if (stmt != null) stmt.close();
        if (conn != null) conn.close();
    }
}
```

---

## 📊 Comparison of Options

| Option | Format | Length | Sortable | Unique After Restart | DB Required |
|--------|--------|--------|----------|---------------------|-------------|
| **Current** | 1, 2, 3... | Short | ✅ | ❌ | ❌ |
| **Option 1 (UUID)** | a3f5c912-... | 36 chars | ❌ | ✅ | ❌ |
| **Option 2 (Timestamp)** | 1730225555-001 | 15 chars | ✅ | ✅ | ❌ |
| **Option 3 (Readable)** | MSG-20251029-001 | 20 chars | ✅ | ✅ | ❌ |
| **Option 8 (Database)** | 1, 2, 3... | Short | ✅ | ✅ | ✅ |
| **Option 9 (Snowflake)** | 123456789012 | 13 digits | ✅ | ✅ | ❌ |

---

## 🎯 My Recommendation

**For your SMS system:**

Use **Option 3 (Human-Readable)** because:
- ✅ Easy to debug (you can see date/time in the ID)
- ✅ Sortable by time
- ✅ Unique across multiple servers (with different prefixes)
- ✅ Good length for SMS IDs (20 chars)
- ✅ No database dependency

**Format:** `MSG-20251029-163045-000001`
- `MSG` - Prefix (configurable)
- `20251029` - Date (YYYYMMDD)
- `163045` - Time (HHMMSS)
- `000001` - Counter (resets each second)

---

## 🚀 Quick Start

```bash
# 1. Edit the file
nano src/main/java/com/seleniumsoftware/SMPPSim/Smsc.java

# 2. Replace getMessageID() method at line 330

# 3. Rebuild
mvn clean package

# 4. Restart
bash run.sh

# 5. Test and check MySQL
```

Done! Your custom message IDs will now appear in all SMPP responses and MySQL database. 🎉

---

## 📚 Additional Resources

- **All Examples:** `MESSAGE_ID_EXAMPLES.java`
- **SMPP Spec:** Message IDs can be up to 65 characters (C-Octet String)
- **MySQL Column:** `message_id VARCHAR(50)` - supports up to 50 chars

---

## 💡 Need Help?

If you have issues:
1. Check compilation errors - add missing imports
2. Test with simple format first (just counter + timestamp)
3. Verify MySQL column is wide enough for your format
4. Check logs for any exceptions during ID generation
