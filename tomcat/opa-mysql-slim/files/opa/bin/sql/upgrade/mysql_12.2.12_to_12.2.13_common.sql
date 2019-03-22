-- 12.2.13 data upgrade for MySQL
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

CREATE TABLE IF NOT EXISTS SSL_PRIVATE_KEY (
  ssl_private_key_id int(11) NOT NULL AUTO_INCREMENT,
  key_name VARCHAR(80) CHARACTER SET UTF8 NOT NULL,
  keystore LONGTEXT CHARACTER SET UTF8,
  last_updated DATETIME NULL,
  fingerprint_sha256 VARCHAR(100) CHARACTER SET UTF8 NULL,
  fingerprint_sha1 VARCHAR(60) CHARACTER SET UTF8 NULL,
  issuer VARCHAR(255) CHARACTER SET UTF8 NULL,
  subject VARCHAR(255) CHARACTER SET UTF8 NULL,
  valid_from DATETIME NULL,
  valid_to DATETIME NULL,

  CONSTRAINT ssl_private_key_pk PRIMARY KEY (ssl_private_key_id),
  CONSTRAINT priv_fingerprint_sha256_uq UNIQUE (fingerprint_sha256),
  CONSTRAINT priv_fingerprint_sha1_uq UNIQUE (fingerprint_sha1),
  CONSTRAINT ssl_key_name_uq UNIQUE (key_name)

) ENGINE=InnoDB;

-- Add new columns
CALL OPAAddColumnIfNotExists('DATA_SERVICE', 'ssl_private_key', 'VARCHAR(80) CHARACTER SET UTF8 NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT', 'activated_chatservice', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_ACTIVATION_HISTORY', 'status_chatservice', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_CHANNEL_DEFAULT', 'default_chatservice', 'SMALLINT DEFAULT 0 NOT NULL');

-- New role
INSERT INTO ROLE(role_name) VALUES ('Chat Service') ON DUPLICATE KEY UPDATE role_name = role_name;


-- Add new configuration properties

INSERT into CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('opa_app_version', NULL, 0, 1, 'Latest version of the Hub that can access this schema')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('feature_chat_service_enabled', 0, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the Chat Service feature')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

