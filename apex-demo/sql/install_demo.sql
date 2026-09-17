-- apex-demo -- support package install script.
--
-- Prerequisite: database/install.sql must already be run in this schema
-- (this script assumes AIR_CONFIG and APEX_AI_ROUTER already exist).
--
-- Usage (SQL*Plus / SQLcl):
--   sqlplus <user>/<password>@<connect_string> @install_demo.sql

whenever sqlerror exit sql.sqlcode
set define on
set serveroutput on size unlimited

prompt == Seeding the demo-only ADMIN_CREDENTIAL_STATIC_ID config key ==
prompt (idempotent -- safe to re-run; does not touch the other AIR_CONFIG keys
prompt seeded by database/install.sql)
merge into air_config t
using (select 'ADMIN_CREDENTIAL_STATIC_ID' as config_key from dual) s
on (t.config_key = s.config_key)
when not matched then
    insert (config_key, config_value, description) values (
        'ADMIN_CREDENTIAL_STATIC_ID', 'AIR_GATEWAY_ADMIN_CREDENTIAL',
        'apex-demo only (not used by database/ or apex-plugin/): static ID of a ' ||
        'Web Credential holding the gateway ADMIN API key as a Bearer token. ' ||
        'Read-only, used solely by the Playground page to look up a request''s ' ||
        'cost/routing detail via GET /admin/requests. Never sent to the browser.'
    );
commit;

prompt == Package: APEX_AI_ROUTER_DEMO ==
@demo_playground_pkg.pks
show errors package apex_ai_router_demo
@demo_playground_pkg.pkb
show errors package body apex_ai_router_demo

prompt == Install complete ==
prompt Next steps:
prompt   1. Create a SECOND Web Credential (Shared Components > Web
prompt      Credentials) named AIR_GATEWAY_ADMIN_CREDENTIAL (or update
prompt      ADMIN_CREDENTIAL_STATIC_ID), holding your gateway's
prompt      APEX_AI_ROUTER_ADMIN_API_KEY as a Bearer token. This must be a
prompt      DIFFERENT credential from AIR_GATEWAY_CREDENTIAL -- the gateway
prompt      rejects an inference key on any /admin/* route by design.
prompt   2. Build the demo app pages per apex-demo/README.md (this script
prompt      only installs the support package, not the APEX pages
prompt      themselves -- see apex-demo/README.md for why).
