-- 12.2.14 data upgrade for MySQL
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('feature_chat_service_enabled', 1, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the Chat Service feature')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('feature_web_rules_enabled', 0, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the experimental Web Rules feature')
    ON DUPLICATE KEY UPDATE config_property_name = config_property_name;

UPDATE CONFIG_PROPERTY SET config_property_int_value = 1 WHERE config_property_name = 'feature_chat_service_enabled';

-- tables for WebRules
CREATE TABLE IF NOT EXISTS MODULE (
	module_id INT NOT NULL AUTO_INCREMENT,
	module_name VARCHAR(127) CHARACTER SET utf8 NOT NULL,

	CONSTRAINT module_pk PRIMARY KEY (module_id),
    CONSTRAINT module_name_unique UNIQUE (module_name),
    INDEX module_name_idx (module_name)
)  ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS MODULE_VERSION (
	module_version_id INT NOT NULL AUTO_INCREMENT,
	module_id INT NOT NULL
		REFERENCES MODULE(module_id),
	version_number INT NOT NULL,
    create_timestamp DATETIME NOT NULL,
    is_draft SMALLINT DEFAULT 0 NOT NULL,

    definition LONGTEXT CHARACTER SET utf8 NOT NULL,

    rulebase_deployable SMALLINT DEFAULT 0 NOT NULL,
    -- stat_rule_count INT NOT NULL,
    -- stat_entity_count INT NOT NULL,
    -- stat_attribute_count INT NOT NULL

	CONSTRAINT module_version_pk PRIMARY KEY (module_version_id),
    CONSTRAINT version_number_unique UNIQUE (module_id, version_number),
    INDEX version_number_idx (module_version_id, version_number)
    -- INDEX definition_hash_idx (definition_hash)    
)  ENGINE=InnoDB;

