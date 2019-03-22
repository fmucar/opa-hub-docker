-- 12.2.7 data upgrade script for MySQL
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('feature_assess_api_enabled', 1, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on Assess API feature.')
	ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
