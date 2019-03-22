-- 12.2.12 data upgrade script for Oracle
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


-- delim ;

CALL ${username}opa_create_obj_if_not_exists('CREATE TABLE ${username}AUDIT_LOG ( audit_id NUMBER(9) NOT NULL, audit_date DATE NOT NULL, auth_id NUMBER(9) NULL, auth_name VARCHAR(100 CHAR) NULL, description CLOB NULL, object_type VARCHAR(50 CHAR) NULL, object_id NUMBER(9) NULL, operation VARCHAR(50 CHAR) NULL, result NUMBER(9) NULL, extension CLOB NULL, CONSTRAINT audit_primary_key PRIMARY KEY (audit_id)) ${tablespace}');
CALL ${username}opa_create_obj_if_not_exists('CREATE INDEX ${username}audit_date_idx ON ${username}AUDIT_LOG(audit_date) ${tablespace}');
CALL ${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}audit_seq START WITH 1 INCREMENT BY 1');
	
INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'audit_enabled', 1, 1, 1,  '0 = disabled, 1 = enabled. Enabling turns on the audit writing' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='audit_enabled'));
