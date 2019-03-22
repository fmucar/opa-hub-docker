-- 12.2.9 data upgrade script for Oracle

UPDATE ${username}CONFIG_PROPERTY SET config_property_description='Maximum allowed total size in megabytes for session attachments excluding generated forms' WHERE config_property_name='file_attach_max_mb_total';