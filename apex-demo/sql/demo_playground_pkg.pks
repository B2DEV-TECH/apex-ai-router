create or replace package apex_ai_router_demo authid definer as
/*
    Support package for the demo app's Page 1 - Playground (spec section
    20). Not part of the reusable product (database/, apex-plugin/) -- this
    package exists only because the Playground needs richer, per-request
    detail (selected tier/model, latency, tokens, estimated cost/baseline/
    savings) than the reusable APEX_AI_ROUTER package's generate()/chat()
    return (response text only, by design -- see database/README.md).

    To get that detail, run_playground() makes its OWN two direct HTTP
    calls instead of going through apex_ai_router.generate():
      1. POST /v1/chat/completions with the INFERENCE Web Credential --
         captures the X-Request-Id response header.
      2. GET /admin/requests?limit=1&offset=0 with a separate, read-only
         ADMIN Web Credential -- matches the row whose request_id equals
         the X-Request-Id captured above, to read the cost/token/latency
         fields the gateway only exposes through the admin API (spec
         section 15), never in the OpenAI-compatible response body itself
         (verified by reading gateway/src/apex_ai_router/api/openai_chat.py
         and telemetry/store.py: the chat-completions response returns only
         id/object/created/model/choices/usage -- no cost fields -- and
         /admin/requests has no request_id filter, so an exact-match lookup
         by X-Request-Id is the only correct correlation, not
         AIR_REQUEST_LOG.gateway_response_id, which is the *OpenAI* response
         id and does not appear anywhere in the gateway's own telemetry
         rows; see HANDOFF.md).

    This means the demo app's Playground page process holds a read-only
    ADMIN gateway credential server-side (never sent to the browser). That
    is an appropriate, explicit trade-off for a reference/demo application
    whose purpose is to showcase routing and cost data -- it is NOT a
    pattern to copy into an arbitrary production page without the same
    justification (most production pages have no reason to hold an admin
    credential at all). See apex-demo/README.md.

    Validated on Oracle Database 23ai Free and APEX 26.1 against the local
    mock gateway; see HANDOFF.md for the remaining production limitations.
*/

    type t_playground_result is record (
        response             clob,
        selected_tier        varchar2(64),
        selected_model       varchar2(128),
        latency_ms           number,
        input_tokens         number,
        output_tokens        number,
        estimated_cost       number,
        estimated_baseline_cost number,
        estimated_savings    number,
        request_id           varchar2(255)
    );

    function run_playground(
        p_prompt in clob,
        p_route  in varchar2 default apex_ai_router.c_route_auto
    ) return t_playground_result;

    -- On-Demand: Ajax Callback process for apex-demo Page 1 (Playground).
    -- Reads apex_application.g_x01 (prompt) / g_x02 (route), calls
    -- run_playground(), writes the result as JSON
    -- ({"success":true,...fields...} or {"success":false,"error":...}) via
    -- apex_json -- same controlled-error convention as
    -- apex-plugin/src/apex_ai_router_da.pkb's ajax(), so a gateway or
    -- config failure never reaches the browser as a raw error page.
    procedure ajax_run;

    -- Server-side proxy used by the Dashboard, Request History, and
    -- Configuration Help pages. Only the documented read-only gateway
    -- endpoints are allowed; credentials never leave the APEX session.
    procedure ajax_proxy(
        p_path  in varchar2,
        p_admin in boolean default true
    );

    -- Page callback wrappers. Request history validates and normalizes the
    -- requested offset before constructing the allowlisted gateway path;
    -- config returns only the non-secret gateway base URL.
    procedure ajax_requests;
    procedure ajax_config;

end apex_ai_router_demo;
/
