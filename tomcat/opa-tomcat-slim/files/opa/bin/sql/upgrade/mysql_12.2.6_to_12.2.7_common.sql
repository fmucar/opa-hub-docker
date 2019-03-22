-- 12.2.7 data upgrade for MySQL
-- property changes (cloud and private-cloud)
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('interview_cors_whitelist', null, 0, 1, 'A ; list of whitelisted servers able to make cross site requests to Web Determinations.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
    
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('det_server_batch_request_max_mb', 10, 1, 1, 'Maximum allowed size in megabytes for an Assess API batch request')
	ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
    
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('deployment_stats_batch_cases_per_session', 25, 1, 1, 'Maximum number of cases included in a session recorded for the batch service')
	ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
	