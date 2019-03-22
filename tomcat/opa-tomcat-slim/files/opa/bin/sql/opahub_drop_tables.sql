
drop table if exists PROJECT_COLL;
drop table if exists AUTH_ROLE_COLL;
drop table if exists AUTHENTICATION_ROLE;
drop table if exists AUTHENTICATION_PWD;
drop table if exists SECURITY_TOKEN;
drop table if exists PROJECT_DEPLOYMENT_HISTORY;
drop table if exists PROJECT_DEPLOYMENT;
drop table if exists DEPLOYED_RULEBASE_REPOS;
drop table if exists PROJECT_SNAPSHOT_REPOS;
drop table if exists PROJECT_SNAPSHOT;
drop table if exists PROJECT_SUMMARY;
drop table if exists PROJECT_OBJECT_STATUS;
drop table if exists PROJECT_VERSION_CHANGE;
drop table if exists PROJECT_VERSION;
drop table if exists PROJECT;

DROP TABLE IF EXISTS DEPLOYMENT_STATS_CHART;
DROP TABLE IF EXISTS OVERVIEW_STATS_CHART;
DROP TABLE IF EXISTS STATISTICS_CHART; 

drop table if exists SESSION_SCREEN_LOG;
drop table if exists SESSION_SCREEN_TEMPLATE;
drop table if exists SESSION_STATS_LOG;
drop table if exists SESSION_STATS_TEMPLATE;
drop table if exists FUNCTION_STATS_LOG;

drop table if exists SNAPSHOT_CHUNK;
drop table if exists SNAPSHOT;

drop table if exists DEPLOYMENT_CHANNEL_DEFAULT;
drop table if exists DEPLOYMENT_COLL;
drop table if exists DEPLOYMENT_ACTIVATION_HISTORY;
drop table if exists DEPLOYMENT_RULEBASE_REPOS;
drop table if exists DEPLOYMENT_VERSION;
drop table if exists DEPLOYMENT;

drop table if exists DATA_SERVICE_COLL;
drop table if exists AUTHENTICATION;
drop table if exists COLLECTION;
drop table if exists ROLE;
drop table if exists CONFIG_PROPERTY;
drop table if exists DATA_SERVICE;
drop table if exists LOG_ENTRY;
drop procedure if exists OPAAddColumnIfNotExists;
drop table if exists PROJECT_SNAPSHOT_COVERAGE;
drop table if exists DEPLOYMENT_ACTION_LOG;
drop table if exists DEPLOYMENT_STATS_CHART;
drop table if exists OVERVIEW_STATS_CHART;
drop table if exists STATISTICS_CHART;

drop table if exists SSL_PUBLIC_CERTIFICATE;
drop table if exists SSL_PRIVATE_KEY;
drop table if exists AUDIT_LOG;

drop table if exists MODULE;
drop table if exists MODULE_VERSION;
