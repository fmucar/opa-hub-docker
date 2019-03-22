-- 12.2.8 data upgrade for MySQL
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
CALL OPAAddColumnIfNotExists('DATA_SERVICE', 'use_trust_store', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT', 'activated_javascript_sessions', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_ACTIVATION_HISTORY', 'status_javascript_sessions', 'SMALLINT DEFAULT 0 NOT NULL');

-- Drop the SSL_PUBLIC_CERTIFICATE table in case it has been created incorrectly
-- in this upgrade at step 12.2.5 -> 12.2.6

DROP TABLE IF EXISTS SSL_PUBLIC_CERTIFICATE;

CREATE TABLE IF NOT EXISTS SSL_PUBLIC_CERTIFICATE (
  ssl_certificate_id int(11) NOT NULL AUTO_INCREMENT,
  cert_alias VARCHAR(80) CHARACTER SET UTF8 NOT NULL,
  certificate longtext CHARACTER SET UTF8,
  last_updated datetime NULL,
  fingerprint_sha256 VARCHAR(100) CHARACTER SET UTF8 NULL,
  fingerprint_sha1 VARCHAR(60) CHARACTER SET UTF8 NULL,
  issuer VARCHAR(255) CHARACTER SET UTF8 NULL,
  subject VARCHAR(255) CHARACTER SET UTF8 NULL,
  valid_from DATETIME NULL,
  valid_to DATETIME NULL,

  CONSTRAINT ssl_public_certificate_pk PRIMARY KEY (ssl_certificate_id),
  CONSTRAINT fingerprint_sha256_uq UNIQUE (fingerprint_sha256),
  CONSTRAINT fingerprint_sha1_uq UNIQUE (fingerprint_sha1),
  CONSTRAINT ssl_cert_alias_uq UNIQUE (cert_alias)

) ENGINE=InnoDB;

DELETE FROM CONFIG_PROPERTY WHERE config_property_name = 'docgen_server_url_pattern';
