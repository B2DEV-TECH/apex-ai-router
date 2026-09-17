create or replace package body apex_ai_router_da as

    -- Emits the client-side binding for this Dynamic Action's action. Uses
    -- the plug-in framework's declarative javascript_function hook: APEX
    -- calls the named JS function whenever the action fires, passing it a
    -- "pThis" object exposing the resolved attribute values (as
    -- pThis.action.attribute01, .attribute02, etc. -- camelCase, two
    -- digits, per the APEX Dynamic Action plug-in JavaScript API) and the
    -- triggering element. See apex-plugin/static/apex_ai_router_generate.js
    -- for the function itself.
    --
    -- Confidence note (see HANDOFF.md): the attribute_NN server-side
    -- record fields and the render()/ajax() function signatures below are
    -- the stable, decade-old APEX_PLUGIN framework contract and are used
    -- with high confidence. The exact shape of "pThis" on the JavaScript
    -- side is documented in the APEX Plug-In Developer's Guide's Dynamic
    -- Action chapter for the installed APEX version -- confirm it there
    -- before relying on this in production, since that specific JS-facing
    -- contract is the one part of this plug-in not independently
    -- re-verified against a live APEX instance while building it here.
    function render(
        p_dynamic_action in apex_plugin.t_dynamic_action,
        p_plugin         in apex_plugin.t_plugin
    ) return apex_plugin.t_dynamic_action_render_result is
        l_result apex_plugin.t_dynamic_action_render_result;
    begin
        l_result.javascript_function := 'apexAiRouter.generate';
        return l_result;
    end render;

    function ajax(
        p_dynamic_action in apex_plugin.t_dynamic_action,
        p_plugin         in apex_plugin.t_plugin
    ) return apex_plugin.t_dynamic_action_ajax_result is
        l_result      apex_plugin.t_dynamic_action_ajax_result;
        v_prompt      clob    := apex_application.g_x01;
        v_route       varchar2(30) := nvl(apex_application.g_x02, apex_ai_router.c_route_auto);
        v_temperature number;
        v_session_id  varchar2(255) := nullif(apex_application.g_x04, '');
        v_answer      clob;
    begin
        if apex_application.g_x03 is not null and apex_application.g_x03 != '' then
            v_temperature := to_number(apex_application.g_x03);
        end if;

        v_answer := apex_ai_router.generate(
            p_prompt      => v_prompt,
            p_route       => v_route,
            p_session_id  => v_session_id,
            p_temperature => v_temperature
        );

        apex_json.open_object;
        apex_json.write('success', true);
        apex_json.write('result', v_answer);
        apex_json.close_object;

        return l_result;
    exception
        when apex_ai_router.e_unknown_route
          or apex_ai_router.e_gateway_error
          or apex_ai_router.e_missing_config then
            apex_json.open_object;
            apex_json.write('success', false);
            apex_json.write('error', sqlerrm);
            apex_json.close_object;
            return l_result;
        when others then
            -- Never let a raw, potentially provider-shaped exception reach
            -- the browser -- mirrors the gateway's own sanitized-error
            -- policy (spec section 22, gateway/README.md security section).
            apex_json.open_object;
            apex_json.write('success', false);
            apex_json.write('error', 'APEX AI Router plug-in call failed. Check AIR_REQUEST_LOG / the gateway logs.');
            apex_json.close_object;
            return l_result;
    end ajax;

end apex_ai_router_da;
/
