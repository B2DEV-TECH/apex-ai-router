-- Reverses grants_to_apex_schema.sql. Run before database/uninstall.sql if
-- you applied those grants; also drop any synonyms you created manually.

set define on
define apex_schema = &1

revoke execute on apex_ai_router from &apex_schema.;
revoke select on air_model_usage_v from &apex_schema.;
revoke select on air_daily_usage_v from &apex_schema.;

prompt == Grants revoked from &apex_schema. ==
