-- Upgrade script for Oracle

-- delim /
create or replace procedure ${username}opa_add_column_if_not_exists (
    tableName IN VARCHAR2,
    colName IN VARCHAR2,
    colDef IN VARCHAR2
) as
begin 
  declare
    column_exists exception;
    pragma exception_init (column_exists , -01430);
  begin
    execute immediate 'ALTER TABLE ' || tableName || ' ADD ' || colName || ' ' || colDef;
  exception 
    when column_exists then null;
  end;
end;
/

create or replace procedure ${username}opa_upgrade_analysis_scenario as
    column_exists exception;
    column_not_exists exception;
    pragma exception_init (column_exists, -01430);
    pragma exception_init (column_not_exists, -00904);
  begin
    execute immediate 'ALTER TABLE ANALYSIS_SCENARIO ADD queued_time DATE';
    execute immediate 'UPDATE ANALYSIS_SCENARIO SET queued_time = start_time';
    execute immediate 'ALTER TABLE ANALYSIS_SCENARIO DROP COLUMN server_scenario_id';
  exception
    when column_exists then null;
    when column_not_exists then null;
  end;
/
-- delim ;

CALL ${username}opa_add_column_if_not_exists('${username}DATA_SERVICE', 'soap_action_pattern', 'VARCHAR2(255 CHAR)');

CALL ${username}opa_upgrade_analysis_scenario();

UPDATE ${username}CONFIG_PROPERTY SET config_property_public=1 WHERE config_property_name='feature_repository_enabled';
UPDATE ${username}CONFIG_PROPERTY SET config_property_public=1 WHERE config_property_name='feature_webservice_datasource';

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
	(SELECT 'analysis_schemaVersion', NULL, 0, 1, 'Version of the analysis server database schema' FROM DUAL 
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_schemaVersion'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
	(SELECT 'log_billingId', NULL, 0, 1, 'billing id sent to the ACS logging system when a loggable event occurs' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_billingId'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
	(SELECT 'log_instanceId', NULL, 0, 1, 'instance id sent to the ACS logging system when a loggable event occurs'  FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_instanceId'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
	(SELECT 'log_trackingHost', NULL, 0, 1, 'tracking host sent to the ACS logging system when a loggable event occurs' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_trackingHost'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
	(SELECT 'log_enabled', 0, 1, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_enabled'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
	(SELECT 'log_outputDirectory', NULL, 0, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_outputDirectory'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
	(SELECT 'log_outputRecordPerFile', 0, 1, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_outputRecordPerFile'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
	(SELECT 'log_outputRolloverInterval', 0, 1, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_outputRolloverInterval'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
	(SELECT 'log_productFamily', NULL, 0, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_productFamily'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
	(SELECT 'log_engagementRequestSecure', 0, 1, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_engagementRequestSecure'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
	(SELECT 'log_ipForwarderPropertyFile', NULL, 0, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_ipForwarderPropertyFile'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
	(SELECT 'log_ipForwarderPropertyKey', NULL, 0, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='log_ipForwarderPropertyKey'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
	(SELECT 'max_active_deployments', 0, 1, 1, 'The maximum number of active deployments (interview and web service). 0 = no limit' FROM DUAL 
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='max_active_deployments'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'file_attach_max_mb_single', 10, 1, 1, 'Maximum allowed size in megabytes for a single attachment excluding generated forms' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='file_attach_max_mb_single'));
    
INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'file_attach_max_mb_total', 50, 1, 1, 'Maximum allowed total size in megabytes for session attachments including generated forms' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='file_attach_max_mb_total'));

DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name = 'analysis_batch_analysisDriverPath';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name = 'analysis_serverKey';