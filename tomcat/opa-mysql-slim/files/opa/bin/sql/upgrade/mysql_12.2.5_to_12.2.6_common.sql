-- 12.2.6 data upgrade for MySQL
DROP PROCEDURE IF EXISTS OPAAddColumnIfNotExists;
DROP PROCEDURE IF EXISTS OPADropColumnIfExists;

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

CREATE PROCEDURE OPADropColumnIfExists(
    tableName VARCHAR(64),
    colName VARCHAR(64)
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
    IF colExists = 1 THEN
        SET @sql = CONCAT('ALTER TABLE ', tableName, ' DROP COLUMN ', colName);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
    END IF;
END;

;PROC;

DELIMITER ;

-- increase user name size
ALTER TABLE AUTHENTICATION MODIFY COLUMN user_name VARCHAR(255);
ALTER TABLE DEPLOYMENT_ACTION_LOG MODIFY COLUMN user_id VARCHAR(255);

-- Add new columns
CALL OPAAddColumnIfNotExists('AUTHENTICATION', 'user_type', 'SMALLINT DEFAULT 0 NOT NULL');

-- just in case this script has already been run, temporarily create the onld rows
CALL OPAAddColumnIfNotExists('DEPLOYMENT', 'activator_id', 'INT');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_ACTIVATION_HISTORY', 'authentication_id', 'INT');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_VERSION', 'creator_authentication_id', 'INT');
CALL OPAAddColumnIfNotExists('PROJECT_VERSION', 'creator_authentication_id', 'INT');
CALL OPAAddColumnIfNotExists('DEPLOYMENT', 'user_name', 'VARCHAR(255)');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_VERSION', 'user_name', 'VARCHAR(255)');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_ACTIVATION_HISTORY', 'user_name', 'VARCHAR(255)');
CALL OPAAddColumnIfNotExists('PROJECT_VERSION', 'user_name', 'VARCHAR(255)');
CALL OPAAddColumnIfNotExists('SECURITY_TOKEN', 'is_long_term', 'SMALLINT NOT NULL');

-- replace user_ids with user_names
UPDATE DEPLOYMENT D set user_name = (SELECT A.user_name from AUTHENTICATION A WHERE D.activator_id = A.authentication_id) WHERE user_name IS NULL;
UPDATE DEPLOYMENT_ACTIVATION_HISTORY H set user_name = (SELECT A.user_name from AUTHENTICATION A WHERE H.authentication_id = A.authentication_id) WHERE user_name IS NULL;
UPDATE DEPLOYMENT_VERSION V set user_name = (SELECT A.user_name from AUTHENTICATION A WHERE V.creator_authentication_id = A.authentication_id) WHERE user_name IS NULL;
UPDATE PROJECT_VERSION V set user_name = (SELECT A.user_name from AUTHENTICATION A WHERE V.creator_authentication_id = A.authentication_id) WHERE user_name IS NULL;
 
-- property changes (cloud and private-cloud)
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('externally_managed_identity', 0, 1, 0, '0 = disable, 1 = enabled. Enable for users which are managed and authenticated externally')
  ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
  
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('external_logout_url', null, 0, 1, 'Used for logging out of externally managed opa site')
  ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
  VALUES ('file_attach_name_max_chars', 100, 1, 1, 'Maximum number of characters allowed in a file attachment name')
  ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

-- remove user id columns
CALL OPADropColumnIfExists('DEPLOYMENT', 'activator_id');
CALL OPADropColumnIfExists('DEPLOYMENT_ACTIVATION_HISTORY', 'authentication_id');
CALL OPADropColumnIfExists('DEPLOYMENT_VERSION', 'creator_authentication_id');
CALL OPADropColumnIfExists('PROJECT_VERSION', 'creator_authentication_id');


