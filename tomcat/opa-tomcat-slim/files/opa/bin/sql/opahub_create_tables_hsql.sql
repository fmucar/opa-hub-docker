SET DATABASE SQL SYNTAX MYS TRUE;


-- create procedure for updating columns


-- Table for users
-- status (0 = enabled, 1 = disabled, 2 = deleted, 3 = Locked)
create table if not exists AUTHENTICATION(
	authentication_id INT NOT NULL AUTO_INCREMENT,
	user_name VARCHAR(255) NOT NULL,
	full_name VARCHAR(255),
	email VARCHAR(255),
	status SMALLINT DEFAULT 0 NOT NULL,
	change_password SMALLINT DEFAULT 0 NOT NULL,
	invalid_logins INT DEFAULT 0 NOT NULL,
	last_login_timestamp DATETIME NULL,
	hub_admin SMALLINT DEFAULT 0 NOT NULL,
	user_type SMALLINT DEFAULT 0 NOT NULL,
	last_locked_timestamp DATETIME NULL,
	CONSTRAINT authentication_pk PRIMARY KEY (authentication_id),
	CONSTRAINT authentication_status_check CHECK(status >= 0 AND status <= 3 ),
	CONSTRAINT change_password CHECK(change_password >= 0 AND change_password <= 1 ),
	CONSTRAINT hub_admin_check CHECK(hub_admin >= 0 AND hub_admin <= 1 ),
	CONSTRAINT auth_unique_user_name UNIQUE(user_name)
);


-- status (0 = current, 1 = previous)
create table if not exists AUTHENTICATION_PWD (
	authentication_pwd_id INT NOT NULL AUTO_INCREMENT,
	authentication_id INT NOT NULL REFERENCES AUTHENTICATION(authentication_id) ON DELETE CASCADE,
	password VARCHAR(512),
	created_date DATETIME NOT NULL,
	status SMALLINT DEFAULT 1 NOT NULL,

	CONSTRAINT authentication_pwd_pk PRIMARY KEY (authentication_pwd_id),
	CONSTRAINT authentication_pwd_status_check CHECK(status >= 0 AND status <= 2 )
);

create table if not exists SECURITY_TOKEN (
	security_token_id INT NOT NULL AUTO_INCREMENT,
	authentication_id INT NULL,
	token_value VARCHAR(255) NOT NULL,
	issue_date DATETIME NOT NULL,
	verified_date DATETIME NOT NULL,
	is_long_term SMALLINT DEFAULT 0 NOT NULL,
	CONSTRAINT security_token_pk PRIMARY KEY (security_token_id),
	CONSTRAINT sec_unique_token_value unique(token_value),
	CONSTRAINT is_long_term_check CHECK(is_long_term >= 0 AND is_long_term <= 1 )
);

create table if not exists ROLE (
	role_id INT NOT NULL AUTO_INCREMENT,
	role_name VARCHAR(63) NOT NULL,

	CONSTRAINT role_pk PRIMARY KEY (role_id),
	CONSTRAINT role_unique_role_name UNIQUE(role_name)
);

create table if not exists COLLECTION (
	collection_id INT NOT NULL AUTO_INCREMENT,
	collection_name VARCHAR(127) NOT NULL,
	collection_status INT NOT NULL,
	collection_description VARCHAR(255),
	deleted_timestamp DATETIME NULL,
	
	CONSTRAINT collection_pk PRIMARY KEY (collection_id),
	CONSTRAINT collection_unique_coll_name UNIQUE(collection_name),
	CONSTRAINT collection_status_check  CHECK(collection_status >= 0 AND collection_status <= 2 )
);

create table if not exists AUTH_ROLE_COLL (
	authentication_id INT NOT NULL references AUTHENTICATION(authentication_id) ON DELETE CASCADE,
    role_id INT NOT NULL references ROLE(role_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT auth_coll_unique_ids UNIQUE(authentication_id, role_id, collection_id)
);

create table if not exists CONFIG_PROPERTY (
	config_property_name VARCHAR(255) NOT NULL,
	config_property_int_value INT,
	config_property_str_value VARCHAR(2048),
	config_property_type INT,
	config_property_public SMALLINT DEFAULT 0 NOT NULL,
	config_property_description VARCHAR(1024),

	CONSTRAINT config_property_pk PRIMARY KEY (config_property_name)
);


-- Data service

-- status (0 = enabled, 1 = disabled/deleted)
-- use_wss (0 = none, 1 = all, 2 = metadata only)
-- wss_use_timestamp (0 = false, 1 = true)
-- use_trust_store (0 = default Java trust store, 1 = use private certificates)
create table if not exists DATA_SERVICE (
	data_service_id INT NOT NULL AUTO_INCREMENT,
	service_name VARCHAR(255) NOT NULL,
	service_type VARCHAR(255) NOT NULL,
	version VARCHAR(20) NULL,
	url VARCHAR(1024) NOT NULL,
	last_updated DATETIME NOT NULL,
	service_user VARCHAR(255),
	service_pass VARCHAR(255),
	use_wss SMALLINT DEFAULT 0 NOT NULL,
	wss_use_timestamp SMALLINT,
	shared_secret VARCHAR(255),
	rn_shared_secret VARCHAR(255),
	cx_site_name VARCHAR(255),
	bearer_token_param VARCHAR(255),
	status SMALLINT DEFAULT 0 NOT NULL,
	soap_action_pattern VARCHAR(255),
    metadata LONGTEXT NULL,
    use_trust_store SMALLINT DEFAULT 0 NOT NULL,
    ssl_private_key VARCHAR(80) NULL,

	-- status (0 = enabled, 1 = disabled/deleted)

	CONSTRAINT data_service_pk PRIMARY KEY (data_service_id),
	CONSTRAINT service_name_unique UNIQUE(service_name),
	CONSTRAINT use_trust_store_check  CHECK(use_trust_store >= 0 AND use_trust_store <= 1)
);


create table if not exists DATA_SERVICE_COLL (
	data_service_id INT NOT NULL references DATA_SERVICE(data_service_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT data_service_coll_unique_ids UNIQUE(data_service_id, collection_id)
);


-- table for CustomerLoggingService
create table if not exists LOG_ENTRY (
    log_entry_id INT NOT NULL AUTO_INCREMENT,
    entry_timestamp DATETIME NOT NULL,
    entry_type VARCHAR(15) NOT NULL,
    code VARCHAR(15)  NOT NULL,
    message LONGTEXT NOT NULL,
    origin VARCHAR(30) NULL,
    CONSTRAINT log_entry_primary_key PRIMARY KEY (log_entry_id)
);

CREATE INDEX entry_timestamp_idx ON LOG_ENTRY(entry_timestamp);



-- Project snapshots (deployments or versioned projects)

create table if not exists SNAPSHOT (
	snapshot_id INT NOT NULL AUTO_INCREMENT,
	uploaded_date DATETIME NOT NULL,
    fingerprint_sha256 VARCHAR(65) NULL,
    scan_status SMALLINT DEFAULT 0 NOT NULL,
    scan_message VARCHAR(255) NULL,
	CONSTRAINT snapshot_id_pk PRIMARY KEY (snapshot_id)
);

create table if not exists SNAPSHOT_CHUNK (
	snapshot_id INT NOT NULL,
	chunk_sequence INT NOT NULL,
	chunk_slice LONGTEXT NOT NULL,
	CONSTRAINT snapshot_chunk_unique PRIMARY KEY (snapshot_id, chunk_sequence)
);


-- Versioned projects
create table if not exists PROJECT (
	project_id INT NOT NULL AUTO_INCREMENT,
	project_name VARCHAR(127) NOT NULL,
	project_description VARCHAR(255),
	last_updated DATETIME NOT NULL,

	-- latest_version used for concurrency control
	-- eg. "update PROJECT set latest_version=foo where latest_version=bar"
	latest_version INT NULL,

	deleted_timestamp DATETIME NULL,

	CONSTRAINT project_id_pk PRIMARY KEY (project_id),
	CONSTRAINT project_name_unique UNIQUE(project_name)
);

create table if not exists PROJECT_VERSION (
	project_version_id INT NOT NULL AUTO_INCREMENT,
	project_id INT NOT NULL
		REFERENCES PROJECT(project_id),
	project_version INT NOT NULL,
	project_snapshot_id INT NOT NULL
		REFERENCES SNAPSHOT(snapshot_id),
	user_name VARCHAR(255) NOT NULL,
	opa_version VARCHAR(15) NOT NULL,
	description VARCHAR(255) NOT NULL,
	creation_date DATETIME NOT NULL,
	deleted_timestamp DATETIME NULL,
	CONSTRAINT project_version_pk PRIMARY KEY (project_version_id)
);

-- Changes made in a version
create table if not exists PROJECT_VERSION_CHANGE (
	project_version_change_id INT NOT NULL AUTO_INCREMENT,
	project_version_id int NOT NULL
		REFERENCES PROJECT_VERSION(project_version_id),
	object_name VARCHAR(255) NOT NULL,
	-- change_type (0=added, 1=deleted, 2=modified)
	change_type smallint not null,

	CONSTRAINT project_version_change_pk PRIMARY KEY (project_version_change_id),
	CONSTRAINT project_version_change_unique UNIQUE (project_version_id, object_name)
);

-- Indicates deployment objects that are currently being worked on
create table if not exists PROJECT_OBJECT_STATUS (
	project_object_status_id INT NOT NULL AUTO_INCREMENT,
	project_id INT NOT NULL
		REFERENCES PROJECT(project_id),
	object_name VARCHAR(255) NOT NULL,
	lock_machine VARCHAR(255) NOT NULL,
	lock_folder VARCHAR(1024) NOT NULL,
	lock_user INT NOT NULL
		REFERENCES AUTHENTICATION(authentication_id),
	lock_timestamp DATETIME NOT NULL,

	CONSTRAINT project_object_status_id_pk PRIMARY KEY (project_object_status_id),
	CONSTRAINT project_object_unique UNIQUE(project_id, object_name)
);


create table if not exists PROJECT_COLL (
	project_id INT NOT NULL references PROJECT(project_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT project_coll_unique_ids UNIQUE(project_id, collection_id)
);


-- migrate PROJECT_SUMMARY into DEPLOYMENT
create table if not exists DEPLOYMENT (
	deployment_id INT NOT NULL AUTO_INCREMENT,
	deployment_name VARCHAR(127) NOT NULL,
	deployment_description VARCHAR(255),
	last_updated DATETIME NOT NULL,

	-- activation properties
	activated_version_id INT NULL,
	activated_interview SMALLINT DEFAULT 0 NOT NULL,
	activated_webservice SMALLINT DEFAULT 0 NOT NULL,
	activated_interviewservice SMALLINT DEFAULT 0 NOT NULL,
	activated_embedjs SMALLINT DEFAULT 0 NOT NULL,
	activated_chatservice SMALLINT DEFAULT 0 NOT NULL,
	activated_mobile SMALLINT DEFAULT 0 NOT NULL,

	-- compatibility_mode (0=current, 1=legacy)
	compatibility_mode SMALLINT DEFAULT 0 NOT NULL,

	user_name VARCHAR(255) NULL,

	deleted_timestamp DATETIME NULL,

	CONSTRAINT deployment_id_pk PRIMARY KEY (deployment_id),
	CONSTRAINT deployment_name_unique UNIQUE(deployment_name)
);

create table if not exists DEPLOYMENT_VERSION (
	deployment_version_id INT NOT NULL AUTO_INCREMENT,
	deployment_id INT NOT NULL REFERENCES DEPLOYMENT(deployment_id),
	deployment_version INT NOT NULL,
	snapshot_id INT NOT NULL
		REFERENCES SNAPSHOT(snapshot_id),
	user_name VARCHAR(255) NULL,
	opa_version VARCHAR(15) NOT NULL,
	description VARCHAR(255) NOT NULL,

	-- activatable 1=yes,0=no
	activatable SMALLINT DEFAULT 1 NOT NULL,
	snapshot_date DATETIME NOT NULL,
	snapshot_deleted_timestamp DATETIME NULL,
	mapping_type VARCHAR(32) NULL,
	data_service_id INT NULL REFERENCES DATA_SERVICE(data_service_id),
	data_service_used SMALLINT DEFAULT 0 NOT NULL,
	CONSTRAINT activatable_check CHECK(activatable >= 0 AND activatable <= 1),
	CONSTRAINT data_service_used_check CHECK(data_service_used >= 0 AND data_service_used <= 2),
	CONSTRAINT deployment_version_pk PRIMARY KEY (deployment_version_id)
);

-- Alter table for foreign keys for cross references
ALTER TABLE DEPLOYMENT ADD FOREIGN KEY (activated_version_id) REFERENCES DEPLOYMENT_VERSION(deployment_version_id);

create table if not exists DEPLOYMENT_ACTIVATION_HISTORY (
	deployment_activation_history_id INT NOT NULL AUTO_INCREMENT,
	deployment_id INT NOT NULL
		REFERENCES DEPLOYMENT(deployment_id),
	deployment_version_id INT NOT NULL
		REFERENCES DEPLOYMENT_VERSION(deployment_version_id),
	activation_date DATETIME NOT NULL,
	status_interview SMALLINT DEFAULT 0 NOT NULL,
	status_webservice SMALLINT DEFAULT 0 NOT NULL,
	status_interviewservice SMALLINT DEFAULT 0 NOT NULL,
    status_chatservice SMALLINT DEFAULT 0 NOT NULL,
	status_embedjs SMALLINT DEFAULT 0 NOT NULL,
	status_mobile SMALLINT DEFAULT 0 NOT NULL,
	user_name VARCHAR(255) NOT NULL,

	CONSTRAINT deployment_activation_history_pk PRIMARY KEY (deployment_activation_history_id)
);


create table if not exists DEPLOYMENT_RULEBASE_REPOS (
	id INT NOT NULL AUTO_INCREMENT,
	deployment_version_id INT NOT NULL
		REFERENCES DEPLOYMENT_VERSION(deployment_version_id),
	chunk_sequence INT NOT NULL,
	chunk_slice LONGTEXT NOT NULL,
	uploaded_date DATETIME NOT NULL,

	CONSTRAINT deployment_rulebase_repos_pk PRIMARY KEY (id),
	CONSTRAINT deployment_rulebase_repos_unique UNIQUE (deployment_version_id, chunk_sequence)
);


create table if not exists DEPLOYMENT_COLL (
	deployment_id INT NOT NULL references DEPLOYMENT(deployment_id) ON DELETE CASCADE,
	collection_id INT NOT NULL references COLLECTION(collection_id) ON DELETE CASCADE,

	CONSTRAINT deployment_coll_unique_ids UNIQUE(deployment_id, collection_id)
);

CREATE TABLE if not exists DEPLOYMENT_CHANNEL_DEFAULT
(
  channel_default_id INT NOT NULL AUTO_INCREMENT,
  collection_id INT NOT NULL,
  default_interview SMALLINT DEFAULT 0 NOT NULL,
  default_webservice SMALLINT DEFAULT 0 NOT NULL,
  default_interviewservice SMALLINT DEFAULT 0 NOT NULL,
  default_chatservice SMALLINT DEFAULT 0 NOT NULL,
  default_mobile SMALLINT DEFAULT 0 NOT NULL ,
  default_embedjs SMALLINT DEFAULT 0 NOT NULL,
  defaults_can_override SMALLINT DEFAULT 1 NOT NULL,
  CONSTRAINT channel_default_idx PRIMARY KEY (channel_default_id),
  CONSTRAINT collection_id_uq UNIQUE (collection_id),
  CONSTRAINT collection_channel_fk
    FOREIGN KEY (collection_id)
    REFERENCES COLLECTION (collection_id)
    ON DELETE CASCADE,
  CONSTRAINT default_interview_check CHECK(default_interview >= 0 AND default_interview <= 1),
  CONSTRAINT default_webservice_check CHECK(default_webservice >= 0 AND default_webservice <= 1),
  CONSTRAINT default_mobile_check CHECK(default_mobile >= 0 AND default_mobile <= 1),
  CONSTRAINT default_javascript_check CHECK(default_embedjs >= 0 AND default_embedjs <= 1),
  CONSTRAINT default_chatservice_check CHECK(default_chatservice >= 0 AND default_chatservice <= 1),
  CONSTRAINT default_override_check CHECK(defaults_can_override >= 0 AND defaults_can_override <= 1)
);

CREATE TABLE IF NOT EXISTS DEPLOYMENT_ACTION_LOG
(
	action_timestamp TIMESTAMP NOT NULL,
	action_year INT NOT NULL,
	action_month INT NOT NULL,
	action_day INT NOT NULL,
	action_hour INT NOT NULL,
	deployment_name VARCHAR(255) NOT NULL,
	product_name VARCHAR(50) NOT NULL,
	product_version VARCHAR(50) NOT NULL,
	session_id VARCHAR(32) NOT NULL,
	user_id VARCHAR(255),
	subject VARCHAR(50) NOT NULL,
	verb VARCHAR(50) NOT NULL
);

CREATE INDEX DEPLOY_ACT_LOG_NAME_YEAR ON DEPLOYMENT_ACTION_LOG(deployment_name, action_year);
CREATE INDEX DEPLOY_ACT_LOG_NAME_MONTH ON DEPLOYMENT_ACTION_LOG(deployment_name, action_month);
CREATE INDEX DEPLOY_ACT_LOG_NAME_DAY ON DEPLOYMENT_ACTION_LOG(deployment_name, action_day);
CREATE INDEX DEPLOY_ACT_LOG_NAME_HOUR ON DEPLOYMENT_ACTION_LOG(deployment_name, action_hour);


CREATE TABLE IF NOT EXISTS SESSION_STATS_TEMPLATE (
    session_stats_template_id INT NOT NULL AUTO_INCREMENT,
    deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
    deployment_version_id INT NOT NULL REFERENCES DEPLOYMENT_VERSION (deployment_version_id),
    CONSTRAINT session_stats_template_pk PRIMARY KEY (session_stats_template_id),
    CONSTRAINT session_stats_template_uq UNIQUE (deployment_id, deployment_version_id)
);

CREATE TABLE IF NOT EXISTS SESSION_SCREEN_TEMPLATE (
    session_screen_template_id INT NOT NULL AUTO_INCREMENT,
    session_stats_template_id INT NOT NULL REFERENCES SESSION_STATS_TEMPLATE (session_stats_template_id),
    screen_id VARCHAR(50) NOT NULL,
    screen_title VARCHAR(255) NOT NULL,
    screen_action_code INT NOT NULL,
    screen_order INT NOT NULL,
    CONSTRAINT session_screen_template_pk PRIMARY KEY (session_screen_template_id),
    CONSTRAINT session_screen_template_uk UNIQUE (session_stats_template_id, screen_id)
);

CREATE TABLE IF NOT EXISTS SESSION_STATS_LOG (
    session_stats_log_id BIGINT NOT NULL AUTO_INCREMENT,
    session_stats_template_id INT NOT NULL REFERENCES SESSION_STATS_TEMPLATE (session_stats_template_id),
    deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
    deployment_version_id INT NOT NULL REFERENCES DEPLOYMENT_VERSION (deployment_version_id),
    product_code INT NOT NULL,
    product_version VARCHAR(25) NOT NULL,
    product_function_code INT NOT NULL,
	product_function_version VARCHAR(25),
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
    CONSTRAINT session_stats_log_pk PRIMARY KEY (session_stats_log_id)
);

CREATE INDEX usage_trend ON SESSION_STATS_LOG(created_hour, deployment_id);
CREATE INDEX obsolete_api_usage ON SESSION_STATS_LOG(deployment_id, created_timestamp, product_function_version, product_function_code, product_code);
CREATE INDEX sessions_by_year ON SESSION_STATS_LOG(product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, created_year);
CREATE INDEX sessions_by_month ON SESSION_STATS_LOG(product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, created_month);
CREATE INDEX sessions_by_day ON SESSION_STATS_LOG(product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, created_day);
CREATE INDEX sessions_by_hour ON SESSION_STATS_LOG(product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, created_hour);
CREATE INDEX sessions_by_duration_min ON SESSION_STATS_LOG(product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, duration_min);
CREATE INDEX sessions_by_screens_visited ON SESSION_STATS_LOG(product_function_code, auth_id, created_timestamp, deployment_id, deployment_version_id, screens_visited);


CREATE TABLE IF NOT EXISTS SESSION_SCREEN_LOG (
    session_screen_log_id BIGINT NOT NULL AUTO_INCREMENT,
    session_stats_log_id BIGINT NOT NULL REFERENCES SESSION_STATS_LOG (session_stats_log_id),
    session_stats_template_id BIGINT NOT NULL REFERENCES SESSION_STATS_TEMPLATE (session_stats_template_id),
    deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
    deployment_version_id INT NOT NULL REFERENCES DEPLOYMENT_VERSION (deployment_version_id),
    product_code INT NOT NULL,
    product_version VARCHAR(25) NOT NULL,
    product_function_code INT NOT NULL,
    session_created_timestamp TIMESTAMP NULL,
    auth_id BINARY(16) NULL,
    authenticated SMALLINT NOT NULL,
    screen_id VARCHAR(50) NOT NULL,
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
    CONSTRAINT session_screen_log_pk PRIMARY KEY (session_screen_log_id)
);

CREATE INDEX screen_by_session_id ON SESSION_SCREEN_LOG(session_stats_log_id);
CREATE INDEX screen_by_vers_id_action ON SESSION_SCREEN_LOG(deployment_version_id, session_created_timestamp, screen_id, screen_action_code);


CREATE TABLE IF NOT EXISTS STATISTICS_CHART (
    statistics_chart_id INT NOT NULL AUTO_INCREMENT,
    chart_type VARCHAR(30) NOT NULL,
    chart_data LONGTEXT NOT NULL,
    CONSTRAINT statistics_chart_pk PRIMARY KEY (statistics_chart_id)
);

CREATE TABLE IF NOT EXISTS DEPLOYMENT_STATS_CHART (
    deployment_stats_chart_id INT NOT NULL AUTO_INCREMENT,
    statistics_chart_id INT NOT NULL REFERENCES STATISTICS_CHART (statistics_chart_id),
    deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
    chart_number INT NOT NULL,
    CONSTRAINT deployment_stats_chart_pk PRIMARY KEY (deployment_stats_chart_id),
    CONSTRAINT deployment_stats_chart_uq UNIQUE (deployment_id, chart_number)
);

CREATE TABLE IF NOT EXISTS OVERVIEW_STATS_CHART (
    overview_stats_chart_id INT NOT NULL AUTO_INCREMENT,
    statistics_chart_id INT NOT NULL REFERENCES STATISTICS_CHART (statistics_chart_id),
    chart_number INT NOT NULL,
    CONSTRAINT overview_stats_chart_pk PRIMARY KEY (overview_stats_chart_id),
    CONSTRAINT overview_stats_chart_uq UNIQUE (chart_number)
);

CREATE TABLE IF NOT EXISTS FUNCTION_STATS_LOG (
	function_stats_log_id INT NOT NULL AUTO_INCREMENT,
	deployment_id INT NOT NULL REFERENCES DEPLOYMENT (deployment_id),
	product_code INT NOT NULL,
	product_function_code INT NOT NULL,
	product_function_version VARCHAR(25) NOT NULL,
	last_used_timestamp TIMESTAMP NOT NULL,
	CONSTRAINT function_stats_log_pk PRIMARY KEY (function_stats_log_id),
	CONSTRAINT function_stats_log_uq UNIQUE KEY (deployment_id, product_code, product_function_code, product_function_version)
);

CREATE INDEX function_usage_obsolete ON FUNCTION_STATS_LOG(last_used_timestamp, product_code, product_function_code, product_function_version, deployment_id);

CREATE TABLE IF NOT EXISTS SSL_PUBLIC_CERTIFICATE (
  ssl_certificate_id INT NOT NULL AUTO_INCREMENT,
  cert_alias VARCHAR(80) NOT NULL,
  certificate LONGTEXT,
  last_updated datetime NULL,
  fingerprint_sha256 VARCHAR(100) NULL,
  fingerprint_sha1 VARCHAR(60) NULL,
  issuer VARCHAR(255) NULL,
  subject VARCHAR(255) NULL,
  valid_from DATETIME NULL,
  valid_to DATETIME NULL,

  CONSTRAINT ssl_public_certificate_pk PRIMARY KEY (ssl_certificate_id),
  CONSTRAINT fingerprint_sha256_uq UNIQUE (fingerprint_sha256),
  CONSTRAINT fingerprint_sha1_uq UNIQUE (fingerprint_sha1),
  CONSTRAINT ssl_cert_alias_uq UNIQUE (cert_alias)
);

-- table for Auditing
create table if not exists AUDIT_LOG (
  audit_id int NOT NULL AUTO_INCREMENT,
  audit_date datetime NOT NULL, 
  auth_id int DEFAULT NULL,
  auth_name varchar(100) DEFAULT NULL,
  description LONGTEXT DEFAULT NULL,
  object_type varchar(50) DEFAULT NULL,
  object_id int DEFAULT NULL,
  operation varchar(50) DEFAULT NULL,
  result int DEFAULT NULL,	
  extension LONGTEXT DEFAULT NULL,

  PRIMARY KEY (audit_id)
);


CREATE INDEX audit_date_idx ON AUDIT_LOG(audit_date);

CREATE TABLE IF NOT EXISTS SSL_PRIVATE_KEY (
  ssl_private_key_id INT NOT NULL AUTO_INCREMENT,
  key_name VARCHAR(80) NOT NULL,
  keystore LONGTEXT,
  last_updated DATETIME NULL,
  fingerprint_sha256 VARCHAR(100) NULL,
  fingerprint_sha1 VARCHAR(60) NULL,
  issuer VARCHAR(255) NULL,
  subject VARCHAR(255) NULL,
  valid_from DATETIME NULL,
  valid_to DATETIME NULL,

  CONSTRAINT ssl_private_key_pk PRIMARY KEY (ssl_private_key_id),
  CONSTRAINT priv_fingerprint_sha256_uq UNIQUE (fingerprint_sha256),
  CONSTRAINT priv_fingerprint_sha1_uq UNIQUE (fingerprint_sha1),
  CONSTRAINT ssl_key_name_uq UNIQUE (key_name)
);
