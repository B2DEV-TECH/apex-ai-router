-- AIR_REQUEST_LOG: application-context log for calls made through the
-- APEX_AI_ROUTER package.
--
-- This intentionally does NOT duplicate the gateway's own telemetry store
-- (gateway/src/apex_ai_router/telemetry/store.py) -- that already records
-- routing/provider/cost detail per request. This table only records what
-- the gateway telemetry cannot know: which APEX application, page, and
-- session made the call. It is a loose, best-effort correlation (by
-- timestamp, route, and the gateway's own response id), not a foreign key
-- into the gateway's SQLite database, which is a separate system.
--
-- Prompt and response content are never stored here, matching the
-- gateway-side default (spec section 13 / 22): this table is for
-- operational visibility inside the APEX application, not a content audit
-- trail.

create table air_request_log (
    id                 number
        generated always as identity
        primary key,
    app_id             number,
    page_id            number,
    session_id         varchar2(255),
    route              varchar2(30)   not null,
    gateway_response_id varchar2(255),
    http_status        number(5),
    success_yn         char(1)        not null,
    error_code         varchar2(128),
    error_message      varchar2(4000),
    duration_ms        number,
    request_timestamp  timestamp with time zone default systimestamp not null,
    constraint air_request_log_success_yn_chk check (success_yn in ('Y', 'N'))
);

create index air_request_log_ts_idx on air_request_log (request_timestamp);
create index air_request_log_app_idx on air_request_log (app_id, page_id);

comment on table air_request_log is 'APEX application-context log for APEX_AI_ROUTER package calls. Does not duplicate gateway telemetry and never stores prompt/response content.';
comment on column air_request_log.route is 'Requested route as passed to the package (AUTO, EFFICIENT, CAPABLE), not the gateway virtual-model id.';
comment on column air_request_log.gateway_response_id is 'The "id" field from the gateway''s OpenAI-shaped response body, if the call succeeded. For loose correlation only.';
comment on column air_request_log.error_message is 'The gateway''s own sanitized error message when the call failed. Never contains the prompt, the response, or any credential.';
