-- 12.2.5 data upgrade for MySQL
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

CALL OPAAddColumnIfNotExists('DATA_SERVICE', 'rn_shared_secret', 'VARCHAR(255) CHARACTER SET utf8');
CALL OPAAddColumnIfNotExists('DATA_SERVICE', 'metadata', 'LONGTEXT CHARACTER SET utf8 NULL');
CALL OPAAddColumnIfNotExists('AUTHENTICATION', 'hub_admin', 'SMALLINT DEFAULT 0 NOT NULL');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_VERSION', 'data_service_id', 'INT NULL REFERENCES DATA_SERVICE(data_service_id)');
CALL OPAAddColumnIfNotExists('DEPLOYMENT_VERSION', 'data_service_used', 'SMALLINT DEFAULT 0 NOT NULL');

create table if not exists COLLECTION (
	collection_id INT NOT NULL AUTO_INCREMENT,
	collection_name VARCHAR(63) CHARACTER SET utf8 NOT NULL,
	collection_status INT NOT NULL,
	collection_description VARCHAR(255) CHARACTER SET utf8,
	deleted_timestamp DATETIME NULL,
	
	CONSTRAINT collection_pk PRIMARY KEY (collection_id),
	CONSTRAINT collection_unique_coll_name UNIQUE(collection_name),
	CONSTRAINT collection_status_check  CHECK(collection_status >= 0 AND collection_status <= 2 )
)  ENGINE=InnoDB;

create table if not exists AUTH_ROLE_COLL (
	authentication_id INT NOT NULL references AUTHENTICATION(authentication_id) ON DELETE CASCADE,
    role_id INT NOT NULL references ROLE(role_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT auth_coll_unique_ids UNIQUE(authentication_id, role_id, collection_id)
)  ENGINE=InnoDB;

create table if not exists DATA_SERVICE_COLL (
	data_service_id INT NOT NULL references DATA_SERVICE(data_service_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT data_service_collection_unique_ids UNIQUE(data_service_id, collection_id)
)  ENGINE=InnoDB;

create table if not exists PROJECT_COLL (
	project_id INT NOT NULL references PROJECT(project_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT project_coll_unique_ids UNIQUE(project_id, collection_id)
)  ENGINE=InnoDB;

create table if not exists DEPLOYMENT_COLL (
	deployment_id INT NOT NULL references DEPLOYMENT(deployment_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT deployment_coll_unique_ids UNIQUE(deployment_id, collection_id)
)  ENGINE=InnoDB;

create table if not exists ANALYSIS_WORKSPACE_COLL (
	analysis_workspace_id INT NOT NULL references ANALYSIS_WORKSPACE(analysis_workspace_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT aw_coll_unique_ids UNIQUE(analysis_workspace_id, collection_id)
)  ENGINE=InnoDB;
