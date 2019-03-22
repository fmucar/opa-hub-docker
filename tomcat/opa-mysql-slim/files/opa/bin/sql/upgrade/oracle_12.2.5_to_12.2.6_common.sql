-- 12.2.5 upgrade script for Oracle

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

create or replace procedure ${username}opa_drop_column_if_exists (
    tableName IN VARCHAR2,
    colName IN VARCHAR2
) as
begin 
  declare
    column_not_exists exception;
    pragma exception_init (column_not_exists , -00904);
  begin
    execute immediate 'ALTER TABLE ' || tableName || ' DROP COLUMN ' || colName;
  exception 
    when column_not_exists then null;
  end;
end;
/

-- delim ;

-- create sequence
CREATE SEQUENCE ${username}ssl_certificate_seq START WITH 1 INCREMENT BY 1;


-- increase user name size
ALTER TABLE ${username}AUTHENTICATION MODIFY user_name VARCHAR2(255 CHAR);
ALTER TABLE ${username}DEPLOYMENT_ACTION_LOG MODIFY user_id VARCHAR2(255 CHAR);

-- Add new columns
CALL ${username}opa_add_column_if_not_exists('${username}AUTHENTICATION', 'user_type', 'NUMBER(5) DEFAULT 0 NOT NULL');

-- just in case this script has already been run, temporarily create the onld rows
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT', 'activator_id', 'INT');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_ACTIVATION_HISTORY', 'authentication_id', 'INT');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_VERSION', 'creator_authentication_id', 'INT');
CALL ${username}opa_add_column_if_not_exists('${username}PROJECT_VERSION', 'creator_authentication_id', 'INT');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT', 'user_name', 'VARCHAR2(255 CHAR)');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_VERSION', 'user_name', 'VARCHAR2(255 CHAR)');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_ACTIVATION_HISTORY', 'user_name', 'VARCHAR2(255 CHAR)');
CALL ${username}opa_add_column_if_not_exists('${username}PROJECT_VERSION', 'user_name', 'VARCHAR2(255 CHAR)');
CALL ${username}opa_add_column_if_not_exists('${username}SECURITY_TOKEN', 'is_long_term', 'NUMBER(5) DEFAULT 0 NOT NULL');

UPDATE ${username}DEPLOYMENT D set user_name = (SELECT A.user_name from ${username}AUTHENTICATION A WHERE D.activator_id = A.authentication_id) WHERE user_name IS NULL;
UPDATE ${username}DEPLOYMENT_ACTIVATION_HISTORY H set user_name = (SELECT A.user_name from ${username}AUTHENTICATION A WHERE H.authentication_id = A.authentication_id) WHERE user_name IS NULL;
UPDATE ${username}DEPLOYMENT_VERSION V set user_name = (SELECT A.user_name from ${username}AUTHENTICATION A WHERE V.creator_authentication_id = A.authentication_id) WHERE user_name IS NULL;
UPDATE ${username}PROJECT_VERSION V set user_name = (SELECT A.user_name from ${username}AUTHENTICATION A WHERE V.creator_authentication_id = A.authentication_id) WHERE user_name IS NULL;

-- property changes (cloud and private-cloud)
INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'externally_managed_identity', 0, 1, 0, '0 = disable, 1 = enabled. Enable for users which are managed and authenticated externally' FROM DUAL 
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='externally_managed_identity'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'external_logout_url', null, 0, 1, 'Used for logging out of externally managed opa site' FROM DUAL 
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='external_logout_url'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'file_attach_name_max_chars', 100, 1, 1, 'Maximum number of characters allowed in a file attachment name' FROM DUAL 
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='file_attach_name_max_chars'));

-- remove user id columns
CALL ${username}opa_drop_column_if_exists('${username}DEPLOYMENT', 'activator_id');
CALL ${username}opa_drop_column_if_exists('${username}DEPLOYMENT_ACTIVATION_HISTORY', 'authentication_id');
CALL ${username}opa_drop_column_if_exists('${username}DEPLOYMENT_VERSION', 'creator_authentication_id');
CALL ${username}opa_drop_column_if_exists('${username}PROJECT_VERSION', 'creator_authentication_id');


