-- 12.2.8 upgrade script for Oracle
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
  declare
    table_not_exists exception;
    pragma exception_init (table_not_exists , -00942);
  begin
    execute immediate 'DROP TABLE ' || tableName;
  exception 
    when table_not_exists then null;
  end;
end;
/

-- delim ;

CALL ${username}opa_create_obj_if_not_exists('CREATE SEQUENCE ${username}ssl_certificate_seq START WITH 1 INCREMENT BY 1');

-- Drop the SSL_PUBLIC_CERTIFICATE table in case it has been created incorrectly
-- in this upgrade at step 12.2.5 -> 12.2.6
CALL ${username}opa_drop_table_if_exists('${username}SSL_PUBLIC_CERTIFICATE');

create table ${username}SSL_PUBLIC_CERTIFICATE (
    ssl_certificate_id NUMBER(9) NOT NULL,
    cert_alias VARCHAR(80) NOT NULL,
    certificate CLOB NULL,
    last_updated DATE NULL,
    fingerprint_sha256 VARCHAR(100) NULL,
    fingerprint_sha1 VARCHAR(60) NULL,
    issuer VARCHAR(255) NULL,
    subject VARCHAR(255) NULL,
    valid_from TIMESTAMP NULL,
    valid_to TIMESTAMP NULL,

    CONSTRAINT ssl_certificate_pk PRIMARY KEY (ssl_certificate_id),
    CONSTRAINT ssl_cert_unique_sha256 UNIQUE (fingerprint_sha256),
    CONSTRAINT ssl_cert_unique_sha1 UNIQUE (fingerprint_sha1),
    CONSTRAINT ssl_cert_unique_alias UNIQUE (cert_alias)
) ${tablespace};

-- Add new column
CALL ${username}opa_add_column_if_not_exists('${username}DATA_SERVICE', 'use_trust_store', 'NUMBER(5) DEFAULT 0 NOT NULL');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT', 'activated_javascript_sessions', 'NUMBER(5) DEFAULT 0 NOT NULL');
CALL ${username}opa_add_column_if_not_exists('${username}DEPLOYMENT_ACTIVATION_HISTORY', 'status_javascript_sessions', 'NUMBER(5) DEFAULT 0 NOT NULL');

DELETE FROM ${username}CONFIG_PROPERTY WHERE config_property_name = 'docgen_server_url_pattern';

