-- AIR_DAILY_USAGE_V: request counts by calendar day, from the
-- application-context log only.

create or replace view air_daily_usage_v as
select
    trunc(request_timestamp)                            as usage_date,
    route,
    count(*)                                            as request_count,
    sum(case when success_yn = 'Y' then 1 else 0 end)   as success_count,
    round(avg(duration_ms), 1)                           as avg_duration_ms
from air_request_log
group by trunc(request_timestamp), route
order by 1 desc, 2;

comment on table air_daily_usage_v is 'Per-day, per-route request counts from AIR_REQUEST_LOG.';
