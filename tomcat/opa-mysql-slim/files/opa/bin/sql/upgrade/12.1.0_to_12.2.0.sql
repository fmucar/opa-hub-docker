-- some update without a where clause are needed
SET SQL_SAFE_UPDATES=0; 

DROP PROCEDURE IF EXISTS OPAAddColumnIfNotExists;
DROP PROCEDURE IF EXISTS OPADropIndexIfExists;
DROP PROCEDURE IF EXISTS OPAUpgradeAnalysisScenario;

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

CREATE PROCEDURE OPADropIndexIfExists(
	tableName VARCHAR(64),
	indexName VARCHAR(128) )
DETERMINISTIC
BEGIN
    DECLARE colExists INT;
    DECLARE dbName VARCHAR(64);
    SELECT database() INTO dbName;

	select COUNT(1) INTO colExists 
		FROM INFORMATION_SCHEMA.STATISTICS 
        WHERE TABLE_SCHEMA = convert(dbName USING utf8) COLLATE utf8_general_ci
            AND TABLE_NAME = convert(tableName USING utf8) COLLATE utf8_general_ci
            AND INDEX_NAME = convert(indexName USING utf8) COLLATE utf8_general_ci;
			
	IF colExists > 0 THEN
		SET @sql = CONCAT('ALTER TABLE ', tableName, ' DROP INDEX ' ,indexName);
		PREPARE stmt FROM @sql;
		EXECUTE stmt;
	END IF;
END;
;PROC;

CREATE PROCEDURE OPAUpgradeAnalysisScenario()
DETERMINISTIC
BEGIN
	DECLARE colExists INT;
    SELECT COUNT(1) INTO colExists FROM INFORMATION_SCHEMA.COLUMNS WHERE 
    	TABLE_SCHEMA= convert(database() USING utf8) COLLATE utf8_general_ci
    	AND TABLE_NAME= convert('ANALYSIS_SCENARIO' USING utf8) COLLATE utf8_general_ci
    	AND COLUMN_NAME=convert('queued_time' USING utf8) COLLATE utf8_general_ci;
    	
    IF colExists = 0 THEN
    	ALTER TABLE ANALYSIS_SCENARIO ADD COLUMN queued_time DATETIME NULL;
    	ALTER TABLE ANALYSIS_SCENARIO MODIFY start_time DATETIME NULL;
    	ALTER TABLE ANALYSIS_SCENARIO MODIFY finish_time DATETIME NULL;
    	
    	UPDATE ANALYSIS_SCENARIO SET queued_time = start_time;
    END IF;
    
    SELECT COUNT(1) INTO colExists FROM INFORMATION_SCHEMA.COLUMNS WHERE 
    	TABLE_SCHEMA= convert(database() USING utf8) COLLATE utf8_general_ci
    	AND TABLE_NAME= convert('ANALYSIS_SCENARIO' USING utf8) COLLATE utf8_general_ci
    	AND COLUMN_NAME=convert('server_scenario_id' USING utf8) COLLATE utf8_general_ci;
    	
    IF colExists = 1 THEN
    	ALTER TABLE ANALYSIS_SCENARIO DROP server_scenario_id;
    END IF;
    
END;
;PROC;

DELIMITER ;

CALL OPAUpgradeAnalysisScenario();

-- add column for SOAP action pattern to DATA_SERVICE table
CALL OPAAddColumnIfNotExists('DATA_SERVICE', 'soap_action_pattern', ' VARCHAR(255) CHARACTER SET utf8');

-- update the analysis scenario table
CALL OPAUpgradeAnalysisScenario();

UPDATE CONFIG_PROPERTY SET config_property_public=1 WHERE config_property_name='feature_repository_enabled';
UPDATE CONFIG_PROPERTY SET config_property_public=1 WHERE config_property_name='feature_webservice_datasource';

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
VALUES ('analysis_schemaVersion', NULL, 0, 1, 'Version of the analysis server database schema')
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
VALUES ('log_billingId', NULL, 0, 1, 'billing id sent to the ACS logging system when a loggable event occurs')
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('log_instanceId', NULL, 0, 1, 'instance id sent to the ACS logging system when a loggable event occurs')
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
VALUES ('log_trackingHost', NULL, 0, 1, 'tracking host sent to the ACS logging system when a loggable event occurs')
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
VALUES ('log_enabled', 0, 1, 0)
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
VALUES ('log_outputDirectory', NULL, 0, 0)
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
VALUES ('log_outputRecordPerFile', 0, 1, 0)
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
VALUES ('log_outputRolloverInterval', 0, 1, 0)
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
VALUES ('log_productFamily', NULL, 0, 0)
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
VALUES ('log_engagementRequestSecure', 0, 1, 0)
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
VALUES ('log_ipForwarderPropertyFile', NULL, 0, 0)
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
VALUES ('log_ipForwarderPropertyKey', NULL, 0, 0)
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
VALUES ('max_active_deployments', 0, 1, 1, 'The maximum number of active deployments (interview and web service). 0 = no limit')
ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
  VALUES ('file_attach_max_mb_single', 10, 1, 1, 'Maximum allowed size in megabytes for a single attachment excluding generated forms')
  ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
    
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
  VALUES ('file_attach_max_mb_total', 50, 1, 1, 'Maximum allowed total size in megabytes for session attachments including generated forms')
  ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
    
DELETE FROM CONFIG_PROPERTY WHERE config_property_name = 'analysis_batch_analysisDriverPath';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name = 'analysis_serverKey';

drop table if exists PROJECT_SUMMARY;
drop table if exists PROJECT_SNAPSHOT;
drop table if exists PROJECT_SNAPSHOT_COVERAGE;
drop table if exists PROJECT_SNAPSHOT_REPOS;
drop table if exists PROJECT_DEPLOYMENT;
drop table if exists PROJECT_DEPLOYMENT_HISTORY;
drop table if exists DEPLOYED_RULEBASE_REPOS;
drop table if exists ANALYSIS_SCHEMA;

