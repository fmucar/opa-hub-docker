-- 12.2.14 upgrade script for Oracle
-- delim /
INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'feature_chat_service_enabled', 1, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the Chat Service feature' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='feature_chat_service_enabled'));

INSERT INTO ${username}CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    (SELECT 'feature_web_rules_enabled', 0, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the experimental Web Rules feature' FROM DUAL
        WHERE NOT EXISTS (SELECT * FROM ${username}CONFIG_PROPERTY WHERE config_property_name='feature_web_rules_enabled'));

UPDATE ${username}CONFIG_PROPERTY SET config_property_int_value = 1 WHERE config_property_name = 'feature_chat_service_enabled';
