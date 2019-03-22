-- 12.2.4 schema upgrade script for Oracle

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
	-- Session statistics template table
	${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}SESSION_STATS_TEMPLATE (session_stats_template_id NUMBER(9) NOT NULL,deployment_id NUMBER(9) NOT NULL,deployment_version_id NUMBER(9) NOT NULL,CONSTRAINT SESSION_STATS_TEMPLATE_PK PRIMARY KEY (session_stats_template_id),CONSTRAINT SESSION_STATS_TEMPLATE_UQ UNIQUE (deployment_id, deployment_version_id),CONSTRAINT SESS_STATS_TEMPL_DEPLOY_ID FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id),CONSTRAINT SESS_STATS_TEMPL_VERSION_ID FOREIGN KEY (deployment_version_id) REFERENCES ${username}DEPLOYMENT_VERSION(deployment_version_id))${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}session_stats_template_seq START WITH 1 INCREMENT BY 1');
	
	-- Session screen template table
	${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}SESSION_SCREEN_TEMPLATE (session_screen_template_id NUMBER(9) NOT NULL, session_stats_template_id NUMBER(9) NOT NULL, screen_id VARCHAR(50) NOT NULL, screen_title VARCHAR(255) NOT NULL, screen_action_code NUMBER(9) NOT NULL, screen_order NUMBER(9) NOT NULL, CONSTRAINT SESSION_SCREEN_TEMPLATE_PK PRIMARY KEY (session_screen_template_id), CONSTRAINT SESSION_SCREEN_TEMPLATE_UQ UNIQUE (session_stats_template_id, screen_id), CONSTRAINT SESS_SCR_TEMPL_SESS_TEMPL_FK FOREIGN KEY (session_stats_template_id) REFERENCES ${username}SESSION_STATS_TEMPLATE(session_stats_template_id) )${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}session_screen_template_seq START WITH 1 INCREMENT BY 1');

	-- Session statistics log table
	${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}SESSION_STATS_LOG (session_stats_log_id NUMBER(19) NOT NULL, session_stats_template_id NUMBER(9) NOT NULL, deployment_id NUMBER(9) NOT NULL, deployment_version_id NUMBER(9) NOT NULL, product_code NUMBER(9) NOT NULL, product_version VARCHAR(25) NOT NULL, product_function_code NUMBER(9) NOT NULL, created_timestamp TIMESTAMP NOT NULL, created_year NUMBER(9) NOT NULL, created_month NUMBER(9) NOT NULL, created_day NUMBER(19) NOT NULL, created_hour NUMBER(19) NOT NULL, last_modified_timestamp TIMESTAMP NOT NULL, last_modified_year NUMBER(9) NOT NULL, last_modified_month NUMBER(9) NOT NULL, last_modified_day NUMBER(19) NOT NULL, last_modified_hour NUMBER(19) NOT NULL, duration_millis NUMBER(19) NOT NULL, duration_sec NUMBER(19) NOT NULL, duration_min NUMBER(19) NOT NULL, screens_visited NUMBER(9) NOT NULL, auth_id RAW(16) NULL, authenticated NUMBER(5) NOT NULL, completed NUMBER(5) NOT NULL, CONSTRAINT SESSION_STATS_LOG_PK PRIMARY KEY (session_stats_log_id), CONSTRAINT SESS_STATS_SESS_TEMPL_FK FOREIGN KEY (session_stats_template_id) REFERENCES ${username}SESSION_STATS_TEMPLATE(session_stats_template_id), CONSTRAINT SESS_STATS_DEPLOYMENT_FK FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id), CONSTRAINT SESS_STATS_VERSION_FK FOREIGN KEY (deployment_version_id) REFERENCES ${username}DEPLOYMENT_VERSION(deployment_version_id) )${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}USAGE_TREND_IDX ON ${username}SESSION_STATS_LOG(created_hour, deployment_id) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SESS_BY_DEPL_IDX ON ${username}SESSION_STATS_LOG(deployment_id, product_function_code, auth_id, created_timestamp) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SESS_BY_DEPL_DURATION_IDX ON ${username}SESSION_STATS_LOG(deployment_id, product_function_code, auth_id, created_timestamp, duration_min) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SESS_BY_DEPL_SCREENS_IDX ON ${username}SESSION_STATS_LOG(deployment_id, product_function_code, auth_id, created_timestamp, screens_visited) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SESS_BY_VERS_IDX ON ${username}SESSION_STATS_LOG(deployment_version_id, product_function_code, auth_id, created_timestamp) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SESS_BY_VERS_DURATION_IDX ON ${username}SESSION_STATS_LOG(deployment_version_id, product_function_code, auth_id, created_timestamp, duration_min) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SESS_BY_VERS_SCREENS_IDX ON ${username}SESSION_STATS_LOG(deployment_version_id, product_function_code, auth_id, created_timestamp, screens_visited) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SESS_BY_CREATED_DAY ON ${username}SESSION_STATS_LOG(created_timestamp, created_day) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SESS_BY_CREATED_MONTH ON ${username}SESSION_STATS_LOG(created_timestamp, created_month) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}session_stats_log_seq START WITH 1 INCREMENT BY 1');

	-- Session screen log table
	${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}SESSION_SCREEN_LOG (session_screen_log_id NUMBER(19) NOT NULL, session_stats_log_id NUMBER(19) NOT NULL, session_stats_template_id NUMBER(9) NOT NULL, deployment_id NUMBER(9) NOT NULL, deployment_version_id NUMBER(9) NOT NULL, product_code NUMBER(9) NOT NULL, product_version VARCHAR(25) NOT NULL, product_function_code NUMBER(9) NOT NULL, session_created_timestamp TIMESTAMP NOT NULL, auth_id RAW(16) NULL, authenticated NUMBER(5) NOT NULL, screen_id VARCHAR(50) NOT NULL, screen_order NUMBER(9) NOT NULL, screen_action_code NUMBER(9) NOT NULL, screen_sequence NUMBER(9) NOT NULL, entry_transition_code NUMBER(5) NOT NULL, entry_timestamp TIMESTAMP NOT NULL, submit_timestamp TIMESTAMP NULL, exit_transition_code NUMBER(5) NULL, exit_timestamp TIMESTAMP NULL, duration_millis NUMBER(19) NOT NULL, duration_sec NUMBER(19) NOT NULL, duration_min NUMBER(19) NOT NULL, CONSTRAINT SESSION_SCREEN_LOG_PK PRIMARY KEY (session_screen_log_id), CONSTRAINT SESSION_SCREEN_STATS_LOG_FK FOREIGN KEY (session_stats_log_id) REFERENCES ${username}SESSION_STATS_LOG (session_stats_log_id), CONSTRAINT SESSION_SCREEN_STATS_TEMPL_FK FOREIGN KEY (session_stats_template_id) REFERENCES ${username}SESSION_STATS_TEMPLATE (session_stats_template_id), CONSTRAINT SESSION_SCREEN_DEPLOYMENT_FK FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT (deployment_id), CONSTRAINT SESSION_SCREEN_DEPL_VERS_FK FOREIGN KEY (deployment_version_id) REFERENCES ${username}DEPLOYMENT_VERSION (deployment_version_id)) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SCREEN_BY_SESSION_ID_IDX ON ${username}SESSION_SCREEN_LOG(session_stats_log_id) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}SCREEN_BY_VERS_ID_ACTION_IDX ON ${username}SESSION_SCREEN_LOG(deployment_version_id, session_created_timestamp, screen_id, screen_action_code) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}session_screen_log_seq START WITH 1 INCREMENT BY 1');
	
	-- Chart tables
	${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}STATISTICS_CHART (statistics_chart_id NUMBER(9) NOT NULL, chart_type VARCHAR(30) NOT NULL, chart_data CLOB NOT NULL, CONSTRAINT STATISTICS_CHART_PK PRIMARY KEY (statistics_chart_id)) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}statistics_chart_seq START WITH 1 INCREMENT BY 1');
	${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}DEPLOYMENT_STATS_CHART (deployment_stats_chart_id NUMBER(9) NOT NULL, statistics_chart_id NUMBER(9) NOT NULL, deployment_id NUMBER(9) NOT NULL, chart_number NUMBER(9) NOT NULL, CONSTRAINT DEPLOYMENT_STATS_CHART_PK PRIMARY KEY (deployment_stats_chart_id), CONSTRAINT DEPL_CHART_STAT_CHART_FK FOREIGN KEY (statistics_chart_id) REFERENCES ${username}STATISTICS_CHART(statistics_chart_id), CONSTRAINT DEPL_CHART_DEPLOYMENT_FK FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id)) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}deployment_stats_chart_seq START WITH 1 INCREMENT BY 1');
	${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}OVERVIEW_STATS_CHART (overview_stats_chart_id NUMBER(9) NOT NULL, statistics_chart_id NUMBER(9) NOT NULL, chart_number NUMBER(9) NOT NULL,	CONSTRAINT OVERVIEW_STATS_CHART_PK PRIMARY KEY (overview_stats_chart_id), CONSTRAINT OVER_CHART_STAT_CHART_FK FOREIGN KEY (statistics_chart_id) REFERENCES ${username}STATISTICS_CHART(statistics_chart_id)) ${tablespace}');
	${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}overview_stats_chart_seq START WITH 1 INCREMENT BY 1');
end;
/

-- delim ;

CALL ${username}opa_add_column_if_not_exists('${username}DATA_SERVICE', 'rn_shared_secret', 'VARCHAR2(255 CHAR)');

CALL ${username}opa_create_statistics_tables();