-- 12.2.4 data upgrade script for MySQL

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type, config_property_public, config_property_description)
    VALUES ('docgen_server_url_pattern', '{0}://{1}:{2}/{3}/document-generation-server', 0, 1, 'URL pattern for the document generation server')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
