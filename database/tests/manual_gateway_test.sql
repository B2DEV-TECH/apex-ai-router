-- Manual, network-dependent test -- NOT run as part of any automated
-- check in this repository. Requires:
--   1. A reachable APEX AI Router gateway (real or the local mock
--      upstream via docker-compose; see gateway/README.md).
--   2. AIR_CONFIG.GATEWAY_BASE_URL pointing at it.
--   3. A Web Credential matching AIR_CONFIG.CREDENTIAL_STATIC_ID holding
--      a valid inference API key as an HTTP header credential
--      (Authorization: Bearer <key>).
--   4. Oracle Database network access to the gateway host (an ACL via
--      DBMS_NETWORK_ACL_ADMIN if egress is restricted).
--
-- Run and read the output by hand -- this prints the result rather than
-- asserting it, since the expected response text depends on which model
-- is actually configured behind the gateway.

set serveroutput on size unlimited

declare
    v_result clob;
begin
    v_result := apex_ai_router.generate(
        p_prompt => 'Reply with the single word: pong',
        p_route  => apex_ai_router.c_route_efficient
    );
    dbms_output.put_line('generate() succeeded. Response:');
    dbms_output.put_line(v_result);
exception
    when apex_ai_router.e_gateway_error then
        dbms_output.put_line('Gateway call failed: ' || sqlerrm);
    when apex_ai_router.e_missing_config then
        dbms_output.put_line('AIR_CONFIG is not fully set up: ' || sqlerrm);
end;
/

prompt Check AIR_REQUEST_LOG and AIR_MODEL_USAGE_V for the row this created:
select * from air_request_log order by request_timestamp desc fetch first 1 rows only;
select * from air_model_usage_v;
