-- SMPPSim Database Schema
-- This schema tracks all received SMPP messages and their delivery status

-- Main table for received messages (SUBMIT_SM)
CREATE TABLE IF NOT EXISTS received_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    message_id VARCHAR(50) NOT NULL UNIQUE,
    source_addr VARCHAR(21) NOT NULL,
    source_addr_ton TINYINT,
    source_addr_npi TINYINT,
    destination_addr VARCHAR(21) NOT NULL,
    dest_addr_ton TINYINT,
    dest_addr_npi TINYINT,
    short_message TEXT,
    service_type VARCHAR(6),
    data_coding TINYINT,
    esm_class TINYINT,
    protocol_id TINYINT,
    priority_flag TINYINT,
    registered_delivery TINYINT,
    replace_if_present TINYINT,
    sm_default_msg_id TINYINT,
    validity_period VARCHAR(17),
    schedule_delivery_time VARCHAR(17),
    sm_length INT,
    received_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_message_id (message_id),
    INDEX idx_source_addr (source_addr),
    INDEX idx_destination_addr (destination_addr),
    INDEX idx_received_time (received_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for message lifecycle tracking (delivery receipts)
CREATE TABLE IF NOT EXISTS message_lifecycle (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    message_id VARCHAR(50) NOT NULL,
    state VARCHAR(20) NOT NULL,
    error_code INT DEFAULT 0,
    submit_count INT DEFAULT 1,
    delivered_count INT DEFAULT 0,
    state_changed_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_message_id (message_id),
    INDEX idx_state (state),
    INDEX idx_state_changed_time (state_changed_time),
    FOREIGN KEY (message_id) REFERENCES received_messages(message_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for optional TLV (Tag-Length-Value) parameters
CREATE TABLE IF NOT EXISTS message_tlv_parameters (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    message_id VARCHAR(50) NOT NULL,
    tag SMALLINT NOT NULL,
    length INT NOT NULL,
    value BLOB,
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_message_id (message_id),
    INDEX idx_tag (tag),
    FOREIGN KEY (message_id) REFERENCES received_messages(message_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- View for latest message status
CREATE OR REPLACE VIEW message_status_view AS
SELECT
    rm.message_id,
    rm.source_addr,
    rm.destination_addr,
    rm.short_message,
    rm.received_time,
    ml.state AS current_state,
    ml.error_code,
    ml.state_changed_time AS last_state_change,
    ml.submit_count,
    ml.delivered_count
FROM
    received_messages rm
LEFT JOIN
    (SELECT
        message_id,
        state,
        error_code,
        submit_count,
        delivered_count,
        state_changed_time,
        ROW_NUMBER() OVER (PARTITION BY message_id ORDER BY state_changed_time DESC) as rn
    FROM
        message_lifecycle
    ) ml ON rm.message_id = ml.message_id AND ml.rn = 1;

-- Create database user (optional - run separately with root privileges)
-- CREATE USER IF NOT EXISTS 'smppsim'@'localhost' IDENTIFIED BY 'smppsim_password';
-- GRANT SELECT, INSERT, UPDATE ON smppsim_db.* TO 'smppsim'@'localhost';
-- FLUSH PRIVILEGES;
