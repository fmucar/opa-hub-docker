-- 12.2.5 data upgrade script for Oracle

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

create or replace procedure ${username}opa_modify_column_accepts_null (
    tableName IN VARCHAR2,
    colName IN VARCHAR2
) as
begin
  declare
    already_null exception;
    pragma exception_init (already_null, -1451);
  begin
    execute immediate 'ALTER TABLE ' || tableName || ' MODIFY ' || colName || ' NULL';
  exception
    when already_null then null;
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

create or replace procedure ${username}opa_create_collection_tables as
begin
  declare
    logTable LONG;
    logTable2 LONG;
    logTable3 LONG;
    logTable4 LONG;
    logTable5 LONG;
    logTable6 LONG;
    logGroupSequence LONG;
  begin
    logTable := 'CREATE TABLE ${username}COLLECTION(collection_id NUMBER(9) NOT NULL, collection_name VARCHAR2(127 CHAR) NOT NULL, collection_status NUMBER(5) DEFAULT 1 NOT NULL, collection_description VARCHAR2(255 CHAR), deleted_timestamp DATE NULL, CONSTRAINT collection_pk PRIMARY KEY (collection_id), CONSTRAINT collection_unique_coll_name UNIQUE(collection_name), CONSTRAINT collection_status_check  CHECK(collection_status >= 0 AND collection_status <= 2 )) ${tablespace}';
    logTable2 := 'CREATE TABLE ${username}AUTH_ROLE_COLL (authentication_id NUMBER(9) NOT NULL, role_id NUMBER(9) NOT NULL, collection_id NUMBER(9) NOT NULL, CONSTRAINT auth_role_coll_unique_ids UNIQUE(authentication_id, role_id, collection_id), CONSTRAINT auth_role_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE, CONSTRAINT auth_role_coll_role_id_fk FOREIGN KEY (role_id) REFERENCES ${username}ROLE(role_id) ON DELETE CASCADE, CONSTRAINT auth_role_coll_auth_id_fk FOREIGN KEY (authentication_id) REFERENCES ${username}AUTHENTICATION(authentication_id) ON DELETE CASCADE ) ${tablespace}';
    logTable3 := 'CREATE TABLE ${username}DATA_SERVICE_COLL (data_service_id NUMBER(9) NOT NULL, collection_id NUMBER(9) NOT NULL, CONSTRAINT data_service_coll_unique_ids UNIQUE(data_service_id, collection_id), CONSTRAINT data_service_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE, CONSTRAINT data_service_coll_ds_id_fk FOREIGN KEY (data_service_id) REFERENCES ${username}DATA_SERVICE(data_service_id) ON DELETE CASCADE ) ${tablespace}';
    logTable4 := 'CREATE TABLE ${username}PROJECT_COLL (project_id NUMBER(9) NOT NULL, collection_id NUMBER(9) NOT NULL, CONSTRAINT project_coll_unique_ids UNIQUE(project_id, collection_id), CONSTRAINT project_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE, CONSTRAINT project_coll_project_id_fk FOREIGN KEY (project_id) REFERENCES ${username}PROJECT(project_id) ON DELETE CASCADE ) ${tablespace}';
    logTable5 := 'CREATE TABLE ${username}DEPLOYMENT_COLL (deployment_id NUMBER(9) NOT NULL, collection_id NUMBER(9) NOT NULL, CONSTRAINT deployment_coll_unique_ids UNIQUE(deployment_id, collection_id), CONSTRAINT deployment_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE, CONSTRAINT deployment_coll_deploy_id_fk FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id) ON DELETE CASCADE ) ${tablespace}';
    logTable6 := 'CREATE TABLE ${username}ANALYSIS_WORKSPACE_COLL (analysis_workspace_id NUMBER(9) NOT NULL, collection_id NUMBER(9) NOT NULL, CONSTRAINT aw_coll_unique_ids UNIQUE(analysis_workspace_id, collection_id), CONSTRAINT aw_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE, CONSTRAINT aw_coll_workspace_id_fk FOREIGN KEY (analysis_workspace_id) REFERENCES ${username}ANALYSIS_WORKSPACE(analysis_workspace_id) ON DELETE CASCADE ) ${tablespace}';

    logGroupSequence  := 'CREATE SEQUENCE ${username}collection_seq START WITH 1 INCREMENT BY 1';

    ${username}opa_create_obj_if_not_exists(logTable);
    ${username}opa_create_obj_if_not_exists(logTable2);
    ${username}opa_create_obj_if_not_exists(logTable3);
    ${username}opa_create_obj_if_not_exists(logTable4);
    ${username}opa_create_obj_if_not_exists(logTable5);
    ${username}opa_create_obj_if_not_exists(logTable6);
    ${username}opa_create_obj_if_not_exists(logGroupSequence);
  end; 
end;
/

-- delim ;

-- Create the configuration properties and database table required for Deployment Statistics
CALL ${username}opa_add_column_if_not_exists('${username}AUTHENTICATION', 'hub_admin', 'NUMBER(5) DEFAULT 0 NOT NULL');
CALL ${username}opa_add_column_if_not_exists('${username}DATA_SERVICE', 'metadata', 'CLOB NULL');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_VERSION', 'data_service_id', 'NUMBER(9) NULL');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_VERSION', 'data_service_used', 'NUMBER(5) DEFAULT 0 NOT NULL');
CALL ${username}opa_create_collection_tables();
CALL ${username}opa_modify_column_accepts_null('${username}DATA_SERVICE', 'url');


-- Create initial values for the Grouping table
INSERT INTO ${username}COLLECTION (collection_id, collection_name, collection_status, collection_description)
VALUES (${username}collection_seq.NEXTVAL, 'Default Collection', 0, 'The default collection');

-- Populate initial values for AUTH_COLL from AUTHENTICATION_ROLE table
INSERT INTO ${username}AUTH_ROLE_COLL (authentication_id, role_id, collection_id)
SELECT authentication_id, role_id, (select collection_id from ${username}COLLECTION where collection_name = 'Default Collection') as collection_id FROM ${username}AUTHENTICATION_ROLE;

-- Populate initial values for DATA_SERVICE_COLL table
INSERT INTO ${username}DATA_SERVICE_COLL (data_service_id, collection_id)
SELECT data_service_id, collection_id FROM ${username}DATA_SERVICE, ${username}COLLECTION WHERE collection_name = 'Default Collection'
AND data_service_id NOT IN (select data_service_id FROM ${username}DATA_SERVICE_COLL);

-- Populate initial values for PROJECT_COLL table
INSERT INTO ${username}PROJECT_COLL (project_id, collection_id)
SELECT project_id, collection_id FROM ${username}PROJECT, ${username}COLLECTION WHERE collection_name = 'Default Collection'
AND project_id NOT IN (select project_id FROM ${username}PROJECT_COLL);

-- Populate initial values for DEPLOYMENT_COLL table
INSERT INTO ${username}DEPLOYMENT_COLL (deployment_id, collection_id)
SELECT deployment_id, collection_id FROM ${username}DEPLOYMENT, ${username}COLLECTION WHERE collection_name = 'Default Collection'
AND deployment_id NOT IN (select deployment_id FROM ${username}DEPLOYMENT_COLL);

-- Populate initial values for ANALYSIS_WORKSPACE_COLL table
INSERT INTO ${username}ANALYSIS_WORKSPACE_COLL (analysis_workspace_id, collection_id)
SELECT analysis_workspace_id, collection_id FROM ${username}ANALYSIS_WORKSPACE, ${username}COLLECTION WHERE collection_name = 'Default Collection'
AND analysis_workspace_id NOT IN (select analysis_workspace_id FROM ${username}ANALYSIS_WORKSPACE_COLL);

DELETE FROM ${username}AUTHENTICATION_ROLE;

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
	(SELECT 'feature_compatibility_mode_enabled', 0, 1, 1, '0 = disabled, 1 = enabled. Enabling makes compatibility mode an option for deployments.  Compatibility mode runtime must be installed.' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='feature_compatibility_mode_enabled'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'deployment_max_size_mb', 64, 1, 1, 'Maximum size of any project or deployment that can be uploaded, in millions of bytes.' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='deployment_max_size_mb'));

CALL ${username}opa_modify_column_accepts_null('${username}DATA_SERVICE', 'url');