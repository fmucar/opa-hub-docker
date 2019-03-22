-- Upgrade script for Oracle

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

create or replace procedure ${username}opa_create_statistics_tables as
begin
  declare
    logTable LONG;
    logYearIndex LONG;
    logMonthIndex LONG;
    logDayIndex LONG;
    logHourIndex LONG;
  begin
	logTable := 'CREATE TABLE ${username}DEPLOYMENT_ACTION_LOG(action_timestamp timestamp NOT NULL, action_year int NOT NULL, action_month int NOT NULL, action_day int NOT NULL, action_hour int NOT NULL, deployment_name varchar(255) NOT NULL, product_name varchar(50) NOT NULL, product_version varchar(50) NOT NULL, session_id varchar(32) NOT NULL, user_id varchar(127), subject varchar(50) NOT NULL, verb varchar(50) NOT NULL )${tablespace}';

    logYearIndex  := 'CREATE INDEX ${username}deploy_act_log_name_year ON ${username}DEPLOYMENT_ACTION_LOG(deployment_name, action_year) ${tablespace}';
    logMonthIndex := 'CREATE INDEX ${username}deploy_act_log_name_month ON ${username}DEPLOYMENT_ACTION_LOG(deployment_name, action_month) ${tablespace}';
    logDayIndex   := 'CREATE INDEX ${username}deploy_act_log_name_day ON ${username}DEPLOYMENT_ACTION_LOG(deployment_name, action_day) ${tablespace}';
    logHourIndex  := 'CREATE INDEX ${username}deploy_act_log_name_hour ON ${username}DEPLOYMENT_ACTION_LOG(deployment_name, action_hour) ${tablespace}';
       
    ${username}opa_create_obj_if_not_exists(logTable);
    ${username}opa_create_obj_if_not_exists(logYearIndex);
    ${username}opa_create_obj_if_not_exists(logMonthIndex);
    ${username}opa_create_obj_if_not_exists(logDayIndex);
    ${username}opa_create_obj_if_not_exists(logHourIndex);
  end; 
end;
/

-- delim ;

-- Create the configuration properties and database table required for Deployment Statistics
CALL ${username}opa_create_statistics_tables();

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
	(SELECT 'feature_deployment_stats_enabled', 1, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on Deployment Statistics feature' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='feature_deployment_stats_enabled'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
	(SELECT 'deployment_stats_logging_interval', 60, 1, 0 FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='deployment_stats_logging_interval'));

