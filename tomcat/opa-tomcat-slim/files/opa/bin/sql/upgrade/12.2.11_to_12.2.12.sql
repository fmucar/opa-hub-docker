-- 12.2.12 data upgrade script for MySQL

-- Table for Auditing
CREATE TABLE if not exists AUDIT_LOG (
  audit_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  audit_date datetime NOT NULL, 
  auth_id int(11) DEFAULT NULL,
  auth_name varchar(100) DEFAULT NULL,
  description longtext DEFAULT NULL,
  object_type varchar(50) DEFAULT NULL,
  object_id int(11) DEFAULT NULL,
  operation varchar(50) DEFAULT NULL,
  result int(11) DEFAULT NULL,	
  extension longtext DEFAULT NULL,

  PRIMARY KEY (audit_id),
  INDEX audit_date_idx (audit_date)
) ENGINE=InnoDB;

-- Configuration for Auditing
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_int_value, config_property_type, config_property_public, config_property_description)
    VALUES ('audit_enabled', 1, 1, 1, '0 = disabled, 1 = enabled. Enabling turns on the audit writing') 
	ON DUPLICATE KEY UPDATE config_property_name = config_property_name;
