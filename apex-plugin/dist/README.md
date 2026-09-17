# dist

This is where the plug-in's distributable, machine-generated export SQL
(a `p####_plugin_....sql` file produced by APEX Builder's own
Shared Components > Plug-ins > **Export** action) belongs once the plug-in
has been built in a real APEX Builder instance.

That file was **not** generated for this repository: it requires a live
APEX Builder to create the plug-in (name, category, attributes, events)
against `apex-plugin/src/apex_ai_router_da.pks/.pkb` and
`apex-plugin/static/apex_ai_router_generate.js`, and no Oracle/APEX
instance was available while building this project (see the root
`HANDOFF.md` and `database/README.md` for the same caveat on the Phase 5
database objects). APEX's plug-in export format embeds internal sequence
IDs and gzip+base64-encoded file content produced by
`wwv_flow_api.create_plugin`/`create_plugin_file` -- hand-writing one
without a live export to verify against risks producing a file that fails
to import or, worse, imports incorrectly, so none is committed here.

To produce it yourself, follow `apex-plugin/README.md`'s "Building the
plug-in in APEX Builder" section, then use **Export** from the plug-in's
page in Shared Components, and commit the resulting file here.
