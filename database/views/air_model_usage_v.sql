-- AIR_MODEL_USAGE_V: request counts and latency by route, from the
-- application-context log only (no cost/token data -- that lives in the
-- gateway's own telemetry store; see database/README.md).

create or replace view air_model_usage_v as
select
    route,
    count(*)                                            as request_count,
    sum(case when success_yn = 'Y' then 1 else 0 end)   as success_count,
    round(
        sum(case when success_yn = 'Y' then 1 else 0 end) / count(*),
        4
    )                                                    as success_rate,
    round(avg(duration_ms), 1)                           as avg_duration_ms,
    max(request_timestamp)                               as last_request_at
from air_request_log
group by route;

comment on table air_model_usage_v is 'Per-route request counts and latency from AIR_REQUEST_LOG. Not a source of cost data -- see the gateway admin API for that.';
