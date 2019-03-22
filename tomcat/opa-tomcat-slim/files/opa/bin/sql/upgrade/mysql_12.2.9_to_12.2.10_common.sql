-- 12.2.10 data upgrade for MySQL
DROP PROCEDURE IF EXISTS OPAAddColumnIfNotExists;

DELIMITER ;PROC;
CREATE PROCEDURE OPAAddColumnIfNotExists(
  tableName VARCHAR(64),
  colName VARCHAR(64),
  colDef VARCHAR(2048)
)
DETERMINISTIC
  BEGIN
    DECLARE colExists INT;
    DECLARE dbName VARCHAR(64);
    SELECT database() INTO dbName;
    SELECT COUNT(1) INTO colExists
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = convert(dbName USING utf8) COLLATE utf8_general_ci
          AND TABLE_NAME = convert(tableName USING utf8) COLLATE utf8_general_ci
          AND COLUMN_NAME = convert(colName USING utf8) COLLATE utf8_general_ci;
    IF colExists = 0 THEN
      SET @sql = CONCAT('ALTER TABLE ', tableName, ' ADD COLUMN ', colName, ' ', colDef);
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
    END IF;
  END;
;PROC;

DELIMITER ;

-- Add new columns
CALL OPAAddColumnIfNotExists('SESSION_STATS_LOG', 'product_function_version', 'VARCHAR(25) DEFAULT NULL');
