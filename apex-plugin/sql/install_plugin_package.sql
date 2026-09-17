-- Compiles the plug-in's render/ajax callback package. Run this in the
-- same schema as database/install.sql (APEX_AI_ROUTER must already exist),
-- BEFORE creating the plug-in itself in APEX Builder (see
-- apex-plugin/README.md) -- the plug-in's Render Function / Ajax Callback
-- Function attributes reference this package by name.
--
-- Usage:
--   sqlplus <user>/<password>@<connect_string> @install_plugin_package.sql

whenever sqlerror exit sql.sqlcode
set define off
set serveroutput on size unlimited

prompt == Package: APEX_AI_ROUTER_DA ==
@@../src/apex_ai_router_da.pks
show errors package apex_ai_router_da
@@../src/apex_ai_router_da.pkb
show errors package body apex_ai_router_da

prompt == Done. Next: create the plug-in in APEX Builder -- see apex-plugin/README.md ==
