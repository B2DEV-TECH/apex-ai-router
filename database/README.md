# database

Oracle database objects and the `APEX_AI_ROUTER` PL/SQL package (project
prefix `AIR_`). Not implemented yet — planned for Phase 5. See the root
spec sections 16-17 for the target design: `AIR_CONFIG`, `AIR_REQUEST_LOG`,
`AIR_MODEL_USAGE_V`, `AIR_DAILY_USAGE_V`, and
`apex_ai_router.generate(p_prompt, p_route, p_session_id, p_temperature)`.

`install.sql` / `uninstall.sql` will be added once the package is written
and tested against a real Oracle APEX instance; the exact APEX and Oracle
Database versions tested will be recorded here rather than assumed.
