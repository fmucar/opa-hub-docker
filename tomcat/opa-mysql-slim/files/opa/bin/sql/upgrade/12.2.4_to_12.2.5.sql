-- 12.2.5 data upgrade script for MySQL
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

CALL OPAAddColumnIfNotExists('AUTHENTICATION', 'hub_admin', 'SMALLINT DEFAULT 0 NOT NULL');

CALL OPAAddColumnIfNotExists('DATA_SERVICE', 'metadata', 'LONGTEXT CHARACTER SET utf8 NULL');

CALL OPAAddColumnIfNotExists('DEPLOYMENT_VERSION', 'data_service_id', 'INT NULL REFERENCES DATA_SERVICE(data_service_id)');

CALL OPAAddColumnIfNotExists('DEPLOYMENT_VERSION', 'data_service_used', 'SMALLINT DEFAULT 0 NOT NULL');

create table if not exists COLLECTION (
	collection_id INT NOT NULL AUTO_INCREMENT,
	collection_name VARCHAR(127) CHARACTER SET utf8 NOT NULL,
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


-- Create initial values for the Collection table
INSERT INTO COLLECTION (collection_name, collection_status, collection_description)
VALUES ('Default Collection', 0, 'The default collection')
ON DUPLICATE KEY UPDATE collection_name = collection_name;

-- Move Hub admin privilege over to the authentication table
UPDATE AUTHENTICATION SET hub_admin = 1 WHERE AUTHENTICATION_ID IN (SELECT AR.AUTHENTICATION_ID FROM AUTHENTICATION_ROLE AR JOIN ROLE R ON AR.ROLE_ID = R.ROLE_ID WHERE R.ROLE_NAME = 'Hub Admin');

-- Don't populate collection tables with Hub Admin role
DELETE FROM AUTHENTICATION_ROLE WHERE ROLE_ID = (SELECT ROLE_ID FROM ROLE WHERE ROLE_NAME = 'Hub Admin');

-- Populate initial values for AUTH_ROLE_COLL from AUTHENTICATION_ROLE table
INSERT INTO AUTH_ROLE_COLL (authentication_id, role_id, collection_id)
SELECT authentication_id, role_id, (select collection_id from COLLECTION where collection_name = 'Default Collection') AS collection_id FROM AUTHENTICATION_ROLE
ON DUPLICATE KEY UPDATE AUTH_ROLE_COLL.authentication_id = AUTH_ROLE_COLL.authentication_id;

-- Populate initial values for DATA_SERVICE_COLL table
INSERT INTO DATA_SERVICE_COLL (data_service_id, collection_id)
SELECT data_service_id, collection_id FROM DATA_SERVICE, COLLECTION WHERE collection_name = 'Default Collection'
AND data_service_id NOT IN (select data_service_id FROM DATA_SERVICE_COLL)
ON DUPLICATE KEY UPDATE DATA_SERVICE_COLL.data_service_id = DATA_SERVICE_COLL.data_service_id;

-- Populate initial values for PROJECT_COLL table
INSERT INTO PROJECT_COLL (project_id, collection_id)
SELECT project_id, collection_id FROM PROJECT, COLLECTION WHERE collection_name = 'Default Collection'
AND project_id NOT IN (select project_id FROM PROJECT_COLL)
ON DUPLICATE KEY UPDATE PROJECT_COLL.project_id = PROJECT_COLL.project_id;

-- Populate initial values for DEPLOYMENT_COLL table
INSERT INTO DEPLOYMENT_COLL (deployment_id, collection_id)
SELECT deployment_id, collection_id FROM DEPLOYMENT, COLLECTION WHERE collection_name = 'Default Collection'
AND deployment_id NOT IN (select deployment_id FROM DEPLOYMENT_COLL)
ON DUPLICATE KEY UPDATE DEPLOYMENT_COLL.deployment_id = DEPLOYMENT_COLL.deployment_id;

-- Populate initial values for ANALYSIS_WORKSPACE_COLL table
INSERT INTO ANALYSIS_WORKSPACE_COLL (analysis_workspace_id, collection_id)
SELECT analysis_workspace_id, collection_id FROM ANALYSIS_WORKSPACE, COLLECTION WHERE collection_name = 'Default Collection'
AND analysis_workspace_id NOT IN (select analysis_workspace_id FROM ANALYSIS_WORKSPACE_COLL)
ON DUPLICATE KEY UPDATE ANALYSIS_WORKSPACE_COLL.analysis_workspace_id = ANALYSIS_WORKSPACE_COLL.analysis_workspace_id;

DELETE FROM AUTHENTICATION_ROLE;

DELETE FROM ROLE WHERE ROLE_NAME = 'Hub Admin';

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('feature_compatibility_mode_enabled', 0, 1, 1, '0 = disabled, 1 = enabled. Enabling makes compatibility mode an option for deployments.  Compatibility mode runtime must be installed.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('deployment_max_size_mb', 64, 1, 1, 'Maximum size of any project or deployment that can be uploaded, in millions of bytes.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

-- Populate data_service_used where a foreign key exists
UPDATE DEPLOYMENT_VERSION SET data_service_used = 2 WHERE data_service_id IS NOT NULL;

