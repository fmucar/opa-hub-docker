
-- create opa-hub tables in the username schema
create table ${username}AUTHENTICATION(
	authentication_id NUMBER(9) NOT NULL,
	user_name VARCHAR2(255 CHAR) NOT NULL,
	full_name VARCHAR2(255 CHAR),
	email VARCHAR2(255 CHAR),
	status NUMBER(5) DEFAULT 0 NOT NULL,
	change_password NUMBER(5) DEFAULT 0 NOT NULL,
	invalid_logins NUMBER(9) DEFAULT 0 NOT NULL,
	last_login_timestamp DATE NULL,
	hub_admin NUMBER(5) DEFAULT 0 NOT NULL,
	user_type NUMBER(5) DEFAULT 0 NOT NULL,
	last_locked_timestamp DATE NULL,
	CONSTRAINT authentication_pk PRIMARY KEY (authentication_id),
	CONSTRAINT authentication_status_check CHECK(status >= 0 AND status <= 3 ),
	CONSTRAINT change_password CHECK(change_password >= 0 AND change_password <= 1 ),
	CONSTRAINT auth_unique_user_name UNIQUE(user_name)
) ${tablespace};

-- status (0 = current, 1 = previous)
create table ${username}AUTHENTICATION_PWD (
	authentication_pwd_id NUMBER(9) NOT NULL,
	authentication_id NUMBER(9) NOT NULL,
	password VARCHAR2(512 CHAR),
	created_date DATE NOT NULL,
	status NUMBER(5) DEFAULT 1 NOT NULL,

	CONSTRAINT authentication_pwd_pk PRIMARY KEY (authentication_pwd_id),
	CONSTRAINT authentication_pwd_id_fk FOREIGN KEY (authentication_id) REFERENCES ${username}AUTHENTICATION(authentication_id) ON DELETE CASCADE,
	CONSTRAINT authentication_pwd_status CHECK(status >= 0 AND status <= 2)
) ${tablespace};

create table ${username}SECURITY_TOKEN (
	security_token_id NUMBER(9) NOT NULL,
	authentication_id NUMBER(9) NULL,
	token_value VARCHAR2(255 CHAR) NOT NULL,
	issue_date DATE NOT NULL,
	verified_date DATE NOT NULL,
	is_long_term NUMBER(5) DEFAULT 0 NOT NULL,

	CONSTRAINT security_token_pk PRIMARY KEY (security_token_id),
	CONSTRAINT sec_unique_token_value unique(token_value)
) ${tablespace};

create table ${username}ROLE (
	role_id NUMBER(9) NOT NULL,
	role_name VARCHAR2(63 CHAR) NOT NULL,

	CONSTRAINT role_pk PRIMARY KEY (role_id),
	CONSTRAINT role_unique_role_name UNIQUE(role_name)
) ${tablespace};

create table ${username}COLLECTION (
	collection_id NUMBER(9) NOT NULL,
	collection_name VARCHAR2(127 CHAR) NOT NULL,
	collection_status NUMBER(5) DEFAULT 1 NOT NULL,
	collection_description VARCHAR2(255 CHAR),
	deleted_timestamp DATE NULL,

	CONSTRAINT collection_pk PRIMARY KEY (collection_id),
	CONSTRAINT collection_unique_coll_name UNIQUE(collection_name),
	CONSTRAINT collection_status_check  CHECK(collection_status >= 0 AND collection_status <= 2 )
) ${tablespace};

create table ${username}AUTH_ROLE_COLL (
    authentication_id NUMBER(9) NOT NULL,
    role_id NUMBER(9) NOT NULL,
    collection_id NUMBER(9) NOT NULL,
    CONSTRAINT auth_coll_unique_ids UNIQUE(authentication_id, role_id, collection_id),
    CONSTRAINT auth_role_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE,
    CONSTRAINT auth_role_coll_role_id_fk FOREIGN KEY (role_id) REFERENCES ${username}ROLE(role_id) ON DELETE CASCADE,
    CONSTRAINT auth_role_coll_auth_id_fk FOREIGN KEY (authentication_id) REFERENCES ${username}AUTHENTICATION(authentication_id) ON DELETE CASCADE
) ${tablespace};

create table ${username}CONFIG_PROPERTY (
	config_property_name VARCHAR2(255 CHAR) NOT NULL,
	config_property_int_value NUMBER(9),
	config_property_str_value VARCHAR2(2048 CHAR),
	config_property_type NUMBER(9),
	config_property_public NUMBER(5) DEFAULT 0 NOT NULL,
	config_property_description VARCHAR2(1024 CHAR),

	CONSTRAINT config_property_pk PRIMARY KEY (config_property_name)
) ${tablespace};


-- Data service

-- status (0 = enabled, 1 = disabled/deleted)
-- use_wss (0 = none, 1 = all, 2 = metadata only)
-- wss_use_timestamp (0 = false, 1 = true)
-- use_trust_store (0 = default Java trust store, 1 = use private certificates)
create table ${username}DATA_SERVICE (
	data_service_id NUMBER(9) NOT NULL,
	service_name VARCHAR2(255 CHAR) NOT NULL,
	service_type VARCHAR2(255 CHAR) NOT NULL,
	version VARCHAR(20 CHAR) NULL,
	url VARCHAR2(1024 CHAR),
	last_updated DATE NOT NULL,
	service_user VARCHAR2(255 CHAR),
	service_pass VARCHAR2(255 CHAR),
	use_wss NUMBER(5) DEFAULT 0 NOT NULL,
	wss_use_timestamp NUMBER(5),
	shared_secret VARCHAR2(255 CHAR),
	rn_shared_secret VARCHAR2(255 CHAR),
	cx_site_name VARCHAR2(255 CHAR),
	bearer_token_param VARCHAR(255 CHAR),
	status NUMBER(5) DEFAULT 0 NOT NULL,
	soap_action_pattern VARCHAR2(255 CHAR),
    metadata CLOB NULL,
    use_trust_store NUMBER(5) DEFAULT 0 NOT NULL,
    ssl_private_key VARCHAR2(80 CHAR) NULL,

	-- status (0 = enabled, 1 = disabled/deleted)

	CONSTRAINT data_service_pk PRIMARY KEY (data_service_id),
	CONSTRAINT service_name_unique UNIQUE(service_name),
	CONSTRAINT use_trust_store_check CHECK(use_trust_store >= 0 AND use_trust_store <= 1)
) ${tablespace};

CREATE TABLE ${username}DATA_SERVICE_COLL (
	data_service_id NUMBER(9) NOT NULL,
	collection_id NUMBER(9) NOT NULL,

	CONSTRAINT data_service_coll_unique_ids UNIQUE(data_service_id, collection_id),
	CONSTRAINT data_service_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE,
	CONSTRAINT data_service_coll_ds_id_fk FOREIGN KEY (data_service_id) REFERENCES ${username}DATA_SERVICE(data_service_id) ON DELETE CASCADE
) ${tablespace};

-- table for CustomerLoggingService
create table ${username}LOG_ENTRY (
	log_entry_id NUMBER(9) NOT NULL,
	entry_timestamp DATE NOT NULL,
	entry_type VARCHAR2(15 CHAR) NOT NULL,
	code VARCHAR2(15 CHAR) NOT NULL,
	message CLOB NOT NULL,
	origin VARCHAR2(30 CHAR) NULL,

	CONSTRAINT log_entry_primary_key PRIMARY KEY (log_entry_id)
) ${tablespace};

CREATE INDEX ${username}log_entry_timestamp_idx ON ${username}LOG_ENTRY(entry_timestamp) ${tablespace};

-- Project snapshots (deployments or versioned projects
	
create table ${username}SNAPSHOT (
	snapshot_id NUMBER(9) NOT NULL,
	uploaded_date DATE NOT NULL,
    fingerprint_sha256 VARCHAR2(65 CHAR),
    scan_status NUMBER(5) DEFAULT 0 NOT NULL,
    scan_message VARCHAR2(255 CHAR),
	CONSTRAINT snapshot_id_pk PRIMARY KEY (snapshot_id)
) ${tablespace};

create table ${username}SNAPSHOT_CHUNK (
	snapshot_id NUMBER(9) NOT NULL,
	chunk_sequence NUMBER(9) NOT NULL,
	chunk_slice CLOB NOT NULL,

	CONSTRAINT snapshot_chunk_unique PRIMARY KEY (snapshot_id, chunk_sequence),
	CONSTRAINT snapshot_id_fk FOREIGN KEY (snapshot_id) REFERENCES ${username}SNAPSHOT(snapshot_id)
) ${tablespace};

-- Versioned projects
create table ${username}PROJECT (
	project_id NUMBER(9) NOT NULL,
	project_name VARCHAR2(127 CHAR) NOT NULL,
	project_description VARCHAR2(255 CHAR),
	last_updated DATE NOT NULL,
	
	-- latest_version used for concurrency control
	-- eg. "update PROJECT set latest_version=foo where latest_version=bar"
	latest_version NUMBER(9) NULL,
	
	deleted_timestamp DATE NULL,

	CONSTRAINT project_id_pk PRIMARY KEY (project_id),
	CONSTRAINT project_name_unique UNIQUE(project_name)
) ${tablespace};

create table ${username}PROJECT_VERSION (
	project_version_id NUMBER(9) NOT NULL,
	project_id NUMBER(9) NOT NULL,
	project_version NUMBER(9) NOT NULL,
	project_snapshot_id NUMBER(9) NOT NULL,
	user_name VARCHAR2(255) NOT NULL,
	opa_version VARCHAR2(15 CHAR) NOT NULL,
	description VARCHAR2(255 CHAR) NOT NULL,
	creation_date DATE NOT NULL,
	deleted_timestamp DATE NULL,

	CONSTRAINT project_version_pk PRIMARY KEY (project_version_id),
	CONSTRAINT project_version_id_fk FOREIGN KEY (project_id) REFERENCES ${username}PROJECT(project_id),
	CONSTRAINT project_version_snapshot_fk FOREIGN KEY (project_snapshot_id) REFERENCES ${username}SNAPSHOT(snapshot_id)
) ${tablespace};

-- Changes made in a version
create table ${username}PROJECT_VERSION_CHANGE (
	project_version_change_id NUMBER(9) NOT NULL,
	project_version_id NUMBER(9) NOT NULL,
	object_name VARCHAR2(255 CHAR) NOT NULL,
	-- change_type (0=added, 1=deleted, 2=modified)
	change_type NUMBER(5) NOT NULL,

	CONSTRAINT project_version_change_pk PRIMARY KEY (project_version_change_id),
	CONSTRAINT project_version_change_id_fk FOREIGN KEY (project_version_id) REFERENCES ${username}PROJECT_VERSION(project_version_id),
	CONSTRAINT project_version_change_unique UNIQUE (project_version_id, object_name)
) ${tablespace};

-- Indicates deployment objects that are currently being worked on
create table ${username}PROJECT_OBJECT_STATUS (
	project_object_status_id NUMBER(9) NOT NULL,
	project_id NUMBER(9) NOT NULL,
	object_name VARCHAR2(255 CHAR) NOT NULL,
	lock_machine VARCHAR2(255 CHAR) NOT NULL,
	lock_folder VARCHAR2(1024 CHAR) NOT NULL,
	lock_user NUMBER(9) NOT NULL,
	lock_timestamp DATE NOT NULL,
	
	CONSTRAINT project_object_status_id_pk PRIMARY KEY (project_object_status_id),
	CONSTRAINT project_object_id_fk FOREIGN KEY (project_id) REFERENCES ${username}PROJECT(project_id),
	CONSTRAINT lock_user_fk FOREIGN KEY (lock_user) REFERENCES ${username}AUTHENTICATION(authentication_id),
	CONSTRAINT project_object_unique UNIQUE(project_id, object_name)
) ${tablespace};

CREATE TABLE ${username}PROJECT_COLL (
	project_id NUMBER(9) NOT NULL,
	collection_id NUMBER(9) NOT NULL,

	CONSTRAINT project_coll_unique_ids UNIQUE(project_id, collection_id),
	CONSTRAINT project_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE,
	CONSTRAINT project_coll_project_id_fk FOREIGN KEY (project_id) REFERENCES ${username}PROJECT(project_id) ON DELETE CASCADE
) ${tablespace};


-- migrate PROJECT_SUMMARY into DEPLOYMENT
create table ${username}DEPLOYMENT (
	deployment_id NUMBER(9) NOT NULL,
	deployment_name VARCHAR2(127 CHAR) NOT NULL,
	deployment_description VARCHAR2(255 CHAR),
	last_updated DATE NOT NULL,
	
	-- activation properties
	activated_version_id NUMBER(9) NULL,
	activated_interview NUMBER(5) DEFAULT 0 NOT NULL,
	activated_webservice NUMBER(5) DEFAULT 0 NOT NULL,
	activated_interviewservice NUMBER(5) DEFAULT 0 NOT NULL,
	activated_embedjs NUMBER(5) DEFAULT 0 NOT NULL,
	activated_chatservice NUMBER(5) DEFAULT 0 NOT NULL,
	activated_mobile NUMBER(5) DEFAULT 0 NOT NULL,

	-- compatibility_mode (0=current, 1=legacy)
	compatibility_mode NUMBER(5) DEFAULT 0 NOT NULL,	
	user_name VARCHAR2(255),
	deleted_timestamp DATE NULL,

	CONSTRAINT deployment_id_pk PRIMARY KEY (deployment_id),
	CONSTRAINT deployment_name_unique UNIQUE(deployment_name)
) ${tablespace};

create table ${username}DEPLOYMENT_VERSION (
	deployment_version_id NUMBER(9) NOT NULL,
	deployment_id NUMBER(9) NOT NULL,
	deployment_version NUMBER(9) NOT NULL,
	snapshot_id NUMBER(9) NOT NULL,	
	user_name VARCHAR(255) NOT NULL,	
	opa_version VARCHAR2(15 CHAR) NOT NULL,
	description VARCHAR2(255 CHAR) NOT NULL,
	
	-- activatable 1=yes,0=no
	activatable NUMBER(5) DEFAULT 1 NOT NULL,
	snapshot_date DATE NOT NULL,
	snapshot_deleted_timestamp DATE NULL,
	mapping_type VARCHAR2(32 CHAR) NULL,
	data_service_id NUMBER(9) NULL,
	data_service_used NUMBER(5) NULL,

	CONSTRAINT deployment_version_pk PRIMARY KEY (deployment_version_id),
	CONSTRAINT deployment_version_id_fk FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id),
	CONSTRAINT deployment_snapshot_id_fk FOREIGN KEY (snapshot_id) REFERENCES ${username}SNAPSHOT(snapshot_id),
	CONSTRAINT data_service_id_version_fk  FOREIGN KEY (data_service_id) REFERENCES ${username}DATA_SERVICE(data_service_id),
	CONSTRAINT activatable_check CHECK(activatable >= 0 AND activatable <= 1),
	CONSTRAINT data_service_used_check CHECK(data_service_used >= 0 AND data_service_used <= 2)

) ${tablespace};

-- Have circular constraints, need to pick one to apply after both tables exist
ALTER TABLE ${username}DEPLOYMENT
ADD CONSTRAINT activated_version_id_fk FOREIGN KEY (activated_version_id) REFERENCES ${username}DEPLOYMENT_VERSION(deployment_version_id);

create table ${username}DEPLOYMENT_ACTIVATION_HISTORY (
	deployment_activation_hist_id NUMBER(9) NOT NULL,
	deployment_id NUMBER(9) NOT NULL,
	deployment_version_id NUMBER(9) NOT NULL,
	activation_date DATE NOT NULL,
	status_interview NUMBER(5) DEFAULT 0 NOT NULL,
	status_webservice NUMBER(5) DEFAULT 0 NOT NULL,
	status_interviewservice NUMBER(5) DEFAULT 0 NOT NULL,
	status_embedjs NUMBER(5) DEFAULT 0 NOT NULL,
	status_chatservice NUMBER(5) DEFAULT 0 NOT NULL,
	status_mobile NUMBER(5) DEFAULT 0 NOT NULL,
	user_name VARCHAR(255) NOT NULL,

	CONSTRAINT deployment_activ_history_pk PRIMARY KEY (deployment_activation_hist_id),
	CONSTRAINT deployment_activ_history_id_fk FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id),
	CONSTRAINT deployment_activ_version_id_fk FOREIGN KEY (deployment_version_id) REFERENCES ${username}DEPLOYMENT_VERSION(deployment_version_id)
) ${tablespace};

create table ${username}DEPLOYMENT_RULEBASE_REPOS (
	id NUMBER(9) NOT NULL,
	deployment_version_id NUMBER(9) NOT NULL,
	chunk_sequence NUMBER(9) NOT NULL,
	chunk_slice CLOB NOT NULL,
	uploaded_date DATE NOT NULL,

	CONSTRAINT deployment_rulebase_repos_pk PRIMARY KEY (id),
	CONSTRAINT deployment_rulebase_version_fk FOREIGN KEY (deployment_version_id) REFERENCES ${username}DEPLOYMENT_VERSION(deployment_version_id),
	CONSTRAINT deployment_rulebase_repos_uq UNIQUE (deployment_version_id, chunk_sequence)
) ${tablespace};

CREATE TABLE ${username}DEPLOYMENT_COLL (
	deployment_id NUMBER(9) NOT NULL,
	collection_id NUMBER(9) NOT NULL,

	CONSTRAINT deployment_coll_unique_ids UNIQUE(deployment_id, collection_id),
	CONSTRAINT deployment_coll_coll_id_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION(collection_id) ON DELETE CASCADE,
	CONSTRAINT deployment_coll_deploy_id_fk FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id) ON DELETE CASCADE
) ${tablespace};

CREATE TABLE ${username}DEPLOYMENT_CHANNEL_DEFAULT (
  channel_default_id NUMBER(9) NOT NULL,
  collection_id NUMBER(9) NOT NULL,
  default_interview NUMBER(5) DEFAULT 0 NOT NULL,
  default_webservice NUMBER(5) DEFAULT 0 NOT NULL,
	default_interviewservice NUMBER(5) DEFAULT 0 NOT NULL,
	default_mobile NUMBER(5) DEFAULT 0 NOT NULL,
  default_embedjs NUMBER(5) DEFAULT 0 NOT NULL,
  default_chatservice NUMBER(5) DEFAULT 0 NOT NULL,
  defaults_can_override NUMBER(5) DEFAULT 1 NOT NULL,
  CONSTRAINT channel_default_idx PRIMARY KEY (channel_default_id),
  CONSTRAINT collection_id_uq UNIQUE (collection_id),
  CONSTRAINT collection_channel_fk FOREIGN KEY (collection_id) REFERENCES ${username}COLLECTION (collection_id)
    ON DELETE CASCADE,
  CONSTRAINT default_interview_check CHECK(default_interview >= 0 AND default_interview <= 1),
  CONSTRAINT default_webservice_check CHECK(default_webservice >= 0 AND default_webservice <= 1),
  CONSTRAINT default_interviewservice_check CHECK(default_interviewservice >= 0 AND default_interviewservice <= 1),
  CONSTRAINT default_mobile_check CHECK(default_mobile >= 0 AND default_mobile <= 1),
  CONSTRAINT default_javascript_check CHECK(default_embedjs >= 0 AND default_embedjs <= 1),
  CONSTRAINT default_override_check CHECK(defaults_can_override >= 0 AND defaults_can_override <= 1)
) ${tablespace};

CREATE TABLE ${username}DEPLOYMENT_ACTION_LOG
(
	action_timestamp timestamp NOT NULL,
	action_year int NOT NULL,
	action_month int NOT NULL,
	action_day int NOT NULL,
	action_hour int NOT NULL,
	deployment_name varchar(255) NOT NULL,
	product_name varchar(50) NOT NULL,
	product_version varchar(50) NOT NULL,
	session_id varchar(32) NOT NULL,
	user_id varchar(127),
	subject varchar(50) NOT NULL,
	verb varchar(50) NOT NULL
) ${tablespace};

CREATE INDEX ${username}deploy_act_log_name_year ON ${username}DEPLOYMENT_ACTION_LOG(deployment_name, action_year) ${tablespace};
CREATE INDEX ${username}deploy_act_log_name_month ON ${username}DEPLOYMENT_ACTION_LOG(deployment_name, action_month) ${tablespace};
CREATE INDEX ${username}deploy_act_log_name_day ON ${username}DEPLOYMENT_ACTION_LOG(deployment_name, action_day) ${tablespace};
CREATE INDEX ${username}deploy_act_log_name_hour ON ${username}DEPLOYMENT_ACTION_LOG(deployment_name, action_hour) ${tablespace};

CREATE TABLE ${username}SESSION_STATS_TEMPLATE (
  session_stats_template_id NUMBER(9) NOT NULL,
  deployment_id NUMBER(9) NOT NULL,
  deployment_version_id NUMBER(9) NOT NULL,
  CONSTRAINT SESSION_STATS_TEMPLATE_PK PRIMARY KEY (session_stats_template_id),
  CONSTRAINT SESSION_STATS_TEMPLATE_UQ UNIQUE (deployment_id, deployment_version_id),
  CONSTRAINT SESS_STATS_TEMPL_DEPLOY_ID FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id),
  CONSTRAINT SESS_STATS_TEMPL_VERSION_ID FOREIGN KEY (deployment_version_id) REFERENCES ${username}DEPLOYMENT_VERSION(deployment_version_id)
)${tablespace};

CREATE TABLE ${username}SESSION_SCREEN_TEMPLATE (
  session_screen_template_id NUMBER(9) NOT NULL,
  session_stats_template_id NUMBER(9) NOT NULL,
  screen_id VARCHAR(50) NOT NULL,
  screen_title VARCHAR(255) NOT NULL,
  screen_action_code NUMBER(9) NOT NULL,
  screen_order NUMBER(9) NOT NULL,
  CONSTRAINT SESSION_SCREEN_TEMPLATE_PK PRIMARY KEY (session_screen_template_id),
  CONSTRAINT SESSION_SCREEN_TEMPLATE_UQ UNIQUE (session_stats_template_id, screen_id),
  CONSTRAINT SESS_SCR_TEMPL_SESS_TEMPL_FK FOREIGN KEY (session_stats_template_id) REFERENCES ${username}SESSION_STATS_TEMPLATE(session_stats_template_id)
)${tablespace};

CREATE TABLE ${username}SESSION_STATS_LOG (
  session_stats_log_id NUMBER(19) NOT NULL,
  session_stats_template_id NUMBER(9) NOT NULL,
  deployment_id NUMBER(9) NOT NULL,
  deployment_version_id NUMBER(9) NOT NULL,
  product_code NUMBER(9) NOT NULL,
  product_version VARCHAR(25) NOT NULL,
  product_function_code NUMBER(9) NOT NULL,
	product_function_version VARCHAR(25),
  created_timestamp TIMESTAMP NOT NULL,
  created_year NUMBER(9) NOT NULL,
  created_month NUMBER(9) NOT NULL,
  created_day NUMBER(19) NOT NULL,
  created_hour NUMBER(19) NOT NULL,
  last_modified_timestamp TIMESTAMP NOT NULL,
  last_modified_year NUMBER(9) NOT NULL,
  last_modified_month NUMBER(9) NOT NULL,
  last_modified_day NUMBER(19) NOT NULL,
  last_modified_hour NUMBER(19) NOT NULL,
  duration_millis NUMBER(19) NOT NULL,
  duration_sec NUMBER(19) NOT NULL,
  duration_min NUMBER(19) NOT NULL,
  screens_visited NUMBER(9) NOT NULL,
  auth_id RAW(16) NULL,
  authenticated NUMBER(5) NOT NULL,
  completed NUMBER(5) NOT NULL,
  CONSTRAINT SESSION_STATS_LOG_PK PRIMARY KEY (session_stats_log_id),
  CONSTRAINT SESS_STATS_SESS_TEMPL_FK FOREIGN KEY (session_stats_template_id) REFERENCES ${username}SESSION_STATS_TEMPLATE(session_stats_template_id),
  CONSTRAINT SESS_STATS_DEPLOYMENT_FK FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id),
  CONSTRAINT SESS_STATS_VERSION_FK FOREIGN KEY (deployment_version_id) REFERENCES ${username}DEPLOYMENT_VERSION(deployment_version_id)
)${tablespace};

CREATE INDEX ${username}USAGE_TREND_IDX ON ${username}SESSION_STATS_LOG(created_hour, deployment_id) ${tablespace};
CREATE INDEX ${username}OBSOLETE_API_USAGE_IDX ON ${username}SESSION_STATS_LOG(deployment_id, created_timestamp, product_function_version, product_function_code, product_code) ${tablespace};
CREATE INDEX ${username}SESS_BY_DEPL_IDX ON ${username}SESSION_STATS_LOG(deployment_id, product_function_code, auth_id, created_timestamp) ${tablespace};
CREATE INDEX ${username}SESS_BY_DEPL_DURATION_IDX ON ${username}SESSION_STATS_LOG(deployment_id, product_function_code, auth_id, created_timestamp, duration_min) ${tablespace};
CREATE INDEX ${username}SESS_BY_DEPL_SCREENS_IDX ON ${username}SESSION_STATS_LOG(deployment_id, product_function_code, auth_id, created_timestamp, screens_visited) ${tablespace};
CREATE INDEX ${username}SESS_BY_VERS_IDX ON ${username}SESSION_STATS_LOG(deployment_version_id, product_function_code, auth_id, created_timestamp) ${tablespace};
CREATE INDEX ${username}SESS_BY_VERS_DURATION_IDX ON ${username}SESSION_STATS_LOG(deployment_version_id, product_function_code, auth_id, created_timestamp, duration_min) ${tablespace};
CREATE INDEX ${username}SESS_BY_VERS_SCREENS_IDX ON ${username}SESSION_STATS_LOG(deployment_version_id, product_function_code, auth_id, created_timestamp, screens_visited) ${tablespace};
CREATE INDEX ${username}SESS_BY_CREATED_DAY ON ${username}SESSION_STATS_LOG(created_timestamp, created_day) ${tablespace};
CREATE INDEX ${username}SESS_BY_CREATED_MONTH ON ${username}SESSION_STATS_LOG(created_timestamp, created_month) ${tablespace};


CREATE TABLE ${username}SESSION_SCREEN_LOG (
  session_screen_log_id NUMBER(19) NOT NULL,
  session_stats_log_id NUMBER(19) NOT NULL,
  session_stats_template_id NUMBER(9) NOT NULL,
  deployment_id NUMBER(9) NOT NULL,
  deployment_version_id NUMBER(9) NOT NULL,
  product_code NUMBER(9) NOT NULL,
  product_version VARCHAR(25) NOT NULL,
  product_function_code NUMBER(9) NOT NULL,
  session_created_timestamp TIMESTAMP NOT NULL,
  auth_id RAW(16) NULL,
  authenticated NUMBER(5) NOT NULL,
  screen_id VARCHAR(50) NOT NULL,
  screen_order NUMBER(9) NOT NULL,
  screen_action_code NUMBER(9) NOT NULL,
  screen_sequence NUMBER(9) NOT NULL,
  entry_transition_code NUMBER(5) NOT NULL,
  entry_timestamp TIMESTAMP NOT NULL,
  submit_timestamp TIMESTAMP NULL,
  exit_transition_code NUMBER(5) NULL,
  exit_timestamp TIMESTAMP NULL,
  duration_millis NUMBER(19) NOT NULL,
  duration_sec NUMBER(19) NOT NULL,
  duration_min NUMBER(19) NOT NULL,
  CONSTRAINT SESSION_SCREEN_LOG_PK PRIMARY KEY (session_screen_log_id),
  CONSTRAINT SESSION_SCREEN_STATS_LOG_FK FOREIGN KEY (session_stats_log_id) REFERENCES ${username}SESSION_STATS_LOG (session_stats_log_id),
  CONSTRAINT SESSION_SCREEN_STATS_TEMPL_FK FOREIGN KEY (session_stats_template_id) REFERENCES ${username}SESSION_STATS_TEMPLATE (session_stats_template_id),
  CONSTRAINT SESSION_SCREEN_DEPLOYMENT_FK FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT (deployment_id),
  CONSTRAINT SESSION_SCREEN_DEPL_VERS_FK FOREIGN KEY (deployment_version_id) REFERENCES ${username}DEPLOYMENT_VERSION (deployment_version_id)
) ${tablespace};

CREATE INDEX ${username}SCREEN_BY_SESSION_ID_IDX ON ${username}SESSION_SCREEN_LOG(session_stats_log_id) ${tablespace};
CREATE INDEX ${username}SCREEN_BY_VERS_ID_ACTION_IDX ON ${username}SESSION_SCREEN_LOG(deployment_version_id, session_created_timestamp, screen_id, screen_action_code) ${tablespace};

CREATE TABLE ${username}STATISTICS_CHART (
	statistics_chart_id NUMBER(9) NOT NULL,
	chart_type VARCHAR(30) NOT NULL,
	chart_data CLOB NOT NULL,
	CONSTRAINT STATISTICS_CHART_PK PRIMARY KEY (statistics_chart_id)
) ${tablespace};

CREATE TABLE ${username}DEPLOYMENT_STATS_CHART (
	deployment_stats_chart_id NUMBER(9) NOT NULL,
	statistics_chart_id NUMBER(9) NOT NULL,
	deployment_id NUMBER(9) NOT NULL,
	chart_number NUMBER(9) NOT NULL,
	CONSTRAINT DEPLOYMENT_STATS_CHART_PK PRIMARY KEY (deployment_stats_chart_id),
	CONSTRAINT DEPL_CHART_STAT_CHART_FK FOREIGN KEY (statistics_chart_id) REFERENCES ${username}STATISTICS_CHART(statistics_chart_id),
	CONSTRAINT DEPL_CHART_DEPLOYMENT_FK FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id)
) ${tablespace};

CREATE TABLE ${username}OVERVIEW_STATS_CHART (
	overview_stats_chart_id NUMBER(9) NOT NULL,
	statistics_chart_id NUMBER(9) NOT NULL,
	chart_number NUMBER(9) NOT NULL,
	CONSTRAINT OVERVIEW_STATS_CHART_PK PRIMARY KEY (overview_stats_chart_id),
	CONSTRAINT OVER_CHART_STAT_CHART_FK FOREIGN KEY (statistics_chart_id) REFERENCES ${username}STATISTICS_CHART(statistics_chart_id)
) ${tablespace};

CREATE TABLE ${username}FUNCTION_STATS_LOG (
  function_stats_log_id NUMBER(9) NOT NULL,
  deployment_id NUMBER(9) NOT NULL,
  product_code NUMBER(9) NOT NULL,
  product_function_code NUMBER(9) NOT NULL,
  product_function_version VARCHAR(25) NOT NULL,
  last_used_timestamp DATE NOT NULL,
  CONSTRAINT FUNCTION_STATS_LOG_PK PRIMARY KEY (function_stats_log_id),
  CONSTRAINT FUNCTION_STATS_LOG_UQ UNIQUE (deployment_id, product_code, product_function_code, product_function_version),
  CONSTRAINT FUNCTION_STATS_DEPLOY_FK FOREIGN KEY (deployment_id) REFERENCES ${username}DEPLOYMENT(deployment_id)
) ${tablespace};

CREATE INDEX ${username}FUNCTION_USAGE_OBSOLETE_IDX ON ${username}FUNCTION_STATS_LOG(last_used_timestamp, product_code, product_function_code, product_function_version, deployment_id) ${tablespace};



-- SSL trust store

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

-- table for Auditing

create table ${username}AUDIT_LOG (
	audit_id NUMBER(9) NOT NULL,	
	audit_date DATE NOT NULL,
	auth_id NUMBER(9) NULL,
	auth_name VARCHAR(100 CHAR) NULL,
	description CLOB NULL,
	object_type VARCHAR(50 CHAR) NULL,
	object_id NUMBER(9) NULL,
	operation VARCHAR(50 CHAR) NULL,
	result NUMBER(9) NULL,
	extension CLOB NULL,

	CONSTRAINT audit_primary_key PRIMARY KEY (audit_id)
) ${tablespace};

CREATE INDEX ${username}audit_date_idx ON ${username}AUDIT_LOG(audit_date) ${tablespace};

create table ${username}SSL_PRIVATE_KEY (
	ssl_private_key_id NUMBER(9) NOT NULL,
    key_name VARCHAR(80) NOT NULL,
	keystore CLOB NULL,
	last_updated DATE NULL,
	fingerprint_sha256 VARCHAR(100) NULL,
    fingerprint_sha1 VARCHAR(60) NULL,
    issuer VARCHAR(255) NULL,
    subject VARCHAR(255) NULL,
    valid_from TIMESTAMP NULL,
    valid_to TIMESTAMP NULL,

	CONSTRAINT ssl_private_key_pk PRIMARY KEY (ssl_private_key_id),
	CONSTRAINT priv_fingerprint_sha256_uq UNIQUE (fingerprint_sha256),
	CONSTRAINT priv_fingerprint_sha1_uq UNIQUE (fingerprint_sha1),
	CONSTRAINT ssl_key_name_unique UNIQUE (key_name)
) ${tablespace};

-- Create the sequences for the primary keys
CREATE SEQUENCE ${username}authentication_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}authentication_pwd_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}security_token_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}role_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}collection_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}data_service_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}log_entry_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}snapshot_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}project_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}project_version_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}project_change_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}project_object_status_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}deployment_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}deployment_version_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}deployment_activation_hist_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}deployment_rulebase_repos_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}deployment_channel_default_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}session_stats_template_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}session_screen_template_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}session_stats_log_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}session_screen_log_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}function_stats_log_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}statistics_chart_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}deployment_stats_chart_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}overview_stats_chart_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}ssl_certificate_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}audit_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ${username}ssl_private_key_seq START WITH 1 INCREMENT BY 1;
