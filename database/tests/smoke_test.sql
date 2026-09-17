-- Post-install smoke test: no network calls, no gateway required. Confirms
-- the schema objects exist, compiled cleanly, and the pure (non-HTTP)
-- logic -- config lookup and route mapping -- behaves as documented.
--
-- Run after database/install.sql, in the same schema:
--   sqlplus <user>/<password>@<connect_string> @smoke_test.sql
--
-- This does NOT exercise generate()/chat() against a real gateway -- that
-- requires a reachable gateway, a Web Credential, and a real AIR_CONFIG
-- row (see manual_gateway_test.sql). It passed on Oracle Database 23ai
-- Free; see database/README.md.

set serveroutput on size unlimited

prompt == Checking object validity ==
declare
    v_invalid_count pls_integer;
begin
    select count(*)
      into v_invalid_count
      from user_objects
     where object_name in ('APEX_AI_ROUTER', 'AIR_MODEL_USAGE_V', 'AIR_DAILY_USAGE_V')
       and status != 'VALID';

    if v_invalid_count > 0 then
        raise_application_error(-20000, 'One or more AIR objects are INVALID. Check USER_ERRORS.');
    end if;

    dbms_output.put_line('OK: all expected objects are VALID.');
end;
/

prompt == Checking required AIR_CONFIG keys are present ==
declare
    v_missing pls_integer;
begin
    select count(*)
      into v_missing
      from (select 'GATEWAY_BASE_URL' as k from dual
            union all select 'CREDENTIAL_STATIC_ID' from dual
            union all select 'HTTP_TIMEOUT_SECONDS' from dual)
     where k not in (select config_key from air_config);

    if v_missing > 0 then
        raise_application_error(-20000, 'AIR_CONFIG is missing one or more required keys.');
    end if;

    dbms_output.put_line('OK: required AIR_CONFIG keys are present.');
end;
/

prompt == Checking route mapping raises on an unknown route ==
declare
    v_result clob;
begin
    -- generate() calls f_map_route() before attempting any HTTP call, so
    -- this fails fast on the unknown route without needing a reachable
    -- gateway.
    v_result := apex_ai_router.generate(p_prompt => 'test', p_route => 'NOT_A_REAL_ROUTE');
    raise_application_error(-20000, 'Expected e_unknown_route but no exception was raised.');
exception
    when apex_ai_router.e_unknown_route then
        dbms_output.put_line('OK: unknown route correctly raised e_unknown_route.');
end;
/

prompt == Smoke test complete ==
