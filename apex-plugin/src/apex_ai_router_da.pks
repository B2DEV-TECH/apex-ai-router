create or replace package apex_ai_router_da authid definer as
/*
    APEX AI Router - Generate -- Dynamic Action plug-in callbacks
    (spec sections 18-19).

    This package holds the two functions an APEX Dynamic Action plug-in of
    type "Dynamic Action" registers in Shared Components > Plug-ins:
    render() as the "PL/SQL Code" render function, ajax() as the "Ajax
    Callback" function. It is not, itself, the plug-in -- the plug-in
    metadata (name, category, attributes, events) must still be created in
    APEX Builder; see apex-plugin/README.md for the exact steps and
    attribute mapping, and why the machine-generated export SQL under
    apex-plugin/dist/ cannot be produced without a live APEX Builder.

    Flow (browser never calls an upstream AI provider directly):
      browser (apex.server.plugin) -> ajax() below -> apex_ai_router.generate()
      -> gateway -> Switchyard -> model -> gateway -> ajax() -> browser.

    Attribute mapping (see apex-plugin/README.md for the Builder-side
    definitions of each):
      attribute_01  Prompt Source Type   (STATIC / ITEM / JS_EXPRESSION)
      attribute_02  Prompt Source Value  (literal text / item name / JS expr)
      attribute_03  Route                (AUTO / EFFICIENT / CAPABLE)
      attribute_04  Result Page Item     (item name, optional)
      attribute_05  Temperature          (optional, numeric string)
      attribute_06  Session ID Page Item (item name, optional)
      attribute_07  Show Processing Indicator (Y/N)
      attribute_08  Error Page Item      (item name, optional)

    attribute_01/02/06/08 only affect the *client-side* JS
    (apex-plugin/static/apex_ai_router_generate.js), which resolves the
    prompt and session id before calling the ajax callback -- this package
    only ever sees the already-resolved values, passed as x01..x04 (see
    ajax() below), so it never needs to evaluate a JavaScript expression or
    read an arbitrary page item itself.
*/

    function render(
        p_dynamic_action in apex_plugin.t_dynamic_action,
        p_plugin         in apex_plugin.t_plugin
    ) return apex_plugin.t_dynamic_action_render_result;

    -- Reads the browser-resolved prompt/route/temperature/session id from
    -- apex_application.g_x01..g_x04 (set by apex-plugin/static's
    -- apex.server.plugin() call), calls apex_ai_router.generate(), and
    -- writes a JSON body: {"success":true,"result":"..."} or
    -- {"success":false,"error":"..."}. Always HTTP 200 -- errors are
    -- reported in the JSON body, not via an uncaught exception, so the
    -- browser side has one controlled shape to branch on either way.
    function ajax(
        p_dynamic_action in apex_plugin.t_dynamic_action,
        p_plugin         in apex_plugin.t_plugin
    ) return apex_plugin.t_dynamic_action_ajax_result;

end apex_ai_router_da;
/
