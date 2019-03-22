-- 12.2.11 data upgrade for MySQL
DROP PROCEDURE IF EXISTS OPAAddColumnIfNotExists;

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

DELIMITER ;

-- Add new columns
CALL OPAAddColumnIfNotExists('SNAPSHOT', 'fingerprint_sha256', 'varchar(65) CHARACTER SET utf8 NULL');
CALL OPAAddColumnIfNotExists('SNAPSHOT', 'scan_status', 'smallint DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('SNAPSHOT', 'scan_message', 'varchar(255) CHARACTER SET utf8 NULL');

CALL OPAAddColumnIfNotExists('DEPLOYMENT', 'activated_embedjs', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_ACTIVATION_HISTORY', 'status_embedjs', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_CHANNEL_DEFAULT', 'default_embedjs', 'SMALLINT DEFAULT 0 NOT NULL');

-- New configuration property

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('clamd_location', null, 0, 1, 'The clamd location, either local path or TCP socket, for virus scanning deployment or project data.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

