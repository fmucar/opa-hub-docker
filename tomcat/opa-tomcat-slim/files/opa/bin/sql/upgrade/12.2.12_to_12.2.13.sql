-- 12.2.13 data upgrade script for MySQL

-- New configuration properties for throttling Batch Assess API for cloud deployments
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
	VALUES ('cloud_batch_concurrent_limit_enabled', 0, 1, 0, '0 = Disabled, 1 = Enabled. Enabling turns on limiting for Batch Assess API requests')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
	VALUES ('cloud_batch_concurrent_proc_max', 4, 1, 0, 'Maximum number of Batch Assess API request to be processed concurrently per server')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
    
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
	VALUES ('cloud_batch_concurrent_queue_max', 12, 1, 0, 'Maximum number of Batch Assess API requests to be queued concurrently per server')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
