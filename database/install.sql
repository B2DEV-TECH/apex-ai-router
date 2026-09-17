-- APEX AI Router -- database install script.
--
-- Run as (or granted appropriate privileges in) the schema that should own
-- the AIR_ objects -- typically the same schema as your APEX workspace's
-- parsing schema, so the package can be called directly from application
-- pages without cross-schema grants. If you use a separate schema, run
-- database/grants/grants_to_apex_schema.sql afterwards.
--
-- Usage (SQL*Plus / SQLcl):
--   sqlplus <user>/<password>@<connect_string> @install.sql
--
-- This script does not create a database user, a tablespace, or an APEX
-- workspace -- see database/README.md for prerequisites.

whenever sqlerror exit sql.sqlcode
set define on
set serveroutput on size unlimited

prompt == AIR_CONFIG ==
@@tables/air_config.sql

prompt == Seeding AIR_CONFIG placeholders (edit these before real use) ==
insert into air_config (config_key, config_value, description) values
    ('GATEWAY_BASE_URL', 'https://CHANGE-ME.example.com/v1',
     'Full base URL of the APEX AI Router gateway, including /v1. Edit before use.');
insert into air_config (config_key, config_value, description) values
    ('CREDENTIAL_STATIC_ID', 'AIR_GATEWAY_CREDENTIAL',
     'Static ID of the Shared Components > Web Credential holding the gateway API key as a Bearer token.');
insert into air_config (config_key, config_value, description) values
    ('HTTP_TIMEOUT_SECONDS', '30',
     'APEX_WEB_SERVICE.MAKE_REST_REQUEST transfer timeout, in seconds.');
commit;

prompt == AIR_REQUEST_LOG ==
@@tables/air_request_log.sql

prompt == Views ==
@@views/air_model_usage_v.sql
@@views/air_daily_usage_v.sql

prompt == Package: APEX_AI_ROUTER ==
@@packages/apex_ai_router.pks
show errors package apex_ai_router
@@packages/apex_ai_router.pkb
show errors package body apex_ai_router

prompt == Install complete ==
prompt Next steps:
prompt   1. Create a Web Credential (Shared Components > Web Credentials)
prompt      named AIR_GATEWAY_CREDENTIAL (or update CREDENTIAL_STATIC_ID)
prompt      holding your gateway API key as an HTTP header credential
prompt      (Authorization: Bearer <key>).
prompt   2. Update AIR_CONFIG.GATEWAY_BASE_URL to your real gateway endpoint.
prompt   3. Run database/tests/smoke_test.sql to sanity-check the install.
