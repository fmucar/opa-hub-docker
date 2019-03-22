-- 12.2.13 data upgrade script for Oracle
-- delim /

-- New configuration properties for throttling Batch Assess API for cloud deployments
INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'cloud_batch_concurrent_limit_enabled', 0, 1, 0,  '0 = Disabled, 1 = Enabled. Enabling turns on limiting for Batch Assess API requests' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='cloud_batch_concurrent_limit_enabled'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'cloud_batch_concurrent_proc_max', 4, 1, 0,  'Maximum number of Batch Assess API requests to be processed concurrently per server' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='cloud_batch_concurrent_proc_max'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'cloud_batch_concurrent_queue_max', 12, 1, 0,  'Maximum number of Batch Assess API requests to be queued concurrently per server' FROM DUAL
		WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='cloud_batch_concurrent_queue_max'));
		