-- 12.2.7 data upgrade script for Oracle
INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'feature_assess_api_enabled', 1, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the Assess API feature' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='feature_assess_api_enabled'));
