create or replace package body apex_ai_router_demo as

    -- Non-secret config, reusing AIR_CONFIG (database/tables/air_config.sql)
    -- plus one demo-only extra key this package expects to find there:
    -- ADMIN_CREDENTIAL_STATIC_ID -- the name of a Web Credential holding a
    -- gateway ADMIN key (Authorization: Bearer <admin-key>), separate from
    -- CREDENTIAL_STATIC_ID's inference key. See apex-demo/README.md for
    -- the insert statement.
    function f_config(p_key in varchar2) return varchar2 is
        v_value varchar2(4000);
    begin
        select config_value into v_value from air_config where config_key = p_key;
        return v_value;
    exception
        when no_data_found then
            raise_application_error(-20060, 'apex-demo: AIR_CONFIG is missing key: ' || p_key);
    end f_config;

    -- Confidence note (see HANDOFF.md): apex_web_service.g_headers as a
    -- name/value collection populated after make_rest_request() is
    -- documented Oracle APEX API surface, used with high confidence. Not
    -- independently re-verified against a live instance while building
    -- this, same caveat as every other APEX_WEB_SERVICE call in this repo.
    function f_response_header(p_name in varchar2) return varchar2 is
    begin
        for i in 1 .. apex_web_service.g_headers.count loop
            if lower(apex_web_service.g_headers(i).name) = lower(p_name) then
                return apex_web_service.g_headers(i).value;
            end if;
        end loop;
        return null;
    end f_response_header;

    function run_playground(
        p_prompt in clob,
        p_route  in varchar2 default apex_ai_router.c_route_auto
    ) return t_playground_result is
        v_result       t_playground_result;
        v_route_mapped varchar2(30);
        v_body         json_object_t := json_object_t();
        v_message      json_object_t := json_object_t();
        v_messages     json_array_t := json_array_t();
        v_response     clob;
        v_response_obj json_object_t;
        v_admin_response clob;
        v_admin_obj    json_object_t;
        v_requests_arr json_array_t;
        v_row          json_object_t;
        v_started      pls_integer := dbms_utility.get_time;
    begin
        -- Route names map identically to apex_ai_router's internal
        -- convention (apex-auto / apex-efficient / apex-capable); reuse it
        -- rather than duplicating the mapping.
        case upper(trim(p_route))
            when apex_ai_router.c_route_auto then v_route_mapped := 'apex-auto';
            when apex_ai_router.c_route_efficient then v_route_mapped := 'apex-efficient';
            when apex_ai_router.c_route_capable then v_route_mapped := 'apex-capable';
            else raise_application_error(-20050, 'Unknown route: ' || p_route);
        end case;

        v_message.put('role', 'user');
        v_message.put('content', p_prompt);
        v_messages.append(v_message);
        v_body.put('model', v_route_mapped);
        v_body.put('messages', v_messages);

        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        v_response := apex_web_service.make_rest_request(
            p_url                  => f_config('GATEWAY_BASE_URL') || '/chat/completions',
            p_http_method          => 'POST',
            p_credential_static_id => f_config('CREDENTIAL_STATIC_ID'),
            p_body                 => v_body.to_clob(),
            p_transfer_timeout     => to_number(f_config('HTTP_TIMEOUT_SECONDS'))
        );

        if apex_web_service.g_status_code != 200 then
            raise_application_error(
                -20051,
                'Gateway returned HTTP ' || apex_web_service.g_status_code || ': ' || v_response
            );
        end if;

        v_result.request_id := f_response_header('X-Request-Id');
        v_result.latency_ms := (dbms_utility.get_time - v_started) * 10;

        v_response_obj  := json_object_t(v_response);
        v_result.response := treat(
                                 treat(
                                     v_response_obj.get_array('choices').get(0) as json_object_t
                                 ).get_object('message') as json_object_t
                             ).get_clob('content');

        -- Second call: look up this exact request's cost/routing detail
        -- from the admin API by X-Request-Id (see the package header
        -- comment for why this is the only correct correlation).
        apex_web_service.g_request_headers.delete;
        v_admin_response := apex_web_service.make_rest_request(
            p_url                  => f_config('GATEWAY_BASE_URL') || '/admin/requests?limit=20&offset=0',
            p_http_method          => 'GET',
            p_credential_static_id => f_config('ADMIN_CREDENTIAL_STATIC_ID'),
            p_transfer_timeout     => to_number(f_config('HTTP_TIMEOUT_SECONDS'))
        );

        if apex_web_service.g_status_code = 200 and v_result.request_id is not null then
            v_admin_obj    := json_object_t(v_admin_response);
            v_requests_arr := v_admin_obj.get_array('requests');
            for i in 0 .. v_requests_arr.get_size - 1 loop
                v_row := treat(v_requests_arr.get(i) as json_object_t);
                if v_row.get_string('request_id') = v_result.request_id then
                    v_result.selected_tier          := v_row.get_string('selected_target');
                    v_result.selected_model         := v_row.get_string('selected_model');
                    v_result.input_tokens           := v_row.get_number('input_tokens');
                    v_result.output_tokens          := v_row.get_number('output_tokens');
                    v_result.estimated_cost         := v_row.get_number('estimated_cost');
                    v_result.estimated_baseline_cost := v_row.get_number('estimated_baseline_cost');
                    v_result.estimated_savings      := v_row.get_number('estimated_savings');
                    exit;
                end if;
            end loop;
        end if;
        -- If the matching row isn't found (e.g. telemetry write lag, or the
        -- admin credential isn't configured), the response text above is
        -- still returned -- the enrichment fields are simply left null and
        -- the Playground page should render them as "n/a", never as zero.

        return v_result;
    end run_playground;

    procedure ajax_run is
        v_prompt clob        := apex_application.g_x01;
        v_route  varchar2(30) := nvl(apex_application.g_x02, apex_ai_router.c_route_auto);
        v_result t_playground_result;
    begin
        v_result := run_playground(p_prompt => v_prompt, p_route => v_route);

        apex_json.open_object;
        apex_json.write('success', true);
        apex_json.write('result', v_result.response);
        apex_json.write('selected_tier', v_result.selected_tier);
        apex_json.write('selected_model', v_result.selected_model);
        apex_json.write('latency_ms', nvl(v_result.latency_ms, 0));
        apex_json.write('input_tokens', v_result.input_tokens);
        apex_json.write('output_tokens', v_result.output_tokens);
        apex_json.write('estimated_cost', v_result.estimated_cost);
        apex_json.write('estimated_baseline_cost', v_result.estimated_baseline_cost);
        apex_json.write('estimated_savings', v_result.estimated_savings);
        apex_json.write('request_id', v_result.request_id);
        apex_json.close_object;
    exception
        when others then
            -- Same controlled-error convention as
            -- apex-plugin/src/apex_ai_router_da.pkb's ajax(): never let a
            -- raw exception (gateway unreachable, bad config, malformed
            -- admin response) reach the browser as an uncaught error.
            apex_json.open_object;
            apex_json.write('success', false);
            apex_json.write('error', sqlerrm);
            apex_json.close_object;
    end ajax_run;

end apex_ai_router_demo;
/
