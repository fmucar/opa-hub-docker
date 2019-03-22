-- 12.2.13 upgrade script for Oracle
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

create or replace procedure ${username}opa_add_index_if_not_exists (
  tableName in varchar2,
  indexName in varchar2,
  indexDef in varchar2
) as
  begin
    declare
      index_exists exception;
      cols_already_indexed exception;
      pragma exception_init (index_exists, -955);
      pragma exception_init (cols_already_indexed, -1408);
    begin
	  execute immediate 'CREATE INDEX ' || indexName || ' ON ' || tableName || ' ' || indexDef;
	exception
	  when index_exists then null;
	  when cols_already_indexed then null;
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

create or replace procedure ${username}opa_create_func_stats_table as
begin
  declare 
    tbl LONG;
    idx LONG;
    seq LONG;
  begin
	tbl := 'CREATE TABLE ${username}FUNCTION_STATS_LOG (function_stats_log_id NUMBER(9) NOT NULL, deployment_id NUMBER(9) NOT NULL, product_code NUMBER(9) NOT NULL, product_function_code NUMBER(9) NOT NULL, product_function_version VARCHAR(25) NOT NULL, last_used_timestamp DATE NOT NULL, CONSTRAINT FUNCTION_STATS_LOG_PK PRIMARY KEY (function_stats_log_id), CONSTRAINT FUNCTION_STATS_LOG_UQ UNIQUE (deployment_id, product_code, product_function_code, product_function_version), CONSTRAINT FUNCTION_STATS_DEPLOY_FK FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id) ) ${tablespace}';
	idx := 'CREATE INDEX ${username}FUNCTION_USAGE_OBSOLETE_IDX ON ${username}FUNCTION_STATS_LOG(last_used_timestamp, product_code, product_function_code, product_function_version, deployment_id) ${tablespace}';
	seq := 'CREATE SEQUENCE ${username}function_stats_log_seq START WITH 1 INCREMENT BY 1';
	
	${username}opa_create_obj_if_not_exists(tbl);
	${username}opa_create_obj_if_not_exists(idx);
	${username}opa_create_obj_if_not_exists(seq);
  end;
end;
/

-- delim ;

CALL ${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}ssl_private_key_seq START WITH 1 INCREMENT BY 1');

create table ${username}SSL_PRIVATE_KEY (
	ssl_private_key_id NUMBER(9) NOT NULL,
    key_name VARCHAR(80) NOT NULL,
	keystore CLOB NULL,
	last_updated DATE NULL,
	fingerprint_sha256 VARCHAR(100) NULL,
    fingerprint_sha1 VARCHAR(60) NULL,
    issuer VARCHAR(255) NULL,
    subject VARCHAR(255) NULL,
    valid_from TIMESTAMP NULL,
    valid_to TIMESTAMP NULL,

	CONSTRAINT ssl_private_key_pk PRIMARY KEY (ssl_private_key_id),
	CONSTRAINT priv_fingerprint_sha256_uq UNIQUE (fingerprint_sha256),
	CONSTRAINT priv_fingerprint_sha1_uq UNIQUE (fingerprint_sha1),
	CONSTRAINT ssl_key_name_unique UNIQUE (key_name)
) ${tablespace};

-- Add new column
CALL ${username}opa_add_column_if_not_exists('${username}DATA_SERVICE', 'ssl_private_key', 'VARCHAR(80) NULL');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT', 'activated_chatservice', 'NUMBER(5) DEFAULT 0 NOT NULL');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_ACTIVATION_HISTORY', 'status_chatservice', 'NUMBER(5) DEFAULT 0 NOT NULL');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_CHANNEL_DEFAULT', 'default_chatservice', 'NUMBER(5) DEFAULT 0 NOT NULL');

INSERT INTO ${username}ROLE (role_id, role_name)
    (SELECT ${username}role_seq.NEXTVAL, 'Chat Service' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}ROLE WHERE role_name='Chat Service'));


INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'opa_app_version', NULL, 0, 1, 'Latest version of the Hub that can access this schema' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='opa_app_version'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'feature_chat_service_enabled', 0, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the Chat Service feature' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='feature_chat_service_enabled'));
