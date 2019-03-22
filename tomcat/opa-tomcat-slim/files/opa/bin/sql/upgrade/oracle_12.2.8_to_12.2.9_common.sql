-- 12.2.9 upgrade script for Oracle
-- delim /
create or replace procedure ${username}opa_create_obj_if_not_exists (
	objectDef IN VARCHAR2
) as
begin
  declare
    object_exists exception;
    pragma exception_init (object_exists, -955);
  begin
    execute immediate objectDef;
  exception
    when object_exists then null;
  end;
end; 
/

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

create or replace procedure ${username}opa_drop_table_if_exists (
    tableName IN VARCHAR2
) as
begin 
    execute immediate 'DROP TABLE ' || tableName;
exception
   when others then
      if SQLCODE != -942 then
         RAISE;
      end if;
end;
/

create or replace procedure ${username}opa_drop_sequence_if_exists (
    seqName IN VARCHAR2
) as
begin 
    execute immediate 'DROP SEQUENCE ' || seqName;
exception
   when others then
      if SQLCODE != -2289 then
         RAISE;
      end if;
end;
/

-- delim ;

CALL ${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}deployment_channel_default_seq START WITH 1 INCREMENT BY 1');
CALL ${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}DEPLOYMENT_CHANNEL_DEFAULT (channel_default_id NUMBER(9) NOT NULL, collection_id NUMBER(9) NOT NULL, default_interview NUMBER(5) DEFAULT 0 NOT NULL, default_webservice NUMBER(5) DEFAULT 0 NOT NULL, default_mobile NUMBER(5) DEFAULT 0 NOT NULL, default_javascript_sessions NUMBER(5) DEFAULT 0 NOT NULL, defaults_can_override NUMBER(5) DEFAULT 1 NOT NULL, CONSTRAINT channel_default_idx PRIMARY KEY (channel_default_id), CONSTRAINT collection_id_uq UNIQUE (collection_id), CONSTRAINT collection_channel_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION (collection_id) ON DELETE CASCADE, CONSTRAINT default_interview_check CHECK(default_interview >= 0 AND default_interview <= 1), CONSTRAINT default_webservice_check CHECK(default_webservice >= 0 AND default_webservice <= 1), CONSTRAINT default_mobile_check CHECK(default_mobile >= 0 AND default_mobile <= 1), CONSTRAINT default_javascript_check CHECK(default_javascript_sessions >= 0 AND default_javascript_sessions <= 1), CONSTRAINT default_override_check CHECK(defaults_can_override >= 0 AND defaults_can_override <= 1) ) ${tablespace}');

CALL opa_drop_sequence_if_exists('${username}analysis_workspace_seq');
CALL opa_drop_sequence_if_exists('${username}analysis_scenario_seq');
CALL opa_drop_sequence_if_exists('${username}analysis_parameter_seq');
CALL opa_drop_sequence_if_exists('${username}analysis_chart_seq');

CALL opa_drop_table_if_exists('${username}ANALYSIS_CHART');
CALL opa_drop_table_if_exists('${username}ANALYSIS_PARAMETER');
CALL opa_drop_table_if_exists('${username}ANALYSIS_SCENARIO');
CALL opa_drop_table_if_exists('${username}ANALYSIS_WORKSPACE_COLL');
CALL opa_drop_table_if_exists('${username}ANALYSIS_WORKSPACE');

-- remove analytics properties
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_batch_blockSize';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_batch_dbDriver';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_batch_dbDriverPath';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_batch_procCount';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_batch_procLimit';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_batch_procPath';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_batch_procType';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_schemaVersion';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='analysis_serverURL';
DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name='feature_analytics_enabled';

-- Add new column
CALL ${username}opa_add_column_if_not_exists('${username}SNAPSHOT', 'fingerprint_sha256', 'VARCHAR2(65 CHAR)');
CALL ${username}opa_add_column_if_not_exists('${username}SNAPSHOT', 'scan_status', 'NUMBER(5) DEFAULT 0 NOT NULL');
CALL ${username}opa_add_column_if_not_exists('${username}SNAPSHOT', 'scan_message', 'VARCHAR2(255 CHAR)');

-- remove analytics permissions
DELETE FROM ${username}AUTH_ROLE_COLL WHERE role_id IN (select role_id FROM ROLE WHERE role_name='Analysis');
DELETE FROM ${username}ROLE WHERE role_name='Analysis';

-- analysis data services
DELETE FROM ${username}DATA_SERVICE WHERE service_type IN ('AnalysisOutput', 'Analysis');

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'runtime_enabled_for_employees', 0, 1, 0, '0 = disabled, 1 = enabled. If enabled, interviews are allowed only for employees. Ignored if runtime_disabled_for_users is zero.'  FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='runtime_enabled_for_employees'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'wsc_req_timeout_for_metadata', 20, 1, 1, 'Read timeout in seconds for each Web Service metadata request. One request is made per Hub Model Refresh operation.'  FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='wsc_req_timeout_for_metadata'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'hub_cors_whitelist', '*', 0, 1, 'A ; list of whitelisted servers able to make cross site requests to OPA-Hub.'   FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='hub_cors_whitelist'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'det_server_cors_whitelist', '*', 0, 1, 'A ; list of whitelisted servers able to make cross site requests to Determinations Server.'   FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='det_server_cors_whitelist'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
    (SELECT 'idcs_audience', null, 0, 0 FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='idcs_audience'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
    (SELECT 'idcs_client_id', null, 0, 0 FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='idcs_client_id'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
    (SELECT 'idcs_client_sec', null, 0, 0 FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='idcs_client_sec'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public)
    (SELECT 'idcs_url', null, 0, 0 FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='idcs_url'));

UPDATE ${username}CONFIG_PROPERTY 
    SET config_property_description='0 = internally managed, 1 = externally managed by app server, 2 = externally managed by IDCS'
    WHERE config_property_name='externally_managed_identity';
    
ALTER TABLE ${username}CONFIG_PROPERTY MODIFY config_property_str_value VARCHAR2(2048 CHAR);

-- Upgrade the statistics charts using the superceded INVERVIEWS_BY_SCREEN data type.
UPDATE ${username}STATISTICS_CHART
	SET chart_type='INTERVIEWS_BY_SCREEN_STATE', chart_data=replace(replace(chart_data, '"ivw_by_screen"', '"ivw_by_screen_state"'), '"INTERVIEWS_BY_SCREEN"', '"INTERVIEWS_BY_SCREEN_STATE"')
	WHERE chart_type = 'INTERVIEWS_BY_SCREEN';