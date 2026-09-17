# dist

`dynamic_action_plugin_air_dynamic_action_generate.sql` is the
distributable export produced by APEX Builder 26.1. It was imported into a
second application and verified to contain the render and Ajax callbacks,
client file, and all eight component attributes.

Compile `../sql/install_plugin_package.sql` in the parsing schema first,
then import the component SQL through APEX Builder. Local workspace,
instance, schema, and exporter identifiers were neutralized in the file;
Builder or `apex_application_install` supplies the target values at import
time. Re-export from the target APEX version if its plug-in metadata format
has changed.
