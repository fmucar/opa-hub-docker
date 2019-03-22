-- 12.2.4 schema upgrade for MySQL
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


---------------------------------------------------------------------
-- Database tables required by the Deployment Statistics functions --
---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS SESSION_STATS_TEMPLATE (
    session_stats_template_id INT NOT NULL AUTO_INCREMENT,
    deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
    deployment_version_id INT NOT NULL REFERENCES DEPLOYMENT_VERSION (deployment_version_id),
    CONSTRAINT session_stats_template_pk PRIMARY KEY (session_stats_template_id),
    CONSTRAINT session_stats_template_uq UNIQUE (deployment_id, deployment_version_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS SESSION_SCREEN_TEMPLATE (
    session_screen_template_id INT NOT NULL AUTO_INCREMENT,
    session_stats_template_id INT NOT NULL REFERENCES SESSION_STATS_TEMPLATE (session_stats_template_id),
    screen_id VARCHAR(50) CHARACTER SET UTF8 NOT NULL,
    screen_title VARCHAR(255) CHARACTER SET UTF8 NOT NULL,
    screen_action_code INT NOT NULL,
    screen_order INT NOT NULL,
    CONSTRAINT session_screen_template_pk PRIMARY KEY (session_screen_template_id),
    CONSTRAINT session_screen_template_uk UNIQUE (session_stats_template_id, screen_id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS SESSION_STATS_LOG (
    session_stats_log_id BIGINT NOT NULL AUTO_INCREMENT,
    session_stats_template_id INT NOT NULL REFERENCES SESSION_STATS_TEMPLATE (session_stats_template_id),
    deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
    deployment_version_id INT NOT NULL REFERENCES DEPLOYMENT_VERSION (deployment_version_id),
    product_code INT NOT NULL,
    product_version VARCHAR(25) CHARACTER SET UTF8 NOT NULL,
    product_function_code INT NOT NULL,
    created_timestamp TIMESTAMP NULL,
    created_year INT NOT NULL,
    created_month INT NOT NULL,
    created_day INT NOT NULL,
    created_hour INT NOT NULL,
    last_modified_timestamp TIMESTAMP NULL,
    last_modified_year INT NOT NULL,
    last_modified_month INT NOT NULL,
    last_modified_day INT NOT NULL,
    last_modified_hour INT NOT NULL,
    duration_millis BIGINT NOT NULL,
    duration_sec INT NOT NULL,
    duration_min INT NOT NULL,
    screens_visited INT NOT NULL,
    auth_id BINARY(16) NULL,
    authenticated SMALLINT NOT NULL,
    completed SMALLINT NOT NULL,
    CONSTRAINT session_stats_log_pk PRIMARY KEY (session_stats_log_id),
    INDEX usage_trend (created_hour, deployment_id),
    INDEX sessions_by_year (product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, created_year),
    INDEX sessions_by_month (product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, created_month),
    INDEX sessions_by_day (product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, created_day),
    INDEX sessions_by_hour (product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, created_hour),
    INDEX sessions_by_duration_min (product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, duration_min),
    INDEX sessions_by_screens_visited (product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, screens_visited)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS SESSION_SCREEN_LOG (
    session_screen_log_id BIGINT NOT NULL AUTO_INCREMENT,
    session_stats_log_id BIGINT NOT NULL REFERENCES SESSION_STATS_LOG (session_stats_log_id),
    session_stats_template_id BIGINT NOT NULL REFERENCES SESSION_STATS_TEMPLATE (session_stats_template_id),
    deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
    deployment_version_id INT NOT NULL REFERENCES DEPLOYMENT_VERSION (deployment_version_id),
    product_code INT NOT NULL,
    product_version VARCHAR(25) CHARACTER SET UTF8 NOT NULL,
    product_function_code INT NOT NULL,
    session_created_timestamp TIMESTAMP NULL,
    auth_id BINARY(16) NULL,
    authenticated SMALLINT NOT NULL,
    screen_id VARCHAR(50) CHARACTER SET UTF8 NOT NULL,
    screen_order INT NOT NULL,
    screen_action_code INT NOT NULL,
    screen_sequence INT NOT NULL,
    entry_transition_code SMALLINT NOT NULL,
    entry_timestamp TIMESTAMP NULL,
    submit_timestamp TIMESTAMP NULL,
    exit_transition_code SMALLINT NULL,
    exit_timestamp TIMESTAMP NULL,
    duration_millis BIGINT NOT NULL,
    duration_sec INT NOT NULL,
    duration_min INT NOT NULL,
    CONSTRAINT session_screen_log_pk PRIMARY KEY (session_screen_log_id),
    INDEX screen_by_session_id (session_stats_log_id),
    INDEX screen_by_vers_id_action (deployment_version_id, session_created_timestamp, screen_id, screen_action_code)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS STATISTICS_CHART (
    statistics_chart_id INT NOT NULL AUTO_INCREMENT,
    chart_type VARCHAR(30) CHARACTER SET UTF8 NOT NULL,
    chart_data LONGTEXT CHARACTER SET UTF8 NOT NULL,
    CONSTRAINT statistics_chart_pk PRIMARY KEY (statistics_chart_id)
) Engine = InnoDB;

CREATE TABLE IF NOT EXISTS DEPLOYMENT_STATS_CHART (
    deployment_stats_chart_id INT NOT NULL AUTO_INCREMENT,
    statistics_chart_id INT NOT NULL REFERENCES STATISTICS_CHART (statistics_chart_id),
    deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
    chart_number INT NOT NULL,
    CONSTRAINT deployment_stats_chart_pk PRIMARY KEY (deployment_stats_chart_id),
    CONSTRAINT deployment_stats_chart_uq UNIQUE (deployment_id, chart_number)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS OVERVIEW_STATS_CHART (
    overview_stats_chart_id INT NOT NULL AUTO_INCREMENT,
    statistics_chart_id INT NOT NULL REFERENCES STATISTICS_CHART (statistics_chart_id),
    chart_number INT NOT NULL,
    CONSTRAINT overview_stats_chart_pk PRIMARY KEY (overview_stats_chart_id),
    CONSTRAINT overview_stats_chart_uq UNIQUE (chart_number)
) ENGINE = InnoDB;