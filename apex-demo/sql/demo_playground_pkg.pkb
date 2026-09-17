create or replace package body apex_ai_router_demo as

    -- Non-secret config, reusing AIR_CONFIG (database/tables/air_config.sql)
    -- plus one demo-only extra key this package expects to find there:
    -- ADMIN_CREDENTIAL_STATIC_ID -- the name of a Web Credential holding a
    -- gateway ADMIN key (Authorization: Bearer <admin-key>), separate from
    -- CREDENTIAL_STATIC_ID's inference key. See apex-demo/README.md for
    -- the insert statement.

    -- Per-request cache for gateway_json(). APEX resets package state at
    -- the end of every request, so this never leaks between page views or
    -- sessions: it only lets the regions of ONE page render share ONE
    -- gateway call per endpoint.
    type t_json_cache is table of clob index by varchar2(200);
    g_json_cache   t_json_cache;
    g_last_error   varchar2(4000);

    c_nls constant varchar2(40) := 'NLS_NUMERIC_CHARACTERS=''.,''';

    function f_config(p_key in varchar2) return varchar2 is
        v_value varchar2(4000);
    begin
        select config_value into v_value from air_config where config_key = p_key;
        return v_value;
    exception
        when no_data_found then
            raise_application_error(-20060, 'apex-demo: AIR_CONFIG is missing key: ' || p_key);
    end f_config;

    -- apex_web_service.g_headers is read after make_rest_request() to
    -- correlate the gateway request ID. This path was exercised on APEX
    -- 26.1 against the local gateway.
    function f_response_header(p_name in varchar2) return varchar2 is
    begin
        for i in 1 .. apex_web_service.g_headers.count loop
            if lower(apex_web_service.g_headers(i).name) = lower(p_name) then
                return apex_web_service.g_headers(i).value;
            end if;
        end loop;
        return null;
    end f_response_header;

    -- GATEWAY_BASE_URL intentionally includes /v1 for the OpenAI-compatible
    -- endpoints. Administrative endpoints live at the server root, so derive
    -- that root without introducing a second hostname configuration value.
    function f_gateway_root return varchar2 is
    begin
        return regexp_replace(f_config('GATEWAY_BASE_URL'), '/v1/?$', '');
    end f_gateway_root;

    -- The only gateway paths the demo app is allowed to read. Anything
    -- else (including any write endpoint) is rejected before an HTTP call
    -- is made, so a page bug can never turn the admin credential into a
    -- general-purpose proxy.
    function f_is_allowed_path(p_path in varchar2) return boolean is
    begin
        return p_path in (
                   '/admin/metrics/summary',
                   '/admin/metrics/models',
                   '/admin/metrics/backends',
                   '/admin/metrics/daily',
                   '/admin/routes',
                   '/health',
                   '/ready'
               )
            or regexp_like(p_path, '^/admin/requests\?limit=(100|500)&offset=[0-9]+$');
    end f_is_allowed_path;

    -- Single GET against the gateway root. Raises on a non-200 status.
    function f_fetch(
        p_path  in varchar2,
        p_admin in boolean
    ) return clob is
        v_response clob;
    begin
        if not f_is_allowed_path(p_path) then
            raise_application_error(-20061, 'Unsupported demo proxy path.');
        end if;

        apex_web_service.g_request_headers.delete;
        if p_admin then
            v_response := apex_web_service.make_rest_request(
                p_url                  => f_gateway_root || p_path,
                p_http_method          => 'GET',
                p_credential_static_id => f_config('ADMIN_CREDENTIAL_STATIC_ID'),
                p_transfer_timeout     => to_number(f_config('HTTP_TIMEOUT_SECONDS'))
            );
        else
            v_response := apex_web_service.make_rest_request(
                p_url              => f_gateway_root || p_path,
                p_http_method      => 'GET',
                p_transfer_timeout => to_number(f_config('HTTP_TIMEOUT_SECONDS'))
            );
        end if;

        if apex_web_service.g_status_code != 200 then
            raise_application_error(
                -20062,
                'Gateway returned HTTP ' || apex_web_service.g_status_code
            );
        end if;
        return v_response;
    end f_fetch;

    -- Formatting helpers for the rendered regions. NULL means "the
    -- gateway does not know" (unknown pricing, no requests yet) and must
    -- show as n/a, never as 0 -- spec section 29.
    function f_num(p_value in number, p_decimals in pls_integer default 0) return varchar2 is
    begin
        if p_value is null then
            return 'n/a';
        end if;
        return to_char(
                   p_value,
                   case when p_decimals = 0 then 'FM999G999G999G990'
                        else 'FM999G999G999G990D' || rpad('0', p_decimals, '0') end,
                   c_nls
               );
    end f_num;

    function f_usd(p_value in number) return varchar2 is
    begin
        return case when p_value is null then 'n/a' else '$' || f_num(p_value, 6) end;
    end f_usd;

    function f_pct(p_rate in number) return varchar2 is
    begin
        return case when p_rate is null then 'n/a' else f_num(p_rate * 100, 1) || '%' end;
    end f_pct;

    function f_esc(p_value in varchar2) return varchar2 is
    begin
        return apex_escape.html(nvl(p_value, 'n/a'));
    end f_esc;

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
            p_url                  => f_gateway_root || '/admin/requests?limit=20&offset=0',
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
                    v_result.selected_tier           := v_row.get_string('selected_target');
                    v_result.selected_model          := v_row.get_string('selected_model');
                    v_result.upstream_model          := v_row.get_string('upstream_model');
                    v_result.input_tokens            := v_row.get_number('input_tokens');
                    v_result.output_tokens           := v_row.get_number('output_tokens');
                    v_result.estimated_cost          := v_row.get_number('estimated_cost');
                    v_result.estimated_baseline_cost := v_row.get_number('estimated_baseline_cost');
                    v_result.estimated_savings       := v_row.get_number('estimated_savings');
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
        apex_json.write('upstream_model', v_result.upstream_model);
        -- Tier of the backend that answered, resolved against /admin/routes
        -- so the page never hard-codes a model id: 'efficient' | 'capable'
        -- | null (unknown model, or the request failed before any backend).
        apex_json.write('answered_tier',
            case v_result.upstream_model
                when tier_model('efficient') then 'efficient'
                when tier_model('capable')   then 'capable'
            end);
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

    procedure ajax_proxy(
        p_path  in varchar2,
        p_admin in boolean default true
    ) is
        v_response clob;
        v_offset   pls_integer := 1;
        v_chunk    varchar2(32000);
    begin
        v_response := f_fetch(p_path, p_admin);

        while v_offset <= dbms_lob.getlength(v_response) loop
            v_chunk := dbms_lob.substr(v_response, 32000, v_offset);
            sys.htp.prn(v_chunk);
            v_offset := v_offset + length(v_chunk);
        end loop;
    exception
        when others then
            apex_json.open_object;
            apex_json.write('success', false);
            apex_json.write('error', 'Gateway data is temporarily unavailable.');
            apex_json.close_object;
    end ajax_proxy;

    procedure ajax_config is
    begin
        apex_json.open_object;
        apex_json.write('success', true);
        apex_json.write('gateway_base_url', f_config('GATEWAY_BASE_URL'));
        apex_json.close_object;
    exception
        when others then
            apex_json.open_object;
            apex_json.write('success', false);
            apex_json.write('error', 'Gateway configuration is temporarily unavailable.');
            apex_json.close_object;
    end ajax_config;

    function gateway_json(p_path in varchar2) return clob is
    begin
        if not g_json_cache.exists(p_path) then
            begin
                g_json_cache(p_path) := f_fetch(
                    p_path,
                    p_admin => p_path not in ('/health', '/ready')
                );
            exception
                when others then
                    -- Cache the failure too, so one unreachable gateway
                    -- costs one timeout per page view, not one per region.
                    g_json_cache(p_path) := null;
                    g_last_error := substr(sqlerrm, 1, 4000);
            end;
        end if;
        return g_json_cache(p_path);
    end gateway_json;

    function last_gateway_error return varchar2 is
    begin
        return g_last_error;
    end last_gateway_error;

    function tier_model(p_tier in varchar2) return varchar2 is
        v_routes clob := gateway_json('/admin/routes');
        v_obj    json_object_t;
    begin
        if v_routes is null or lower(p_tier) not in ('efficient', 'capable') then
            return null;
        end if;
        v_obj := json_object_t(v_routes);
        return v_obj.get_object('targets')
                    .get_object(v_obj.get_object('routes').get_object('apex-auto')
                                     .get_string(lower(p_tier) || '_target'))
                    .get_string('model');
    exception
        when others then
            -- No apex-auto route, or a target name that does not exist:
            -- the caller falls back to a neutral label.
            return null;
    end tier_model;

    -- Health/readiness pills plus the routing strategy of every virtual
    -- model, read from the gateway itself (never from a hard-coded list).
    procedure render_gateway_status is
        v_health  clob := gateway_json('/health');
        v_ready   clob := gateway_json('/ready');
        v_routes  clob := gateway_json('/admin/routes');
        v_status  varchar2(64) := 'unreachable';
        v_rstatus varchar2(64) := 'unreachable';
        v_routes_obj json_object_t;
        v_route   json_object_t;
        v_keys    json_key_list;
        v_html    clob;

        function pill(p_id in varchar2, p_label in varchar2, p_value in varchar2, p_ok in boolean) return varchar2 is
        begin
            return '<span class="air-pill ' || case when p_ok then 'air-pill--ok' else 'air-pill--bad' end || '">'
                || '<span class="air-pill-label">' || f_esc(p_label) || '</span> '
                || '<span id="' || p_id || '">' || f_esc(p_value) || '</span></span>';
        end pill;
    begin
        if v_health is not null then
            v_status := json_object_t(v_health).get_string('status');
        end if;
        if v_ready is not null then
            v_rstatus := json_object_t(v_ready).get_string('status');
        end if;

        v_html := '<div class="air-status">'
               || pill('air-health', 'Gateway health', v_status, v_status = 'ok')
               || pill('air-ready', 'Readiness', v_rstatus, v_rstatus = 'ready')
               || '<span class="air-status-url"><span class="air-pill-label">API base</span> '
               || '<span id="air-gateway-base">' || f_esc(f_config('GATEWAY_BASE_URL')) || '</span></span>';

        if v_routes is not null then
            v_routes_obj := json_object_t(v_routes).get_object('routes');
            v_keys := v_routes_obj.get_keys;
            v_html := v_html || '<ul class="air-routes">';
            for i in 1 .. v_keys.count loop
                v_route := v_routes_obj.get_object(v_keys(i));
                v_html := v_html || '<li><code>' || f_esc(v_keys(i)) || '</code> &rarr; ';
                if v_route.get_string('strategy') = 'llm_classifier' then
                    v_html := v_html
                        || 'NVIDIA NeMo Switchyard sidecar (<code>llm_classifier</code>, judge target <code>'
                        || f_esc(v_route.get_string('judge_target')) || '</code>, threshold '
                        || f_esc(to_char(v_route.get_number('threshold'), 'FM990D00', c_nls))
                        || ') picks <code>' || f_esc(v_route.get_string('efficient_target'))
                        || '</code> or <code>' || f_esc(v_route.get_string('capable_target')) || '</code>';
                else
                    v_html := v_html || 'fixed target <code>' || f_esc(v_route.get_string('target')) || '</code>';
                end if;
                v_html := v_html || '</li>';
            end loop;
            v_html := v_html || '</ul>';
        end if;

        if g_last_error is not null then
            v_html := v_html || '<p class="air-error">' || f_esc(g_last_error) || '</p>';
        end if;
        v_html := v_html || '</div>';
        sys.htp.p(v_html);
    end render_gateway_status;

    -- KPI tiles over /admin/metrics/summary plus the apex-auto split
    -- taken from /admin/metrics/backends (the backend the sidecar
    -- actually called, per gateway telemetry -- not the configured
    -- route target).
    procedure render_kpis is
        v_summary   clob := gateway_json('/admin/metrics/summary');
        v_backends  clob := gateway_json('/admin/metrics/backends');
        v_sum       json_object_t;
        v_arr       json_array_t;
        v_row       json_object_t;
        v_efficient_model varchar2(128);
        v_auto_total    number := 0;
        v_auto_efficient number := 0;
        v_requests  number;
        v_split     varchar2(200) := 'n/a';
        v_split_hint varchar2(400) := 'No apex-auto request recorded yet.';

        function tile(p_label in varchar2, p_value in varchar2, p_hint in varchar2, p_icon in varchar2)
            return varchar2 is
        begin
            return '<div class="air-tile"><span class="air-tile-icon fa ' || p_icon || '" aria-hidden="true"></span>'
                || '<span class="air-tile-label">' || f_esc(p_label) || '</span>'
                || '<span class="air-tile-value">' || f_esc(p_value) || '</span>'
                || '<span class="air-tile-hint">' || f_esc(p_hint) || '</span></div>';
        end tile;
    begin
        if v_summary is null then
            sys.htp.p('<p class="air-error">Metrics are unavailable: '
                      || f_esc(nvl(g_last_error, 'gateway did not answer')) || '</p>');
            return;
        end if;
        v_sum := json_object_t(v_summary);
        v_requests := v_sum.get_number('requests');

        -- Which model id is the "efficient" one is read from the routing
        -- config, so the tile stays correct when real model ids replace
        -- the mocks.
        v_efficient_model := tier_model('efficient');

        if v_backends is not null then
            v_arr := json_object_t(v_backends).get_array('backends');
            for i in 0 .. v_arr.get_size - 1 loop
                v_row := treat(v_arr.get(i) as json_object_t);
                if v_row.get_string('route') = 'apex-auto' and v_row.get_string('upstream_model') is not null then
                    v_auto_total := v_auto_total + v_row.get_number('requests');
                    if v_row.get_string('upstream_model') = v_efficient_model then
                        v_auto_efficient := v_auto_efficient + v_row.get_number('requests');
                    end if;
                end if;
            end loop;
        end if;
        if v_auto_total > 0 then
            v_split := f_num(v_auto_efficient) || ' of ' || f_num(v_auto_total)
                    || ' (' || f_pct(v_auto_efficient / v_auto_total) || ')';
            v_split_hint := 'apex-auto requests the NeMo Switchyard sidecar sent to '
                         || nvl(v_efficient_model, 'the efficient model')
                         || ' (gateway telemetry: upstream_model)';
        end if;

        sys.htp.p('<div class="air-tiles">'
            || tile('Requests', case when v_requests = 0 then 'n/a' else f_num(v_requests) end,
                    'all routes, all time', 'fa-paper-plane')
            || tile('Success rate', case when v_requests = 0 then 'n/a' else f_pct(v_sum.get_number('success_rate')) end,
                    'HTTP 200 responses', 'fa-check-circle')
            || tile('Estimated cost', case when v_requests = 0 then 'n/a' else f_usd(v_sum.get_number('estimated_cost')) end,
                    'from config/pricing.yaml, USD', 'fa-calculator')
            || tile('Estimated capable-model baseline',
                    case when v_requests = 0 then 'n/a' else f_usd(v_sum.get_number('estimated_capable_baseline_cost')) end,
                    'if every apex-auto request had used the capable model', 'fa-balance-scale')
            || tile('Estimated savings', case when v_requests = 0 then 'n/a' else f_usd(v_sum.get_number('estimated_savings')) end,
                    'baseline minus estimated cost (estimate, not billing)', 'fa-line-chart')
            || tile('Auto requests answered by the efficient model', v_split, v_split_hint, 'fa-random')
            || '</div>');
    end render_kpis;

    -- Route x backend table over /admin/metrics/backends.
    procedure render_backends_table is
        v_backends clob := gateway_json('/admin/metrics/backends');
        v_arr      json_array_t;
        v_row      json_object_t;
    begin
        if v_backends is null then
            sys.htp.p('<p class="air-error">Backend breakdown is unavailable.</p>');
            return;
        end if;
        v_arr := json_object_t(v_backends).get_array('backends');
        if v_arr.get_size = 0 then
            sys.htp.p('<p class="air-muted">No requests recorded yet. Send a prompt from the Playground first.</p>');
            return;
        end if;

        sys.htp.p('<div class="t-Report t-Report--altRowsDefault t-Report--rowHighlight"><div class="t-Report-wrap">'
            || '<table class="t-Report-report" summary="Backend called per route">'
            || '<thead><tr><th class="t-Report-colHead">Route</th><th class="t-Report-colHead">Backend that answered</th>'
            || '<th class="t-Report-colHead u-tR">Requests</th><th class="t-Report-colHead u-tR">Success rate</th>'
            || '<th class="t-Report-colHead u-tR">Input tokens</th><th class="t-Report-colHead u-tR">Output tokens</th>'
            || '<th class="t-Report-colHead u-tR">Estimated cost</th></tr></thead><tbody>');
        for i in 0 .. v_arr.get_size - 1 loop
            v_row := treat(v_arr.get(i) as json_object_t);
            sys.htp.p('<tr><td class="t-Report-cell"><code>' || f_esc(v_row.get_string('route')) || '</code></td>'
                || '<td class="t-Report-cell">'
                || case when v_row.get_string('upstream_model') is null
                        then '<span class="air-badge air-badge--none">none (request failed)</span>'
                        else '<span class="air-badge">' || f_esc(v_row.get_string('upstream_model')) || '</span>' end
                || '</td>'
                || '<td class="t-Report-cell u-tR">' || f_num(v_row.get_number('requests')) || '</td>'
                || '<td class="t-Report-cell u-tR">' || f_pct(v_row.get_number('success_rate')) || '</td>'
                || '<td class="t-Report-cell u-tR">' || f_num(v_row.get_number('input_tokens')) || '</td>'
                || '<td class="t-Report-cell u-tR">' || f_num(v_row.get_number('output_tokens')) || '</td>'
                || '<td class="t-Report-cell u-tR">' || f_usd(v_row.get_number('estimated_cost')) || '</td></tr>');
        end loop;
        sys.htp.p('</tbody></table></div></div>');
    end render_backends_table;

end apex_ai_router_demo;
/
