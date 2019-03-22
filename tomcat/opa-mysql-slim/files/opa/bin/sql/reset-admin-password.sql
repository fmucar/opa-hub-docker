
-- remove any existing password for admin account
DELETE FROM AUTHENTICATION_PWD WHERE authentication_id IN
	(SELECT authentication_id from AUTHENTICATION WHERE user_name='admin');

-- set the password for admin account
INSERT INTO AUTHENTICATION_PWD (authentication_id, password, created_date, status)
	VALUES ((SELECT authentication_id from AUTHENTICATION WHERE user_name='admin'),
	'$password', now(), 1);

-- make sure the account is active
UPDATE AUTHENTICATION
	SET status = 0, change_password = $changepassword
	WHERE user_name='admin';

#if($salt)
-- create application salt for encrypted data
INSERT INTO CONFIG_PROPERTY (config_property_name, config_property_str_value, config_property_type)
	VALUES ('app_salt', '$salt', 0);
#end
