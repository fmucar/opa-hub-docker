-- 12.2.10 upgrade script for Oracle
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

-- delim ;

-- Add new column
CALL ${username}opa_add_column_if_not_exists('${username}SESSION_STATS_LOG', 'product_function_version', 'VARCHAR(25)');

-- New configuration property

