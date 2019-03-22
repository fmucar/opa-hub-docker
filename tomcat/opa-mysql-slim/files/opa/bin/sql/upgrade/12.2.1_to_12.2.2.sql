-- Upgrade script for MySQL
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
	VALUES ('interview_timeout_warning_enabled', 1, 1, 1, '0 = disable, 1 = enabled. Enabling turns on user warnings about session expiry for interviews')
  ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

UPDATE CONFIG_PROPERTY SET config_property_str_value='../hub/news/news-{1}.html' WHERE config_property_name='hub_news_url';