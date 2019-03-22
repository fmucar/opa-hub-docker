-- Compatibility mode upgrade for MySQL

-- Compatibility mode (1) -> no compatibility mode (0)
-- Compatibility mode after upgrade (2) -> compatibility mode (1)
update DEPLOYMENT
	set compatibility_mode=compatibility_mode-1
	where compatibility_mode>0;
