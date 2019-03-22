-- 12.2.9 data upgrade for MySQL
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

-- Create new table
CREATE TABLE if not exists DEPLOYMENT_CHANNEL_DEFAULT
(
  channel_default_id INT NOT NULL AUTO_INCREMENT,
  collection_id INT NOT NULL,
  default_interview SMALLINT NOT NULL DEFAULT 0,
  default_webservice SMALLINT NOT NULL DEFAULT 0,
  default_mobile SMALLINT NOT NULL DEFAULT 0,
  default_javascript_sessions SMALLINT NOT NULL DEFAULT 0,
  defaults_can_override SMALLINT NOT NULL DEFAULT 1,
  CONSTRAINT channel_default_idx PRIMARY KEY (channel_default_id),
  CONSTRAINT channel_default_id_uq UNIQUE (channel_default_id),
  CONSTRAINT collection_id_uq UNIQUE (collection_id),
  CONSTRAINT collection_channel_fk
    FOREIGN KEY (collection_id)
    REFERENCES COLLECTION (collection_id)
    ON DELETE CASCADE,
  CONSTRAINT default_interview_check CHECK(default_interview >= 0 AND default_interview <= 1),
  CONSTRAINT default_webservice_check CHECK(default_webservice >= 0 AND default_webservice <= 1),
  CONSTRAINT default_mobile_check CHECK(default_mobile >= 0 AND default_mobile <= 1),
  CONSTRAINT default_javascript_check CHECK(default_javascript_sessions >= 0 AND default_javascript_sessions <= 1),
  CONSTRAINT default_override_check CHECK(defaults_can_override >= 0 AND defaults_can_override <= 1)
) ENGINE = InnoDB;

-- drop analysis tables
DROP TABLE IF EXISTS ANALYSIS_CHART;
DROP TABLE IF EXISTS ANALYSIS_PARAMETER;
DROP TABLE IF EXISTS ANALYSIS_SCENARIO;
DROP TABLE IF EXISTS ANALYSIS_WORKSPACE_COLL;
DROP TABLE IF EXISTS ANALYSIS_WORKSPACE;

-- remove analytics properties
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_batch_blockSize';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_batch_dbDriver';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_batch_dbDriverPath';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_batch_procCount';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_batch_procLimit';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_batch_procPath';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_batch_procType';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_schemaVersion';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='analysis_serverURL';
DELETE FROM CONFIG_PROPERTY WHERE config_property_name='feature_analytics_enabled';

-- remove analytics permissions
DELETE FROM AUTH_ROLE_COLL WHERE role_id IN (select role_id FROM ROLE WHERE role_name='Analysis');
DELETE FROM ROLE WHERE role_name='Analysis';

-- analysis data services
DELETE FROM DATA_SERVICE WHERE service_type IN ('AnalysisOutput', 'Analysis');

-- New configuration property for allowing/preventing OPA for Human Resources Help Desk usage
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('runtime_enabled_for_employees', 0, 1, 1, '0 = disabled, 1 = enabled. If enabled, interviews are allowed only for employees. Ignored if runtime_disabled_for_users is zero.')   
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT into CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('wsc_req_timeout_for_metadata', 20, 1, 1, 'Read timeout in seconds for each Web Service metadata request. One request is made per Hub Model Refresh operation.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('hub_cors_whitelist', '*', 0, 1, 'A ; list of whitelisted servers able to make cross site requests to OPA-Hub.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('det_server_cors_whitelist', '*', 0, 1, 'A ; list of whitelisted servers able to make cross site requests to Determinations Server.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT into CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
    VALUES ('idcs_audience', null, 0, 0)
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT into CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
    VALUES ('idcs_client_id', null, 0, 0)
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT into CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
    VALUES ('idcs_client_sec', null, 0, 0)
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT into CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
    VALUES ('idcs_url', null, 0, 0)
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('clamd_location', null, 0, 1, 'The clamd location, either local path or TCP socket, for virus scanning deployment or project data.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

UPDATE CONFIG_PROPERTY 
    SET config_property_description='0 = internally managed, 1 = externally managed by app server, 2 = externally managed by IDCS'
    WHERE config_property_name='externally_managed_identity';


ALTER TABLE CONFIG_PROPERTY MODIFY COLUMN config_property_str_value varchar(2048) CHARACTER SET utf8;

-- Update statistics charts that use superceded type definitions.
UPDATE STATISTICS_CHART 
	SET chart_type = 'INTERVIEWS_BY_SCREEN_STATE', 
	    chart_data = REPLACE(REPLACE(chart_data,'"ivw_by_screen"','"ivw_by_screen_state"'),'"INTERVIEWS_BY_SCREEN"','"INTERVIEWS_BY_SCREEN_STATE"')
	WHERE chart_type = 'INTERVIEWS_BY_SCREEN';

