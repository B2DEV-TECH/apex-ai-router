create or replace package apex_ai_router authid definer as
/*
    APEX AI Router -- PL/SQL client for the APEX AI Router gateway
    (spec section 16).

    Calls the gateway's OpenAI-compatible POST /v1/chat/completions over
    HTTPS using APEX_WEB_SERVICE.MAKE_REST_REQUEST with a Web Credential
    (p_credential_static_id): the gateway API key is stored in Shared
    Components > Web Credentials, never read or stored by this package.
    See database/README.md for the required AIR_CONFIG rows and the Web
    Credential setup.

    generate() and chat() both return the assistant's response text (the
    parsed "choices[0].message.content" field), not the raw gateway JSON
    body -- this is a design decision made when implementing this package,
    not something the product spec itself mandates; see HANDOFF.md if a
    raw-JSON variant turns out to be more useful.

    p_route accepts AUTO, EFFICIENT, or CAPABLE (case-insensitive),
    mapped internally to the gateway's apex-auto / apex-efficient /
    apex-capable virtual models -- callers never need to know that
    naming convention.

    Untested against a live Oracle/APEX instance in this repository as of
    this writing (see database/README.md); the JSON and HTTP APIs used
    (JSON_OBJECT_T / JSON_ARRAY_T, APEX_WEB_SERVICE.MAKE_REST_REQUEST with
    p_credential_static_id and g_request_headers) are real, documented
    Oracle/APEX APIs, hand-verified against their published signatures,
    but the package has not been compiled or run end to end here.
*/

    c_route_auto      constant varchar2(10) := 'AUTO';
    c_route_efficient constant varchar2(10) := 'EFFICIENT';
    c_route_capable   constant varchar2(10) := 'CAPABLE';

    -- Reserved application error range for this package: -20050 .. -20059.
    e_unknown_route  exception;
    pragma exception_init(e_unknown_route, -20050);
    e_gateway_error  exception;
    pragma exception_init(e_gateway_error, -20051);
    e_missing_config exception;
    pragma exception_init(e_missing_config, -20052);

    -- Sends a single user-turn prompt. p_temperature is forwarded to the
    -- gateway only when supplied (omitted from the request body otherwise,
    -- so the provider's own default applies).
    function generate(
        p_prompt      in clob,
        p_route       in varchar2 default c_route_auto,
        p_session_id  in varchar2 default null,
        p_temperature in number   default null
    ) return clob;

    -- Sends a full OpenAI-style messages array: a JSON array of
    -- {"role": "...", "content": "..."} objects, as a CLOB.
    function chat(
        p_messages_json in clob,
        p_route         in varchar2 default c_route_auto,
        p_session_id    in varchar2 default null
    ) return clob;

end apex_ai_router;
/
