-- AIR_CONFIG: non-secret configuration for the APEX_AI_ROUTER package.
--
-- Never store credential *values* here. p_credential_static_id below is a
-- reference to a Web Credential defined in Shared Components > Web
-- Credentials (or, outside APEX, in the wallet/credential store your
-- environment uses) -- the package looks the credential up by name at call
-- time, it never reads or stores the secret itself.

create table air_config (
    config_key   varchar2(128)  not null,
    config_value varchar2(4000),
    description  varchar2(4000),
    updated_at   timestamp with time zone default systimestamp not null,
    constraint air_config_pk primary key (config_key)
);

comment on table air_config is 'Non-secret configuration for the APEX_AI_ROUTER package (gateway base URL, timeouts, credential reference). No secret values.';
comment on column air_config.config_key is 'Upper-case key, e.g. GATEWAY_BASE_URL, HTTP_TIMEOUT_SECONDS, CREDENTIAL_STATIC_ID.';
comment on column air_config.config_value is 'Non-secret value. For CREDENTIAL_STATIC_ID this is the *name* of a Web Credential, never the credential itself.';
