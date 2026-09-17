create or replace package apex_ai_router_demo authid definer as
/*
    Support package for the demo app (spec section 20). Not part of the
    reusable product (database/, apex-plugin/) -- this package exists only
    because the demo pages need richer, per-request and aggregate detail
    (selected tier/model, the backend that actually answered, latency,
    tokens, estimated cost/baseline/savings) than the reusable
    APEX_AI_ROUTER package's generate()/chat() return (response text only,
    by design -- see database/README.md).

    To get that detail, run_playground() makes its OWN two direct HTTP
    calls instead of going through apex_ai_router.generate():
      1. POST /v1/chat/completions with the INFERENCE Web Credential --
         captures the X-Request-Id response header.
      2. GET /admin/requests?limit=20&offset=0 with a separate, read-only
         ADMIN Web Credential -- matches the row whose request_id equals
         the X-Request-Id captured above, to read the cost/token/latency
         fields and the `upstream_model` (for apex-auto: the efficient or
         capable backend the NeMo Switchyard sidecar actually called) that
         the gateway only exposes through the admin API (spec section 15),
         never in the OpenAI-compatible response body itself (verified by
         reading gateway/src/apex_ai_router/api/openai_chat.py and
         telemetry/store.py: the chat-completions response returns only
         id/object/created/model/choices/usage -- no cost fields -- and
         /admin/requests has no request_id filter, so an exact-match lookup
         by X-Request-Id is the only correct correlation, not
         AIR_REQUEST_LOG.gateway_response_id, which is the *OpenAI* response
         id and does not appear anywhere in the gateway's own telemetry
         rows; see HANDOFF.md).

    This means the demo app's server-side processes hold a read-only
    ADMIN gateway credential (never sent to the browser). That is an
    appropriate, explicit trade-off for a reference/demo application
    whose purpose is to showcase routing and cost data -- it is NOT a
    pattern to copy into an arbitrary production page without the same
    justification (most production pages have no reason to hold an admin
    credential at all). See apex-demo/README.md.

    Validated on Oracle Database 26ai Free and APEX 26.1 against the local
    gateway, the mock model providers and a real switchyard-server
    sidecar; see HANDOFF.md for the remaining production limitations.
*/

    type t_playground_result is record (
        response                clob,
        selected_tier           varchar2(64),
        selected_model          varchar2(128),
        -- Model id the upstream reported. For apex-auto this is the
        -- backend the Switchyard sidecar picked (efficient or capable);
        -- for a fixed route it equals selected_model.
        upstream_model          varchar2(128),
        latency_ms              number,
        input_tokens            number,
        output_tokens           number,
        estimated_cost          number,
        estimated_baseline_cost number,
        estimated_savings       number,
        request_id              varchar2(255)
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

    -- Server-side proxy used by the Configuration Help page. Only the
    -- documented read-only gateway endpoints are allowed; credentials
    -- never leave the APEX session.
    procedure ajax_proxy(
        p_path  in varchar2,
        p_admin in boolean default true
    );

    -- Page callback wrapper: returns only the non-secret gateway base URL.
    procedure ajax_config;

    -- Read-only gateway JSON for use as a SQL source through json_table()
    -- (Dashboard charts, Request History Interactive Report). Same
    -- allowlist as ajax_proxy. Cached per page request so several regions
    -- on one page share a single gateway call. Returns NULL (so the
    -- region renders "No data found" rather than an error page) when the
    -- gateway cannot be reached; the reason is kept in last_gateway_error
    -- for the Dashboard's status region. Never returns prompt/response
    -- content: the admin API does not expose it.
    function gateway_json(p_path in varchar2) return clob;
    function last_gateway_error return varchar2;

    -- Model id configured for the apex-auto route's 'efficient' or
    -- 'capable' target, read from /admin/routes (NULL when unknown). Lets
    -- the pages label a backend by tier without hard-coding model ids.
    function tier_model(p_tier in varchar2) return varchar2;

    -- PL/SQL Dynamic Content regions of Page 2 (Dashboard). All values
    -- are HTML-escaped; numbers are rendered as "n/a" when the gateway
    -- reports null, never as zero.
    procedure render_gateway_status;
    procedure render_kpis;
    procedure render_backends_table;

end apex_ai_router_demo;
/
