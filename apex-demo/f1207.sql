prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.0'
,p_default_workspace_id=>0
,p_default_application_id=>1207
,p_default_id_offset=>16449096071893373
,p_default_owner=>'CHANGE_ME'
);
end;
/

prompt APPLICATION 1207 - APEX AI Router Demo
--
-- Application Export:
--   Application:     1207
--   Name:            APEX AI Router Demo
--   Date and Time:   10:54 Thursday September 17, 2026
--   Exported By:     REDACTED
--   Flashback:       0
--   Export Type:     Application Export
--     Pages:                      6
--       Items:                   16
--       Processes:               12
--       Regions:                  6
--       Buttons:                  5
--       Dynamic Actions:          3
--     Shared Components:
--       Logic:
--         Build Options:          1
--       Navigation:
--         Lists:                  2
--         Breadcrumbs:            1
--           Entries:              1
--       Security:
--         Authentication:         1
--         Authorization:          1
--       User Interface:
--         Themes:                 1
--         Templates:
--         LOVs:                   1
--         Plug-ins:               1
--       PWA:
--       Globalization:
--       Reports:
--       E-Mail:
--     Supporting Objects:  Included
--   Version:         26.1.0
--   Instance ID:     0
--

prompt --application/delete_application
begin
wwv_flow_imp.remove_flow(wwv_flow.g_flow_id);
end;
/
prompt --application/create_application
begin
wwv_imp_workspace.create_flow(
 p_id=>wwv_flow.g_flow_id
,p_owner=>nvl(wwv_flow_application_install.get_schema,'CHANGE_ME')
,p_name=>nvl(wwv_flow_application_install.get_application_name,'APEX AI Router Demo')
,p_alias=>nvl(wwv_flow_application_install.get_application_alias,'APEX-AI-ROUTER-DEMO-1207')
,p_page_view_logging=>'YES'
,p_page_protection_enabled_y_n=>'Y'
,p_checksum_salt=>'6301F1A152481778B2ABD023F7E03ED065D2B7367B1710A2E3B112D7A3D11816'
,p_bookmark_checksum_function=>'SH512'
,p_compatibility_mode=>'26.1'
,p_flow_language=>'en'
,p_flow_language_derived_from=>'FLOW_PRIMARY_LANGUAGE'
,p_allow_feedback_yn=>'Y'
,p_date_format=>'DS'
,p_timestamp_format=>'DS'
,p_timestamp_tz_format=>'DS'
,p_flow_image_prefix=>nvl(wwv_flow_application_install.get_image_prefix,'')
,p_authentication_id=>wwv_flow_imp.id(32860479883450368)
,p_application_tab_set=>0
,p_logo_type=>'T'
,p_logo_text=>'APEX AI Router Demo'
,p_proxy_server=>nvl(wwv_flow_application_install.get_proxy,'')
,p_no_proxy_domains=>nvl(wwv_flow_application_install.get_no_proxy_domains,'')
,p_flow_version=>'Release 1.0'
,p_flow_status=>'AVAILABLE_W_EDIT_LINK'
,p_browser_cache=>'N'
,p_browser_frame=>'D'
,p_authorize_batch_job=>'N'
,p_rejoin_existing_sessions=>'N'
,p_csv_encoding=>'Y'
,p_substitution_string_01=>'APP_NAME'
,p_substitution_value_01=>'APEX AI Router Demo'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_last_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_last_updated_by=>'AIR_ADMIN'
,p_file_prefix=>nvl(wwv_flow_application_install.get_static_app_file_prefix,'')
,p_files_version=>2461301094840
,p_version_scn=>'14470197'
,p_print_server_type=>'NATIVE'
,p_file_storage=>'DB'
,p_is_pwa=>'Y'
,p_pwa_is_installable=>'N'
,p_pwa_is_push_enabled=>'N'
,p_theme_id=>42
,p_home_url=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_login_url=>'f?p=&APP_ID.:LOGIN:&APP_SESSION.::&DEBUG.:::'
,p_theme_style_by_user_pref=>false
,p_built_with_love=>false
,p_global_page_id=>0
,p_navigation_list_id=>wwv_flow_imp.id(32861304509450374)
,p_navigation_list_position=>'SIDE'
,p_navigation_list_template_id=>2469215554099805162
,p_nav_list_template_options=>'#DEFAULT#:t-TreeNav--styleA:js-navCollapsed--hidden'
,p_nav_bar_type=>'LIST'
,p_nav_bar_list_id=>wwv_flow_imp.id(32862021839450408)
,p_nav_bar_list_template_id=>2849019392706229583
,p_nav_bar_template_options=>'#DEFAULT#'
);
end;
/
prompt --application/shared_components/plugins/dynamic_action/air_dynamic_action_generate
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(16450819125013396)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'AIR.DYNAMIC_ACTION.GENERATE'
,p_display_name=>'APEX AI Router - Generate'
,p_apexlang_name=>'apexAiRouterGenerate'
,p_category=>'EXECUTE'
,p_image_prefix=>nvl(wwv_flow_application_install.get_static_plugin_file_prefix('DYNAMIC ACTION','AIR.DYNAMIC_ACTION.GENERATE'),'')
,p_javascript_file_urls=>'#PLUGIN_FILES#apex_ai_router_generate.js'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'function render(',
'    p_dynamic_action in apex_plugin.t_dynamic_action,',
'    p_plugin         in apex_plugin.t_plugin',
') return apex_plugin.t_dynamic_action_render_result is',
'begin',
'    return apex_ai_router_da.render(p_dynamic_action, p_plugin);',
'end render;',
'',
'function ajax(',
'    p_dynamic_action in apex_plugin.t_dynamic_action,',
'    p_plugin         in apex_plugin.t_plugin',
') return apex_plugin.t_dynamic_action_ajax_result is',
'begin',
'    return apex_ai_router_da.ajax(p_dynamic_action, p_plugin);',
'end ajax;'))
,p_api_version=>1
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_substitute_attributes=>true
,p_help_text=>'Generate a response through the server-side APEX AI Router gateway integration.'
,p_version_identifier=>'1.0.0'
,p_files_version=>2461301104441
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(16450819125013406)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'attribute_01'
,p_prompt=>'Prompt Source Type'
,p_apexlang_name=>'promptSourceType'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'STATIC'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(16450819125013497)
,p_plugin_attribute_id=>wwv_flow_imp.id(16450819125013406)
,p_display_sequence=>30
,p_display_value=>'JavaScript Expression'
,p_return_value=>'JS_EXPRESSION'
,p_apexlang_name=>'javascriptExpression'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(16450819125013496)
,p_plugin_attribute_id=>wwv_flow_imp.id(16450819125013406)
,p_display_sequence=>20
,p_display_value=>'Page Item'
,p_return_value=>'ITEM'
,p_apexlang_name=>'pageItem'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(16450819125013495)
,p_plugin_attribute_id=>wwv_flow_imp.id(16450819125013406)
,p_display_sequence=>10
,p_display_value=>'Static Text'
,p_return_value=>'STATIC'
,p_apexlang_name=>'staticText'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(16450819125013407)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'attribute_02'
,p_prompt=>'Prompt Source Value'
,p_apexlang_name=>'promptSourceValue'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(16450819125013408)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'attribute_03'
,p_prompt=>'Route'
,p_apexlang_name=>'route'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'AUTO'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(16450819125013498)
,p_plugin_attribute_id=>wwv_flow_imp.id(16450819125013408)
,p_display_sequence=>10
,p_display_value=>'Auto'
,p_return_value=>'AUTO'
,p_apexlang_name=>'auto'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(16450819125013500)
,p_plugin_attribute_id=>wwv_flow_imp.id(16450819125013408)
,p_display_sequence=>30
,p_display_value=>'Capable'
,p_return_value=>'CAPABLE'
,p_apexlang_name=>'capable'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(16450819125013499)
,p_plugin_attribute_id=>wwv_flow_imp.id(16450819125013408)
,p_display_sequence=>20
,p_display_value=>'Efficient'
,p_return_value=>'EFFICIENT'
,p_apexlang_name=>'efficient'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(16450819125013409)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_static_id=>'attribute_04'
,p_prompt=>'Result Page Item'
,p_apexlang_name=>'resultPageItem'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(16450819125013410)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_static_id=>'attribute_05'
,p_prompt=>'Temperature'
,p_apexlang_name=>'temperature'
,p_attribute_type=>'NUMBER'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(16450819125013411)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_static_id=>'attribute_06'
,p_prompt=>'Session ID Page Item'
,p_apexlang_name=>'sessionIdPageItem'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(16450819125013412)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_static_id=>'attribute_07'
,p_prompt=>'Show Processing Indicator'
,p_apexlang_name=>'showProcessingIndicator'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(16450819125013413)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_static_id=>'attribute_08'
,p_prompt=>'Error Page Item'
,p_apexlang_name=>'errorPageItem'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A0D0A202A204150455820414920526F75746572202D2047656E6572617465202D2D2044796E616D696320416374696F6E20706C75672D696E20636C69656E74207363726970742E0D0A202A0D0A202A20526567697374657265642061732074686520';
wwv_flow_imp.g_varchar2_table(2) := '706C75672D696E2773202246696C652055524C22202F204A6176615363726970742046696C652061747472696275746520616E640D0A202A20696E766F6B6564206279204150455827732044796E616D696320416374696F6E206672616D65776F726B20';
wwv_flow_imp.g_varchar2_table(3) := '766961207468652072656E6465722066756E6374696F6E27730D0A202A206A6176617363726970745F66756E6374696F6E202822617065784169526F757465722E67656E657261746522292C207365650D0A202A20617065782D706C7567696E2F737263';
wwv_flow_imp.g_varchar2_table(4) := '2F617065785F61695F726F757465725F64612E706B622E0D0A202A0D0A202A20546869732066696C65206F6E6C7920657665722074616C6B7320746F20415045582773206F776E20416A61782043616C6C6261636B2028617065782E7365727665722E70';
wwv_flow_imp.g_varchar2_table(5) := '6C7567696E290D0A202A202D2D206E6576657220746F2061206D6F64656C2070726F7669646572206469726563746C792C2070657220737065632073656374696F6E2031382E0D0A202A0D0A202A204150455820696E766F6B657320612044796E616D69';
wwv_flow_imp.g_varchar2_table(6) := '6320416374696F6E204A6176615363726970742066756E6374696F6E20776974682069747320616374696F6E20636F6E746578740A202A206173206074686973602E20416363657074696E6720616E206578706C6963697420617267756D656E74206173';
wwv_flow_imp.g_varchar2_table(7) := '2077656C6C206B65657073207468652066756E6374696F6E20656173790A202A20746F20657865726369736520696E2069736F6C6174696F6E20616E6420636F6D70617469626C6520776974682064697265637420696E746567726174696F6E732E0A20';
wwv_flow_imp.g_varchar2_table(8) := '2A2F0D0A2866756E6374696F6E2028617065782C20617065784169526F7574657229207B0D0A202020202275736520737472696374223B0D0A0D0A202020202F2F206174747269627574655F30313A2050726F6D707420536F757263652054797065202D';
wwv_flow_imp.g_varchar2_table(9) := '2D20535441544943207C204954454D207C204A535F45585052455353494F4E0D0A202020202F2F206174747269627574655F30323A2050726F6D707420536F757263652056616C7565202D2D206C69746572616C2074657874207C206974656D206E616D';
wwv_flow_imp.g_varchar2_table(10) := '65207C204A532065787072657373696F6E20626F64790D0A2020202066756E6374696F6E207265736F6C766550726F6D707428705468697329207B0D0A20202020202020207661722074797065203D2070546869732E616374696F6E2E61747472696275';
wwv_flow_imp.g_varchar2_table(11) := '746530313B0D0A20202020202020207661722076616C7565203D2070546869732E616374696F6E2E61747472696275746530323B0D0A0D0A20202020202020206966202874797065203D3D3D20224954454D2229207B0D0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(12) := '72657475726E20617065782E6974656D2876616C7565292E67657456616C756528293B0D0A20202020202020207D0D0A20202020202020206966202874797065203D3D3D20224A535F45585052455353494F4E2229207B0D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(13) := '202F2F204576616C756174656420696E20616E2069736F6C617465642066756E6374696F6E2073636F70652C206E6576657220737472696E672D6576616C27640D0A2020202020202020202020202F2F20696E746F2074686520676C6F62616C2073636F';
wwv_flow_imp.g_varchar2_table(14) := '70652E2054686520646576656C6F70657220636F6E6669677572696E6720746869730D0A2020202020202020202020202F2F206174747269627574652069732074727573746564206170702D6275696C64657220696E7075742C207468652073616D6520';
wwv_flow_imp.g_varchar2_table(15) := '7472757374206C6576656C0D0A2020202020202020202020202F2F204150455820697473656C66206772616E7473202245786563757465204A61766153637269707420436F6465222044796E616D696320416374696F6E732E0D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(16) := '2020202F2A2065736C696E742D64697361626C65206E6F2D6E65772D66756E63202A2F0D0A20202020202020202020202072657475726E206E65772046756E6374696F6E280D0A202020202020202020202020202020202272657475726E202822202B20';
wwv_flow_imp.g_varchar2_table(17) := '76616C7565202B2022293B220D0A202020202020202020202020292E63616C6C2870546869732E74726967676572696E67456C656D656E74293B0D0A2020202020202020202020202F2A2065736C696E742D656E61626C65206E6F2D6E65772D66756E63';
wwv_flow_imp.g_varchar2_table(18) := '202A2F0D0A20202020202020207D0D0A20202020202020202F2F20535441544943202864656661756C74293A20746865206C69746572616C206174747269627574652076616C756520697473656C662E0D0A202020202020202072657475726E2076616C';
wwv_flow_imp.g_varchar2_table(19) := '75653B0D0A202020207D0D0A0D0A20202020617065784169526F757465722E67656E6572617465203D2066756E6374696F6E202870436F6E7465787429207B0A2020202020202020766172207054686973203D2070436F6E746578742026262070436F6E';
wwv_flow_imp.g_varchar2_table(20) := '746578742E616374696F6E203F2070436F6E74657874203A20746869733B0A202020202020202076617220726573756C744974656D203D2070546869732E616374696F6E2E61747472696275746530343B0A2020202020202020766172206572726F7249';
wwv_flow_imp.g_varchar2_table(21) := '74656D203D2070546869732E616374696F6E2E61747472696275746530383B0D0A20202020202020207661722073686F775370696E6E6572203D2070546869732E616374696F6E2E6174747269627574653037203D3D3D202259223B0D0A202020202020';
wwv_flow_imp.g_varchar2_table(22) := '20207661722073657373696F6E49644974656D203D2070546869732E616374696F6E2E61747472696275746530363B0D0A0D0A20202020202020207661722070726F6D7074203D207265736F6C766550726F6D7074287054686973293B0D0A2020202020';
wwv_flow_imp.g_varchar2_table(23) := '20202076617220726F757465203D2070546869732E616374696F6E2E6174747269627574653033207C7C20224155544F223B0D0A20202020202020207661722074656D7065726174757265203D2070546869732E616374696F6E2E617474726962757465';
wwv_flow_imp.g_varchar2_table(24) := '3035207C7C2022223B0D0A20202020202020207661722073657373696F6E4964203D2073657373696F6E49644974656D203F20617065782E6974656D2873657373696F6E49644974656D292E67657456616C75652829203A2022223B0D0A0D0A20202020';
wwv_flow_imp.g_varchar2_table(25) := '20202020766172207370696E6E6572203D206E756C6C3B0D0A20202020202020206966202873686F775370696E6E657229207B0D0A2020202020202020202020207370696E6E6572203D20617065782E7574696C2E73686F775370696E6E657228705468';
wwv_flow_imp.g_varchar2_table(26) := '69732E74726967676572696E67456C656D656E74293B0D0A20202020202020207D0D0A0D0A202020202020202066756E6374696F6E20636C65616E75702829207B0D0A202020202020202020202020696620287370696E6E657229207B0D0A2020202020';
wwv_flow_imp.g_varchar2_table(27) := '20202020202020202020207370696E6E65722E72656D6F766528293B0D0A202020202020202020202020202020207370696E6E6572203D206E756C6C3B0D0A2020202020202020202020207D0D0A20202020202020207D0D0A0D0A202020202020202061';
wwv_flow_imp.g_varchar2_table(28) := '7065782E7365727665722E706C7567696E280D0A20202020202020202020202070546869732E616374696F6E2E616A61784964656E7469666965722C0D0A2020202020202020202020207B0D0A202020202020202020202020202020207830313A207072';
wwv_flow_imp.g_varchar2_table(29) := '6F6D70742C0D0A202020202020202020202020202020207830323A20726F7574652C0D0A202020202020202020202020202020207830333A20537472696E672874656D7065726174757265292C0D0A202020202020202020202020202020207830343A20';
wwv_flow_imp.g_varchar2_table(30) := '73657373696F6E49640D0A2020202020202020202020207D2C0D0A2020202020202020202020207B0D0A2020202020202020202020202020202064617461547970653A20226A736F6E222C0D0A2020202020202020202020202020202073756363657373';
wwv_flow_imp.g_varchar2_table(31) := '3A2066756E6374696F6E2028704461746129207B0D0A2020202020202020202020202020202020202020636C65616E757028293B0D0A20202020202020202020202020202020202020206966202870446174612026262070446174612E73756363657373';
wwv_flow_imp.g_varchar2_table(32) := '29207B0D0A20202020202020202020202020202020202020202020202069662028726573756C744974656D29207B0D0A20202020202020202020202020202020202020202020202020202020617065782E6974656D28726573756C744974656D292E7365';
wwv_flow_imp.g_varchar2_table(33) := '7456616C75652870446174612E726573756C74293B0D0A2020202020202020202020202020202020202020202020207D0D0A202020202020202020202020202020202020202020202020696620286572726F724974656D29207B0D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(34) := '2020202020202020202020202020202020202020617065782E6974656D286572726F724974656D292E73657456616C7565282222293B0D0A2020202020202020202020202020202020202020202020207D0D0A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(35) := '20202020202020617065782E6576656E742E74726967676572280D0A2020202020202020202020202020202020202020202020202020202070546869732E74726967676572696E67456C656D656E742C0D0A202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(36) := '2020202020202020202022617065786169726F757465723A73756363657373222C0D0A2020202020202020202020202020202020202020202020202020202070446174610D0A202020202020202020202020202020202020202020202020293B0D0A2020';
wwv_flow_imp.g_varchar2_table(37) := '2020202020202020202020202020202020207D20656C7365207B0D0A202020202020202020202020202020202020202020202020696620286572726F724974656D29207B0D0A202020202020202020202020202020202020202020202020202020206170';
wwv_flow_imp.g_varchar2_table(38) := '65782E6974656D286572726F724974656D292E73657456616C75652870446174612026262070446174612E6572726F72293B0D0A2020202020202020202020202020202020202020202020207D0D0A202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(39) := '202020617065782E6576656E742E74726967676572280D0A2020202020202020202020202020202020202020202020202020202070546869732E74726967676572696E67456C656D656E742C0D0A20202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(40) := '20202020202022617065786169726F757465723A6572726F72222C0D0A2020202020202020202020202020202020202020202020202020202070446174610D0A202020202020202020202020202020202020202020202020293B0D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(41) := '2020202020202020202020207D0D0A202020202020202020202020202020207D2C0D0A202020202020202020202020202020206572726F723A2066756E6374696F6E20286A715848522C207465787453746174757329207B0D0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(42) := '20202020202020202020636C65616E757028293B0D0A2020202020202020202020202020202020202020766172206D657373616765203D20224150455820414920526F757465722072657175657374206661696C6564202822202B207465787453746174';
wwv_flow_imp.g_varchar2_table(43) := '7573202B2022292E223B0D0A2020202020202020202020202020202020202020696620286572726F724974656D29207B0D0A202020202020202020202020202020202020202020202020617065782E6974656D286572726F724974656D292E7365745661';
wwv_flow_imp.g_varchar2_table(44) := '6C7565286D657373616765293B0D0A20202020202020202020202020202020202020207D0D0A2020202020202020202020202020202020202020617065782E6576656E742E74726967676572280D0A202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(45) := '20202070546869732E74726967676572696E67456C656D656E742C0D0A20202020202020202020202020202020202020202020202022617065786169726F757465723A6572726F72222C0D0A202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(46) := '7B20737563636573733A2066616C73652C206572726F723A206D657373616765207D0D0A2020202020202020202020202020202020202020293B0D0A202020202020202020202020202020207D0D0A2020202020202020202020207D0D0A202020202020';
wwv_flow_imp.g_varchar2_table(47) := '2020293B0D0A202020207D3B0D0A7D2928617065782C202877696E646F772E617065784169526F75746572203D2077696E646F772E617065784169526F75746572207C7C207B7D29293B0D0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(16450819125013397)
,p_plugin_id=>wwv_flow_imp.id(16450819125013396)
,p_file_name=>'apex_ai_router_generate.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
,p_created_on=>wwv_flow_imp.dz('20260917104441Z')
,p_updated_on=>wwv_flow_imp.dz('20260917104441Z')
);
end;
/
prompt --application/plugin_settings
begin
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32857857258450362)
,p_plugin_type=>'DYNAMIC ACTION'
,p_plugin=>'NATIVE_OPEN_AI_ASSISTANT'
,p_version_scn=>'SH256:NcagEyRP_F17oe14bnrSYSYienkBgpdRSvH17g_NxoE'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32856670753450360)
,p_plugin_type=>'ITEM TYPE'
,p_plugin=>'NATIVE_COLOR_PICKER'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'display_as', 'POPUP',
  'mode', 'FULL')).to_clob
,p_version_scn=>'SH256:FJR60MFzlfEjx0PvnpYBK4631rNeUHXaF3eGFKxcTgE'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32858106670450362)
,p_plugin_type=>'ITEM TYPE'
,p_plugin=>'NATIVE_DATE_PICKER_APEX'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'appearance_behavior', 'MONTH-PICKER:YEAR-PICKER:TODAY-BUTTON',
  'days_outside_month', 'VISIBLE',
  'show_on', 'FOCUS',
  'time_increment', '15')).to_clob
,p_version_scn=>'SH256:dQTHqehcDG0h-d-qmHe5lf-DuViElEHDw9zMkscLr6M'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32858481482450362)
,p_plugin_type=>'ITEM TYPE'
,p_plugin=>'NATIVE_GEOCODED_ADDRESS'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'background', 'default',
  'display_as', 'LIST',
  'map_preview', 'POPUP:ITEM',
  'match_mode', 'RELAX_HOUSE_NUMBER')).to_clob
,p_version_scn=>'SH256:CU9J9l4sUtY-UffjdBCosfDW6ER-I0swXpw8GekLiYQ'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32856377408450360)
,p_plugin_type=>'ITEM TYPE'
,p_plugin=>'NATIVE_SELECT_MANY'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'display_values_as', 'separated')).to_clob
,p_version_scn=>'SH256:jJTPfH8wphTXe7ahDytF6PbWlPl1mXrDRYylCDda0k0'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32859923952450363)
,p_plugin_type=>'ITEM TYPE'
,p_plugin=>'NATIVE_SINGLE_CHECKBOX'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'checked_value', 'Y',
  'unchecked_value', 'N')).to_clob
,p_version_scn=>'SH256:oAqKgc-cSRXHDMjfwwNIgo78WqYXKjQz8MWGBG6Euj0'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32856941206450360)
,p_plugin_type=>'ITEM TYPE'
,p_plugin=>'NATIVE_STAR_RATING'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'default_icon', 'fa-star',
  'tooltip', '#VALUE#')).to_clob
,p_version_scn=>'SH256:uT4QhQbZQY61UFxAGl7ieo2urrCo8jUsFNprrg7lGHo'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32857198942450360)
,p_plugin_type=>'ITEM TYPE'
,p_plugin=>'NATIVE_YES_NO'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'display_style', 'SWITCH_CB',
  'off_value', 'N',
  'on_value', 'Y')).to_clob
,p_version_scn=>'SH256:wAjuCAsVhoIbbuKGWTMQ__Rd_YS_sY9KgWhpqOO11mc'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32859626960450363)
,p_plugin_type=>'PROCESS TYPE'
,p_plugin=>'NATIVE_GEOCODING'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'match_mode', 'RELAX_HOUSE_NUMBER')).to_clob
,p_version_scn=>'SH256:GIeRbUJQ8yKfen6-dFvkghmSUZXFoUAXCCTNRhCJgh0'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32857526136450360)
,p_plugin_type=>'REGION TYPE'
,p_plugin=>'NATIVE_DISPLAY_SELECTOR'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'include_slider', 'Y')).to_clob
,p_version_scn=>'SH256:4M27aN0U-JyQ0prILtI8ITLXOphqUdO-xWNcwkSL1SI'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32856070946450351)
,p_plugin_type=>'REGION TYPE'
,p_plugin=>'NATIVE_IR'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'actions_menu_structure', 'IG')).to_clob
,p_version_scn=>'SH256:tNGqNT-VaoKqWOwKbAdEqb6C0QO-GMcYRZJLXjScHMo'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32858736846450362)
,p_plugin_type=>'REGION TYPE'
,p_plugin=>'NATIVE_MAP_REGION'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'use_vector_tile_layers', 'Y')).to_clob
,p_version_scn=>'SH256:vJP7K77hiNj1R2RE6dHVyRAhlmxDg6KGn4yRE20J9Qw'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32859336801450363)
,p_plugin_type=>'WEB SOURCE TYPE'
,p_plugin=>'NATIVE_ADFBC'
,p_version_scn=>'SH256:fiSZ-OfcUl-d0e0dtJUYffG7q61xKsHlomsv7ZU1BMw'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_plugin_setting(
 p_id=>wwv_flow_imp.id(32859095582450363)
,p_plugin_type=>'WEB SOURCE TYPE'
,p_plugin=>'NATIVE_BOSS'
,p_version_scn=>'SH256:dRkCWi6vQMhdQUSqb0QlRls9iYcsZ93IPYrbTqFqJFE'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/navigation/lists/navigation_bar
begin
wwv_flow_imp_shared.create_list(
 p_id=>wwv_flow_imp.id(32862021839450408)
,p_name=>'Navigation Bar'
,p_static_id=>'navigation-bar'
,p_version_scn=>'SH256:vnb1-G39r80BPE-5P2Enpuf0sMSVvBeNQDVbFiNwRto'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(32875212536450471)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'&APP_USER.'
,p_static_id=>'app-user'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-user'
,p_list_text_02=>'has-username'
,p_list_item_current_type=>'TARGET_PAGE'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(32875834007450471)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'---'
,p_static_id=>'list_item'
,p_list_item_link_target=>'separator'
,p_list_item_disp_cond_type=>'USER_IS_NOT_PUBLIC_USER'
,p_parent_list_item_id=>wwv_flow_imp.id(32875212536450471)
,p_list_item_current_type=>'TARGET_PAGE'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(32876310600450473)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Sign Out'
,p_static_id=>'sign-out'
,p_list_item_link_target=>'&LOGOUT_URL.'
,p_list_item_icon=>'fa-sign-out'
,p_list_item_disp_cond_type=>'USER_IS_NOT_PUBLIC_USER'
,p_parent_list_item_id=>wwv_flow_imp.id(32875212536450471)
,p_list_item_current_type=>'TARGET_PAGE'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/navigation/lists/navigation_menu
begin
wwv_flow_imp_shared.create_list(
 p_id=>wwv_flow_imp.id(32861304509450374)
,p_name=>'Navigation Menu'
,p_static_id=>'navigation-menu'
,p_version_scn=>'SH256:cHt1JBAsdhBQ33AnvpfXBU18H-3M3vYQlMNJXIW4-yc'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(16450999438902401)
,p_list_item_display_sequence=>40
,p_list_item_link_text=>'Configuration Help'
,p_static_id=>'configuration-help'
,p_list_item_link_target=>'f?p=&APP_ID.:4:&APP_SESSION.::&DEBUG.:::'
,p_list_item_icon=>'fa-info-circle'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(16450999436902401)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Dashboard'
,p_static_id=>'dashboard'
,p_list_item_link_target=>'f?p=&APP_ID.:2:&APP_SESSION.::&DEBUG.:::'
,p_list_item_icon=>'fa-dashboard'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(32872685155450452)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Home'
,p_static_id=>'home'
,p_list_item_link_target=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_list_item_icon=>'fa-home'
,p_list_item_current_type=>'TARGET_PAGE'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(16450999437902401)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Request History'
,p_static_id=>'request-history'
,p_list_item_link_target=>'f?p=&APP_ID.:3:&APP_SESSION.::&DEBUG.:::'
,p_list_item_icon=>'fa-history'
,p_list_item_current_type=>'TARGET_PAGE'
);
end;
/
prompt --application/shared_components/navigation/listentry
begin
null;
end;
/
prompt --application/shared_components/files/icons_app_icon_144_rounded_png
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '89504E470D0A1A0A0000000D4948445200000090000000900806000000E746E2B800000EA7494441547801EC9D6B6C5CC515C7CFF53A5E1C13DB89ED3C21383C132CA008BC1428851409904A55A9452552251EB190DA7EAAAA7E41FD40E8977E2C88BEA4';
wwv_flow_imp.g_varchar2_table(2) := '960468551C55A145859404DA384AD234362189821B48F370E3E6C986D879D871FCB89DFFDC9DB076EEAE7777E6EE63E6587BEE63EECC9999737E3B73EEDD7BAFAB88FFD8021A166080348CC745891820A640CB020C9096F9B83003C40C68598001D2321F';
wwv_flow_imp.g_varchar2_table(3) := '17668098012D0B140C9056AD5CD81A0B3040D6B8B2341D61804A63776B6A6580AC7165693AC20095C6EED6D4CA0059E3CAD27484012A8DDDADA9B5F8004D63BA1D4FBDDEB4E3C9D76F8674AF587DDFCE27573FAEA47BC5ABCFB822E833FA0F812DA408DB';
wwv_flow_imp.g_varchar2_table(4) := '4C63BEA21F2E3940DB57AC69ED59F1EA0BDD2B566F1270F8DEA5B1A4E78D7D0A21F2B78D7BFE5F9508EBAC7145D067F41F025B4811B611363A2C644D8FB059CF8ADF3E24EC51D24F490042C76104217E8C260EFB44AB84A11E22FECBC502AD22D333B099';
wwv_flow_imp.g_varchar2_table(5) := '4F55F8D20128C83322BDE89FA202846F8D80460053B549F4B4241D16F5DAF601509035B02D6C5CCC0E160520744A74CEC7B746740E9D152BFE44608156D858D8FA306C1E81FE2B54460E50B7886DD0A92B6AE684282D2041EA1171529495407764002138';
wwv_flow_imp.g_varchar2_table(6) := 'EE16F0706C03339746F0C5C568045F44D582480042908CE0D82C3C5199C07ABDADC21708B62389398D0304DA717660BD5B2AAB83883B5F806F4C37DB384031F271ADC6743B599FBE05E448A4AF66B206A30071CC33D9B865B8D72A6222A35F706300F5C8';
wwv_flow_imp.g_varchar2_table(7) := '88DFE78B816548CD9426C99F83A6A415BC6B0C209F2892208DF82F0A0BBC604AA91180C4B0087810A8996A17EB89D60298CAE033ED5A8C00245A618C68A1CBF487F5855BC088CFB401E2D127DC3B1590DA8AEB75BAEDD40688C87B9AF8AF222DE0534C7B';
wwv_flow_imp.g_varchar2_table(8) := '14320090CF675E15890F1AED6BC7AD5A00A5A62FB484A5322DA03D8D6901549936E3564FB640D58393F7F3DBD30548ABF2FC9ACAB9A3B0804F9E5608A20B9056E55118C4A44E3774F95A71902E405A95BBE1A0B2EF652B9E8429B495050384C74C0AAD94';
wwv_flow_imp.g_varchar2_table(9) := 'CB95990546A8A9D016150C90E78D37175A2997B3C7020503648F09B8273A830103C4FC6859A06080623ECDD1AA990B978D05747C593040E39ECF315026041C4A2F1820176C941C1E2488ED7DD5190C18A00C741CBF9014F00CA46430432E4E6680421800';
wwv_flow_imp.g_varchar2_table(10) := '3C83231768F6DC2629C96180C41085988A18A02956498A690BF0D4D6D552DB0377D24D77DF4AD84E3244532C15EC3240811DE47270E4BC9CB200CC5D8FDD2FD36A6AE374DB837713D218226992490B0628658EA1B18B74FCC269090A804925CB550D4324';
wwv_flow_imp.g_varchar2_table(11) := 'ED10B66080845500CF91B32709A3CC2DEDB7518D0046244FFA200D6021CFC0C839C268352983919DCA53C200099F011EB122C07375533D364345413436314E9F89982834936389CE03745C9CAEC3E7D7B7DD4CD9E0411E0820425E40A4CA22DD55711A20';
wwv_flow_imp.g_varchar2_table(12) := '4C5D83E2741DD3D2C2A58B7366A0F9BA79F2F41E65A123E7821666741AA0A43865874F3175619DAB6014C2E93DF21F3B9FC4CA59711620C033347A91301DE532754D250410A12CA632E89A7ADC957D27011A9D1893D77BE0E4FA96463A7FFA6C4112AF8B';
wwv_flow_imp.g_varchar2_table(13) := '13A63F9C954127F4B9264E02745C5CEF518EDEDDD54D85CABEEEBD347C6198300AA5EB54BA8BB82E59554E0284A9AB7EFE1C6A7BB4DD88401774BA18503B07D0A0F8B9025FD7B647DAE98EEF3F6A44A00B3A874647B0724A9C03485D005CF2AD76638E86';
wwv_flow_imp.g_varchar2_table(14) := 'AEBAB90D8458C898D20A51E41440986210AFCCBF668171F7342D9C2B6321D4615C79192B740A20357D2DF9DAEDD3BAE4E0BA6EFAE8977FA3ADABD6D2D1CDFBE8D2E9F359CBDCF4F09DF2B8AA43EE38B0700AA00BE2BA0F7C8A2907EB30B9983C47EF7CEF';
wwv_flow_imp.g_varchar2_table(15) := '57B4E3F71BE993F777D291DDFFA1CD3F5F471B7FF2068D648168DE033713A6315547986E1BD39C01082303A6AFBBBFFB70563F7EF88BF5743E39485FFAE657E8911F3F490FFFE809B98DB4F70544D946A26BEFB8B1E2A6B1ACC6C8E1A033008D8A5FD061';
wwv_flow_imp.g_varchar2_table(16) := '8F59F36663152A67F61D9523CE8DF7B5D1DC9B16C93CB1AA98DC46DAD9139FD3F0A9B3323D6CB1E8F61B64B24B67630E01342A9D3BA7ED1AB90E5B0CEC3B26931B5AAE84ACBE39483B7F2AF3BDD1B52DB3647997026987001A97CE8D375D2DD7618B992D';
wwv_flow_imp.g_varchar2_table(17) := '0D327964F8925CA72F262E050056795E7AF2A4EDFAA5E6CFEE265550863BCE0074697C5406B9D97CD078EB4299A7FFE38334E14F5CCE8AED837BF6CBFD6C231832E0AA34EAC2B60BE20C4008A06BABE3597D8AD1E9F6C7BE4C678E9CA2EDABDFA3FDE22C';
wwv_flow_imp.g_varchar2_table(18) := '6CDF861EDAFABBF534D89FA47B9F7A9490279B929AAA6A194867CB63D331670082D3EAE707710CB633094EF1978B33AF587C06F5ED3940FD7B0FD1D8B98BF4F59FAD241CCB544EA537B75D2B3747C52FFE72C3F2851300A9A076CEB2CC0174BA9F177C75';
wwv_flow_imp.g_varchar2_table(19) := '293DFE9B1FD0B75FFD213D21E43B6F3D4F0DCB16A667C9B85D139B218F590F90EC25B9F160E1E8F898ECEE8C58B55CE7BAC074559325E80ED3337B5970FA1F76CCC634274620E5B87C6150E5F259AB0B8D0ADA7CCA56625E270052230F2E1446ED2457C0';
wwv_flow_imp.g_varchar2_table(20) := '5176740220D5D9629C5E0F27832BD50A5A55B7AD6B27009A214EADE1C0A1CF02E7623B2A39777240AA5675CA1D8B174E00A4EE571E38713A7257AA3AFE7BF644E475954305D60374E4DC491A4ADDC63194E577AC306720663ABA795FD8A18C69F8C11507';
wwv_flow_imp.g_varchar2_table(21) := '71E1F2C0C0FFB069B5E40F50059943C1A35E1405A7E27E9F5CBBB0EDE5B769D79B9B72CD7EF9A6B3F4FA6C87C85A80D2E1C18BA2E6B70617024FF746372AA8D10A75E1C9558004686D86C84A80A6C28321645673235674F2E33EB98E62A174A3AE9ADAB8';
wwv_flow_imp.g_varchar2_table(22) := '7CBB99ED105907101E3346CC03C761E451A0C0A1483BF0F7DD97A71A75CCD4FAD0479F4A55A80B1B58A78F44681BD26D12AB00C26F5EC9E101C2E3C6E9F02887CD6E6992BF940F67B9AB50E5CD777D3175FD67D1F5C18FA9AA7C4D6A24429BF0D80FDAA8';
wwv_flow_imp.g_varchar2_table(23) := '8ED9B0B60AA0E4346FDBC073F0705A5FD75EAC8CCA914DBD525FCBE22B6F2A0344780308E221DBDEE661154098BA3002647ADB46CDCCE07EA0FE3D078D4F63BBDFEC920065AA1BE9984201914DBFD417112069DFC81683A94796E3B5B519EBC04800C070';
wwv_flow_imp.g_varchar2_table(24) := 'AD469D3165CC9CC781C36FF5C8A911BAB315C3148AE30C10AC5066329A7AEA02AF5CC9D6B4454B5BE5E1DE8D3DC646A19E3F7C20752ADD722764A1A6D0218B9EA1B766041A9D086E7A8FCFCC3C02C1A71885F062288C4226AE09A9D1073AA11B754C27AA';
wwv_flow_imp.g_varchar2_table(25) := 'ADD3E5AB84E3D600948FB1F18E43E4DFF9C77F688F4218C9A02B9F772C22BF2DE22440182996256E23DD5108A30F7460F4B105887CFBE124403012AE16E3DACC9697FE9CF59977E40D133C27BFFD8D0DF290ABA30F3AEF2C401885AEAA9B29CF9EA67BE6';
wwv_flow_imp.g_varchar2_table(26) := '1D869A2A3DAFBC2B93A63BF392992C5E540240C6CD7F6978847AB7ECA233A782FB83300DF577FD3BE77AF0EA17BCB503058E1EEAA79DEF6D23E8C4BE6BE21C4070F4DECD1F4A7866CEB88A6E685C44D55531F93A97C1D4B3F1D920401EBCFA056516D7CF';
wwv_flow_imp.g_varchar2_table(27) := 'A3E6DA46C28B36A113BAB395B5F1985300E175BEDDEBB7488737C4EB68F1AC79845B4F175EDD2C7DBBE5E5BF648D8710F7BCFBFC6A99176566565F45D0930ED1E9FE93F2B82B0B670082637777754BBF2EA86BA205750134480008800053D9DBCFBD42FF';
wwv_flow_imp.g_varchar2_table(28) := 'FAE99F68CFAF37C8B3B4A15383721BFBEB3A5E427639EAA00C760060736D834CC348D4D77B808E7D7204879C1027008243F14E677814D34E43FCCA37742808F05B156ECBE8DDD083EC32C8C63604D31640435E79306D8134E80644877AF73B0391F50021';
wwv_flow_imp.g_varchar2_table(29) := '588643E17C38588D1C69BEBFBC090896CEB94EC645C88B3238886DC88D8DD78891A60149A102DD2AA6429D877705F7078566B624D14A8010CC42000FCEB400029C0F07E7E2374C4B2A2FCA621B926BD9EBEAE7CBC05C9DA121F6CAA56C25E6B10E20C439';
wwv_flow_imp.g_varchar2_table(30) := '0894218007412EE029A673002020C27487290D6DDABAEE03F92F158AD98E62D4650D40886B705AAE04CEC3B4931E2CE76BD0C6F82C6A11A7E9F996437E40842911531A2056EDC21A6D451E1BA4608062BE5756FF280B530C4ECB95C07948D3711274E83A';
wwv_flow_imp.g_varchar2_table(31) := '1B200162D52EAC75DBA5D327D3650B06C87443585FE92CA03318140CD0B8479F97AECB5CB3490BE8F8B260804C76807555AE050A06C8F76365150355AE0B4ADF721D5F160C50E9BB1D610B5875CE16281CA03805F742E45C15672C5B0B68F8B26080EE79';
wwv_flow_imp.g_varchar2_table(32) := 'E36906A86C89C8AF613ABE2C18A0A0895E57B0E665055BE0359DB66B01E491CF00E958BF3CCA6ED66986164044135A95EB349CCB9AB1C03855690D02553ACD18A3EAE85EB6A3D3302E9BB305EEED7C56CB875A000595731CF485B72A6E4B2BFE416FB500';
wwv_flow_imp.g_varchar2_table(33) := '82028FC65FC49AA5F22CE0D1C4EBBAADD606A8BDF3393187F228A4EB881294EF0B7CA757B3364041F5BE36C9811E5E16D10246660E2300A52279AD60AC8886E3AA8405129D1DDAF18F5063E6DF3D05C13419211A8D6289D6021ED12A32F4676404425B52';
wwv_flow_imp.g_varchar2_table(34) := '441BA11AFA58A2B280D7D5DED961ECCB6E0C2074574C65A2619E08AAB1C79287058A95B52FD1B972B9C9CA8C0284A96C9CBC674D36907599B380386D37EE1BA300A1AB8048AC8D3754E8E48F8605043CCBDBE525170D2521458D03843A1222C217D3D912';
wwv_flow_imp.g_varchar2_table(35) := 'B1CD6766C20825FEF445050FFA150940508C914840B4DC3318F1432F4B3E16F0BAC49779497B04238F6A456400A1024084883F05118F46304A71448C3AB42A6138600E6B7AA400A90A01114623B12F62238FCFD2842122FAA4C0E910A38EB953F56C6D2D';
wwv_flow_imp.g_varchar2_table(36) := '0A40680046A384888D12C1B7824182510C484A0546F767139DC5032755AF992BD14A59AE6BD1D1D7120224312A2D418027CA09A0882F42524E7F0216AFCB13B1256C97E8ECF0842C115212FB156D040A330D46A57611E025E4C8D4816F90E7D75437FB7E';
wwv_flow_imp.g_varchar2_table(37) := 'F52D1022EF7E48CCF7BE414480CC09417F9590B0016C0111764AC1B2529C9277BCD82E6C4725FE2B2940617DC71302F7AC7D7A3F24D1B9F29F90BBD6AE7C2711402646AE0EEB05FD55921036802D2061F62A755AD901546A8370FDF9598001CACF5E9C7B';
wwv_flow_imp.g_varchar2_table(38) := '8A0518A02906E1DDFC2CC000E5672F7B721BEA090364C890AEAA61805CF5BCA17E3340860CE9AA1A06C855CF1BEA370364C890AEAA61805CF5BCA17E3340860CE98E9AC93D658026DB83F7F2B4000394A7C138FB640BFC1F0000FFFFE319A29C00000006';
wwv_flow_imp.g_varchar2_table(39) := '494441540300EBCB7F7B4596197B0000000049454E44AE426082';
wwv_flow_imp_shared.create_app_static_file(
 p_id=>wwv_flow_imp.id(32863448795450423)
,p_file_name=>'icons/app-icon-144-rounded.png'
,p_mime_type=>'image/png'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/files/icons_app_icon_192_png
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '89504E470D0A1A0A0000000D49484452000000C0000000C0080600000052DC6C0700001000494441547801EC5D4D8C1CC515AE18ECF57AEDF5CFAE7FB1BD803136B61C41829D4809019440A490030A498C222587708922E592E482920307A25C12892852';
wwv_flow_imp.g_varchar2_table(2) := 'C4251C824462458E388488808320761430983FC718436C846D6C6376837FD6BB5ED698F4D73355F3BA777ABAABA77AA67BEA5B6D4D5757BD7AF5EAABF775BFAAE99999B5F7DEDF7FC2440C7CF581598A7F44C0630448008F279F43578A04A017788D0009';
wwv_flow_imp.g_varchar2_table(3) := 'E0F5F473F01E1380934F041802D1073C47807700CF1DC0F7E19300BE7B80E7E327013C7700DF874F02F8E8011CB3418004305030E3230224808FB3CE311B0448000305333E224002F838EB1CB3418004305030E30302F1319200714478EE1502248057D3';
wwv_flow_imp.g_varchar2_table(4) := 'CDC1C6112001E288F0DC2B044800AFA69B838D234002C411E1B95708784400AFE69583CD8800099011288AF5260224406FCE2B479511011220235014EB4D044880DE9C578E2A2302244046A02A2D46E31311200112A161850F0890003ECC32C798880009';
wwv_flow_imp.g_varchar2_table(5) := '90080D2B7C408004F0619639C644044880446858D10B08A48D8104484388F53D8D0009D0D3D3CBC1A5214002A421C4FA9E468004E8E9E9E5E0D2102001D210627D4F23D0C304E8E979E3E01C2140023802926AAA89000950CD79A3D58E1020011C014935';
wwv_flow_imp.g_varchar2_table(6) := 'D5448004A8E6BCD16A470890008E802C951A1A9319011220335414EC450448805E9C558E293302244066A828D88B089000BD38AB1C5366044880CC5051B00A08D8DA4802D822E6487EFAF225F5DF33C7C384BC23B554638900096009980BF1894B17D5E1';
wwv_flow_imp.g_varchar2_table(7) := '33EFA94B973F0ED3BBE74E2994B9D04D1D760890007678B52D0D473F7AEEFD881E10E1C4F828491041A53327244067700E7B893B7FFF40BF4242254900143A9F48800E61DECCF9376CDDA2B6DC7A3349D0A13968D64D0F11A0D9F0CA5116777E5805E79F';
wwv_flow_imp.g_varchar2_table(8) := '3F34A8E6F4F78524401912EF0440A173890428186BECF0C463FE1B6FDBA6E0FCBA6B9060DBD76ED1A7E1C2186B02B43585CC148200095008AC35A57060ECF0D4CE6AAF71E7AF95AAF04E70C3B62DFA342401DA42872964C63902248073481B0A4F5E180B';
wwv_flow_imp.g_varchar2_table(9) := '1D59972439BFAE1F5AB35C352381AEE7D13D0224807B4C438D47CFBFAF26A62F8679BCC0B165D883B2660924B876F3F5A60A6B82931746CD39336E112001DCE2196A1B9D3C3BC3F9E1D861658697551BD72A4982B353171474263665456E044880DCD035';
wwv_flow_imp.g_varchar2_table(10) := '6F881D9FD1C933A6128E6CE3FCBA619C04D009DDBA9E47370890006E70345AB07BA34F162F1B5270647D6E7B1C1E59AEA043B793BA75198FED214002B4875FA435E27EC4ECBA7064D33A9DCD75C4F6E8FA9B3799B6D0CDF58081C34986047002A30A9FE3';
wwv_flow_imp.g_varchar2_table(11) := '918B5E843E5916BD69DD830458406B39AC07CE4E8DEB531EDB44800468134034C75EBD7CB30B614B3BA10F74CAB46078512414FA205863A04F29E36BBEDD719300ED2218B43F19ECF70707F3DF6EE86314D533B80BCC0C85C6EAB53CB4830009D00E7A41';
wwv_flow_imp.g_varchar2_table(12) := '5BECCC1411FA04AA23FF20810C85D027FA8E08F1C41A0112C01AB26883D160CF5F97B80E7DB45E7D8C8742DC15D2C8E43F9200F9B153588CE24AAC55B80E7DB45E7DC45D201E0AC1065DCFA33D0224803D66A60516A3FAC4D5AE8FD6977404096428246D';
wwv_flow_imp.g_varchar2_table(13) := '486AC3F264042A4C80E44175A206A10FF6E5755F470EBCA5F6ECDCD5917470EF7EDD6DF8B0DD493E2B64F0B0CD9000B688D5E54783ADC87AB6EB870BE2A1BBAE1B53310348801C1356B6B81B77A251B118CF31246F9B900039A65EC6DDB7FFF89BEA3B8F';
wwv_flow_imp.g_varchar2_table(14) := 'FFBC2B097D6BF3CF4C9DD7591E2D1020012CC08228AEFEB8E2228FB4F24B1B71E84A5AB279B5E91736F17D010347E60C099019AA9AE0D98F2ED432C1EBE6AF6E0D5EBBF05FEFB26F68BEFADC77EFAC9F297E66C020913D430264C74AE1F91BB9EFBFF1DB';
wwv_flow_imp.g_varchar2_table(15) := '5FB0685D8CE8EADB1A4F8BC236DE05EC7026012CF01A153B3FB8FAE30A6CD1BC1051D8B0F6C6F54637423473C24C2A0224402A440D01B9DD78F56D8D6F7068487427B7657BE32B55A48DDDB1A65ABD920016F38585A6165F78C32A9DB53A4E8D8DABC33B';
wwv_flow_imp.g_varchar2_table(16) := 'F7AA3D0FEC508FDDFDA0FAEB0F7E17E6FFF3F02E853A2B6575E1B9CB06EB3915BE31C630C8C0919A21015221AA09C8D002E14FADD4EEF5ECC1136AE77D0FA9171E7D4A1D7DF5EDB0F1B953FF0BF3AF3FF9BC7AFA677F08C9115658BCC4C3A089E9298BD6';
wwv_flow_imp.g_varchar2_table(17) := 'D512756D2D09901151B9FBB36CF348C6560D315CF59FB8FF914641931CC8007240B64975CB221906F10ED012AA482509108123F964423C6E20F7DF935B346A70E58763EB92A16B56A8ADDB6F5777FE74BBFACA4FBEA53E7FEF9715CA74FDC1A75F5268A3';
wwv_flow_imp.g_varchar2_table(18) := 'CFB31C6518F4D1C7D3599A502640605690F89F82403CFC41C891D22452BD7FC76E73BEE6D3EBD467EFB9552D5EB32C2C9BF5A9596A70F5B0BAE91BB728D4A1107782DDBF791CD9CC0936ADADEF0661ADC2BB4036E848800C384967CA13FEE8787FF6BC3E';
wwv_flow_imp.g_varchar2_table(19) := 'B5E18ECF34ED1144401D64200012D82E8A576EB9064DC334C175408843DA0B09908650503F7DF9E3E035DFFFC97FBE691AAEDE30A2E0E8A6209641DD8AF56B4CE9C5D3E74C3E4B667853E3D10849DA2C6D7D95A91001BA374532A6B68DFF273E6838F1DC';
wwv_flow_imp.g_varchar2_table(20) := '8181D441CC5FB0C0C88CBE71DCE4B364B80EC8825254860488E2D1F40C31B5AE40ACADF3598EF2AA3C7E3EFD89CD8B171ACF1ACD5BDAD8DFCFD297B40D364F5FBE94A599D7322440CAF4CB05B05E64A6348954CBABF2E8E113EAF2279723F5F20475C7DF';
wwv_flow_imp.g_varchar2_table(21) := '7CD714D9DE6DD050DA48020091D68904688D4FA476C1F24591F32C27B82A6BA79C1C9F50879E7E39B1D9A15D2FABE9C9DA9B586883B689C20915D2462E84134012C5248000A359562E26F3EC0041E7D61FDD8543988EBD7E58EDDBF99C3A77BCF69DFFB8';
wwv_flow_imp.g_varchar2_table(22) := 'EA9F7F6F4CEDFBCB73EAD86B874319BCC837B6709E35CD5FB6D8884E5FE6FB01068C840C0990008CCB625CC9E573FB63EF9C52CFFFE91FEAA95FED50BB7EFD67F5EF3FEE5263474E992E211B79D6C8D4A467E49A63BA8DDDABF49E7A438204489947E944';
wwv_flow_imp.g_varchar2_table(23) := 'B68B52A97ADD3DDB143EC238B862892C8EE45177D72FBFAF201BA9E0496108900029D0CA2DD014D1D46A7C7CF28E5F7C2FFC1417627C3480D3238FABFED71FFEA1CA7BE5872E267B0448000BCCE48E8E45B38828C2215CE1BFF8C0F6F083F4707AE45116';
wwv_flow_imp.g_varchar2_table(24) := '11CC79226D7449DE9CE694BE190950FA29A28145224002A4A08B3794B408AEDE3A5FD6A3B451DA5E567BD3EC2ABA9E04281A61EA2F35022440CAF45C39EB0A2361FB74A669D8A58CB4BD4B2694BE5B12A0F453646760D5486A373AF7D224400AA673AE98';
wwv_flow_imp.g_varchar2_table(25) := '6D246C1F4F360D3B9891364ADB3B6842A5BA22012A355D76C6CE16E19B5D4B7FA44B4C80724C42D59C487EFEA01C0896DB0A1220657EA6C5F334B61F5049515D48B52480B4BD90CE7A402909D06212F1CB2B13E2DB204EEE7FA7857439AAC64F7F680C81';
wwv_flow_imp.g_varchar2_table(26) := 'EDA3FCDD008347B30C09D00C95A00CCE7F76AAF1E9ACA0A812FFF2916A183C3A7986DF1A0D20121209D0049824E73F73CAED8F53E36B11918ADEBA24099A4C72BD8804A803A10F71E7BFEADAC6B734E4F9AA12AD377EC4B745401FD2F167DF8856B77106';
wwv_flow_imp.g_varchar2_table(27) := '7DBAF9B59BAFD7D9E02EC03B810143644800014633E7BFE6A60D6AF1B2212325F7D94D618E8C5CACE668DEB40948A52B40DC551BD72A924023D2FC4802D47149727E542F5EDA20409977824E1F687CA0BEAFBF1FA62B92208421F1850408A069E5FC41B5';
wwv_flow_imp.g_varchar2_table(28) := '1A5CDAF8303CBEB71365654C7201DC37D0674C24090C143332DE1320CDF981D89C790D67923136EACA94A46D436B96474C230922709813AF09301AEC91CBADCEAB82052F627E834E3D33A7BF2FB20EB0FDE6E6BA9A420F32FE976B16D969154820EDED44';
wwv_flow_imp.g_varchar2_table(29) := 'DE5B02E0EB4E46833D720D329CA699F39B7AB10E90DFF6ACEBBB7D94F1BF5CB3C4ED8A93E0CCD479052CE272BE9C7B4B8013E3B5EFE5C144C3F937DF7213B2896978A41152B87E3F20B1538B8A037F7FD1484B5B4DA1C8A01E6346113E3526B140994FC9';
wwv_flow_imp.g_varchar2_table(30) := '4B029C9D1A0F7F4B4B4F749AF3434E864188B5CB1406C5C31FD80A9B9312EAD7DFBC49F50FD4768A4002609224DFCBE55E12E00311FADCB02DFBAF3DCAD0A24C61900C7F565C9DEDC7FBE604EB9AAB375F677C5B62620A3DC87847005CE970C5D3731BDF';
wwv_flow_imp.g_varchar2_table(31) := '2DD1E5CD8E081D747999C22019FE2C186E6CD96A5B938E909577011FD702252240D234B92D97938C5D1F1BEDB86AEAD81961509E1FB3B3E92F8BAC0C7F301ED898A51D6420BB64F930B2619AF0F05765BC23807C467E7038FBD532F490E06564D3BAE0B5';
wwv_flow_imp.g_varchar2_table(32) := 'F65F8637C5F63DF64CCD98E075E9DA95C1ABDDBF6C232F0E765AAA2BED1D01E4B7A52104B09D3ABC2926EF02DD5C0CE3EA8F3B11C6805066FE90DD0F6AA01DC6832392C406E73E24EF08D0EEA4226C900BCD6E2E860F3FF39A198E5CD09A42665211F08E';
wwv_flow_imp.g_varchar2_table(33) := '0072010C674E45A88900EE1CB8E2A2EAE8AB6F5BFFA62FDAB59B70E741DF5A8FCD625EB7C1516220B1419D0FC93B02B89854388DBCE2DAFEA6EF0C1B7214C83B8F7CE439872AAF9B900039A75FDE051087231ECFA9CABA19FA92577F3CDE60AD840D4204';
wwv_flow_imp.g_varchar2_table(34) := '48801006FB97F85D40EEC6D86BB36B21FBB27923CFAE173FA4498036E6197701B923D489F705D007EE38301B7DE78DFDD19E492912A00D2FC05D00CFD46815785F008B537DEEFA880FCFBFF0E85346AD7C4FC21432638500096005D74C619000EFC0A206';
wwv_flow_imp.g_varchar2_table(35) := '57E62217C42FFEF609741326F49967DF3F6C5CA2976E9B4202389E019000618A63B50A3AE5C2577FE6D7753FBEE92301DA9CF1775E39A4DE3B722CA2C5752884B04A863EE8ECC881B7D489378F22CBD4060224404EF03E9A9C520776BF32C3F9A10E7701';
wwv_flow_imp.g_varchar2_table(36) := '97A190DCF3973F7A0112EC7BF25FE89229270224400EE0E0FC6FBFF486FAF074E39BE216F60DA8758BAE52DA4141823D0FECC8A13DDA043A74E803DD23832BD4707FE321BEC90B930A24804DD1963CCB82000990052521333E764EEDFDDBEE88F3C32157';
wwv_flow_imp.g_varchar2_table(37) := '0E0CABD9B3AE5470502D0EC745ECAECF6D8F680B1DBADDAAF9B53E86FB17CE20C1FEE75E52B04DCBF2980D812E12209B8165928283BDFAECDE88496B079707CEB8D09481042B071A5FA485D81D8E6C043266E2713F74CEBB72AE690D12A04C17E04E70E8';
wwv_flow_imp.g_varchar2_table(38) := 'C5FD5C176840321E49808C4061C1299D1FE1089C5F3AA556B5B06F7E408A469882453148807D7C2D9374840C649FB8FF1123326FF65C059DA6A09E41990CBB4002AC0B606B5D8487140448801480508D9D1E3816F248707E843ACD9C1FF5485813C07191';
wwv_flow_imp.g_varchar2_table(39) := 'C77A0077829DF73DA41EBBFBC130E11C7548C8EB72C8E01CE548E86BED82C63752A04C26DC71600BE474396C2509341AAD8F24400B7CB0B08CEFF4C0A9AF5BB43A8CF75B340DEB11A2607DD04AAE559DEEAB950CEA3409403A9C238104581C23CF948C00';
wwv_flow_imp.g_varchar2_table(40) := '0990800D9CBFD94E4FABAB715C151C53C7EA704E79958ECBEA73C84016C4B1EF6B5124F442480412602C5A3F8F51044880281EE11916BB493B3DA180E50B6275EC12E1CEB171C988DA182438B85683BC2E870C64411C5D9FF5A809077DBA0D48C01D228D';
wwv_flow_imp.g_varchar2_table(41) := 'C6CC230910C364ECD8FB4A2E76518DC56E1E8744DB6E24D88AF04BF70D12708748A3113D9200011E081170D547BC7F70EFFEA0A4F68F7004CEDF6AB15B932CDF2BEE3ACD7688101281E4186FF9ACEEBC455E1360CFCE5D0A09E10EAEFAF29D5D383F7657';
wwv_flow_imp.g_varchar2_table(42) := 'AAE8FCDA8D1012610C188B2EC3DD0024C7783176245DE7E3D16B02244D386268C4E270A02466922E5500000212494441541997E545FE1837C60012604C2E6DEE155DDE11A09923E00A892D47D461318A18BAE809C64E0FFAD47D17D91F4880312124C2DA';
wwv_flow_imp.g_varchar2_table(43) := '40F72DFB841DA8936545E4CBA6D343022C5470729970B5C796239CA4531304A7449FE81BF94EF48B7EB036C02E13FA8E6380BA4ED851A63EBC234099C0A72DDD478004E8FE1CD0822E22400274117C76DD7D044880EECF012DE822021D24401747C9AE89';
wwv_flow_imp.g_varchar2_table(44) := '400202244002302CF6030112C08F79E62813102001128061B11F0890007ECC33479980000990008CD3622A2B2D02244069A7868675020112A01328B38FD222400294766A6858271020013A8132FB282D02244069A7A6370C2BFB284880B2CF10ED2B1401';
wwv_flow_imp.g_varchar2_table(45) := '12A05078A9BCEC089000659F21DA5728022440A1F05279D9112001CA3E43B4AF50040A2440A17653391170820009E004462AA92A02244055678E763B4180047002239554150112A0AA3347BB9D204002388131A684A795418004A8CC54D1D0221020018A';
wwv_flow_imp.g_varchar2_table(46) := '40953A2B8300095099A9A2A14520400214812A7556060112A03253550D43AB66250950B519A3BD4E1120019CC2496555438004A8DA8CD15EA70890004EE1A4B2AA214002546DC668AF53041C12C0A95D5446043A820009D01198D94959112001CA3A33B4';
wwv_flow_imp.g_varchar2_table(47) := 'AB230890001D81999D94150112A0AC3343BB3A820009E00266EAA82C02244065A78E86BB4080047081227554160112A0B25347C35D204002B840913A2A8B000950D9A92B87E155B7E2FF000000FFFF64121DDC00000006494441540300D32CBF6A7DEEF8';
wwv_flow_imp.g_varchar2_table(48) := 'AC0000000049454E44AE426082';
wwv_flow_imp_shared.create_app_static_file(
 p_id=>wwv_flow_imp.id(32863708405450423)
,p_file_name=>'icons/app-icon-192.png'
,p_mime_type=>'image/png'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/files/icons_app_icon_256_rounded_png
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '89504E470D0A1A0A0000000D49484452000001000000010008060000005C72A86600001000494441547801EC5D69901C45767E3DA383D1C5A191B49256D2087108840CD868B039CC6076BD0EAF83D8F0B572783756307684ED3F8EB0FF78637F201C8EF0';
wwv_flow_imp.g_varchar2_table(2) := '3F1FE1F0DA110E2101F65AD8063B88C561C04692610333122C9710CBAE9010488360041A4933A3D11CEDFCAA3BABB36BAAA78FA9CACAEAFC3A3A3BB3B2F278EF7BF5BE3CAABABB43F8220244C05B044800DE9A9E8A1301111200AF0222E0310224008F8D';
wwv_flow_imp.g_varchar2_table(3) := '4FD5FD4600DA930080020311F014011280A786A7DA440008900080020311F014011280A786A7DA7E23A0B5270168241813010F112001786874AA4C04340224008D046322E0210224000F8D4E95FD46C0D49E0460A2C13411F00C0112806706A7BA44C044';
wwv_flow_imp.g_varchar2_table(4) := '800460A2C13411F00C0112806706A7BA7E2310D59E04104584C744C0230448001E199BAA12812802248028223C26021E214002F0C8D854D56F04E2B42701C4A1C23C22E0090224004F0C4D3589401C02248038549847043C418004E089A1A9A6DF08D4D2';
wwv_flow_imp.g_varchar2_table(5) := '9E04500B19E613010F102001C418F9A5FB772D4538F48DC757EBF0CAD71FBD8E213F1868BBE918F68C31B5F759DE12C0CBDB77F70C6CDFB5E3E0F65D0FA978F7C0F647F6A9F8980AC5058BE41CC2F4E4A5533A140A933F62C80F06DA6E3A863D615B1594';
wwv_flow_imp.g_varchar2_table(6) := '8D035B2B9BEF4250D7C03FF4F9CA045E1040B5B307C62F76CAF43165F4DD45919D22B243A4D827223DC257BB23A06C1CD85AD95C10D435D0A1C95F91438914A48D5EB3A9D2B60400A73F188CEE8FECAB76F6C0F8B361C2737E22A08841100252503385A2';
wwv_flow_imp.g_varchar2_table(7) := '0AC7700D1DDCDEBE3384B622808AD3EF3A06A72F8AA8D1BDD8277C1181D610E8298AEC2C4A6986003268AD19776BB50501C0F1155BEFAE38BD80C9852F229020020119A8EB2C5826B4CBAC20D7045072FC708A8FA95B82F66653442016010C2E3B4AB382';
wwv_flow_imp.g_varchar2_table(8) := '47F6B94E04B11A1899B9248092E3EF0A467C91629FA10F9344C02202C5BE1211ECDA8D6BD262C78975953B02C03A0C537D8500477C0502DF4E20B0435D936A36B0EB2127A4694288DC1000187640DDAB2F8AEC14BE88807B08F4E0DAC41E01AE55F7C48B';
wwv_flow_imp.g_varchar2_table(9) := '97281704807596625875DFBED817AF067389803308F4A86BD589D9402388384F008A51830D974694611922E00802C16CE0E076F797044E138072FEDDCAA0082AE29B08E40B81A2C84ED749C059021850EB7D656E6EF42910F8CE2F022081F240E6A4124E';
wwv_flow_imp.g_varchar2_table(10) := '124009B0629F9388512822D03C023B0E5A5E0E342AA2730450068A237FA31664B95C2050143797034E110076FB01542E2C4A2189409308E0DA2E0F704DD64CAFB83304807BA778AA2A3D55D93211C81E0145023B70AD672F4949026708A0538ADCED2FD9';
wwv_flow_imp.g_varchar2_table(11) := '849FED8D404FDAD77A33F0394100A56951B1AF19C1599608E41781625FE99ACF5E83CC0900D3A1A2081FEF15BE7C42405DF3EACE40F63F34923901B8341DF2E902A4AE9923D05394CECCBF3C94290160D75FA4D897B929280011C804012C05929D0534AB';
wwv_flow_imp.g_varchar2_table(12) := '46A604E00203360B18CB13812411C8DA073223008EFE495E466C2BBF08643B0BC88C008AD2F1ADFC1A8D921381E4102866B81790190128F8F8B8AF02816F22A0F6C1F03B837306A2950632218081EDBBE8FCAD588B75DA15819EAC9E0BC8840094151F52';
wwv_flow_imp.g_varchar2_table(13) := '816F224004CA0814837FA72A1F588CAC134079F4CF6CCA63115B7645049A4140CD02ECDF12B44E0005910DCDA0C2B244C01F043AEE6955D756EB592780ACA63AAD02C47A44C016024529587F28CE3A01283039FD5720F04D046622506C6F0228AFFF67EA';
wwv_flow_imp.g_varchar2_table(14) := 'CD1C22400402044A0FC805492B1FB66700D6D73856506427442021045A7928682E5DDB2600EB539CB980C3BA44C03E0245AB4B64DB04605539FBC6638F44205F08582300FCF047BEA0A1B444201304AC3E0F608D003A659AD3FF4CAE2776DACE08CC5537';
wwv_flow_imp.g_varchar2_table(15) := '6B04A004E506A002816F22501F017B0F04D92480FA7AB30411200252B4F84090450228700390173711700C018B0450240138667C8AE32A028DF94A12D25B24002101085F44A02104ACF98A4D026848731622024440E4A5FB772DB58183150238F48DC757';
wwv_flow_imp.g_varchar2_table(16) := 'DB50867D10817641E0B2650B96D8D0C50A01D850847D10019F10484A5712405248B21D22904304480039341A4526024921608500A626A6AD6C6824050ADB2102592360CB67AC1040D660B27F22D04E0824A90B0920493473D6D6C4F464CE24A6B8492340';
wwv_flow_imp.g_varchar2_table(17) := '02481AD19CB4373A79518E9E3D293F39FB910C8D0DE7446A8A9934022480A411CD417BC3E317E4C4B9D381A493D3538A00CEAA40120800F1EC8304E099C1E1FC83236766683D34461298018A8319498B4402481A5187DB8B3A7FD7E22E41D02293043412';
wwv_flow_imp.g_varchar2_table(18) := 'FEC424004F6C1DE7FCD76FDB2A5BEFB98D24E0C93510A72609200E9536CB1B529B7CE6B41FA33E9C7FC9F265B2A06B2149A0CDECDD8C3A248066D0CA6159ECF60FA9F5BD16DD747E9D4712D048B81DA7211D09200D541D6913CEAF77FB21129CFF677EE9';
wwv_flow_imp.g_varchar2_table(19) := '4EC1C88F6333C491C0D9F1F38236CC724CB717022480F6B267A80D1EF2319D1F2730ED475C2B6812D0E7718BF0D48521415B3A8F717B214002682F7B86DA986B7E64DED2D71B3BF2E39C194002BDBF7C77980512F8E0DCC724811091F64A9000DACB9E81';
wwv_flow_imp.g_varchar2_table(20) := '3627CE9F96D1898B411A1F8D3A3FCA2280046EE8DD8A641034090407FCC80481B43A2501A4856C46ED469DFFEA2DD73534F247C55DBE6E95A0AECE07090C8E0CE943C66D820009A04D0C0935B061678EFC57AE5C2E6B36AFC7A99602EAAEBD7A5D587778';
wwv_flow_imp.g_varchar2_table(21) := '7C4486C72F84C74CE41F011240FE6D1868808D3A73D30F3BFE5BEEBE353837978FB59B7B046DE9363E55B714D1973E669C6F044800F9B65F28FD60E4F9FE7A3BFE61C53A8905E5078574B1D25260E67709F479C6C92390668B248034D1B5D436A6E5E6D4';
wwv_flow_imp.g_varchar2_table(22) := '1F6BF7B87BFDAD8A0312409BBA3EFA1A1AE3B707351E798E490079B69E921DD37173F49FEBBA5F3519FBEEDEB04AD0B63E898784D0B73E669C4F044800F9B45B28B5E9FCC8BCF6B61B11251E300B30DBC65200CF0724DE111BB48A0009C02ADCC9761637';
wwv_flow_imp.g_varchar2_table(23) := 'F587A326DB4BA535B41D7D3E00771E2A25984A1A81B4DB2301A48D708AED63475E378FE9396EDBE9E3B4E2A5DD57542D05F0A8705A7DB1DDF4112001A48F712A3D60F4C7345C37BEE1C64D3A996A8C5980D91764802CA976CAC653438004901AB4E9366C';
wwv_flow_imp.g_varchar2_table(24) := 'AEFDF1B04E92BBFEF524475FE853973367223A8F713E102001E4C34E5552466FC18D5E1895C32FFED06AF8EC74E5B160CC0206F99870958D9238B0D10609C006CA09F7313476B6AAC5CF3F3923B6C3D8C858950C231317F98DC12A44F2714002C8879D42';
wwv_flow_imp.g_varchar2_table(25) := '295D1D69310B881253283413CE22400270D634F18261A4D567B67C659BDCFB47BF9E69800C5A1E53369DC7D86D0448006EDBA74A3AECB663A4D59937FFFE5764F5CF6FCE346CFECD3B65F1CACB0391201B640C0EF83127046C552601D8423A817E862F8D';
wwv_flow_imp.g_varchar2_table(26) := '84AD98236F98994162E1F225B2EEE66BC29E794720842217898E5C484921831FE7C4977034143D7D955FECD17959C59B7EE1E6B06BCC02F874600887F3091280F3262A09684EADBBD7AC94CB6F58533AE1C02764814C5A1453569DC7D84D0448006EDA65';
wwv_flow_imp.g_varchar2_table(27) := '8654C3E395E9FFB55F9AFB0F7DCCE8608E19A64CDC0C9C1B98366B93006CA2DD625FC3919FE1DAF8ABDB5A6C6966B5F133C9FCC41764323703B90C9889B58B39240017AD1291C974A6AB7FFAFAC8D9E60E878F9C9237FEEE59F9FEEF7D57BEF7B53F9327';
wwv_flow_imp.g_varchar2_table(28) := 'FBFF2A48BFB4F309C1B9E65AAB2E6D6E060EF10743AAC171F48804E0A8614CB1CC29F5AA9B7ACC534DA5E1E4CF7CFB1139FCEC4139F7F167615DA44FBCFE63C1399043ABB382D55B37866D5E9A9A08D34CB88B0009C05DDB049261FA8F9DF5E0407D60AA';
wwv_flow_imp.g_varchar2_table(29) := 'ADA2A6DF707E3879BD8A2087E7BFF398B44202576DF962D83C6436672EE109266645C0F64912806DC49BECCF74A2655FB8AAC9DAA5E2479F1C10D3F9D7DCD023B7FFD67DF2A53FFE8D20DCF1DB5F9615D7559C1733828FF6BF53AADCC4279E0930EF068C';
wwv_flow_imp.g_varchar2_table(30) := '4E8C37519B45B34080049005EA4DF4694EFFAFBBAFF9DD7F8CE4AF3CFE5CD8E3B577DC24377DF576B97C6DB774143A82B064F55572EBFD77CAE6BB6E0ECBA10EEA86190D2636DD774B5812BF1B181E30E12402240027CD52110A53697DB4EAA60D3AD970';
wwv_flow_imp.g_varchar2_table(31) := '6C8EE457AE5F291BEFD852B3EEFA9FDD2C28A30BBCFB2F3FD0C986E3EE1B2B330953F6861B6041AB089000ACC2DD5C67E6F41F35F1C00DE266C2E05BC7C2E2EB6EAAFFAB411B7FAAF258EFF9D3D55F3B0E1B9A25119531AAC32C55BD3F95050024802C50';
wwv_flow_imp.g_varchar2_table(32) := '6FB0CF89A9C9B064ABEBFF136A775F37B27445E94B3BFA382EEE5ABE2CCC36EB86990D24B80FD000488E1421013862883831CCD173DDCDF547EFB8364CE2989E9E8E2B5295679631EB5615AA73D0BDA5F27F82758AF274C60890003236C06CDD4F4C4F85';
wwv_flow_imp.g_varchar2_table(33) := 'A797ACBC324C37933089E3CCB18FEB563D7BFC93B08C5937CC6C20B1A0737E58CA24B13093096710200138638A9982980FD32C5A51999ACF2C593BC7248EF70F1E9189B14B350B4F8C8DCB7B0387C3F366DD30B381C48A2D957F24367568A0AAB745B252';
wwv_flow_imp.g_varchar2_table(34) := '9C049015F20DF46BEEA29B0FD93450352CB2E9D77A454FE527C727E4B5A70EC492C0F8E898BCF51F2FCB942A83CAA883BA48371BBA562C0DAB408789E9CA5E4678820927102001386186994244A7CE78C86666A9C6726EF8F26D61C1E1C1CF64DFDFFEBB';
wwv_flow_imp.g_varchar2_table(35) := '1C79EE909C7AE35810DE7BEE3539F0DDA765E8E4E9B0DCDD7FF8B530DD6C62D9E6D55555480055703875400270CA1CF1C2E86FD9C59FAD9F8B91FCF66FFE623813408D0FDF3C2A6F3F3F1084E36FFE18596140D9E8EDBCF0648309CC201A2CCA62192240';
wwv_flow_imp.g_varchar2_table(36) := '02C810FCD9BA366F01767674CE56B4A17320018CEAB33926CE7DF5CF1F14946DA8D1060B99BA3458C5AB62592A4B02C812FD06FB5ED031AFC192B317C3A8FE2B7FFF070227C728BFFE966B05BF2D88347E5D18E75066F6561A3B9B94CC8DF5C652AD2240';
wwv_flow_imp.g_varchar2_table(37) := '026815B994EB4D18B70017957F7537A92EE1E418E5EFDAF975C12F0B238D5F174EAA7DB463CA6CEA82730CEE20400270C716352599D7913F33B57ADBB226083C910A02F9BBB25281C1BD4627A62B3FA8D1D5E23300596AD5D9C14BAB11FCB32E432B656D';
wwv_flow_imp.g_varchar2_table(38) := '811AFDCFEFA83C4D57A3486EB24D32CB8DD09E084A02C881A1A71A7886DF3535C63E3D178AD44E64162AD5260912400E0C396A38530EC40D449C34486B7E02B7318346F99138022480C4214DA6C1BC3BCD041FFFAD7B21B8508004E08215626498DF59B9';
wwv_flow_imp.g_varchar2_table(39) := 'F77FF6E3333125DCCE1AF964D86D01295D8000092080C1ED8FD11C3A9329B349666E23ED9F742400476D3EDF78FA6F727A4A2E25F40F3E36D485AC9059F765EAA2F318BB810009C00D3BCC906270A47ADA3F5D2CCE28E36A4654D60FCED5FF2112577549';
wwv_flow_imp.g_varchar2_table(40) := '4B2E57DA2501B86209438E13E74FCBE8C445234764F8C860D5B1CB079FBF73B24A3CCC067E72F6A3AA3C1EB8810009C00D3B8452C4393F4EC289102719CEBD3B281787CE27D964D056DC6D4BC84F1208E071EA8304E090396A393F443CFDF671448985CF';
wwv_flow_imp.g_varchar2_table(41) := '8F9C94EFFFC92E79EA77FE5A4EBFF85E62EDA2A10B9F7C8E68462009CC8024F30C1240E62628091075FE2B572E97ABB75C573AA93E874F57FECC531DCEF9FDE9DB27C2363E7EBBF2DF0161E61C121FBE7134AC0D1DA08BCE200988682C5C883B5C10C277';
wwv_flow_imp.g_varchar2_table(42) := '19E29C7FCBDDB7CAB2155784D00CBE794C5AF9ABAEB08148626CA8F2A86EE4D49C0E710700F0886F2800000D5F49444154FF2DA81BE9DEB04AAEBDED4621096844DC8A490019DBA396F343AC058B16220AC3D9774E85695713D1078016742D140492809B';
wwv_flow_imp.g_varchar2_table(43) := '162301646897D99C1F62C171CC91F3D3C395693BCEBB18CCA5C5DAAB2B7F10025D4802EE598C0490914DEA39BF16EBCA15CB75523E3D55F9D5DE30D3B1C4C9B7DE0F255AD8D515A691A84502C002E77D08AEE94802C8C02283234355F7F931CA63CD1F27';
wwv_flow_imp.g_varchar2_table(44) := '8AB90F80D1156BECB8722EE44136EC5568594CD9755E1C09E0990760A2CB30B6870009C01ED6414FF8BDFFE1F191208D8FD99C1FE7CD7D00ECA09F39ECEE0335270F1C81C8615862FCD16898A9127124004C86C6F80522058FD53709C02ADC2227CE55A6';
wwv_flow_imp.g_varchar2_table(45) := 'F15D8BBBA4D6C8AFC582B3986BE9A32FBCA14F39179F7CB332FD37658E13147A614F0018E8F367C7CF0BBF46ACD1B0139300ECE01CF4129DE65EBF6D6B905FEF63C5FACA3FED9C524E86A976BD3AB6CF4326F3EFC44D996BC90212D87A4FE55F8B30C319';
wwv_flow_imp.g_varchar2_table(46) := '1A3B5BAB78EEF35D54800460D12A98E6EAEEF0804CAD29B22EA3E33C2C031A9DFE6B9D740C12B8A1B7428423131705CB247D9E71BA089000D2C5376C7D78FC42984662CDE6F5881A0A7012734AEDE232A099E97F54E9A5DD57885E0A6016303A311E2DC2';
wwv_flow_imp.g_varchar2_table(47) := 'E394102001A4046CB4D9E14B958D3FD399A3E56A1D9B536A4CB5D3F8124FADBEEBE54316C8A4CB99B2EABCD9E2055D0B65754FE59901CE0066432BD973248064F1ACD9DAA89ADAEA93CD3A08EA61B9803B0648239CD8F736222782290B4672C8DAAC60E6';
wwv_flow_imp.g_varchar2_table(48) := '2DC34B5395FF4468B61D57CBBB2A1709C08265A2235A2B0E0231BFD0B30651105EFFE7FD4EFC4A1036FF0EFDD3FF0432E1A367CB35889A0ED17D8E28664D37C80A0D2140026808A6B9159A989A9C5B03E5DAD1B5F287FBDF299FC92E8ACAB07CDDAA9684';
wwv_flow_imp.g_varchar2_table(49) := 'C13200B387962AB352CB0890005A86AEB58A73B9C8E124E6087BE4F94399CF025E35467F7337BF15742E5BBC28AC961469860D32118B0009201696F432CD8BBC955E300BD0F5F0B5DBE808ACCFD9888F3D7550B06BAFFB6A75F4D7F5DB3576592F1280CB';
wwv_flow_imp.g_varchar2_table(50) := 'D689910DB300F32E024660ACC3638AA69A853E5F7EECD9B00F53A6309309E7112001386FA29902AEDDDC136662043EFEC25BE1B1AD44B4CF8DB75E6FAB6BF6932002248004C1B4D5146601E67A1B7704702FDE56FFF8652273E7DF94C5960CEC27190448';
wwv_flow_imp.g_varchar2_table(51) := '00C9E068BD15EC05E8E702300B30EFC5A72DCCE1BD2F865D4006AEFD433866245CCF2001B86EA11AF26116B0E1C64DE1598CC883FFFB6E789C5662F8C82979F7F957C3E64D19C24C26728300092037A69A29281E283237DF5EFDDE0B89FE7068B4476CFC';
wwv_flow_imp.g_varchar2_table(52) := '3DF3ED47C26CF40D19C20C2672870009207726AB16785977E59783715BF08314370407FEE699AACEA33FF955759207B9408004900B33C50B79E6C3D37264A0FA0E405A4B014CFDCD2FFC40A2C1E31FCAA977DDFFA152C89A45C8439F24803C5829464638';
wwv_flow_imp.g_varchar2_table(53) := '5ED4F975B1A49702D8F537A7FEBA9FB1913179FFF07B24010D480E6312400E8D76F8C51F068EA7459FD7D129AB172F17C4C8C352E0F9EF3C96D863C2072353FFF5CB56857DA13F900064429A215F0890007264AF4B63E30247FBFC9333A1D470FA354BBA';
wwv_flow_imp.g_varchar2_table(54) := 'E5F2854B04B13E0112883EACA3CF3513BFB4F30931A7FE70FE45F32E930DCBBE50450290E9D5FFFA8140C666DA67D96C112001648B7FC3BDC3B106FEF34581A3E94A8BE65F26D75CF1458143220F717757655310FB01479F1CC0A99602EA9ACE8FB6D107';
wwv_flow_imp.g_varchar2_table(55) := '1A9BDF312F2001C88063042C09DE3A7088242022C0230F810490032B5D38734EE0FCA6A870BCF54B677EF5F6F2858B05E774D9571E7F4EA2BFD7A7CFCD1663D30F757519B4D9DD75B93E0C629000961E208620437D6812C01E853AE4DB710448008E1B08';
wwv_flow_imp.g_varchar2_table(56) := '3BFDAFEFAF1EC5E17071CE0F55B4536269806384037FF9A4FCDF9FFEABE0DB7B785808E1FCE9CAAFEF228D3C049005A6FDE6A61FDA9AAD3F100364425F082001DE210012EE071280C336C2281ADDE9C71A1C0E379BD82081E81AFDFDD77E24F8F6DEBEBF';
wwv_flow_imp.g_varchar2_table(57) := 'F8374130A7F648230F01648163DD3E9C7F8DDA63D0C7B562C81425016C0E42875A75989F3D022480EC6D102B0136FBE040FA241C11CEAFD7E03ABF56AC490053F75A65EAE5A3AEB9C750AF3C4860D3156BAB3607A10374A957B79DCEE74917128063D6C2';
wwv_flow_imp.g_varchar2_table(58) := '661F1CC6DCEC83F363146ED4F9B54A2081D5EAF62082DE1B805323A04D5D0E69E4E980911C64536BDAAFEBC5C5E8333AFB802EBC43108756F6792480EC6D104A00E7C7661F1C4667C2299B1985753D1DC321718B70F5E26E8143EBB058DD41D06590D6F9';
wwv_flow_imp.g_varchar2_table(59) := '883192374B36BA2DC4E8132400D9718C807D01DE2100126E05128023F6C0661F9CDF14070E048734F3F292060960E681D98496599300F7053422D9C724800C6D80111F8E8F297F74B30F8E9357E7D7908204309B802E3A0F24807D012C09A03B6E71EA73';
wwv_flow_imp.g_varchar2_table(60) := 'ED10E74D071280658B617AFFD293FF2D0818F1E1F8C833C5C0FA1B8E63E6E5390D5D4C12802E2002E88E5B9CC002218A03CA31A48B0009205D7C83D6E777CE0BE27A1F98F263177D2EEBEF7A7D64751E2400DDB01999950CEC77260224809998249E83A9';
wwv_flow_imp.g_varchar2_table(61) := '3076DAE31A463E1C1FA33EA6FC281B572EE93C6C0CA24DF4AFD3384E3340B7603372D92A011140EFB8FE6CCA14D7BF4F7924000BD6C6858F5DF1C0C9D5C5AFE3CD576D089EE587E3DB1EF5D11F46E4B9DC6168153AF41D10C1D2550219341E3A864CADB6';
wwv_flow_imp.g_varchar2_table(62) := '9D65BD3CF64D02B0643590002E7C3358EABA663790A9E6494B2720838909D296BA66370A012B04D039BFE3BCEA8B6F2240041C43C00A0138A633C52102CE23606BD02401387F2950C03C20905719490079B51CE5260209206085002E9EBB74210159D904';
wwv_flow_imp.g_varchar2_table(63) := '11F006015B3E638500BCB11A1525023943C00A01DCF5743FEF02E4ECC2A0B88D239046495B3E638500CA001D2FC78C880011981D016BBE6291000AD6949A1D5B9E2502AE2360CF572C1280EBA0533E22E00A02456B83A53502284871BF2BF0520E229014';
wwv_flow_imp.g_varchar2_table(64) := '02796FC71A01884C1FC83B58949F085842C09AAF5823804999676D5A63C948EC8608A482C09474589B2D77A4A2011B250244A065047E6EEF03D6064B6B045052AA608DD95A469F1589408308A453CCAE8F5823801258456BCC56EA8F9F44206F08D8F511';
wwv_flow_imp.g_varchar2_table(65) := 'AB045090E947F3660ECA4B042C23606D03107A5925006E0402720622501B019B1B8090C22A01701F009033B4030229E9B0A7E42329B51ED3AC550240FF053E1004181888C00C040A22D6F7C8AC13001F0812BE88400D04A6ADAEFF21847502D8B6F777D5';
wwv_flow_imp.g_varchar2_table(66) := 'ADC0820AE89E810810813202C74BBE513EB214592780925E45DE0D2801C1CF1C229092C80FA7D4EEACCD664200B6773A674580278980030864E51399104069A793CB0007AE3B8AE00602D677FFB5DA9910003A2FC85426531EF4CD40045C42A090E10372';
wwv_flow_imp.g_varchar2_table(67) := '99114069C383B300972E44CA521F81E44B14F6977C21F9961B69313302807053527800310311F01581AC67C2991200F7027CBDECA97719813D598EFE9021530280009C050005061F11503BFF99EF83654E00A559807029E0A307E44CE724C52D88EC2C5F';
wwv_flow_imp.g_varchar2_table(68) := 'FB4936DB745B99130024EEDDDBBF47A4C0A703852F3F10C0C65F7FE6A33FB0768200200897024081C107045CBAD69D2180F274884B011F3CC0631DD53DFF7BCBD7BA132838430040034B81825A1B21CD40045C422021591ED8167C192EA1D61268C62902';
wwv_flow_imp.g_varchar2_table(69) := '803EDBF6F63F4C1200120C6D86C09EDE60AFCB2DAD9C2300C033291D8F92048004437B2050D8AF9CDFC9E5AD930480351249A03D2E7D6A216AE47FF05E577170920000164880CB0120C1903502ADF68F59ACAB23BFD6C95902D002820454DAC9E993928B';
wwv_flow_imp.g_varchar2_table(70) := '6F22108B0076FBCBD76EEC7957329D270000A55874CF94746C143E2C247CB98E40613FAED56D8EEDF6D7422D170400E1B124E8DDFBE0BD9856E1988108B88600AE4D5CA3B8565D93AD963CB92100AD00A655605875BC4705BE8940AA0834D6B81EF5FB9D';
wwv_flow_imp.g_varchar2_table(71) := '78BCB731994BA5724700101B0CDBBBB7FF011201D060C80E8192E3F7AA9929AEC9ECE468BDE75C12805617A0F79208341C8CED21B0079B7CBD39767C0D55AE09402B611201D661C2CD42E12B71048EE3DAEADDDB5F50C1B9477A5BD5B62D08402B0F22C0';
wwv_flow_imp.g_varchar2_table(72) := '1E41AF62662C0F60302119085FAD21A06A054E5F1AEDFB37E2DA52796DF56E2B02302D132503750ECF12A88DC3027F774081C1772C026587979DBDA5913E70FA6D39B9A517AB519DCCB62500536F9041EFDEFE3D2A3CD05B9E1D6086A0CA944941343158';
wwv_flow_imp.g_varchar2_table(73) := 'FF7346E1CB3602CAC6C120A0D6F1B2B32008D3F7F656397CFE76F3A5C597170410C5068480A08C5E2685FE8018D4F146150A9746651942C7BC056B742816E75DCF901F0CB4DD740CBB9683B2F1837078B58EEF7F18D3FA6D6D3CC247AFFDE8B197041005';
wwv_flow_imp.g_varchar2_table(74) := '217A7CD7D3FDE7116EFBC76F0EEA70FB13DF7A8F213F1868BBE9386AE37AC7BE9C2701F86269EA490462102001C480C22C22E00B0224005F2C4D3D89400C022480185098E537023E694F02F0C9DAD49508441020014400E12111F0090112804FD6A6AE44';
wwv_flow_imp.g_varchar2_table(75) := '208200092002080FFD46C037ED4900BE599CFA12010301128001069344C037044800BE599CFA1201030112800106937E23E0A3F624001FAD4E9D89401901124019084644C0470448003E5A9D3A13813202248032108CFC46C057ED4900BE5A9E7A130185';
wwv_flow_imp.g_varchar2_table(76) := '00094081C03711F015011280AF96A7DE44402140025020F0ED37023E6B4F02F0D9FAD4DD7B044800DE5F0204C0670448003E5B9FBA7B8F0009C0FB4BC06F007CD7FEFF010000FFFF1E58B12D00000006494441540300434F9CB522FAD455000000004945';
wwv_flow_imp.g_varchar2_table(77) := '4E44AE426082';
wwv_flow_imp_shared.create_app_static_file(
 p_id=>wwv_flow_imp.id(32864013752450426)
,p_file_name=>'icons/app-icon-256-rounded.png'
,p_mime_type=>'image/png'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/files/icons_app_icon_32_png
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7AF400000200494441547801EC943B4FE34010C7FFF8F2C0398B189CC33AC45DD0E9C4E9EE9A3B28A0A6E11B20A8F822B4B4749434D44083441D9040228886B790507829A0';
wwv_flow_imp.g_varchar2_table(2) := '400093880427B1C92C384A1AB2EBF090902DCDCEEE7FC7333F8FBD96E2C353F67B9A8477BE3C00AF035E071AEAC065CE80719F6DE820BB06A0E29D7DDD50FF7F6F08C21540C12AA2E5473B14AD059AAE41EED2401A5C5CAE008E6ECF59A9E4DE31C86891';
wwv_flow_imp.g_varchar2_table(3) := '2C5CB9821006A0271D1C1F45FFF8508D0D8C8DBC0D8015F623FCBB831E1A7BD34BCCEED359A6D96A80E9228324124CB1EA9FC7E2C66E123EBF0FA8CA10F9FB8D4284ACEA76BEFB021185055217BEFCEBC2D7DE9F086A8F9A6915D89EC8200C904D5D57F2';
wwv_flow_imp.g_varchar2_table(4) := '1304992328EDADCE94DB0B01DC15F3308D5C2539BD7B324738DB4C80629C358FE706A0AFBFAD278A52C68453349FBA059953A8295344B05B1382E006C885C07E3C91A8EED4ABF104A5FFEA841EED403E64D7EC3DB7E006686EFDCCF204E420D626E62B5D';
wwv_flow_imp.g_varchar2_table(5) := '606279589B5C00ED95A76550951C97710354672BE54C9CC6762AD2C16C1C4D86F809A004C200FBCB1BF87469E260268E93C51D1CC636713CB70EFBE20EA9FD53946C8BF2721B3740367D83C3C56DB4993242BE6644E4306E5612C8AF26110E2A4C2B9D64';
wwv_flow_imp.g_varchar2_table(6) := '90886DE1FA22FDF2005458B102358909C42F95FF864F2ACD55C8D08BCA9352DF49F5435E37C203F03AF0F13B50EF0C3D000000FFFF15E629E5000000064944415403003A380610486170610000000049454E44AE426082';
wwv_flow_imp_shared.create_app_static_file(
 p_id=>wwv_flow_imp.id(32863150758450421)
,p_file_name=>'icons/app-icon-32.png'
,p_mime_type=>'image/png'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/files/icons_app_icon_512_png
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '89504E470D0A1A0A0000000D4948445200000200000002000806000000F478D4FA00001000494441547801ECDD6B8C5EC77DDFF10929925ADE2FCBA578BF492245EA6A59921DDBB2DADA928106A811374D61C06951B781DBA26883F68DE122308A00E98B';
wwv_flow_imp.g_varchar2_table(2) := '368D61D42E0A24706DC4819D285080D88D2CC59225FA464B11659922234AB2BDA244915AD25CDEA925E9ECEFA11E72B97B9E9939F799335F41CFEEB367E6CC99FF671EF0FCCF3973CE336BF73FFFA35FF2C280CF009F013E037C06F80CA4F5199865F80F';
wwv_flow_imp.g_varchar2_table(3) := '01041040000104121330860420B92127600410400001044800F80C208000020820909C8002E60C801478218000020820909800094062034EB80820800002A90B5C8E9F04E0B2033F114000010410484A800420A9E126580410400081D405FAF19300F425';
wwv_flow_imp.g_varchar2_table(4) := 'F88D00020820804042022400090D36A12280000208A42E70357E1280AB16BC430001041040201901128064869A4011400001045217981A3F09C0540DDE238000020820908800094022034D980820800002A90B5C1B3F09C0B51EFC850002082080401202';
wwv_flow_imp.g_varchar2_table(5) := '2400490C33412280000208A42E303D7E1280E922FC8D00020820804002022400090C32212280000208A42E30337E128099262C410001041040A0F30224009D1F62024400010410485D202B7E12802C1596218000020820D0710112808E0F30E121800002';
wwv_flow_imp.g_varchar2_table(6) := '08A42E901D3F0940B60B4B114000010410E8B4000940A78797E01040000104521718143F09C0201996238000020820D0610112800E0F2EA12180000208A42E30387E1280C13694208000020820D059011280CE0E2D812180000208A42E608B9F04C0A643';
wwv_flow_imp.g_varchar2_table(7) := '190208208000021D152001E8E8C012160208208040EA02F6F84900EC3E94228000020820D0490112804E0E2B412180000208A42EE08A9F04C02544390208208000021D142001E8E0A012120208208040EA02EEF84900DC46D4400001041040A073022400';
wwv_flow_imp.g_varchar2_table(8) := '9D1B52024200010410485DC0277E12001F25EA208000020820D0310112808E0D28E12080000208A42EE0173F09809F13B5104000010410E894000940A786936010400001045217F08D9F04C0578A7A08208000020874488004A0438349280820800002A9';
wwv_flow_imp.g_varchar2_table(9) := '0BF8C74F02E06F454D0410400001043A234002D099A124100410400081D405F2C44F0290478BBA08208000020874448004A0230349180820800002A90BE48B9F04209F17B5114000010410E8840009402786912010400001045217C81B3F09405E31EA23';
wwv_flow_imp.g_varchar2_table(10) := '8000020820D0010112800E0C22212080000208A42E903F7E1280FC66AC81000208208040F4022400D10F21012080000208A42E50247E1280226AAC83000208208040E4022400910F20DD4700010410485DA058FC2400C5DC580B010410400081A8054800';
wwv_flow_imp.g_varchar2_table(11) := 'A21E3E3A8F0002082090BA40D1F849008ACAB11E020820800002110B9000443C78741D01041040207581E2F1930014B7634D041040000104A21520018876E8E8380208208040EA0265E2270128A3C7BA082080000208442A400210E9C0D16D0410400081';
wwv_flow_imp.g_varchar2_table(12) := 'D405CAC54F0250CE8FB51140000104108852800420CA61A3D30820800002A90B948D9F04A0AC20EB23800002082010A10009408483469711400001045217281F3F094079435A400001041040203A011280E8868C0E2380000208A42E5045FC24005528D2';
wwv_flow_imp.g_varchar2_table(13) := '06020820800002910990004436607417010410402075816AE22701A8C69156104000010410884A800420AAE1A2B30820800002A90B54153F09405592B48300020820804044022400110D165D4500010410485DA0BAF84900AAB3A425041040000104A211';
wwv_flow_imp.g_varchar2_table(14) := '20018866A8E8280208208040EA0255C64F0250A5266D21800002082010890009402403453711400001045217A8367E12806A3D690D01041040008128044800A218263A890002082090BA40D5F19300542D4A7B0820800002084420400210C120D1450410';
wwv_flow_imp.g_varchar2_table(15) := '400081D405AA8F9F04A07A535A4400010410402078011280E087880E2280000208A42E5047FC240075A8D226020820800002810B9000043E40740F010410402075817AE22701A8C79556114000010410085A800420E8E1A1730820800002A90BD4153F09';
wwv_flow_imp.g_varchar2_table(16) := '405DB2B48B000208208040C0022400010F0E5D4300010410485DA0BEF84900EAB3A56504104000010482152001087668E8180208208040EA0275C64F0250A72E6D23800002082010A8000940A00343B710400001045217A8377E12807A7D691D01041040';
wwv_flow_imp.g_varchar2_table(17) := '008120054800821C163A850002082090BA40DDF19300D42D4CFB0820800002080428400210E0A0D0250410400081D405EA8F9F04A07E63B68000020820804070022400C10D091D4200010410485DA089F849009A50661B0820800002080426400210D880';
wwv_flow_imp.g_varchar2_table(18) := 'D01D0410400081D4059A899F04A01967B68200020820804050022400410D079D4100010410485DA0A9F849009A92663B0820800002080424400210D060D0150410400081D4059A8B9F04A0396BB68400020820804030022400C10C051D4100010410485D';
wwv_flow_imp.g_varchar2_table(19) := 'A0C9F849009AD4665B0820800002080422400210C840D00D0410400081D4059A8D9F04A0596FB68600020820804010022400410C039D4000010410485DA0E9F849009A16677B0820800002080420400210C020D0050410400081D4059A8F9F04A07973B6';
wwv_flow_imp.g_varchar2_table(20) := '88000208208040EB022400AD0F011D4000010410485DA08DF84900DA50679B082080000208B42C4002D0F200B0790410400081D405DA899F04A01D77B68A000208208040AB022400ADF2B3710410400081D405DA8A9F04A02D79B68B0002082080408B02';
wwv_flow_imp.g_varchar2_table(21) := '24002DE2B3690410400081D405DA8B9F04A03D7BB68C0002082080406B022400ADD1B3610410400081D405DA8C9F04A04D7DB68D0002082080404B0224002DC1B3590410400081D405DA8D9F04A05D7FB68E0002082080402B022400ADB0B35104104000';
wwv_flow_imp.g_varchar2_table(22) := '81D405DA8E9F04A0ED1160FB08342C3071E98239747ACCBC7CFC60EF357AF2B0D1B286BBC1E61040A065011280960780CD23D0A4C0990BE7CC2BC75F37E3E74F9B0B972EF65E67262E2F2309687224D81602ED0B9000B43F06F400814604B4F31F3D7178';
wwv_flow_imp.g_varchar2_table(23) := 'E0B62E2706A7069653800002DD122001E8D678120D029902AE9D7F7FA543A78F4E9E1D2009E87BF01B81BA0442689704208451A00F08D428307EFE94B11DF94FDFB49280B1B3E3D317F3370208744C8004A063034A38084C15D08E5C3BF4A9CB7CDE8F9D';
wwv_flow_imp.g_varchar2_table(24) := '3D6EC648027CA8A8834001813056210108631CE80502950B1C3A3D36B9133F5EB8DD319280C276AC88400C022400318C127D4420A7806EED1B3F7F3AE75A33ABF79300EE109869C312048A0A84B21E09402823413F10A848403B7FDDDA575173BDB3084A';
wwv_flow_imp.g_varchar2_table(25) := '264802AA12A51D04C210200108631CE805029508E4D9F90F2D18327AF96C58670248027CA4A883804B209C72128070C6829E20504A40D7FC7D8FFC978DAC30777FE47DE6CE07EE350B8797786DB79F047855A6120208042F400210FC10D14104DC02DAF9';
wwv_flow_imp.g_varchar2_table(26) := 'EB08DD5DD318EDFC777EE0AE5ED5D9D7CF31B7DD7767AE24608CBB037A76FC40A0884048EB900084341AF4058102024577FEFD4D9104F425F88D405A022400698D37D1764CA0ECCEBFCF4112D097E03702750A84D536094058E3416F10F016A86AE7DFDF';
wwv_flow_imp.g_varchar2_table(27) := '2049405F82DF08A421400290C6381365C704C6CF9F32E39EF7F94FBDE6EF6220097009518E407181D0D62401086D44E80F020E017DB1CFA1D3471DB52E17E7D9F95F5EC3982249C0F86442D25F9FDF082010870009401CE3442F11E80968E7EFFBC53E45';
wwv_flow_imp.g_varchar2_table(28) := '76FEBD8D4CFEE827011B766C99FCCBFDBF12121E14E476A246CA02E1C54E0210DE98D023043205B4836D62E7DFDFB89280B59BD71BDF24E095E3AF1BF5B1BF3EBF1140206C011280B0C787DE21D013D08E553BD8DE1F8E1F658EFCA7379D3709F8F98937';
wwv_flow_imp.g_varchar2_table(29) := '4902A623F23702C69810114800421C15FA84C01401EDFC758A7DCAA2816FABDCF9F737D24F027C9E1878E1D2454312D097E33702610B9000843D3EF40E01A39DBFCF237EF55CFFFE13FEAA665312B0E3DEDBBDBE3B404980FAACC4A5EA7ED01E02710A84';
wwv_flow_imp.g_varchar2_table(30) := 'D96B128030C7855E21D01338747ACCF8ECFCAF9B35DB6CBBE7B6DE3A75FD983B34CFDCF6C1771B251AAE6DA8CFE39EB729BADAA21C0104EA112001A8C7955611282DA067EEFBEE446FBDFF6EB370C5E2D2DB743530773209D871FF5D460987ABEED8D9E3';
wwv_flow_imp.g_varchar2_table(31) := '668CEF0D7031519E8040A8219200843A32F42B6901DDEE3736B903F541E87DA35F033BFF7E5F86E6CF379BDFB5ADFFA7F5B762E05280958842045A132001688D9E0D23902DA01DA6EFED7E5B76DEDCC891FFF49EAEDAB8C668DBD39767FDCDA4C02C1596';
wwv_flow_imp.g_varchar2_table(32) := 'A523106EA42400E18E0D3D4B54E090E753FE466E18316BB66F684D49DBF6490234299024A0B56162C3080C1420011848430102CD0B8C9E3CEC35E96FD9C80A73F3FB6E376DFFB76AD36AE37B7BA0EF7C86B66362FB08542910725B2400218F0E7D4B4A60';
wwv_flow_imp.g_varchar2_table(33) := 'ECECB8D7CE5FB3F0EBBADD2F2FB86E0FBCEDBE3B8DFAE45A77EC2C93025D469423D0A400094093DA6C0B810102BE93FEB4A3D5AD78039A6965712F09F0BC3D504980E638B4D251368A40E302616F900420ECF1A17709086887E83BE94FF7FACF1D9A179C';
wwv_flow_imp.g_varchar2_table(34) := '8AFAA4C4C4E7F640E60304377C74285101128044079EB0C311F09DF4D7F4ED7E79859404F8DC1EA84981CC07C8AB4BFD180542EF330940E82344FF3A2D30E679DD5F33FE9B78D04F596CDFDB03C7980F50969AF511282D4002509A9006102826A053FFDA';
wwv_flow_imp.g_varchar2_table(35) := '11BAD6D675FF1066FCBBFAD92FD79D01EA73FFEF41BF15BB0C0695B31C81B805C2EF3D0940F863440F3B2AA06BE13EA1E9BABF4FBD50EAF42705321F209411A11F08640B900064BBB014815A050E9D1E33BA16EEDAC896969EF4E7EA97AB9CF9002E21CA';
wwv_flow_imp.g_varchar2_table(36) := 'BB2E10437C2400318C127DEC94C0F8F95366DCE39BF2F4B01F3D6D2FD6E0351F4031B8FAAF4B016367C75DD5284700818A0548002A06A539046C02BAE67DC8E351BFBA861ECAC37E6CF1B8CA6E7AF70EA3585CF5C6CE1E37B271D5A31C813804E2E82509';
wwv_flow_imp.g_varchar2_table(37) := '401CE3442F3B22E0B3F357A8B15DF7579FB35E7387E699AD77EF303EF3017CCE8A646D83650820504C8004A0981B6B21905B404FFB3B3371CEB95EACD7FD0705B674E532B3E196AD838AAF2CD75980F1C9CB235716F00681480562E93609402C23453FA3';
wwv_flow_imp.g_varchar2_table(38) := '16D0E96D9FA7FDE99A79CCD7FD070D926E0DF4F9D2A0B7B814308890E508542E40025039290D223053C0E7D4BF4E93EB9AF9CCB5E35FA25B0377DC7BBBF35280EE8C18F7982019BF08117457209EC84800E2192B7A1AA980EFA9FF5BEFBFDBE89A79A461';
wwv_flow_imp.g_varchar2_table(39) := '3ABBADD87C1E15AC4B013273364805041028254002508A8F9511B00BF89EFA5FBB65BD89E151BFF668DDA5BA3570E3D6CDCE8A6F9C1AE3AE00A71215421488A94F2400318D167D8D4EC0E774B64EFD6FBE6B5B74B115EDF0AA6DEBB81450148FF510A850';
wwv_flow_imp.g_varchar2_table(40) := '8004A0424C9A4260AA808EFE753A7BEAB2ACF73EA7C5B3D68B75599E4B01328C354EFA9DA2405C319300C4355EF43622019F897F9A19AFD3E2118555495715B3627735E663E86A83720410C8162001C876612902A504C6CF9F323EF7FCDF786B3AA7FEA7';
wwv_flow_imp.g_varchar2_table(41) := '836EBB67A7F352800C65397D5DFE46204481D8FA440210DB88D1DF28047C8E5C35192E85897F83066C68FE7CAF0704F16C8041822C47A09C000940393FD6466086C098C717DB68E2DFFA3BDD4FC79BD178C716ACDAB4DAB8BE2B806703746CD03B1B4E7C';
wwv_flow_imp.g_varchar2_table(42) := '819100C43766F43860014D5A1B3B7BDCD9C3EDEFBFD35927850A7A40D0BA5BDCB705CA54B65EB67941000010004944415429981023024D0990003425CD769210F039F5AFC7FDEAF9F849807804E93B21709C27047A6852A52D8118B74B0210E3A8D1E720';
wwv_flow_imp.g_varchar2_table(43) := '057484AA496BAECE6DD97993AB4A72E53E8F09E62C40721F0B02AE598004A066609A4F47C0E7E85FDFF437B47C613A289E91CE1D9AE73521D0C7D873935443A04281389B22018873DCE87560027A76BDEBE85F93DDBAF84D7F550D85CF844019CBBAAA6D';
wwv_flow_imp.g_varchar2_table(44) := 'D20E02290B9000A43CFAC45E99809E5DEF6A6CDB3DB7B9AA245DAE09815BEFDEE13418F3B8CBC2D9081510A85020D6A64800621D39FA1D8C808E4875AB9AAB437B9EDC6D763DFC382F8BC14F9E7AD6C5D87BC0D2F8F953CE7A54400001BB000980DD8752';
wwv_flow_imp.g_varchar2_table(45) := '049C023E47FFCE46A8904B60FCEDD3B9EA531981FA04E26D990420DEB1A3E70108E848D4E7E83F80AE76AA0B9A0B20FB4E05453008342C4002D030389BEB96801E53DBAD88E28946F6BAF5329E1ED3D32E0AC41C130940CCA347DF5B15D064348EFEDB1B';
wwv_flow_imp.g_varchar2_table(46) := '02D9EB4C407B3D60CB08C42D400210F7F8D1FB16058E9F3FD9E2D6D9B404980B20055EED09C4BD651280B8C78FDEB724A053CF3A026D69F36CF61D019D01D058BCF327BF104020870009400E2CAA22D01718F3F8C29F7E5D7ED72BC058D4EB4BEB830562';
wwv_flow_imp.g_varchar2_table(47) := '2F2101887D04E97FE3023AE21C777C31CD7D9F78D07CFC91FFCAAB02839D0FDD631D638D85C6C45A89420410982140023083840508D805B4C3B1D73066DD03EE27DAB9DAA0FCB2C0A607DC4F50F41993CBADF11381AA04E26F870420FE312482060574A4';
wwv_flow_imp.g_varchar2_table(48) := 'E93AE5BCF886E566DE0ABEF0A7AA615972CB1A23535B7B1A138D8DAD0E65082070AD0009C0B51EFC858055C0E748F3EE8FFF436B1B14E617F8C07FFCA873259FB171364205043C05BA508D04A00BA3480C8D09E848D3B6311DA9AEBE7FBBAD0A65050438';
wwv_flow_imp.g_varchar2_table(49) := '0B50008D55107008900038802846A02F30EEF10534B77CF8DDFDEAFCAE58C0C756B70556BC599A432043A01B8B4800BA318E44D18080BEF5CFB6191DFD6FFDD8BDB62A94951090AD8C6D4DB8C6C8B62E6508A426400290DA88136F21014D301B77DCFAE7';
wwv_flow_imp.g_varchar2_table(50) := '73845A68E3AC7445C065AC31D2585D59813708D420D095264900BA3292C451AB80762CAE0DE808D55587F27202BABDD27516C067ACCAF582B511E88600094037C691286A16703DF7DFB553AAB97BC934AFDB2BD7DFB1D51AAF6BACAC2B53888053A03B15';
wwv_flow_imp.g_varchar2_table(51) := '4800BA3396445293804E29BB9EFBCFAD7F35E167343BB27363C6D2AB8B34561AB3AB4B7887000259022400592A2C43608A80EB94B28EFEB9F56F0A58CD6F652D73DB665CB76BDAD6A50C019B4097CA4800BA349AC452B9808E245D3B13D7C4B4CA3B4583';
wwv_flow_imp.g_varchar2_table(52) := 'C665AEA44D63071502080C162001186C430902463B12178326A6B9EA505EADC0F08E75CE0679268093880AB905BAB5020940B7C693682A1698B834616D51A7A23531CD5A89C2CA057C9E0CC833012A67A7C18E099000746C4009A73A019D42769D01709D';
wwv_flow_imp.g_varchar2_table(53) := '8AAEAE37B4345DC035F15263A7319CBE1E7F235054A06BEB9100746D4489A732019F9D474CF7FEBFFE9D7DE6F92F3E6A767DF66BE6AF3EF505F3D58FFE9EF9FAAFFF7EEFBD96FDE0BFFD9939F4D47E736EEC6465867536E4331990CB00758E006DC72E40';
wwv_flow_imp.g_varchar2_table(54) := '0210FB08D2FFDA04CE4C9CB7B6ADD3FFD60A0114BEF2F0EEDE0E5E3BFBEFFCAF87CDDE477F6446F71C3027DE3CD6EB9D6E99D37B2D7BF56FFFCE3CF1077F6EFEE25F7FCE3CF1BB7F629430BC7DF454AF5EA83F96DEB0C2DA352E03587928CC25D0BDCA24';
wwv_flow_imp.g_varchar2_table(55) := '00DD1B5322AA4820E6D9FFDAF16BA7FFC3AF7CEBCACE3E0FCBA11FFFD4286178E4DF7C3EE84460F56D9BAD617119C0CA4361E2022400897F00083F5BC0E7C831C4D3FFE3FBDE307FF9DB9F37DAF16747966FA9CE102811F8D667BEDC4B04F2AD5D7F6D9F';
wwv_flow_imp.g_varchar2_table(56) := '3B30CE4C9CABBF236CA1F3025D0C9004A08BA34A4CA505CE4478FA5F47FDDFF8F41F9BD347C64BC73FBD015D26F8EEE71E31DAC6F4B236FFD61D18AE4B313EC95C9B31B06D04DA122001684B9EED062D10DBE9FF5D9FFD5A6547FD830646670374664149';
wwv_flow_imp.g_varchar2_table(57) := '404873035C7762E832C0A098588E809F40376B910074735C89AA8480CFEC7F9F53CF25BA906B55EDFC35892FD74A252A2B09F8D9B75F28D142B5ABFA3C14C8674CABED15AD2110BE000940F863440F1B16701D31EA94B34E3D37DCADCCCDE968BCC99D7F';
wwv_flow_imp.g_varchar2_table(58) := 'BF13CFFCC9DF047339C0EBA140CC03E80F1DBF0B087475151280AE8E2C711516705D33769D722EBCE19C2B6AC29F8EC67D575B34B2D4DC72FFBBCC7B3FFE61F30FFEFD47CD83FFE537CD87FEF36FF4DE6BD9CDEFBFDDA88E6F7BCF4E2601EA836FFD3AEB';
wwv_flow_imp.g_varchar2_table(59) := 'ADBF63ABB5F9F1B74F5BCB2944204501128014479D98AD02671C478B3EA79CAD1BA8A050D7E01FFDCCFFF36A69E1F01273D747DF6FDEFB5B0F99F5F7DE6416AD596EE60CCDEBAD3BEB5766F5DE6BD9A6F7DC62EEFBC4877B75B58E71FCA739014F7FEE11';
wwv_flow_imp.g_varchar2_table(60) := 'A3BE38AAD65EECFA8A608D2997016A1F868E6EA0BB61910074776C89AC8080CF4E42A79C0B345DE92AAF3DF9A2D10ED8D5E8FA3B6F34BFFA2F3F6256DEB8D655B557AE844075DFF32F1E3437DDBDA3B7CCF643770784301FC0E7A980B638284320450112';
wwv_flow_imp.g_varchar2_table(61) := '8014479D98070AF85CFF1FB87243053AE2F639F57FE37B6F35B77CE8EE42BD5222B0F1819D66FBAFDEE15C7FCF9F3E19C4590057475D63EB5A9FF23405BA1C350940974797D8720BC470FD5F47FFAEC074E4BFE57D3B5DD5ACE54A02D6BDF766A3B66C15';
wwv_flow_imp.g_varchar2_table(62) := '7526C2A74FB636AA2873CD03708D6D157DA00D04621220018869B4E86BED02BA566CDB4808D7FFF73DF68CAD8B6668C5A2C247FED31B5612B0ED1FDD655C7302469F3F307DD5C6FFDEF4C06DD66D6A6C7D2EF1581BA13031816E874B02D0EDF125BA1C02';
wwv_flow_imp.g_varchar2_table(63) := '3E3B87B6AFFFEBF4BFAEBBDBC2DA79FF5DB6E2DC654A02B67FC07E2940DF1DD0F6B7086A6C748B66EE0059018144054800121D78C29E29E0BA461CC2CE45DFD037B3E75797CC1F5E6C966F5D7D754145EF966E596596DFB0D2DADAD1BD07ADE54D143ABF';
wwv_flow_imp.g_varchar2_table(64) := '1DD0718747137D641BF10874BDA724005D1F61E2AB4C2084FBFF4F1C3E668D67DDF64DD6F2A2853A0BB0EAE6F5D6D50FFFE467D6F2260A17AD5A6ADD0CF300AC3C142626400290D88013EE608118760E270F1F1F1CC064C9B275F6A3F4C92A85FF5FBA6E';
wwv_flow_imp.g_varchar2_table(65) := '8575DD336F9DB0963751E87A1EC0C4A58B4D74836D7442A0FB419000747F8C89D04360E2D205A34962B6AA5B3F76AFADB891B2E36F1EB56E67FE8A45D6F23285D72F5B605DDDD537EBCA1515CE5FB9D8DA92C658636DAD442102890890002432D084594E';
wwv_flow_imp.g_varchar2_table(66) := '2084EBFF8AC03501B0FF843FD5ADFA35FBFA39D626CFD4F035C4D60D6614FA4C042401C88063D10C8114169000A430CAC4E814183F6F7F56BC6B7299730315555830B2A4A296F237A37900B6B5E60D2FB4153756E61AAB898B171AEB0B1B422064011280';
wwv_flow_imp.g_varchar2_table(67) := '904787BE0523B0FAB6CD41F465F6ACD9D67E4C9C3D6F2D2F53E86ADBD5B732DBCEB32E1301F36851375B208DA52400698C33513A045C13005DD7961DCD5756EC3ABA3DF70BFB998C321D393D76D2BABAAB6FD6952B2C642260859834D5690112804E0F2F';
wwv_flow_imp.g_varchar2_table(68) := 'C1F90A687298ADEEF29DEB6CC58D95B91291A3A3876BEBCBF1D78F58DB761D795B57AEB0D065E41AEB0ABB4253910AA4D26D128054469A38070AF84C0A9BB7228CEBDBAE4B11875E1A1D1867D982375F7ACDDAC4E255CBADE54D153211B02969B613BB00';
wwv_flow_imp.g_varchar2_table(69) := '0940EC2348FF4B0BB8128050EE0050A0AE4980278F1C37C75E39A4AA95BE8EBEFC863931D9B6ADD1CDBF7E8FAD38A832D79807D5593AD3B0403A9B23014867AC897480C09909FBC4B950AE6DABFB8BB7AF36C36B46F476E06BFFD3CF0F2C2B5AF0D2777F';
wwv_flow_imp.g_varchar2_table(70) := '6C5DD595985857AEA1D03566DC0950033A4D4627400210DD90D1E1A6055CA7DD9BEECF4D1FB27FD9CFA9B171B3EFF1672BEBD6BEC79E3527DF1AB7B677EB43F759CB9B2E74CD47704DFA6CBABF6C2F1C81947A420290D268136BA6406C3B039D6A771D71';
wwv_flow_imp.g_varchar2_table(71) := 'BFB6E76533FABDFD99F1E659F8EAAE9F98D79E7FD9BA8AFA12C25312A776D27527C0D4BABC47205501128054479EB8BD058677847107C0D40EDFFE91F74CFD33F3FDFEEF3D5FF84CC0A55F5E323AF27FF9077B33DB9EBA30B4A37FF5CD7527C004DF0920';
wwv_flow_imp.g_varchar2_table(72) := '265E3304D25A400290D678136D86C0998973194BAF2EBA7EC4FE7CF9AB359B7BA7B3003E93137526E07B5FFA6BF3D6CBAF7B77EEC881D7CD77BFF4FF9D47FE6A30C4A37FF5CB3566AE31571BBC10E8BA000940D74798F8AC021397DC8F850DE516C0E981';
wwv_flow_imp.g_varchar2_table(73) := 'EC7CF01EA31DF0F4E5D3FFD69C80E71ED965BEFFE547CDCF7EB0CF9C7CE398E93FD54F47FA7A7FE2F563E6B5DD2F995D5FFAA6D9F397BBCCD9A3A7A63793F9F703BFF3B1CCE56D2FF419339FB16F3B0EB6DFAC406A5B2301486DC489379780CF5176AE06';
wwv_flow_imp.g_varchar2_table(74) := '2BACACB300794EBFEB16C19776FDD87CFFAB8F9927FEF723E65BFFE36BE6F1FFF967BDF73FF8D3C7CCBEA79E33671C4FFB9BDAFDFB3EF1A0D13DF7539785F43EE4B10BC989BEA42B400290EED813F9A440EC47819A7CE7331F6032D44AFFDF70E74D46DB';
wwv_flow_imp.g_varchar2_table(75) := 'AEB4D1861B8B7DEC1BE64A6073E985480290DE9813F11401D7FDE0AEFBC9A734D5DADB5B3FF521D36412A09DFFFB3FFB9BADC5EBBB61D7D8B9C6DE773BD443205601128058478E7E572230E1980DEEBA9FBC924E54D08892009D92F79913506673DA460C';
wwv_flow_imp.g_varchar2_table(76) := '3B7FC518CBD8A9AFBCDA1748B1072400298E3A317B0B2C1C59E65DB7ED8A3A25FF9E4F3C64EAB8F67DDDACD9E61FFFFEBF8AFEB4FFD43172257F53EBF21E812E0A900074715489295981551FB8D9FCDAFFF977BD4B02559C0DD08E5F47FDFFEC2F3E1DF4';
wwv_flow_imp.g_varchar2_table(77) := '843F93F19FEB614013972632D662519A0269464D0290E6B813F53B02AE9D80EB8132EF3413DC2F5D12F827FFF73F18EDBC5DDF1D90D5F9A93B7E9D59C8AAC3320410885B800420EEF1A3F725055CA781634D00FA2CDA793FF885DF36BFF6DF3F69DEFB5B';
wwv_flow_imp.g_varchar2_table(78) := '0F992DEFDA6634894F97097486403B7ABDD7B29D0FDD633EF83B1F33FFF48FFE93D111BFD6EDB713E36FD7D8B9C63EC698E973318154D722014875E4893B29017D8BA09E1BF09EDFFD0DA3497CBA4CA03304DAD1EBBD96DDF16F1F326B3F788B99BB6261';
wwv_flow_imp.g_varchar2_table(79) := '5236048B40AA022400A98E3C7123800002081863D24520014877EC897C52E0ED8BF68960AE67CA4F36C1FF810AB8C6CE35F6818645B710A84C8004A0324A1A4200010410884D20E5FE9200A43CFAC48E0002082090AC000940B2434FE012B8E07812A0EA';
wwv_flow_imp.g_varchar2_table(80) := 'F0420081AE0AA41D170940DAE34FF40E8179CC887708855BEC1A3B92BF70C78E9E35234002D08C335B4100010410084C20F5EE9000A4FE09207E041040008124054800921C7682EE0BE84978FDF759BFCF1F3D95B5986511083076110C52AB5D64E32400';
wwv_flow_imp.g_varchar2_table(81) := '7C06104020490157F297240A412725400290D470136C5E8173474EE45D85FA08201081005D348604804F010208745280E4AD93C34A50150A900054884953DD1338F3166700BA37AA448400021220019002AF6405E6CE9E936CEC5D0FDC95BC31F65DFF04';
wwv_flow_imp.g_varchar2_table(82) := '109F4B8004C025443902084429E04A00A20C8A4E57224023970548002E3BF013814C017622992C2C4400810E08900074601009A1B8C09C59B38BAFCC9A510B30F6510F5F89CEB36A5F8004A02FC16F0432044E1DF945C65216C520E01ABB39B398FF11C3';
wwv_flow_imp.g_varchar2_table(83) := '38D2C7FA044800EAB3A5E50804E65F777D04BDA48B0820509500ED5C152001B86AC13B0466089C3C7C7CC6321625CCBC5B0000100049444154C421E01A3B2E01C4318EF4B23E011280FA6C6939028139B3AF8BA09774B10E01C6BE0ED5D0DBA47F530548';
wwv_flow_imp.g_varchar2_table(84) := '00A66AF03E398139B3EC09C0F1378F2667D2958047F71CB086E21A7BEBCA1422D0010112800E0C2221141770ED044EBC79CCF0AD72C57DDB5AD367CC5C63DF56DFD96E7D02B47CAD0009C0B51EFC95A000DF0A97E0A013320208F065407C06D2163873E1';
wwv_flow_imp.g_varchar2_table(85) := '9CB970E9A215E1D8DE83D6720AC313F019B3894B17C2EB383DAA5180A6A70B700660BA087F2723A09DFFE889C3C9C49B52A03E4F707CE5F8EB862420A54F05B14E172001982EC2DF4908E4D9F91FD9FBF3244CBA14A4EB2140FD584902FA12DDFF4D8433';
wwv_flow_imp.g_varchar2_table(86) := '054800669AB0A4E3027976FEA270DD4FAE3ABCC212C833662401618D1DBD694E8004A0396BB6148040DE9DBFBAECBA9D4C757885259077CC4802C21ABFEA7B438B59022400592A2CEBA440919D7F1FC2E7B6B27E5D7EB72B5074AC4802DA1D37B6DEBC00';
wwv_flow_imp.g_varchar2_table(87) := '0940F3E66CB10581323B7F75F7DC9113FAC5ABE3022401DD1C60A2CA162001C87661698704CAEEFC45E133AB5CF56278E908F9F92F3E6AFEEA535FE8BD767DF66B9D7AD891CF2D80B6712209B0E950D6250112802E8D26B1CC10A862E7AF46BB920068E7';
wwv_flow_imp.g_varchar2_table(88) := 'FFF027FFD0EC7DF447464F39D44BD7CBB54C658A35F6571563451210FBA7606AFF793F48800460900CCBA317A86AE72F08DFDBCA5437E4D7FEAF7F7760F70E3EF9E2C0B2980AAA1A2B928098469DBE1611200128A2C63AC10BE4DDF98FDC30628D29CF6D';
wwv_flow_imp.g_varchar2_table(89) := '65D6865A2ED491FFA02EFCF02BDF1A5414D572D7586DD8B1C5F83EFE992420AAA1CFEC2C0B070B90000CB6A1245281BC3BFF3B1FB8D7ACBFEB466BB4A37B0E74EA3AB935D8880B75194363650B61E5C61BCC1D0FDD47126043A22C090112802486399D20';
wwv_flow_imp.g_varchar2_table(90) := '8BECFC17AE586C86E6CF77EE10B81320FCCF916B8C74E4AFB1D68B2420FCF12CDF435AB0099000D874288B4AA0E8CEBF1FE4A2E1A5FDB799BFC75EE44B813261025AE81AA3E51B565DE92D49C0150ADE242A400290E8C0772DECB23B7F792C5BB942BF06';
wwv_flow_imp.g_varchar2_table(91) := 'BE0EBDF0D38165148421E01AA325D3923C928030C6ADAE5ED0AE5D8004C0EE4369040255ECFC15E6E295F63300BAB6AC6BCCAACB2B4C018D91AD6759634C126013A3ACCB0224005D1EDD0462AB6AE72FAAA10543CC031044A42F9FE44C3BFBACF0B49C39';
wwv_flow_imp.g_varchar2_table(92) := '015932312FA3EF2E0112009710E5C10A54B9F35790B3AF9F6398072089385F071DCF3158B6DE7EAB2749409CE34EAF8B0B900014B763CD1605AADEF9F7435934BCA4FF36F3B7EB1A73E64A2C6C44C03536CB16DB2FF1A893240152E8C68B28DC0224006E';
wwv_flow_imp.g_varchar2_table(93) := '236A042650D7CE5F612E1F19D6AF81AF519E0730D0A6ED028D8DAD0F0B16CDB7155F292309B842C19B8E0B9000747C80BB165E9D3B7F59F9CC03503D5E6109F85CFF5FB2D69EDC4D8D882460AA468CEFE9B38F0009808F1275821098B874C18C9E38ECDD';
wwv_flow_imp.g_varchar2_table(94) := '173DE14F0FF9F15E61B2A2E6015CBF7CE1E4BBC1FF97FDB6B9C12D535254E060C9EBFF59DB2509C852615997044800BA349A1D8E453B7F3D97DD37C4223BFF7EDBCB47ECCF0338B2F7E7FDAAFC0E44C075FD7FF1DC05857A9A3709F8F989378D3EAB8536';
wwv_flow_imp.g_varchar2_table(95) := 'C64A9509D0909F0009809F13B55A163874FAA8770FCAECFCB591C5C3CBF46BE0CBF6853A0357A2A05681D13D07ACED2F5E699FDC695B394F1270E1D245431260D3A42C24011280904683BE640A8C9E3C6CCE4C9CCB2C9BBEB0ECCE5FED2D5A64BF04A03A';
wwv_flow_imp.g_varchar2_table(96) := '3ED79C558F57FD023E63B17045F1044011E44D02C6CF9FD66ABC5A1160A3BE022400BE52D46B4560ECEC78A33B7F05A979000B1DB7031E745C73563BBC9A11708D85BE0048635AB637799280B1B3C7CDD8E467B7EC36591F813A054800EAD4A5ED52029A';
wwv_flow_imp.g_varchar2_table(97) := 'F13F36F90FA94F23551CF94FDDCEC8AAAB5F1A337579FFFDBEC79EE9BFE577CB023FFCCAB7AC3D58BB7983B53C4F61DE2460FCFCA93CCD53B702019AF0172001F0B7A26683029A48E53BE3BFEA9DBFC25CB6C17ECBD889378F199F53CF6A8B577D023E63';
wwv_flow_imp.g_varchar2_table(98) := 'B06ADBBA4A3B902709D0DC157D962BED008D21509100094045903453AD80EF91FFADF7DF6D16AE585CEDC6275BD33FF25C06988408FC7FD7E97F8DE1DCA1799547A1CFC7E6776DF36AD7F7B3ECD518951C0214E7112001C8A345DD460474C434EE31896A';
wwv_flow_imp.g_varchar2_table(99) := 'CBCE9BCDD295F619FB653ACC6580327ACDACEB3AFDBF7AD3DADA3AB26AE31AA3CFA06B03FA2CEB33EDAA4739024D0B9000342DCEF69C023A6DEAAAB46C648559B37D83AB5AA9722E0394E2AB7D659FD3FFC3AB56D6DA8F559B569B914D6B9CDBF0F94C3B';
wwv_flow_imp.g_varchar2_table(100) := '1BA18253800AF9044800F27951BB66014DFC73DDF2A7C7F5EEFCC05D35F7C4189DE6D52964DB865CA7A06DEB52564EC065AF6FFFAB62F6BFAD976A7FEBCE9B8C3E93B67AFA4C8F3321D04644590B0224002DA0B3C9C1026F9C1A1B5CF84EC98E7BEF78E7';
wwv_flow_imp.g_varchar2_table(101) := '5DFDBF5CA790750ADAE748B4FE9EA6B705D9DBA21E5E356C2BAEAC4C49C08EFBDD09E95B678FF394C0CAD4B31A62595E011280BC62D4AF4D60ECECB8D193D46C1BD0E9D621C7B3FA6DEBE72DD3A506D73AE78E9C7055A1BC62019FA46BB8E6D3FF5343D2';
wwv_flow_imp.g_varchar2_table(102) := 'D9A2B55BD64F5D34E3BD3EDB3A1330A3800508B4244002D0123C9B9D29303679843473E9B54B36EDD87AED829AFF9A3B34CFB82E03FCECC9176AEE05CD4F1738E878105313A7FFA7F769EDF64D460F1D9ABE7CEADF9C0598AA51ED7B5ACB2F400290DF8C';
wwv_flow_imp.g_varchar2_table(103) := '356A10F09925BD71EB66A31D720D9BB736B97E8B7DB2A1BE1BC0E788D4BA110A73098472FA7F6AA7F5D9743D744867017C3EEB53DBE53D0275099000D4254BBBB904C63D6EFBAB7BD6FFA00E2F5DB9DC7964C76580417AD52FF749B69A3CFD3F35423D74';
wwv_flow_imp.g_varchar2_table(104) := 'C87516E0CCC4F9A9ABF0BE12011A2922400250448D752A17387EFEA4B5CD2D3B6F369A6C65AD5453A1B6BB6878A9B5752E0358792A2D749DFED73C118D59A51BF56C4C670136DC62BF4CA53B5D3C9BA31A02B50A9000D4CA4BE33E023A25AA53A3B6BAC3';
wwv_flow_imp.g_varchar2_table(105) := '1BEDCFE6B7AD5B4599AEEFDADAE132804DA7BA321DFDBB4EFF2F71246BD5F526BB25D7F323CE4C9CE36E806CBAC24B59B1980009403137D6AA50C075FA5FA754756455E1267337B568D142E76500D79169EE8DB2C20C011F633DA16FC68A0D2ED01D01AE';
wwv_flow_imp.g_varchar2_table(106) := '89A34A021AEC129B4220538004209385854D0AB84E89BA265635D1579D525E3EB2C2BA291D99EA08D55A89C2520232B635A089A2B6F2A6CA5C9F95F1B74F37D59504B64388450548008ACAB15E25023AFDEF3A1A5AB6BEDEC7B9FA06B266FB2667D5637B';
wwv_flow_imp.g_varchar2_table(107) := '0F3AEB50A198C02B0FEF76AE38BCA1DD4B45FD0E2E1F19EEBFCDFCADCFBC3EFB99852C44A02101128086A0D94CB680EB1F419DFEAFE3DBFEB27B635FAA7EB84EEDBEF2EDE7ED8D505A5860DF63CF58D7D5D834F990285B67F468607D766D755C9F7DDBBA';
wwv_flow_imp.g_varchar2_table(108) := '945D15E05D71011280E276AC5981C0C4C50BD65656797CD18AB5818A0B37EDB8D1DAE2E89E03E6D053FBAD7528CC2FA04B2B27DE3C665DD13536D6952B2EF4B964E4FAEC57DC259A4360860009C00C121634293071E9A27573F38686ACE54D17EAEB8775';
wwv_flow_imp.g_varchar2_table(109) := 'A469DB2E67016C3AC5CAF67FFDBBD61575C4ADB1B1566AB870E10AFBADA3AECF7EC3DD8D747374BB8C000940193DD6AD5D60F6D075B56F23EF06566F5A6B5D45670174C46AAD44A1B7802C759BA56D8575B76CB615B75276DD2CFB3FAF1397265AE9171B';
wwv_flow_imp.g_varchar2_table(110) := '45A02F60FF84F66BF11B819A045CFF085E376B764D5B2EDEECF0AA9546479CB6160E3A9E556F5B97B26B055C96FA8CB47DEBDFB53DBEFCD7DC650B2EBFE1676D02345C4E8004A09C1F6B9714709D069D373FAC4B000A57D7775D479CBA5D4D47AEAACFAB';
wwv_flow_imp.g_varchar2_table(111) := 'B8800C65696B61F3BBB6D98A5B2B536262DBB8EBB36F5B973204AA102001A84291360A0BBC7DD17E1A74EEFC7985DBAE73459D0570FD03EF3A72ADB37F5D69DB65A83108F1E85FFEAECFAEEBB3AF3678D904282B2B4002505690F54B09B81E013C7728CC';
wwv_flow_imp.g_varchar2_table(112) := '044067015C0F28D26D6B3A822D0594F8CAAEA37FD718B4C937FB57ECFFBCBA3EFB6DF69D6DA72160FF84A6614094081412707DF39B6E5B731DC116DA70222BF93CF8A7AD6F88F4190225893EF5A8534C80B5CA0B90009437A48544057476C2F59C02CE02';
wwv_flow_imp.g_varchar2_table(113) := '14FB70E8CC89EBE85F8FFD65275BCC97B510900009801478215050E0866DEBAD6B7216C0CA33B0D0E7CC89CEC00C6C80828E0B105E150224005528D246B202FAE6B7911B46ACF1EB485647B4D64A145E119095CCAE2CC878B36CFD88D119988C22162180';
wwv_flow_imp.g_varchar2_table(114) := '80A70009802714D5101824E0F325413E47B483DA4F6DB98FD5C6ADEE2F664ACD2DA57889B51A0112806A1C692561019F2F09D211AD8E6C1366F20A5D46B2B255D6A398656EAB43190208B8054800DC46D440C029B0ED9E9D46F7A4DB2AFEE8F3DFB01553';
wwv_flow_imp.g_varchar2_table(115) := '3629E063B4EDB65B266BF27FBA02445E950009405592B493B480E602B8EE491FE59B02AD9F91F17D6F1819D92A6DDCBAD90C2D5F68AB42190208780A90007842510D01978066A5BBCE023CFBD56F1B9DE676B59562F9D39F7BC41AB66CD7DFB9D55A87C2';
wwv_flow_imp.g_varchar2_table(116) := 'EE0B106175022400D559D252E2029A95EE7A2E3DB705667F48F4D01FD964975E5EEAB2BD5C8B9F0820E02B4002E02B453D043C04F41D019AA466ABCAC381AED5D119119F897FA13EF3FFDA68F8AB5E015AAF528004A04A4DDA4A5E404FA6BBF156FBB7D3';
wwv_flow_imp.g_varchar2_table(117) := 'E948F7E0932F266FD507F0B17099F6DBE2370208F80B9000F85B5113012F01DDA2B6768BFD09813AE2D591AF57831DAE240359D8421CD9B4C6C8D45687B2340488B25A0112806A3D690D819EC0DAED9BBC6E0BD40EB0B742A23F7C6EFBDBBAF3A6447508';
wwv_flow_imp.g_varchar2_table(118) := '1B817A054800EAF5A5F544057C26048EEE39600E267C294013FF46270D6C1F912D3B6F36BAAC62AB43592A02C459B5000940D5A2B487C03B029A1038B460E89DBFB27FE9F4778A670114B362CF56B9BC54766BB66FB8FC073F1140A072011280CA496910';
wwv_flow_imp.g_varchar2_table(119) := '81CB023A72DD74D7F6CB7F587EEA34B87688962A9D2B52CCAEA0B6DD739BAB0AE50909106AF5022400D59BD22202570456AC5A615CB705EA34F8C1842E05F89CFA5F3632E9B662F11547DE208040F5022400D59BD22202D708ECB8F776E784409D0E4FE1';
wwv_flow_imp.g_varchar2_table(120) := '2C806254ACD70065FCB185897F192A292F22F63A044800EA50A54D04A6089C1C3B6E2E5CBA386549F6DBC73EF3E5CE3F26D8E7D4FF9CA1794666D94A2C450081AA044800AA92A41D04320446F7BD6AF6ED7E21A364E6A2AE3F20C8E7D4BF5426CE9E372F';
wwv_flow_imp.g_varchar2_table(121) := 'BDB0DFBCB17FD45CFCE5252DE295B800E1D7234002508F2BAD2260F63EFD9C197DF1D55C123A3DAED3E4B9568AA0B262526C79BAFAEADE977ADF0E481290478DBA08F80B9000F85B5113012F81B7278F60B5F3FFC591A35EF5A757EAE2A500C5343D4E9F';
wwv_flow_imp.g_varchar2_table(122) := 'BF5F7FF535B3F7F1678C4C7DEA53A78B02C454970009405DB2B49BA48076547FFBD7DF334577FE42EBDAA5009DFA574C8AADC8EBC48913E685EF3C431250048F7510B008900058702842208FC0A9A327CCEE6F3EED35E1CFD5AE4E976BC7E9AA177AF9F8';
wwv_flow_imp.g_varchar2_table(123) := 'BE378C6229DBCFB3A7CF9AE79ED86D8EBD7CA86C53AC1F9900DDAD4F8004A03E5B5A4E48E0E86B87CD9E27777B477CDDACD9CEBADA71EADAB9B362A015D4F76F7CFA8F2BEB9D26071E78E96573E4A58395B5494308A42C400290F2E8137B25027966FA6B';
wwv_flow_imp.g_varchar2_table(124) := '83F3E75C6F6E5CBACEF96C00D5D5B573ED48F53EA697FAFCF027FFD0D9652542DB976F344BE62D70D6550525012F71878028127911F106D0E100000F7049444154669D02240075EAD276E70534D92FCF4CFFE1A1A566C3A2553D978D8B6F702601BA76AE';
wwv_flow_imp.g_varchar2_table(125) := '7BE7B543EDAD14C90FF5D9D555EDFC9508A9DEEA05C346367AEFF3E20E011F25EA2060172001B0FB508A40A68026FB69E79F67B2DFEA052B2677724BAEB43767D67566E9BC4557FE1EF46674CF81A8BE35F0F92F3EDABB7D6F503CFDE56B160EF7DFF67E';
wwv_flow_imp.g_varchar2_table(126) := '0F0F2D99F459EA4C8A7A95277F7087C02442C7FF27BC7A054800EAF5A5F50E0A68E79F77A6FF86C5AB264F732F9CA1D1DFE9CD2898B640F30162981478E8A9FD66EFA33F9AD6FB997FEA687FFE75D7CF28908712039D1D985198B1E004770864A8B00801';
wwv_flow_imp.g_varchar2_table(127) := '3F0112003F276A21D013C83BD35F3B32EDFCB37676BD06277F68A7A77A936FADFF2B0908F9528066FC3FF1077F6E8D41859A03A198F53EEB25AB3C49007708642976611931D42D400250B730ED774620EF4C7FEDE8748D5B3B341782CF7C00B511EAA440';
wwv_flow_imp.g_varchar2_table(128) := '25263E33FE95E8F4E740289E412F99F99AA80D4D0EE40E0149F042C05F8004C0DF8A9A090B8CE678A6BF98B4F3F7D9D1A9AE5EBEF301342930C424C067D29FE2D491BD7EFBBC64A2048A3B047CB4BA578788EA172001A8DF982D442EA0C97E4567FAE709';
wwv_flow_imp.g_varchar2_table(129) := '5DA7C5756DDCB58E9280834FBEE8AAD658F9AECF7ECD6BD29F2641EAC83E6FC7B84320AF18F511F0132001F073A25682029AECA79D7F9999FE79D99404E834B96B3DCD07D0A4409D7A77D5ADB3DC77E7AFA3F825F3664E82F4ED9B5C941CF9D8A84DEE10';
wwv_flow_imp.g_varchar2_table(130) := '9042CC2FFADE8400094013CA6C233A01EDFCAB9AE99F3778DF6BDF4A0274EABD8D2440DBF4DDF96BA7ADA3F8BC0ED3EB2B09D02504B537BD2CEB6FEE10C85261190257054800AE5AF00E819E401D33FD7B0D7BFED0B56FDF246074CF01A327EE3DFFC547';
wwv_flow_imp.g_varchar2_table(131) := 'CDA1A7F61BED98F5F2DC54AE6A9AE5AF6D685BDAA6B6ED6A403B6BC5E2AAE75BAE4B08799200EE10F0950DAB1EBD69468004A01967B61289409D33FDF3102809F0794850BF4DDD7BAF5BF0B463D6EBAB1FFD3D93F5EAD71FF43B6B9DFE32CDF2D736B4AD';
wwv_flow_imp.g_varchar2_table(132) := '41EB4F5FAE9DB56299BEBCCCDF4A02945428B9F069873B047C94A893A20009408AA34ECC9902A335CFF4CFDCA865A14E79EBBAB7A54AD045EABB76D675745249057708D4211B429BF4A129011280A6A4D94ED0029AECD7C44CFFBC084A0234812EEF7A6D';
wwv_flow_imp.g_varchar2_table(133) := 'D7D76D90EA7BDDFDD0DC02251ABEDBE13B047CA5A897820009400AA34C8C030534D94F3BFF2667FA0FECCC8002EDE4624A02B4F3CFF30C8401617B2F56A2A124C0F79200770878D3B652918D36274002D09C355B0A4C403BFFB666FAE7A55012A09D5CDE';
wwv_flow_imp.g_varchar2_table(134) := 'F59AAEAF3E36B9F3EFC7A72440F30D7C9380137C87409F8EDF090B9000243CF82987DEF64CFF22F6DAC9E97B057C777245B651741DF5497D531F8BB651763DCD37C8930470874059F13AD6A7CD260548009AD4665B41088432D3BF088676729AFCA6A7EA';
wwv_flow_imp.g_varchar2_table(135) := '69A75BA48D2AD7D1E97EF5457D52DFAA6CBB485BEA0377081491639D14054800521CF584630E6DA67FD1A1D053F5B4D3BD7CD4BDD46847AC8440AFA26DFAACA7ED683E8276FA5B97AE353ADDAFBEF8ACDB541DEE10684ABAFAEDD062B3022400CD7AB3B5';
wwv_flow_imp.g_varchar2_table(136) := '160534D92FC499FE654874C4ABD3EEDA112B21D06BFBF28D66D0CBB5AD41EBF5976B3B9A8FA09DBE76B4AEF6DA2C573F3527C1B70FDC21E02B45BDAE0890007465248963A08026FB69E71FF24CFF819DA7A0948092232501BE6746B843A01477C99559BD';
wwv_flow_imp.g_varchar2_table(137) := '69011280A6C5D95EA302DAF9C732D3BF51988436A62420CFE440EE1048E8C39178A82400897F00BA1C7E8C33FDBB3C1E6DC6A64B25799200EE10687EB4D862F3022400CD9BB3C50604DED83F6AF63CB9DB7B4B9ADCA6EBE7DA5178AF44C5A80434B645EE';
wwv_flow_imp.g_varchar2_table(138) := '10D067E9E22F2F45152B9D45C0478004C047893AD108E894BFAEF76B42976FA7B5F3D7E436DFFAD48B5740131795E8E94E069F28F44542FA2CED7DFC19A3CF96CF3AD42922C03A6D089000B4A1CE362B17D03FCEBAC56FF7379F367926FB6982183BFFCA';
wwv_flow_imp.g_varchar2_table(139) := '8723F806F3DE21A07901CF3DB1DBFCF4B9BF33678F9D0A3E3E3A88808F0009808F12758212B8786EA2773476FCAD5F18EDF4F77CE747463BFE3CB7F829A0D50B56184D10D37B5EE90968EC9500FADE21A0B301BA4BE0D9277E607EFCD86EF3DA9E578CE6';
wwv_flow_imp.g_varchar2_table(140) := '99282150029A9E607511D3523B022400EDB8B3554F815D0F3F6EA6BFBEFF8DEFF476F83F79EA59A39DFEA9B171CFD6AE56D30374742FFBD525BC4B514049409EC9817D239D11F8F92B3FEDCD335142A00474FAE7547FF7EBF31B8110054800421C15FA54';
wwv_flow_imp.g_varchar2_table(141) := '9B808EF6B4F3D784B0DA3642C35109E8B3502409882AC8A03B4BE7DA122001684B9EED362EA0C97E9A00A67FF01BDF381B0C5A409F09DD21A0CF48D01DA57308542840025021264D852BA06BBD4CF60B777C42E899EE10D067449F159D290AA14F29F481';
wwv_flow_imp.g_varchar2_table(142) := '18DB13200168CF9E2D4F0AD4FD0FAD8EE874CA5FD77A273797FCFF366F5B594A70FAAC34714900EF943E5561C64A0210E6B824D3AB0573AEAF25D6FE8E5F47743ABD5BCB46226CD4E66D2B8B30D4525DD66746978B943CEAB354AAB1012BE32D185E6D0A';
wwv_flow_imp.g_varchar2_table(143) := '9000B4A9CFB64DD5A75BF58017FDA3CD8E3FFBC335C85B47A3BA373E7BAD74972A11D067499F29250272AA4243EDE05D85246D9411200128A3C7BAA50574DDB53FF94AFF28FA36A8BAFA07593B7CDDCFBF75E9DADE57E0EA1F55FDA3EDDB4E6AF5B2BC65';
wwv_flow_imp.g_varchar2_table(144) := 'A83148CD224FBCFA4C2911E89F155022A5CF9F5EFA2CEAE5DB1EDE57A578D7AE000940BBFE6C7D52403BA5FE3FAEDB976FECEDC85DBF7BFF102F5A65B4C3D7FDFC6A63B229FEF71090D5546F196A99C7AA5499145032A0790232D44B9F45BD5C9FD97E39';
wwv_flow_imp.g_varchar2_table(145) := 'DE9388FC1F8400094010C3402710400081D40488B76D011280B64780ED238000020820D0820009400BE86C12010410485D80F8DB172001687F0CE8010208208000028D0B9000344ECE0611400081D405883F040112801046813E208000020820D0B00009';
wwv_flow_imp.g_varchar2_table(146) := '40C3E06C0E010410485D80F8C310200108631CE8050208208000028D0A900034CACDC610400081D405883F140112805046827E208000020820D0A000094083D86C0A010410485D80F8C311200108672CE8090208208000028D0990003446CD8610400081';
wwv_flow_imp.g_varchar2_table(147) := 'D405883F24011280904683BE208000020820D09000094043D06C06010410485D80F8C3122001086B3CE80D0208208000028D08900034C2CC4610400081D405883F34011280D04684FE208000020820D08000094003C86C02010410485D80F8C313200108';
wwv_flow_imp.g_varchar2_table(148) := '6F4CE811020820800002B50B9000D44ECC0610400081D405883F440112801047853E21800002082050B3000940CDC0348F000208A42E40FC610A900084392EF40A0104104000815A0548006AE5A571041040207501E20F55800420D491A15F0820800002';
wwv_flow_imp.g_varchar2_table(149) := '08D428400250232E4D23800002A90B107FB8022400E18E0D3D430001041040A036011280DA686918010410485D80F843162001087974E81B02082080000235099000D4044BB308208040EA02C41FB6000940D8E343EF104000010410A8458004A016561A';
wwv_flow_imp.g_varchar2_table(150) := '45000104521720FED0054800421F21FA870002082080400D02240035A0D22402082090BA00F1872F400210FE18D1430410400001042A172001A89C940611400081D405883F060112801846893E22800002082050B1000940C5A03487000208A42E40FC71';
wwv_flow_imp.g_varchar2_table(151) := '089000C4314EF4120104104000814A0548002AE5A431041040207501E28F458004209691A29F082080000208542840025021264D21800002A90B107F3C022400F18C153D450001041040A032011280CA286908010410485D80F8631220018869B4E82B02';
wwv_flow_imp.g_varchar2_table(152) := '0820800002150990005404493308208040EA02C41F970009405CE3456F114000010410A8448004A012461A41000104521720FED8044800621B31FA8B000208208040050224001520D20402082090BA00F1C727400210DF98D1630410400001044A0B9000';
wwv_flow_imp.g_varchar2_table(153) := '9426A401041040207501E28F51800420C651A3CF082080000208941420012809C8EA08208040EA02C41FA70009409CE346AF11400001041028254002508A8F9511400081D405883F5601128058478E7E23800002082050428004A0041EAB22800002A90B';
wwv_flow_imp.g_varchar2_table(154) := '107FBC022400F18E1D3D470001041040A0B0000940613A5644000104521720FE98054800621E3DFA8E000208208040410112808270AC86000208A42E40FC710B9000C43D7EF41E0104104000814202240085D85809010410485D80F863172001887D04E9';
wwv_flow_imp.g_varchar2_table(155) := '3F020820800002050448000AA0B10A02082090BA00F1C72F400210FF181201020820800002B90548007293B10202082090BA00F177418004A00BA3480C082080000208E4142001C8094675041040207501E2EF8600094037C69128104000010410C82540';
wwv_flow_imp.g_varchar2_table(156) := '02908B8BCA08208040EA02C4DF15011280AE8C2471208000020820904380042007165511400081D40588BF3B022400DD194B22410001041040C05B8004C09B8A8A08208040EA02C4DF250112802E8D26B1208000020820E0294002E00945350410402075';
wwv_flow_imp.g_varchar2_table(157) := '01E2EF96000940B7C69368104000010410F0122001F062A21202082090BA00F1774D8004A06B234A3C0820800002087808900078205105010410485D80F8BB274002D0BD3125220410400001049C0224004E222A20800002A90B107F17054800BA38AAC4';
wwv_flow_imp.g_varchar2_table(158) := '84000208208080438004C001443102082090BA00F177538004A09BE34A5408208000020858054800AC3C1422800002A90B107F57054800BA3AB2C485000208208080458004C082431102082090BA00F177578004A0BB634B640820800002080C14200118';
wwv_flow_imp.g_varchar2_table(159) := '48430102082090BA00F177598004A0CBA34B6C0820800002080C1020011800C362041040207501E2EFB6000940B7C797E8104000010410C8142001C864612102082090BA00F1775D8004A0EB234C7C0820800002086408900064A0B008010410485D80F8';
wwv_flow_imp.g_varchar2_table(160) := 'BB2F4002D0FD31264204104000010466089000CC20610102082090BA00F1A720400290C2281323020820800002D3044800A681F02702082090BA00F1A721400290C6381325020820800002D70890005CC3C11F08208040EA02C49F8A0009402A234D9C08';
wwv_flow_imp.g_varchar2_table(161) := '20800002084C1120019882C15B041040207501E24F478004209DB12652041040000104AE0890005CA1E00D02082090BA00F1A724400290D268132B020820800002EF089000BC03C12F041040207501E24F4B800420ADF1265A0410400001047A0224003D';
wwv_flow_imp.g_varchar2_table(162) := '067E20800002A90B107F6A022400A98D38F1228000020820302940023089C0FF08208040EA02C49F9E0009407A634EC40820800002081812003E0408208040F20200A428400290E2A813330208208040F2022400C97F0400400081D405883F4D01128034';
wwv_flow_imp.g_varchar2_table(163) := 'C79DA811400001041217200148FC0340F8082090BA00F1A72A400290EAC813370208208040D2022400490F3FC1238040EA02C49FAE000940BA634FE40820800002090B9000243CF8848E0002A90B107FCA022400298F3EB12380000208242B400290ECD0';
wwv_flow_imp.g_varchar2_table(164) := '13380208A42E40FC690BFC3D000000FFFFE7DCBA37000000064944415403009CC3BA2D89E8072C0000000049454E44AE426082';
wwv_flow_imp_shared.create_app_static_file(
 p_id=>wwv_flow_imp.id(32864383491450426)
,p_file_name=>'icons/app-icon-512.png'
,p_mime_type=>'image/png'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/files/playground_js
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A0D0A202A20617065782D64656D6F20506167652031202D2D20506C617967726F756E6420636C69656E74207363726970742E0D0A202A0D0A202A2043616C6C732074686520706167652773206F776E204F6E2D44656D616E643A20416A6178204361';
wwv_flow_imp.g_varchar2_table(2) := '6C6C6261636B2070726F636573732C2022504C415947524F554E445F52554E220D0A202A2028504C2F53514C20436F64653A20617065785F61695F726F757465725F64656D6F2E616A61785F72756E3B292C20776869636820696E7465726E616C6C7920';
wwv_flow_imp.g_varchar2_table(3) := '6D616B6573207468650D0A202A20676174657761792063616C6C732064657363726962656420696E20617065782D64656D6F2F73716C2F64656D6F5F706C617967726F756E645F706B672E706B732E205468650D0A202A2062726F77736572206E657665';
wwv_flow_imp.g_varchar2_table(4) := '722074616C6B7320746F207468652067617465776179206F7220686F6C647320616E7920676174657761792063726564656E7469616C2E0D0A202A0D0A202A20417474616368206173206120706167652D6C6576656C202246696C652055524C22202873';
wwv_flow_imp.g_varchar2_table(5) := '7461746963206170706C69636174696F6E2066696C652920616E642077697265207468650D0A202A2053656E6420627574746F6E20746F2069742C20652E672E20612044796E616D696320416374696F6E3A0D0A202A2020204576656E743A20436C6963';
wwv_flow_imp.g_varchar2_table(6) := '6B2C2053656C6563746F723A202350315F53454E440D0A202A202020416374696F6E3A2045786563757465204A61766153637269707420436F64653A206170657844656D6F506C617967726F756E642E72756E28293B0D0A202A206F722063616C6C2061';
wwv_flow_imp.g_varchar2_table(7) := '70657844656D6F506C617967726F756E642E72756E2829206469726563746C792066726F6D206120627574746F6E27732022457865637574650D0A202A204A61766153637269707420436F64652220616374696F6E202D2D2073656520617065782D6465';
wwv_flow_imp.g_varchar2_table(8) := '6D6F2F70616765732F30312D706C617967726F756E642E6D642E0D0A202A2F0D0A2866756E6374696F6E2028617065782C206170657844656D6F506C617967726F756E6429207B0D0A202020202275736520737472696374223B0D0A0D0A202020207661';
wwv_flow_imp.g_varchar2_table(9) := '72204649454C4453203D205B0D0A20202020202020202250315F53454C45435445445F54494552222C0D0A20202020202020202250315F53454C45435445445F4D4F44454C222C0D0A20202020202020202250315F4C4154454E43595F4D53222C0D0A20';
wwv_flow_imp.g_varchar2_table(10) := '202020202020202250315F494E5055545F544F4B454E53222C0D0A20202020202020202250315F4F55545055545F544F4B454E53222C0D0A20202020202020202250315F455354494D415445445F434F5354222C0D0A20202020202020202250315F4553';
wwv_flow_imp.g_varchar2_table(11) := '54494D415445445F424153454C494E455F434F5354222C0D0A20202020202020202250315F455354494D415445445F534156494E4753222C0D0A20202020202020202250315F524551554553545F4944220D0A202020205D3B0D0A0D0A2020202066756E';
wwv_flow_imp.g_varchar2_table(12) := '6374696F6E20636C656172526573756C744974656D732829207B0D0A2020202020202020617065782E6974656D282250315F524553554C5422292E73657456616C7565282222293B0D0A2020202020202020617065782E6974656D282250315F4552524F';
wwv_flow_imp.g_varchar2_table(13) := '5222292E73657456616C7565282222293B0D0A20202020202020204649454C44532E666F72456163682866756E6374696F6E20286974656D4E616D6529207B0D0A202020202020202020202020617065782E6974656D286974656D4E616D65292E736574';
wwv_flow_imp.g_varchar2_table(14) := '56616C7565282222293B0D0A20202020202020207D293B0D0A202020207D0D0A0D0A202020202F2F2070446174612773206E756D65726963206669656C64732028657374696D617465645F636F73742C206574632E29206D6179206265206E756C6C2077';
wwv_flow_imp.g_varchar2_table(15) := '68656E207468650D0A202020202F2F202F61646D696E2F7265717565737473206C6F6F6B7570206469646E27742066696E642061206D61746368696E6720726F7720796574202874656C656D657472790D0A202020202F2F207772697465206C61672C20';
wwv_flow_imp.g_varchar2_table(16) := '6F722041444D494E5F43524544454E5449414C5F5354415449435F4944206E6F7420636F6E6669677572656429202D2D2072656E6465720D0A202020202F2F20226E2F61222C206E6576657220302C2070657220617065785F61695F726F757465725F64';
wwv_flow_imp.g_varchar2_table(17) := '656D6F2E706B622773206F776E20636F6E74726163742E0D0A2020202066756E6374696F6E20646973706C617956616C75652876616C756529207B0D0A202020202020202072657475726E202876616C7565203D3D3D206E756C6C207C7C2076616C7565';
wwv_flow_imp.g_varchar2_table(18) := '203D3D3D20756E646566696E6564207C7C2076616C7565203D3D3D20222229203F20226E2F6122203A2076616C75653B0D0A202020207D0D0A0D0A202020206170657844656D6F506C617967726F756E642E72756E203D2066756E6374696F6E20282920';
wwv_flow_imp.g_varchar2_table(19) := '7B0D0A2020202020202020766172207370696E6E6572203D20617065782E7574696C2E73686F775370696E6E657228617065782E6A517565727928222350315F53454E442229293B0D0A0D0A2020202020202020617065782E7365727665722E70726F63';
wwv_flow_imp.g_varchar2_table(20) := '657373280D0A20202020202020202020202022504C415947524F554E445F52554E222C0D0A2020202020202020202020207B0D0A202020202020202020202020202020207830313A20617065782E6974656D282250315F50524F4D505422292E67657456';
wwv_flow_imp.g_varchar2_table(21) := '616C756528292C0D0A202020202020202020202020202020207830323A20617065782E6974656D282250315F524F55544522292E67657456616C756528290D0A2020202020202020202020207D2C0D0A2020202020202020202020207B0D0A2020202020';
wwv_flow_imp.g_varchar2_table(22) := '202020202020202020202064617461547970653A20226A736F6E222C0D0A20202020202020202020202020202020737563636573733A2066756E6374696F6E2028704461746129207B0D0A20202020202020202020202020202020202020207370696E6E';
wwv_flow_imp.g_varchar2_table(23) := '65722E72656D6F766528293B0D0A20202020202020202020202020202020202020206966202870446174612026262070446174612E7375636365737329207B0D0A202020202020202020202020202020202020202020202020617065782E6974656D2822';
wwv_flow_imp.g_varchar2_table(24) := '50315F524553554C5422292E73657456616C75652870446174612E726573756C74293B0D0A202020202020202020202020202020202020202020202020617065782E6974656D282250315F4552524F5222292E73657456616C7565282222293B0D0A2020';
wwv_flow_imp.g_varchar2_table(25) := '20202020202020202020202020202020202020202020617065782E6974656D282250315F53454C45435445445F5449455222292E73657456616C756528646973706C617956616C75652870446174612E73656C65637465645F7469657229293B0D0A2020';
wwv_flow_imp.g_varchar2_table(26) := '20202020202020202020202020202020202020202020617065782E6974656D282250315F53454C45435445445F4D4F44454C22292E73657456616C756528646973706C617956616C75652870446174612E73656C65637465645F6D6F64656C29293B0D0A';
wwv_flow_imp.g_varchar2_table(27) := '202020202020202020202020202020202020202020202020617065782E6974656D282250315F4C4154454E43595F4D5322292E73657456616C756528646973706C617956616C75652870446174612E6C6174656E63795F6D7329293B0D0A202020202020';
wwv_flow_imp.g_varchar2_table(28) := '202020202020202020202020202020202020617065782E6974656D282250315F494E5055545F544F4B454E5322292E73657456616C756528646973706C617956616C75652870446174612E696E7075745F746F6B656E7329293B0D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(29) := '20202020202020202020202020202020617065782E6974656D282250315F4F55545055545F544F4B454E5322292E73657456616C756528646973706C617956616C75652870446174612E6F75747075745F746F6B656E7329293B0D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(30) := '20202020202020202020202020202020617065782E6974656D282250315F455354494D415445445F434F535422292E73657456616C756528646973706C617956616C75652870446174612E657374696D617465645F636F737429293B0D0A202020202020';
wwv_flow_imp.g_varchar2_table(31) := '202020202020202020202020202020202020617065782E6974656D282250315F455354494D415445445F424153454C494E455F434F535422292E73657456616C756528646973706C617956616C75652870446174612E657374696D617465645F62617365';
wwv_flow_imp.g_varchar2_table(32) := '6C696E655F636F737429293B0D0A202020202020202020202020202020202020202020202020617065782E6974656D282250315F455354494D415445445F534156494E475322292E73657456616C756528646973706C617956616C75652870446174612E';
wwv_flow_imp.g_varchar2_table(33) := '657374696D617465645F736176696E677329293B0D0A202020202020202020202020202020202020202020202020617065782E6974656D282250315F524551554553545F494422292E73657456616C756528646973706C617956616C7565287044617461';
wwv_flow_imp.g_varchar2_table(34) := '2E726571756573745F696429293B0D0A20202020202020202020202020202020202020207D20656C7365207B0D0A202020202020202020202020202020202020202020202020636C656172526573756C744974656D7328293B0D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(35) := '202020202020202020202020202020617065782E6974656D282250315F4552524F5222292E73657456616C7565282870446174612026262070446174612E6572726F7229207C7C2022556E6B6E6F776E206572726F722E22293B0D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(36) := '2020202020202020202020207D0D0A202020202020202020202020202020207D2C0D0A202020202020202020202020202020206572726F723A2066756E6374696F6E20286A715848522C207465787453746174757329207B0D0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(37) := '202020202020202020207370696E6E65722E72656D6F766528293B0D0A2020202020202020202020202020202020202020636C656172526573756C744974656D7328293B0D0A2020202020202020202020202020202020202020617065782E6974656D28';
wwv_flow_imp.g_varchar2_table(38) := '2250315F4552524F5222292E73657456616C75652822506C617967726F756E642072657175657374206661696C6564202822202B2074657874537461747573202B2022292E22293B0D0A202020202020202020202020202020207D0D0A20202020202020';
wwv_flow_imp.g_varchar2_table(39) := '20202020207D0D0A2020202020202020293B0D0A202020207D3B0D0A7D2928617065782C202877696E646F772E6170657844656D6F506C617967726F756E64203D2077696E646F772E6170657844656D6F506C617967726F756E64207C7C207B7D29293B';
wwv_flow_imp.g_varchar2_table(40) := '0D0A';
wwv_flow_imp_shared.create_app_static_file(
 p_id=>wwv_flow_imp.id(16450999435902401)
,p_file_name=>'playground.js'
,p_mime_type=>'application/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/shared_components/security/authorizations/administration_rights
begin
wwv_flow_imp_shared.create_security_scheme(
 p_id=>wwv_flow_imp.id(32865651717450426)
,p_name=>'Administration Rights'
,p_static_id=>'administration-rights'
,p_scheme_type=>'NATIVE_FUNCTION_BODY'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'plsql_function_body', 'return true;')).to_clob
,p_error_message=>'Insufficient privileges, user is not an Administrator'
,p_version_scn=>'SH256:K94FzTYWdjDQ6WIg6w48Or20nhyD_tWnqCuRh9rK4CU'
,p_caching=>'BY_USER_BY_PAGE_VIEW'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/navigation/navigation_bar
begin
null;
end;
/
prompt --application/shared_components/logic/application_settings
begin
null;
end;
/
prompt --application/shared_components/navigation/tabs/standard
begin
null;
end;
/
prompt --application/shared_components/navigation/tabs/parent
begin
null;
end;
/
prompt --application/shared_components/user_interface/lovs/boolean
begin
wwv_flow_imp_shared.create_list_of_values(
 p_id=>wwv_flow_imp.id(32874121069450466)
,p_lov_name=>'BOOLEAN'
,p_static_id=>'boolean'
,p_lov_query=>'.'||wwv_flow_imp.id(32874121069450466)||'.'
,p_location=>'STATIC'
,p_version_scn=>'SH256:CnCBOq-zabcz-aPWKwU8C5KDeZy6YuyjvpJoTrTywfI'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_static_lov_data(
 p_id=>wwv_flow_imp.id(32874809453450471)
,p_lov_disp_sequence=>2
,p_lov_disp_value=>'No'
,p_lov_return_value=>'FALSE'
,p_static_id=>'false'
);
wwv_flow_imp_shared.create_static_lov_data(
 p_id=>wwv_flow_imp.id(32874403111450469)
,p_lov_disp_sequence=>1
,p_lov_disp_value=>'Yes'
,p_lov_return_value=>'TRUE'
,p_static_id=>'true'
);
end;
/
prompt --application/pages/page_groups
begin
wwv_flow_imp_page.create_page_group(
 p_id=>wwv_flow_imp.id(32865950617450429)
,p_group_name=>'Administration'
,p_static_id=>'administration'
);
end;
/
prompt --application/shared_components/navigation/breadcrumbs/breadcrumb
begin
wwv_flow_imp_shared.create_menu(
 p_id=>wwv_flow_imp.id(32860863886450371)
,p_name=>'Breadcrumb'
,p_static_id=>'breadcrumb'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_menu_option(
 p_id=>wwv_flow_imp.id(32861000745450373)
,p_short_name=>'Home'
,p_static_id=>'home'
,p_link=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_page_id=>1
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/navigation/breadcrumbentry
begin
null;
end;
/
prompt --application/shared_components/user_interface/themes
begin
wwv_flow_imp_shared.create_theme(
 p_id=>wwv_flow_imp.id(32861748964450380)
,p_theme_id=>42
,p_static_id=>'universal-theme'
,p_theme_name=>'Universal Theme'
,p_theme_internal_name=>'UNIVERSAL_THEME'
,p_version_identifier=>'26.1'
,p_navigation_type=>'L'
,p_nav_bar_type=>'LIST'
,p_is_locked=>false
,p_current_theme_style_id=>2243014446517417
,p_default_page_template=>4073832297226169690
,p_default_dialog_template=>2101883943284197310
,p_error_template=>2102634289808461002
,p_printer_friendly_template=>4073832297226169690
,p_login_template=>2102634289808461002
,p_default_button_template=>4073839297780169708
,p_default_region_template=>4073835273271169698
,p_default_chart_template=>4073835273271169698
,p_default_form_template=>4073835273271169698
,p_default_reportr_template=>4073835273271169698
,p_default_wizard_template=>4073835273271169698
,p_default_menur_template=>2532939663579242476
,p_default_listr_template=>4073835273271169698
,p_default_irr_template=>2102002977963900996
,p_default_report_template=>2540130677583398057
,p_default_label_template=>1610598304472262251
,p_default_menu_template=>4073839682315169711
,p_default_list_template=>4073837480889169704
,p_default_top_nav_list_temp=>2528231041045349458
,p_default_side_nav_list_temp=>2469215554099805162
,p_default_nav_list_position=>'SIDE'
,p_default_dialogbtnr_template=>2127905476394690047
,p_default_dialogr_template=>4502917002193490937
,p_default_option_label=>1610598304472262251
,p_default_required_label=>1610598484065263269
,p_default_navbar_list_template=>2849019392706229583
,p_file_prefix=>nvl(wwv_flow_application_install.get_static_theme_file_prefix(42),'#APEX_FILES#themes/theme_42/26.1/')
,p_files_version=>64
,p_icon_library=>'FONTAPEX'
,p_javascript_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#APEX_FILES#libraries/apex/#MIN_DIRECTORY#widget.stickyWidget#MIN#.js?v=#APEX_VERSION#',
'#THEME_FILES#js/theme42#MIN#.js?v=#APEX_VERSION#'))
,p_css_file_urls=>'#THEME_FILES#css/Core#MIN#.css?v=#APEX_VERSION#'
,p_reference_id=>wwv_imp_util.get_subscription_id(4073840274158169736,2000,'universal-theme',8842.261)
,p_version_scn=>'SH256:RQZ7_KKNFF7leXIrwskeQw4WaazlZwly2sNGWk8hwQo'
,p_version_scn_master=>'SH256:WOPVC8vP1TPWUxczh2dJ4mCZcNGSTzA1cn8DjR2oQjY'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/user_interface/theme_style
begin
null;
end;
/
prompt --application/shared_components/user_interface/theme_files
begin
null;
end;
/
prompt --application/shared_components/user_interface/template_opt_groups
begin
null;
end;
/
prompt --application/shared_components/user_interface/template_options
begin
null;
end;
/
prompt --application/shared_components/globalization/language
begin
null;
end;
/
prompt --application/shared_components/globalization/translations
begin
null;
end;
/
prompt --application/shared_components/logic/build_options
begin
wwv_flow_imp_shared.create_build_option(
 p_id=>wwv_flow_imp.id(32860110613450363)
,p_build_option_name=>'Commented Out'
,p_static_id=>'commented-out'
,p_build_option_status=>'EXCLUDE'
,p_version_scn=>'SH256:1lQI3DW9n-0ZEGoDXUirkaB0JWCIATVWpJZCTCkODmI'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/shared_components/globalization/messages
begin
null;
end;
/
prompt --application/shared_components/globalization/dyntranslations
begin
null;
end;
/
prompt --application/shared_components/security/authentications/oracle_apex_accounts
begin
wwv_flow_imp_shared.create_authentication(
 p_id=>wwv_flow_imp.id(32860479883450368)
,p_name=>'Oracle APEX Accounts'
,p_static_id=>'oracle-apex-accounts'
,p_scheme_type=>'NATIVE_APEX_ACCOUNTS'
,p_invalid_session_type=>'LOGIN'
,p_use_secure_cookie_yn=>'N'
,p_ras_mode=>0
,p_version_scn=>'SH256:MwlwV9vQNyvTGV3nRFfTrp5n7mJ1Ugme2lUrlsOYuxw'
,p_created_on=>wwv_flow_imp.dz('20260917094839Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094839Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/user_interfaces/combined_files
begin
null;
end;
/
prompt --application/pages/page_00000
begin
wwv_flow_imp_page.create_page(
 p_id=>0
,p_name=>'Global Page'
,p_reload_on_submit=>null
,p_warn_on_unsaved_changes=>null
,p_autocomplete_on_off=>'OFF'
,p_protection_level=>'D'
,p_page_component_map=>'14'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_last_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_last_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/pages/page_00001
begin
wwv_flow_imp_page.create_page(
 p_id=>1
,p_name=>'Playground'
,p_alias=>'PLAYGROUND'
,p_step_title=>'Playground'
,p_autocomplete_on_off=>'OFF'
,p_javascript_file_urls=>'#APP_FILES#playground.js'
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_component_map=>'13'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(16453887687947821)
,p_plug_name=>'Prompt'
,p_static_id=>'prompt'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>'Send a prompt through the APEX AI Router. The browser calls only an APEX Ajax process; credentials stay on the server.'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(16453887687947822)
,p_plug_name=>'Response and request details'
,p_static_id=>'response-and-request-details'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>20
,p_plug_item_display_point=>'BELOW'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(16453887687947852)
,p_button_sequence=>50
,p_button_plug_id=>wwv_flow_imp.id(16453887687947821)
,p_button_name=>'P1_PLUGIN_ITEM'
,p_static_id=>'p1-plugin-item'
,p_button_static_id=>'P1_PLUGIN_ITEM'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Plug-in: Item / Efficient'
,p_button_position=>'CREATE'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(16453887687947853)
,p_button_sequence=>60
,p_button_plug_id=>wwv_flow_imp.id(16453887687947821)
,p_button_name=>'P1_PLUGIN_JS'
,p_static_id=>'p1-plugin-js'
,p_button_static_id=>'P1_PLUGIN_JS'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Plug-in: JavaScript / Capable'
,p_button_position=>'CREATE'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(16453887687947851)
,p_button_sequence=>40
,p_button_plug_id=>wwv_flow_imp.id(16453887687947821)
,p_button_name=>'P1_PLUGIN_STATIC'
,p_static_id=>'p1-plugin-static'
,p_button_static_id=>'P1_PLUGIN_STATIC'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Plug-in: Static / Auto'
,p_button_position=>'CREATE'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(16453887687947850)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_imp.id(16453887687947821)
,p_button_name=>'P1_SEND'
,p_static_id=>'p1-send'
,p_button_static_id=>'P1_SEND'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Send'
,p_button_position=>'CREATE'
,p_warn_on_unsaved_changes=>null
,p_button_cattributes=>'onclick="apexDemoPlayground.run(); return false;"'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947833)
,p_name=>'P1_ERROR'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Error'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947840)
,p_name=>'P1_ESTIMATED_BASELINE_COST'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Estimated capable-model baseline'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947839)
,p_name=>'P1_ESTIMATED_COST'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Estimated request cost'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947841)
,p_name=>'P1_ESTIMATED_SAVINGS'
,p_item_sequence=>100
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Estimated savings'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947837)
,p_name=>'P1_INPUT_TOKENS'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Input tokens'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947836)
,p_name=>'P1_LATENCY_MS'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Latency (ms)'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947838)
,p_name=>'P1_OUTPUT_TOKENS'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Output tokens'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947830)
,p_name=>'P1_PROMPT'
,p_is_required=>true
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(16453887687947821)
,p_prompt=>'Prompt'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXTAREA'
,p_cHeight=>8
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947842)
,p_name=>'P1_REQUEST_ID'
,p_item_sequence=>110
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Request ID'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947832)
,p_name=>'P1_RESULT'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Response'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXTAREA'
,p_cHeight=>10
,p_read_only_when_type=>'ALWAYS'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947831)
,p_name=>'P1_ROUTE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(16453887687947821)
,p_item_default=>'AUTO'
,p_prompt=>'Route'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>'STATIC:Auto;AUTO,Efficient;EFFICIENT,Capable;CAPABLE'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947835)
,p_name=>'P1_SELECTED_MODEL'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Selected model'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(16453887687947834)
,p_name=>'P1_SELECTED_TIER'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(16453887687947822)
,p_prompt=>'Selected tier'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>2320077351817916916
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(16453887687947874)
,p_name=>'Plugin Item Efficient'
,p_static_id=>'plugin-item-efficient'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(16453887687947852)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(16453887687947875)
,p_event_id=>wwv_flow_imp.id(16453887687947874)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_static_id=>'plugin-air-dynamic-action-generate'
,p_action=>'PLUGIN_AIR.DYNAMIC_ACTION.GENERATE'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'attribute_01', 'ITEM',
  'attribute_02', 'P1_PROMPT',
  'attribute_03', 'EFFICIENT',
  'attribute_04', 'P1_RESULT',
  'attribute_07', 'Y',
  'attribute_08', 'P1_ERROR')).to_clob
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(16453887687947876)
,p_name=>'Plugin JavaScript Capable'
,p_static_id=>'plugin-javascript-capable'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(16453887687947853)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(16453887687947877)
,p_event_id=>wwv_flow_imp.id(16453887687947876)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_static_id=>'plugin-air-dynamic-action-generate'
,p_action=>'PLUGIN_AIR.DYNAMIC_ACTION.GENERATE'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'attribute_01', 'JS_EXPRESSION',
  'attribute_02', '"JavaScript plug-in validation"',
  'attribute_03', 'CAPABLE',
  'attribute_04', 'P1_RESULT',
  'attribute_07', 'Y',
  'attribute_08', 'P1_ERROR')).to_clob
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(16453887687947872)
,p_name=>'Plugin Static Auto'
,p_static_id=>'plugin-static-auto'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_imp.id(16453887687947851)
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'click'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(16453887687947873)
,p_event_id=>wwv_flow_imp.id(16453887687947872)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_static_id=>'plugin-air-dynamic-action-generate'
,p_action=>'PLUGIN_AIR.DYNAMIC_ACTION.GENERATE'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'attribute_01', 'STATIC',
  'attribute_02', 'Static plug-in validation',
  'attribute_03', 'AUTO',
  'attribute_04', 'P1_RESULT',
  'attribute_07', 'Y',
  'attribute_08', 'P1_ERROR')).to_clob
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(16453887687947860)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'PLAYGROUND_RUN'
,p_static_id=>'playground-run'
,p_process_sql_clob=>'apex_ai_router_demo.ajax_run;'
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16453887687947860
);
end;
/
prompt --application/pages/page_00002
begin
wwv_flow_imp_page.create_page(
 p_id=>2
,p_name=>'Dashboard'
,p_alias=>'DASHBOARD'
,p_step_title=>'Dashboard'
,p_autocomplete_on_off=>'OFF'
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'(function ($) {',
'  "use strict";',
'  function call(name) { return new Promise(function (resolve, reject) {',
'    apex.server.process(name, {}, { dataType: "json", success: resolve, error: reject });',
'  }); }',
'  function value(v) { return v === null || v === undefined ? "n/a" : String(v); }',
'  function rows(target, values, cells) {',
'    $(target).html(values.map(function (row) {',
'      return "<tr>" + cells.map(function (cell) { return "<td>" + apex.util.escapeHTML(value(row[cell])) + "</td>"; }).join("") + "</tr>";',
'    }).join(""));',
'  }',
'  $(function () {',
'    Promise.all([call("DASHBOARD_SUMMARY"), call("DASHBOARD_MODELS"), call("DASHBOARD_DAILY")]).then(function (data) {',
'      var summary = data[0], models = data[1].models || [], daily = data[2].daily || [];',
'      $("#air-total").text(value(summary.requests));',
'      $("#air-success").text(summary.success_rate === null ? "n/a" : (summary.success_rate * 100).toFixed(1) + "%");',
'      $("#air-cost").text(value(summary.estimated_cost));',
'      $("#air-baseline").text(value(summary.estimated_capable_baseline_cost));',
'      $("#air-savings").text(value(summary.estimated_savings));',
'      rows("#air-models", models, ["model", "requests", "success_rate", "estimated_cost", "estimated_savings"]);',
'      rows("#air-daily", daily, ["date", "requests", "success_rate", "estimated_cost", "estimated_savings"]);',
'    }).catch(function () { $("#air-dashboard-error").text("Metrics are temporarily unavailable."); });',
'  });',
'})(apex.jQuery);'))
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_component_map=>'11'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(16453887688947821)
,p_plug_name=>'Gateway metrics'
,p_static_id=>'gateway-metrics'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div id="air-dashboard-error" class="u-danger-text"></div>',
'<div class="t-Cards"><div class="t-Card"><h3>Requests</h3><strong id="air-total">n/a</strong></div><div class="t-Card"><h3>Success rate</h3><strong id="air-success">n/a</strong></div><div class="t-Card"><h3>Estimated cost</h3><strong id="air-cost">n/'
||'a</strong></div><div class="t-Card"><h3>Estimated capable-model baseline</h3><strong id="air-baseline">n/a</strong></div><div class="t-Card"><h3>Estimated savings</h3><strong id="air-savings">n/a</strong></div></div>',
'<h3>Models</h3><table class="t-Report-report"><thead><tr><th>Model</th><th>Requests</th><th>Success rate</th><th>Estimated cost</th><th>Estimated savings</th></tr></thead><tbody id="air-models"></tbody></table>',
'<h3>Daily</h3><table class="t-Report-report"><thead><tr><th>Date</th><th>Requests</th><th>Success rate</th><th>Estimated cost</th><th>Estimated savings</th></tr></thead><tbody id="air-daily"></tbody></table>'))
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(16453887688947832)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DASHBOARD_DAILY'
,p_static_id=>'dashboard-daily'
,p_process_sql_clob=>'apex_ai_router_demo.ajax_proxy(''/admin/metrics/daily'');'
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16453887688947832
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(16453887688947831)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DASHBOARD_MODELS'
,p_static_id=>'dashboard-models'
,p_process_sql_clob=>'apex_ai_router_demo.ajax_proxy(''/admin/metrics/models'');'
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16453887688947831
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(16453887688947830)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DASHBOARD_SUMMARY'
,p_static_id=>'dashboard-summary'
,p_process_sql_clob=>'apex_ai_router_demo.ajax_proxy(''/admin/metrics/summary'');'
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16453887688947830
);
end;
/
prompt --application/pages/page_00003
begin
wwv_flow_imp_page.create_page(
 p_id=>3
,p_name=>'Request History'
,p_alias=>'REQUEST-HISTORY'
,p_step_title=>'Request History'
,p_autocomplete_on_off=>'OFF'
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'(function ($) {',
'  "use strict";',
'  function value(v) { return v === null || v === undefined ? "" : String(v); }',
'  $(function () {',
'    apex.server.process("REQUEST_HISTORY", {}, { dataType: "json", success: function (data) {',
'      var fields = ["timestamp", "route", "selected_target", "selected_model", "total_duration_ms", "input_tokens", "output_tokens", "estimated_cost", "estimated_savings", "http_status", "error_code"];',
'      $("#air-requests").html((data.requests || []).map(function (row) {',
'        var status = row.success ? ''<span class="u-success-text">OK</span>'' : ''<span class="u-danger-text">Failed</span>'';',
'        return "<tr>" + fields.map(function (field) { return "<td>" + apex.util.escapeHTML(value(row[field])) + "</td>"; }).join("") + "<td>" + status + "</td></tr>";',
'      }).join(""));',
'    }, error: function () { $("#air-history-error").text("Request history is temporarily unavailable."); } });',
'  });',
'})(apex.jQuery);'))
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_component_map=>'11'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(16453887689947821)
,p_plug_name=>'Recent gateway requests'
,p_static_id=>'recent-gateway-requests'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>'<div id="air-history-error" class="u-danger-text"></div><p>Prompt and response content are never returned by this report.</p><div class="t-Report"><table class="t-Report-report"><thead><tr><th>Timestamp</th><th>Route</th><th>Target</th><th>Model</th>'
||'<th>Latency ms</th><th>Input tokens</th><th>Output tokens</th><th>Estimated cost</th><th>Estimated savings</th><th>HTTP</th><th>Error</th><th>Status</th></tr></thead><tbody id="air-requests"></tbody></table></div>'
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(16453887689947830)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'REQUEST_HISTORY'
,p_static_id=>'request-history'
,p_process_sql_clob=>'apex_ai_router_demo.ajax_proxy(''/admin/requests?limit=100&offset=0'');'
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16453887689947830
);
end;
/
prompt --application/pages/page_00004
begin
wwv_flow_imp_page.create_page(
 p_id=>4
,p_name=>'Configuration Help'
,p_alias=>'CONFIGURATION-HELP'
,p_step_title=>'Configuration Help'
,p_autocomplete_on_off=>'OFF'
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'(function ($) {',
'  "use strict";',
'  function call(name) { return new Promise(function (resolve, reject) {',
'    apex.server.process(name, {}, { dataType: "json", success: resolve, error: reject });',
'  }); }',
'  $(function () {',
'    Promise.all([call("ROUTES_DATA"), call("HEALTH_DATA"), call("READY_DATA")]).then(function (data) {',
'      var routes = data[0], health = data[1], ready = data[2];',
'      $("#air-health").text(health.status || "unknown");',
'      $("#air-ready").text(ready.status || "unknown");',
'      $("#air-routes").html(Object.keys(routes.routes || {}).map(function (name) {',
'        var route = routes.routes[name], target = route.target || route.switchyard_target || "n/a";',
'        return "<tr><td>" + apex.util.escapeHTML(name) + "</td><td>" + apex.util.escapeHTML(route.strategy) + "</td><td>" + apex.util.escapeHTML(target) + "</td></tr>";',
'      }).join(""));',
'      $("#air-targets").html(Object.keys(routes.targets || {}).map(function (name) {',
'        var target = routes.targets[name];',
'        return "<tr><td>" + apex.util.escapeHTML(name) + "</td><td>" + apex.util.escapeHTML(target.provider) + "</td><td>" + apex.util.escapeHTML(target.model) + "</td></tr>";',
'      }).join(""));',
'    }).catch(function () { $("#air-config-error").text("Gateway status is temporarily unavailable."); });',
'  });',
'})(apex.jQuery);'))
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_component_map=>'11'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(16453887690947821)
,p_plug_name=>'Gateway configuration and status'
,p_static_id=>'gateway-configuration-and-status'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>'<div id="air-config-error" class="u-danger-text"></div><p><strong>Gateway API base:</strong> http://localhost:8081/v1</p><p><strong>Health:</strong> <span id="air-health">checking</span> &nbsp; <strong>Readiness:</strong> <span id="air-ready">checkin'
||'g</span></p><p>See <code>docs/apex-ai-setup.md</code> for native APEX_AI configuration. Credentials remain server-side.</p><h3>Routes</h3><table class="t-Report-report"><thead><tr><th>Route</th><th>Strategy</th><th>Target</th></tr></thead><tbody id="'
||'air-routes"></tbody></table><h3>Resolved targets</h3><table class="t-Report-report"><thead><tr><th>Target</th><th>Provider</th><th>Model</th></tr></thead><tbody id="air-targets"></tbody></table>'
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(16453887690947831)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'HEALTH_DATA'
,p_static_id=>'health-data'
,p_process_sql_clob=>'apex_ai_router_demo.ajax_proxy(''/health'', false);'
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16453887690947831
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(16453887690947832)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'READY_DATA'
,p_static_id=>'ready-data'
,p_process_sql_clob=>'apex_ai_router_demo.ajax_proxy(''/ready'', false);'
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16453887690947832
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(16453887690947830)
,p_process_sequence=>10
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'ROUTES_DATA'
,p_static_id=>'routes-data'
,p_process_sql_clob=>'apex_ai_router_demo.ajax_proxy(''/admin/routes'');'
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16453887690947830
);
end;
/
prompt --application/pages/page_09999
begin
wwv_flow_imp_page.create_page(
 p_id=>9999
,p_name=>'Login Page'
,p_alias=>'LOGIN'
,p_step_title=>'APEX AI Router Demo - Log In'
,p_warn_on_unsaved_changes=>'N'
,p_first_item=>'AUTO_FIRST_ITEM'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>2102634289808461002
,p_page_template_options=>'#DEFAULT#'
,p_page_is_public_y_n=>'Y'
,p_protection_level=>'C'
,p_page_component_map=>'12'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_last_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_last_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(32866535065450437)
,p_plug_name=>'APEX AI Router Demo'
,p_static_id=>'apex-ai-router-demo'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>2675634334296186762
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'ABOVE'
,p_region_image=>'#APP_FILES#icons/app-icon-512.png'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(32868136608450446)
,p_button_sequence=>40
,p_button_plug_id=>wwv_flow_imp.id(32866535065450437)
,p_button_name=>'LOGIN'
,p_static_id=>'login'
,p_show_as_disabled=>false
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Sign In'
,p_button_position=>'NEXT'
,p_grid_new_row=>'Y'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(32867405959450443)
,p_name=>'P9999_PASSWORD'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(32866535065450437)
,p_prompt=>'Password'
,p_placeholder=>'Password'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_PASSWORD'
,p_cSize=>40
,p_cMaxlength=>100
,p_tag_attributes=>'autocomplete="current-password"'
,p_label_alignment=>'RIGHT'
,p_field_template=>2042262243893469891
,p_item_icon_css_classes=>'fa-key'
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'submit_when_enter_pressed', 'Y')).to_clob
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(32867852607450446)
,p_name=>'P9999_REMEMBER'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(32866535065450437)
,p_prompt=>'Remember username'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_SINGLE_CHECKBOX'
,p_label_alignment=>'RIGHT'
,p_display_when=>'apex_authentication.persistent_cookies_enabled'
,p_display_when2=>'PLSQL'
,p_display_when_type=>'EXPRESSION'
,p_field_template=>2042262243893469891
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'use_defaults', 'Y')).to_clob
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(32867032230450443)
,p_name=>'P9999_USERNAME'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(32866535065450437)
,p_prompt=>'Username'
,p_placeholder=>'Username'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>40
,p_cMaxlength=>100
,p_tag_attributes=>'autocomplete="username"'
,p_label_alignment=>'RIGHT'
,p_field_template=>2042262243893469891
,p_item_icon_css_classes=>'fa-user'
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'N',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(32872268977450451)
,p_process_sequence=>30
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_SESSION_STATE'
,p_process_name=>'Clear Page(s) Cache'
,p_static_id=>'clear-page-s-cache'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'type', 'CLEAR_CACHE_CURRENT_PAGE')).to_clob
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_internal_uid=>16423172905557078
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(32871842276450451)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Get Username Cookie'
,p_static_id=>'get-username-cookie'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
':P9999_USERNAME := apex_authentication.get_login_username_cookie;',
':P9999_REMEMBER := case when :P9999_USERNAME is not null then ''Y'' end;'))
,p_process_clob_language=>'PLSQL'
,p_internal_uid=>16422746204557078
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(32868521876450448)
,p_process_sequence=>20
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_INVOKE_API'
,p_process_name=>'Login'
,p_static_id=>'login'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'package', 'APEX_AUTHENTICATION',
  'package_method', 'LOGIN',
  'type', 'PLSQL_PACKAGE')).to_clob
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_internal_uid=>16419425804557075
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_invokeapi_comp_param(
 p_id=>wwv_flow_imp.id(32869540067450449)
,p_page_process_id=>wwv_flow_imp.id(32868521876450448)
,p_page_id=>9999
,p_name=>'p_password'
,p_direction=>'IN'
,p_data_type=>'VARCHAR2'
,p_has_default=>false
,p_display_sequence=>2
,p_value_type=>'ITEM'
,p_value=>'P9999_PASSWORD'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_invokeapi_comp_param(
 p_id=>wwv_flow_imp.id(32870023709450451)
,p_page_process_id=>wwv_flow_imp.id(32868521876450448)
,p_page_id=>9999
,p_name=>'p_set_persistent_auth'
,p_direction=>'IN'
,p_data_type=>'BOOLEAN'
,p_has_default=>true
,p_display_sequence=>3
,p_value_type=>'API_DEFAULT'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_invokeapi_comp_param(
 p_id=>wwv_flow_imp.id(32869028926450449)
,p_page_process_id=>wwv_flow_imp.id(32868521876450448)
,p_page_id=>9999
,p_name=>'p_username'
,p_direction=>'IN'
,p_data_type=>'VARCHAR2'
,p_has_default=>false
,p_display_sequence=>1
,p_value_type=>'ITEM'
,p_value=>'P9999_USERNAME'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(32870430277450451)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_INVOKE_API'
,p_process_name=>'Set Username Cookie'
,p_static_id=>'set-username-cookie'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'package', 'APEX_AUTHENTICATION',
  'package_method', 'SEND_LOGIN_USERNAME_COOKIE',
  'type', 'PLSQL_PACKAGE')).to_clob
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_internal_uid=>16421334205557078
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_invokeapi_comp_param(
 p_id=>wwv_flow_imp.id(32871422774450451)
,p_page_process_id=>wwv_flow_imp.id(32870430277450451)
,p_page_id=>9999
,p_name=>'p_consent'
,p_direction=>'IN'
,p_data_type=>'BOOLEAN'
,p_has_default=>false
,p_display_sequence=>2
,p_value_type=>'ITEM'
,p_value=>'P9999_REMEMBER'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
wwv_flow_imp_shared.create_invokeapi_comp_param(
 p_id=>wwv_flow_imp.id(32870950569450451)
,p_page_process_id=>wwv_flow_imp.id(32870430277450451)
,p_page_id=>9999
,p_name=>'p_username'
,p_direction=>'IN'
,p_data_type=>'VARCHAR2'
,p_has_default=>false
,p_display_sequence=>1
,p_value_type=>'EXPRESSION'
,p_value_language=>'PLSQL'
,p_value=>'lower( :P9999_USERNAME )'
,p_created_on=>wwv_flow_imp.dz('20260917094840Z')
,p_updated_on=>wwv_flow_imp.dz('20260917094840Z')
,p_created_by=>'AIR_ADMIN'
,p_updated_by=>'AIR_ADMIN'
);
end;
/
prompt --application/deployment/definition
begin
null;
end;
/
prompt --application/deployment/checks
begin
null;
end;
/
prompt --application/deployment/buildoptions
begin
null;
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
