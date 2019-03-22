-- 12.2.11 data upgrade script for MySQL
UPDATE CONFIG_PROPERTY SET config_property_str_value = NULL WHERE config_property_name = 'clamd_location';
