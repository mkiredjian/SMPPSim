/**
 * Example: Custom Message ID Generation Methods
 *
 * Replace the getMessageID() method in Smsc.java with one of these implementations
 */

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.UUID;
import java.security.MessageDigest;

// ==================================================================
// OPTION 1: UUID-Based (Globally Unique)
// ==================================================================
public synchronized static String getMessageID() {
    return UUID.randomUUID().toString();
}
// Result: "a3f5c912-4e2b-4c8d-9876-1234567890ab"

// ==================================================================
// OPTION 2: Timestamp + Counter (Sortable, Unique)
// ==================================================================
public synchronized static String getMessageID() {
    long timestamp = System.currentTimeMillis();
    long msgID = message_id++;
    return String.format("%d-%06d", timestamp, msgID);
}
// Result: "1730225555000-000001"

// ==================================================================
// OPTION 3: Human-Readable Format (Recommended)
// ==================================================================
public synchronized static String getMessageID() {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd-HHmmss");
    String timestamp = sdf.format(new Date());
    long msgID = message_id++;

    String prefix = SMPPSim.getMid_prefix();
    if (prefix == null || prefix.isEmpty()) {
        prefix = "MSG";
    }

    return String.format("%s-%s-%06d", prefix, timestamp, msgID);
}
// Result: "MSG-20251029-163045-000001"

// ==================================================================
// OPTION 4: Short Hash (8 chars, Good for URLs/Display)
// ==================================================================
public synchronized static String getMessageID() {
    long timestamp = System.currentTimeMillis();
    long counter = message_id++;
    String input = timestamp + "-" + counter;

    try {
        MessageDigest md = MessageDigest.getInstance("MD5");
        byte[] hash = md.digest(input.getBytes());
        return bytesToHex(hash).substring(0, 8).toUpperCase();
    } catch (Exception e) {
        return String.valueOf(counter);
    }
}

private static String bytesToHex(byte[] bytes) {
    StringBuilder sb = new StringBuilder();
    for (byte b : bytes) {
        sb.append(String.format("%02x", b));
    }
    return sb.toString();
}
// Result: "A3F5C912"

// ==================================================================
// OPTION 5: Composite (Date + Random + Counter)
// ==================================================================
public synchronized static String getMessageID() {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
    String date = sdf.format(new Date());
    int random = (int)(Math.random() * 10000);
    long msgID = message_id++;

    return String.format("%s-%04d-%06d", date, random, msgID);
}
// Result: "20251029-4532-000001"

// ==================================================================
// OPTION 6: Sequential with Server ID (for Distributed Systems)
// ==================================================================
public synchronized static String getMessageID() {
    String serverId = SMPPSim.getSmscid(); // From config
    long msgID = message_id++;

    return String.format("%s-%012d", serverId, msgID);
}
// Result: "SMPPSim-000000000001"

// ==================================================================
// OPTION 7: Base62 Encoded (Short, URL-safe)
// ==================================================================
public synchronized static String getMessageID() {
    long timestamp = System.currentTimeMillis();
    long counter = message_id++;
    long combined = (timestamp << 20) | (counter & 0xFFFFF);

    return encodeBase62(combined);
}

private static final String BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

private static String encodeBase62(long num) {
    StringBuilder sb = new StringBuilder();
    while (num > 0) {
        sb.insert(0, BASE62.charAt((int)(num % 62)));
        num /= 62;
    }
    return sb.length() > 0 ? sb.toString() : "0";
}
// Result: "3nK4mP9"

// ==================================================================
// OPTION 8: Database Auto-Increment (Most Reliable)
// ==================================================================
public synchronized static String getMessageID() {
    DatabaseManager dbManager = DatabaseManager.getInstance();

    if (dbManager.isEnabled()) {
        try {
            // Reserve an ID from database sequence
            Connection conn = dbManager.getConnection();
            Statement stmt = conn.createStatement();

            // For MySQL with auto_increment
            stmt.executeUpdate("INSERT INTO message_id_sequence VALUES ()");
            ResultSet rs = stmt.executeQuery("SELECT LAST_INSERT_ID()");

            if (rs.next()) {
                long dbId = rs.getLong(1);
                rs.close();
                stmt.close();
                conn.close();
                return String.valueOf(dbId);
            }

            rs.close();
            stmt.close();
            conn.close();
        } catch (Exception e) {
            logger.warn("Failed to get database ID, falling back to counter", e);
        }
    }

    // Fallback to in-memory counter
    long msgID = message_id++;
    return SMPPSim.getMid_prefix() + Long.toString(msgID);
}
// Result: Database-generated IDs (1, 2, 3...)

// ==================================================================
// OPTION 9: Twitter Snowflake-like (64-bit, Sortable, Unique)
// ==================================================================
// Bit layout: 41 bits timestamp | 10 bits machine ID | 12 bits sequence
private static long lastTimestamp = -1L;
private static long sequence = 0L;
private static final long MACHINE_ID = 1L; // Configure per server

public synchronized static String getMessageID() {
    long timestamp = System.currentTimeMillis();

    if (timestamp == lastTimestamp) {
        sequence = (sequence + 1) & 0xFFF; // 12 bits
        if (sequence == 0) {
            // Wait for next millisecond
            while (timestamp <= lastTimestamp) {
                timestamp = System.currentTimeMillis();
            }
        }
    } else {
        sequence = 0;
    }

    lastTimestamp = timestamp;

    long id = ((timestamp - 1609459200000L) << 22) // Epoch: 2021-01-01
            | (MACHINE_ID << 12)
            | sequence;

    return String.valueOf(id);
}
// Result: "123456789012345" (sortable, unique, 64-bit)

// ==================================================================
// RECOMMENDED FOR PRODUCTION:
// ==================================================================
// Use Option 3 (Human-Readable) for development/testing
// Use Option 9 (Snowflake) for high-volume production
// Use Option 8 (Database) if you need absolute consistency across restarts
