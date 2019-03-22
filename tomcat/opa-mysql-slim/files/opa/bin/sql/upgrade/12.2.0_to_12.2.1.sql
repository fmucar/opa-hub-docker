-- Upgrade script for MySQL

-- Add configuration properties and database table required for Deployment Statistics
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
  VALUES ('feature_deployment_stats_enabled', 1, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on Deployment Statistics feature')
  ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
	
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public)
  VALUES ('deployment_stats_logging_interval', 60, 1, 0)
  ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

CREATE TABLE IF NOT EXISTS DEPLOYMENT_ACTION_LOG
(
	action_timestamp TIMESTAMP NOT NULL,
	action_year INT NOT NULL,
	action_month INT NOT NULL,
	action_day INT NOT NULL,
	action_hour INT NOT NULL,
	deployment_name VARCHAR(255) CHARACTER SET utf8 NOT NULL,
	product_name VARCHAR(50) CHARACTER SET utf8 NOT NULL,
	product_version VARCHAR(50) CHARACTER SET utf8 NOT NULL,
	session_id VARCHAR(32) CHARACTER SET utf8 NOT NULL,
	user_id VARCHAR(127) CHARACTER SET utf8,
	subject VARCHAR(50) CHARACTER SET utf8 NOT NULL,
	verb VARCHAR(50) CHARACTER SET utf8 NOT NULL,
	INDEX DEPLOY_ACT_LOG_NAME_YEAR (deployment_name, action_year),
	INDEX DEPLOY_ACT_LOG_NAME_MONTH (deployment_name, action_month),
	INDEX DEPLOY_ACT_LOG_NAME_DAY (deployment_name, action_day),
	INDEX DEPLOY_ACT_LOG_NAME_HOUR (deployment_name, action_hour)
) ENGINE=InnoDB;