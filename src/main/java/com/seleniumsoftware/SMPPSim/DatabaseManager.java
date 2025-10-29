/****************************************************************************
 * DatabaseManager.java
 *
 * Copyright (C) Selenium Software Ltd 2006
 *
 * This file is part of SMPPSim.
 *
 * SMPPSim is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * SMPPSim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SMPPSim; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 ****************************************************************************
*/
package com.seleniumsoftware.SMPPSim;

import com.seleniumsoftware.SMPPSim.pdu.SubmitSM;
import com.seleniumsoftware.SMPPSim.pdu.Tlv;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;

/**
 * DatabaseManager handles MySQL database operations for SMPPSim.
 * Uses HikariCP for efficient connection pooling.
 *
 * @author SMPPSim Enhancement
 */
public class DatabaseManager {

    private static final Logger logger = LoggerFactory.getLogger(DatabaseManager.class);
    private static DatabaseManager instance = null;

    private HikariDataSource dataSource;
    private boolean enabled = false;

    /**
     * Private constructor for singleton pattern
     */
    private DatabaseManager() {
    }

    /**
     * Get singleton instance
     */
    public static synchronized DatabaseManager getInstance() {
        if (instance == null) {
            instance = new DatabaseManager();
        }
        return instance;
    }

    /**
     * Initialize database connection pool with configuration
     */
    public void initialize(String host, int port, String database,
                          String username, String password,
                          int poolSize, int connectionTimeout,
                          int maxLifetime) {

        if (!enabled) {
            logger.info("MySQL database logging is disabled");
            return;
        }

        try {
            HikariConfig config = new HikariConfig();

            // JDBC URL
            String jdbcUrl = String.format("jdbc:mysql://%s:%d/%s?useUnicode=true&characterEncoding=utf8mb4&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
                    host, port, database);
            config.setJdbcUrl(jdbcUrl);

            // Credentials
            config.setUsername(username);
            config.setPassword(password);

            // Pool configuration
            config.setMaximumPoolSize(poolSize);
            config.setConnectionTimeout(connectionTimeout);
            config.setMaxLifetime(maxLifetime);
            config.setIdleTimeout(600000); // 10 minutes
            config.setMinimumIdle(2);

            // Connection test query
            config.setConnectionTestQuery("SELECT 1");

            // Pool name
            config.setPoolName("SMPPSim-MySQL-Pool");

            // Additional optimizations
            config.addDataSourceProperty("cachePrepStmts", "true");
            config.addDataSourceProperty("prepStmtCacheSize", "250");
            config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");

            // Create datasource
            dataSource = new HikariDataSource(config);

            logger.info("MySQL connection pool initialized successfully");
            logger.info("JDBC URL: " + jdbcUrl);
            logger.info("Pool size: " + poolSize);

            // Test connection
            testConnection();

        } catch (Exception e) {
            logger.error("Failed to initialize MySQL connection pool", e);
            enabled = false;
        }
    }

    /**
     * Test database connection
     */
    private void testConnection() {
        Connection conn = null;
        try {
            conn = dataSource.getConnection();
            if (conn != null && !conn.isClosed()) {
                logger.info("MySQL connection test successful");
            }
        } catch (SQLException e) {
            logger.error("MySQL connection test failed", e);
            enabled = false;
        } finally {
            closeConnection(conn);
        }
    }

    /**
     * Enable database logging
     */
    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
        logger.info("MySQL database logging " + (enabled ? "enabled" : "disabled"));
    }

    /**
     * Check if database logging is enabled
     */
    public boolean isEnabled() {
        return enabled;
    }

    /**
     * Save a received SUBMIT_SM message to the database
     */
    public void saveReceivedMessage(SubmitSM message, String messageId) {
        if (!enabled || dataSource == null) {
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = dataSource.getConnection();

            String sql = "INSERT INTO received_messages " +
                        "(message_id, source_addr, source_addr_ton, source_addr_npi, " +
                        "destination_addr, dest_addr_ton, dest_addr_npi, short_message, " +
                        "service_type, data_coding, esm_class, protocol_id, priority_flag, " +
                        "registered_delivery, replace_if_present, sm_default_msg_id, " +
                        "validity_period, schedule_delivery_time, sm_length) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, messageId);
            pstmt.setString(2, message.getSource_addr());
            pstmt.setInt(3, message.getSource_addr_ton());
            pstmt.setInt(4, message.getSource_addr_npi());
            pstmt.setString(5, message.getDestination_addr());
            pstmt.setInt(6, message.getDest_addr_ton());
            pstmt.setInt(7, message.getDest_addr_npi());

            // Handle message text - convert byte array to string
            byte[] messageBytes = message.getShort_message();
            String messageText = (messageBytes != null) ? new String(messageBytes) : "";
            pstmt.setString(8, messageText);

            pstmt.setString(9, message.getService_type());
            pstmt.setInt(10, message.getData_coding());
            pstmt.setInt(11, message.getEsm_class());
            pstmt.setInt(12, message.getProtocol_ID());
            pstmt.setInt(13, message.getPriority_flag());
            pstmt.setInt(14, message.getRegistered_delivery_flag());
            pstmt.setInt(15, message.getReplace_if_present_flag());
            pstmt.setInt(16, message.getSm_default_msg_id());
            pstmt.setString(17, message.getValidity_period());
            pstmt.setString(18, message.getSchedule_delivery_time());
            pstmt.setInt(19, message.getSm_length());

            int rowsAffected = pstmt.executeUpdate();

            if (rowsAffected > 0) {
                logger.debug("Message saved to database: " + messageId +
                           " from " + message.getSource_addr() +
                           " to " + message.getDestination_addr());

                // Save TLV parameters if present
                saveTlvParameters(conn, message, messageId);
            }

        } catch (SQLException e) {
            logger.error("Failed to save message to database: " + messageId, e);
            // Don't throw exception - we don't want DB failure to stop SMPP processing
        } finally {
            closeStatement(pstmt);
            closeConnection(conn);
        }
    }

    /**
     * Save TLV (Tag-Length-Value) optional parameters
     */
    private void saveTlvParameters(Connection conn, SubmitSM message, String messageId) {
        ArrayList<Tlv> optionals = message.getOptionals();
        if (optionals == null || optionals.isEmpty()) {
            return;
        }

        PreparedStatement pstmt = null;
        try {
            String sql = "INSERT INTO message_tlv_parameters " +
                        "(message_id, tag, length, value) VALUES (?, ?, ?, ?)";

            pstmt = conn.prepareStatement(sql);

            for (Tlv tlv : optionals) {
                pstmt.setString(1, messageId);
                pstmt.setInt(2, tlv.getTag());
                pstmt.setInt(3, tlv.getLen());
                pstmt.setBytes(4, tlv.getValue());
                pstmt.addBatch();
            }

            pstmt.executeBatch();
            logger.debug("Saved " + optionals.size() + " TLV parameters for message: " + messageId);

        } catch (SQLException e) {
            logger.error("Failed to save TLV parameters for message: " + messageId, e);
        } finally {
            closeStatement(pstmt);
        }
    }

    /**
     * Update message lifecycle state
     */
    public void updateMessageLifecycle(String messageId, String state, int errorCode,
                                       int submitCount, int deliveredCount) {
        if (!enabled || dataSource == null) {
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = dataSource.getConnection();

            String sql = "INSERT INTO message_lifecycle " +
                        "(message_id, state, error_code, submit_count, delivered_count) " +
                        "VALUES (?, ?, ?, ?, ?)";

            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, messageId);
            pstmt.setString(2, state);
            pstmt.setInt(3, errorCode);
            pstmt.setInt(4, submitCount);
            pstmt.setInt(5, deliveredCount);

            int rowsAffected = pstmt.executeUpdate();

            if (rowsAffected > 0) {
                logger.debug("Message lifecycle updated: " + messageId + " -> " + state);
            }

        } catch (SQLException e) {
            logger.error("Failed to update message lifecycle for: " + messageId, e);
        } finally {
            closeStatement(pstmt);
            closeConnection(conn);
        }
    }

    /**
     * Close PreparedStatement safely
     */
    private void closeStatement(PreparedStatement stmt) {
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException e) {
                logger.warn("Error closing PreparedStatement", e);
            }
        }
    }

    /**
     * Close Connection safely (returns to pool)
     */
    private void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close(); // Returns connection to pool
            } catch (SQLException e) {
                logger.warn("Error closing Connection", e);
            }
        }
    }

    /**
     * Shutdown connection pool gracefully
     */
    public void shutdown() {
        if (dataSource != null && !dataSource.isClosed()) {
            logger.info("Shutting down MySQL connection pool");
            dataSource.close();
        }
    }

    /**
     * Get connection pool statistics
     */
    public String getPoolStats() {
        if (dataSource == null) {
            return "Connection pool not initialized";
        }

        return String.format("Pool Stats - Active: %d, Idle: %d, Total: %d, Waiting: %d",
                dataSource.getHikariPoolMXBean().getActiveConnections(),
                dataSource.getHikariPoolMXBean().getIdleConnections(),
                dataSource.getHikariPoolMXBean().getTotalConnections(),
                dataSource.getHikariPoolMXBean().getThreadsAwaitingConnection());
    }
}
