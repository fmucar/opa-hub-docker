-- 12.2.7 upgrade script for Oracle
-- property changes (cloud and private-cloud)
INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'interview_cors_whitelist', null, 0, 1, 'A ; list of whitelisted servers able to make cross site requests to Web Determinations.' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='interview_cors_whitelist'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'det_server_batch_request_max_mb', 10, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the Assess API feature' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='det_server_batch_request_max_mb'));        
        
INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'deployment_stats_batch_cases_per_session', 25, 1, 1, 'Maximum number of cases included in a session recorded for the batch service' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='deployment_stats_batch_cases_per_session'));                