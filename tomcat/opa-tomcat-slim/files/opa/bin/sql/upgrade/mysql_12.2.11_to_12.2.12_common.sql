-- 12.2.12 data upgrade for MySQL
DROP PROCEDURE IF EXISTS OPAAddColumnIfNotExists;
DROP PROCEDURE IF EXISTS OPAAddIndexIfNotExists;

DELIMITER ;PROC;
CREATE PROCEDURE OPAAddColumnIfNotExists(
    tableName VARCHAR(64),
    colName VARCHAR(64),
    colDef VARCHAR(2048)
)
DETERMINISTIC
BEGIN
    DECLARE colExists INT;
    DECLARE dbName VARCHAR(64);
    SELECT database() INTO dbName;
    SELECT COUNT(1) INTO colExists
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = convert(dbName USING utf8) COLLATE utf8_general_ci
            AND TABLE_NAME = convert(tableName USING utf8) COLLATE utf8_general_ci
            AND COLUMN_NAME = convert(colName USING utf8) COLLATE utf8_general_ci;
    IF colExists = 0 THEN
        SET @sql = CONCAT('ALTER TABLE ', tableName, ' ADD COLUMN ', colName, ' ', colDef);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
    END IF;
END;
;PROC;

CREATE PROCEDURE OPAAddIndexIfNotExists(
	tableName VARCHAR(64),
	indexName VARCHAR(64),
	indexDef VARCHAR(2048)
)
DETERMINISTIC
  BEGIN
    DECLARE indexExists INT;
    DECLARE dbName VARCHAR(64);
    SELECT database() INTO dbName;
    
    SELECT COUNT(1) INTO indexExists
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = convert(dbName USING utf8) COLLATE utf8_general_ci
    AND TABLE_NAME = convert(tableName USING utf8) COLLATE utf8_general_ci
    AND INDEX_NAME = convert(indexName USING utf8) COLLATE utf8_general_ci;
    
    IF indexExists = 0 THEN
      SET @sql = CONCAT('ALTER TABLE ', tableName, ' ADD INDEX ', indexName, ' ', indexDef);
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
    END IF;
  END;
;PROC;

DELIMITER ;

-- Add new columns
CALL OPAAddColumnIfNotExists('AUTHENTICATION', 'last_locked_timestamp', 'DATETIME NULL');

-- Add new configuration properties
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type)
    VALUES ('pwd_invalidLockMinutes', 0, 1)
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;


-- New columns, these need to be moved to appropriate upgrade script when this branch is merged into mainline
CALL OPAAddColumnIfNotExists('DEPLOYMENT', 'activated_interviewservice', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_ACTIVATION_HISTORY', 'status_interviewservice', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_CHANNEL_DEFAULT', 'default_interviewservice', 'SMALLINT NOT NULL DEFAULT 0');

-- update data for deployments
UPDATE DEPLOYMENT
	SET activated_interviewservice = 1
	WHERE activated_webservice = 1;

UPDATE DEPLOYMENT_ACTIVATION_HISTORY
	SET status_interviewservice = 1
	WHERE status_webservice = 1;

UPDATE DEPLOYMENT_CHANNEL_DEFAULT
	SET default_interviewservice = 1
	WHERE default_webservice = 1;
	
-- New table for function statistics
CREATE TABLE IF NOT EXISTS FUNCTION_STATS_LOG (
	function_stats_log_id INT NOT NULL AUTO_INCREMENT,
	deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
	product_code INT NOT NULL,
	product_function_code INT NOT NULL,
	product_function_version VARCHAR(25) CHARACTER SET UTF8 NOT NULL,
	last_used_timestamp TIMESTAMP NOT NULL,
	CONSTRAINT function_stats_log_pk PRIMARY KEY (function_stats_log_id),
	CONSTRAINT function_stats_log_uq UNIQUE KEY (deployment_id, product_code, product_function_code, product_function_version),
	INDEX function_usage_obsolete (last_used_timestamp, product_code, product_function_code, product_function_version, deployment_id)
) ENGINE = InnoDB;


-- Table for Auditing
CREATE TABLE if not exists AUDIT_LOG (
  audit_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  audit_date datetime NOT NULL, 
  auth_id int(11) DEFAULT NULL,
  auth_name varchar(100) DEFAULT NULL,
  description longtext DEFAULT NULL,
  object_type varchar(50) DEFAULT NULL,
  object_id int(11) DEFAULT NULL,
  operation varchar(50) DEFAULT NULL,
  result int(11) DEFAULT NULL,	
  extension longtext DEFAULT NULL,

  PRIMARY KEY (audit_id),
  INDEX audit_date_idx (audit_date)
) ENGINE=InnoDB;

-- Configuration for Auditing
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('audit_enabled', 1, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the audit writing') 
	ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
