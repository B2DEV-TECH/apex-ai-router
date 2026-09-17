-- Optional: run this only if AIR_ objects live in a schema OTHER than your
-- APEX workspace's parsing schema. If they're the same schema (the
-- simplest, recommended setup), skip this file entirely.
--
-- Run as the schema that owns the AIR_ objects (the one that ran
-- database/install.sql). Replace &apex_schema. with your APEX parsing
-- schema name when prompted, or pass it directly:
--   sqlplus <owner>/<password>@<connect_string> @grants_to_apex_schema.sql <apex_schema>

set define on
define apex_schema = &1

grant execute on apex_ai_router to &apex_schema.;
grant select on air_model_usage_v to &apex_schema.;
grant select on air_daily_usage_v to &apex_schema.;

prompt == Grants applied to &apex_schema. ==
prompt If &apex_schema. needs to query AIR_MODEL_USAGE_V / AIR_DAILY_USAGE_V
prompt by unqualified name from APEX pages, also create synonyms there:
prompt   create synonym apex_ai_router for <owner>.apex_ai_router;
prompt   create synonym air_model_usage_v for <owner>.air_model_usage_v;
prompt   create synonym air_daily_usage_v for <owner>.air_daily_usage_v;
