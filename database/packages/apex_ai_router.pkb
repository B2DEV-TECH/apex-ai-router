create or replace package body apex_ai_router as

    -- Reads a required, non-secret AIR_CONFIG value.
    function f_config(p_key in air_config.config_key%type) return varchar2 is
        v_value air_config.config_value%type;
    begin
        select config_value
          into v_value
          from air_config
         where config_key = p_key;
        return v_value;
    exception
        when no_data_found then
            raise_application_error(
                -20052,
                'AIR_CONFIG is missing required key: ' || p_key
            );
    end f_config;

    -- Maps the package's public route vocabulary to the gateway's virtual
    -- model ids (routing.yaml route names), so callers never need to know
    -- that naming convention.
    function f_map_route(p_route in varchar2) return varchar2 is
    begin
        case upper(trim(p_route))
            when c_route_auto then
                return 'apex-auto';
            when c_route_efficient then
                return 'apex-efficient';
            when c_route_capable then
                return 'apex-capable';
            else
                raise_application_error(
                    -20050,
                    'Unknown route "' || p_route || '". Expected AUTO, EFFICIENT, or CAPABLE.'
                );
        end case;
    end f_map_route;

    -- Records one row in AIR_REQUEST_LOG for application-context
    -- visibility. Runs as an autonomous transaction and swallows its own
    -- exceptions on purpose: a logging failure must never break the
    -- caller's actual gateway call. This is the one place in this package
    -- that intentionally uses a bare WHEN OTHERS, and only for that
    -- reason.
    procedure p_log_request(
        p_route               in varchar2,
        p_session_id          in varchar2,
        p_gateway_response_id in varchar2,
        p_http_status         in number,
        p_success_yn          in char,
        p_error_code          in varchar2,
        p_error_message       in varchar2,
        p_duration_ms         in number
    ) is
        pragma autonomous_transaction;
        v_app_id     number;
        v_page_id    number;
        v_session_id varchar2(255) := p_session_id;
    begin
        begin
            v_app_id  := v('APP_ID');
            v_page_id := v('APP_PAGE_ID');
            -- The caller-supplied p_session_id (e.g. the plug-in's own
            -- Session ID Page Item, spec section 18) takes precedence;
            -- fall back to the active APEX session id when the caller
            -- didn't pass one.
            if v_session_id is null then
                v_session_id := v('APP_SESSION');
            end if;
        exception
            when others then
                -- No active APEX session (e.g. called from SQL*Plus or a
                -- scheduled job) -- app/page context is simply
                -- unavailable, not an error.
                v_app_id  := null;
                v_page_id := null;
        end;

        insert into air_request_log (
            app_id, page_id, session_id, route, gateway_response_id,
            http_status, success_yn, error_code, error_message, duration_ms
        ) values (
            v_app_id, v_page_id, v_session_id, p_route, p_gateway_response_id,
            p_http_status, p_success_yn, p_error_code, p_error_message, p_duration_ms
        );
        commit;
    exception
        when others then
            rollback;
    end p_log_request;

    -- Shared implementation behind generate() and chat(): builds the
    -- OpenAI-shaped request body, calls the gateway, parses the response,
    -- and logs the call. p_temperature is only ever non-null when called
    -- from generate() -- chat()'s own public signature has no temperature
    -- parameter, per the product spec.
    function f_call_gateway(
        p_messages_json in clob,
        p_route         in varchar2,
        p_session_id    in varchar2,
        p_temperature   in number
    ) return clob is
        v_started      pls_integer := dbms_utility.get_time;
        v_duration_ms  number;
        v_route_mapped varchar2(30) := f_map_route(p_route);
        v_body         json_object_t := json_object_t();
        v_response     clob;
        v_response_obj json_object_t;
        v_response_id  varchar2(255);
        v_content      clob;
        v_error_obj    json_object_t;
        v_error_code   varchar2(128);
        v_error_msg    varchar2(4000);
    begin
        v_body.put('model', v_route_mapped);
        v_body.put('messages', json_array_t(p_messages_json));
        if p_temperature is not null then
            v_body.put('temperature', p_temperature);
        end if;

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

        v_duration_ms := (dbms_utility.get_time - v_started) * 10;

        if apex_web_service.g_status_code = 200 then
            v_response_obj := json_object_t(v_response);
            v_response_id  := v_response_obj.get_string('id');
            v_content      := treat(
                                  treat(
                                      v_response_obj.get_array('choices').get(0) as json_object_t
                                  ).get_object('message') as json_object_t
                              ).get_clob('content');

            p_log_request(
                p_route               => p_route,
                p_session_id          => p_session_id,
                p_gateway_response_id => v_response_id,
                p_http_status         => apex_web_service.g_status_code,
                p_success_yn          => 'Y',
                p_error_code          => null,
                p_error_message       => null,
                p_duration_ms         => v_duration_ms
            );

            return v_content;
        else
            v_error_obj  := json_object_t(v_response).get_object('error');
            v_error_code := v_error_obj.get_string('code');
            v_error_msg  := v_error_obj.get_string('message');

            p_log_request(
                p_route               => p_route,
                p_session_id          => p_session_id,
                p_gateway_response_id => null,
                p_http_status         => apex_web_service.g_status_code,
                p_success_yn          => 'N',
                p_error_code          => v_error_code,
                p_error_message       => v_error_msg,
                p_duration_ms         => v_duration_ms
            );

            raise_application_error(
                -20051,
                'APEX AI Router gateway returned HTTP ' || apex_web_service.g_status_code ||
                ' (' || v_error_code || '): ' || v_error_msg
            );
        end if;
    end f_call_gateway;

    function generate(
        p_prompt      in clob,
        p_route       in varchar2 default c_route_auto,
        p_session_id  in varchar2 default null,
        p_temperature in number   default null
    ) return clob is
        v_messages json_array_t := json_array_t();
        v_message  json_object_t := json_object_t();
    begin
        v_message.put('role', 'user');
        v_message.put('content', p_prompt);
        v_messages.append(v_message);

        return f_call_gateway(
            p_messages_json => v_messages.to_clob(),
            p_route         => p_route,
            p_session_id    => p_session_id,
            p_temperature   => p_temperature
        );
    end generate;

    function chat(
        p_messages_json in clob,
        p_route         in varchar2 default c_route_auto,
        p_session_id    in varchar2 default null
    ) return clob is
    begin
        return f_call_gateway(
            p_messages_json => p_messages_json,
            p_route         => p_route,
            p_session_id    => p_session_id,
            p_temperature   => null
        );
    end chat;

end apex_ai_router;
/
