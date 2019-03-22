-- 12.2.9 data upgrade script for MySQL

-- New configuration property for allowing/preventing OPA for Human Resources Help Desk usage
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('runtime_enabled_for_employees', 0, 1, 0, '0 = disabled, 1 = enabled. If enabled, interviews are allowed only for employees. Ignored if runtime_disabled_for_users is zero.')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

-- total size now exludes generated forms
UPDATE CONFIG_PROPERTY SET config_property_description='Maximum allowed total size in megabytes for session attachments excluding generated forms' WHERE config_property_name='file_attach_max_mb_total';