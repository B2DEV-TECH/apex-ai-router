-- APEX AI Router -- database uninstall script.
-- Drops objects in reverse dependency order. Does not drop the schema
-- itself or revoke any grants made by grants/grants_to_apex_schema.sql --
-- run database/grants/revoke_from_apex_schema.sql first if you applied
-- those grants.

set define on

prompt == Dropping package APEX_AI_ROUTER ==
drop package apex_ai_router;

prompt == Dropping views ==
drop view air_daily_usage_v;
drop view air_model_usage_v;

prompt == Dropping tables ==
drop table air_request_log purge;
drop table air_config purge;

prompt == Uninstall complete ==
