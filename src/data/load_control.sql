generated_exec
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.variance_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'variance_document_xref',
    @source_query_template = 'SELECT *
FROM public.variance_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO

EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_document_identity_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_document_identity_xref',
    @source_query_template = 'SELECT *
FROM public.now_application_document_identity_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_ministry_comment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_ministry_comment',
    @source_query_template = 'SELECT *
FROM public.project_summary_ministry_comment
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_category_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_category_xref',
    @source_query_template = 'SELECT *
FROM public.mine_incident_category_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_req_permit_condition_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_req_permit_condition_xref',
    @source_query_template = 'SELECT *
FROM public.mine_report_req_permit_condition_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident',
    @source_query_template = 'SELECT *
FROM public.mine_incident
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.document_manager',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'document_manager',
    @source_query_template = 'SELECT *
FROM public.document_manager
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_alert',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_alert',
    @source_query_template = 'SELECT *
FROM public.mine_alert
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.etl_permit',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'etl_permit',
    @source_query_template = 'SELECT *
FROM public.etl_permit',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.party_business_role_appt',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'party_business_role_appt',
    @source_query_template = 'SELECT *
FROM public.party_business_role_appt
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.notice_of_departure',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'notice_of_departure',
    @source_query_template = 'SELECT *
FROM public.notice_of_departure
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit',
    @source_query_template = 'SELECT *
FROM public.explosives_permit
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.etl_activity_detail',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'etl_activity_detail',
    @source_query_template = 'SELECT *
FROM public.etl_activity_detail',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.camp_detail',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'camp_detail',
    @source_query_template = 'SELECT *
FROM public.camp_detail',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.etl_mine',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'etl_mine',
    @source_query_template = 'SELECT *
FROM public.etl_mine',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.etl_bond',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'etl_bond',
    @source_query_template = 'SELECT *
FROM public.etl_bond',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_MTA.MTA_TENURE',
    @source_system = 'MTOPROD',
    @source_entity = 'MTA.MTA_TENURE',
    @source_connection_string = 'nrkdb02.bcgov:1521/mtoprod.nrs.bcgov',
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net/',
    @target_schema = 'bronze',
    @target_table = 'MTA_TENURE',
    @source_query_template = 'SELECT * FROM MTA.MTA_TENURE',
    @watermark_column = 'TENURE_NUMBER_ID',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_amendment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_amendment',
    @source_query_template = 'SELECT *
FROM public.permit_amendment
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.camp',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'camp',
    @source_query_template = 'SELECT *
FROM public.camp',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_tier',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_tier',
    @source_query_template = 'SELECT *
FROM public.now_application_tier
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.required_document_due_date_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'required_document_due_date_type',
    @source_query_template = 'SELECT *
FROM public.required_document_due_date_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_gis_export_view2',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_gis_export_view2',
    @source_query_template = 'SELECT *
FROM public.now_application_gis_export_view2',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_conditions',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_conditions',
    @source_query_template = 'SELECT *
FROM public.permit_conditions
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.itrb_exemption_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'itrb_exemption_status',
    @source_query_template = 'SELECT *
FROM public.itrb_exemption_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.help',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'help',
    @source_query_template = 'SELECT *
FROM public.help
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.sub_division_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'sub_division_code',
    @source_query_template = 'SELECT *
FROM public.sub_division_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.user',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'user',
    @source_query_template = 'SELECT *
FROM public.user
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit_amendment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit_amendment',
    @source_query_template = 'SELECT *
FROM public.explosives_permit_amendment
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.bond_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'bond_type',
    @source_query_template = 'SELECT *
FROM public.bond_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_progress',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_progress',
    @source_query_template = 'SELECT *
FROM public.now_application_progress
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.information_requirements_table',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'information_requirements_table',
    @source_query_template = 'SELECT *
FROM public.information_requirements_table
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_authorization_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_authorization_document_xref',
    @source_query_template = 'SELECT *
FROM public.project_summary_authorization_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_disturbance_tenure_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_disturbance_tenure_type',
    @source_query_template = 'SELECT *
FROM public.mine_disturbance_tenure_type',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.bond_permit_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'bond_permit_xref',
    @source_query_template = 'SELECT *
FROM public.bond_permit_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_type_detail_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_type_detail_xref',
    @source_query_template = 'SELECT *
FROM public.mine_type_detail_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.article_act_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'article_act_code',
    @source_query_template = 'SELECT *
FROM public.article_act_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.etl_equipment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'etl_equipment',
    @source_query_template = 'SELECT *
FROM public.etl_equipment',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.subscription',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'subscription',
    @source_query_template = 'SELECT *
FROM public.subscription',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.activity_equipment_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'activity_equipment_xref',
    @source_query_template = 'SELECT *
FROM public.activity_equipment_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_status_code',
    @source_query_template = 'SELECT *
FROM public.mine_incident_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.ams_final_application_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'ams_final_application_document_xref',
    @source_query_template = 'SELECT *
FROM public.ams_final_application_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_delay',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_delay',
    @source_query_template = 'SELECT *
FROM public.now_application_delay
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds_nris',
    @source_system = 'mds',
    @source_entity = 'nris.work_order_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'nris_work_order_status',
    @source_query_template = 'SELECT *
FROM nris.work_order_status',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.duplicate_permit_mapping',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'duplicate_permit_mapping',
    @source_query_template = 'SELECT *
FROM public.duplicate_permit_mapping',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.settling_pond_detail',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'settling_pond_detail',
    @source_query_template = 'SELECT *
FROM public.settling_pond_detail',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit_magazine_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit_magazine_type',
    @source_query_template = 'SELECT *
FROM public.explosives_permit_magazine_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds_nris',
    @source_system = 'mds',
    @source_entity = 'nris.inspection_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'nris_inspection_document_xref',
    @source_query_template = 'SELECT *
FROM nris.inspection_document_xref',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_document',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_document',
    @source_query_template = 'SELECT *
FROM public.mine_document
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.minespace_user',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'minespace_user',
    @source_query_template = 'SELECT *
FROM public.minespace_user
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit_document_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit_document_type',
    @source_query_template = 'SELECT *
FROM public.explosives_permit_document_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permits_to_delete',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permits_to_delete',
    @source_query_template = 'SELECT *
FROM public.permits_to_delete',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_contact',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_contact',
    @source_query_template = 'SELECT *
FROM public.project_contact
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds_nris',
    @source_system = 'mds',
    @source_entity = 'nris.mine_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'nris_mine_type',
    @source_query_template = 'SELECT *
FROM nris.mine_type',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.water_supply_detail',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'water_supply_detail',
    @source_query_template = 'SELECT *
FROM public.water_supply_detail',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_document_type_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_document_type_code',
    @source_query_template = 'SELECT *
FROM public.mine_incident_document_type_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_submission_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_submission_status_code',
    @source_query_template = 'SELECT *
FROM public.mine_report_submission_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.core_user',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'core_user',
    @source_query_template = 'SELECT *
FROM public.core_user
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_status_code',
    @source_query_template = 'SELECT *
FROM public.permit_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_link',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_link',
    @source_query_template = 'SELECT *
FROM public.project_link
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_amendment_type_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_amendment_type_code',
    @source_query_template = 'SELECT *
FROM public.permit_amendment_type_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.ams_final_application',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'ams_final_application',
    @source_query_template = 'SELECT *
FROM public.ams_final_application
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_amendment_document',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_amendment_document',
    @source_query_template = 'SELECT *
FROM public.permit_amendment_document
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.etl_manager',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'etl_manager',
    @source_query_template = 'SELECT *
FROM public.etl_manager',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.requirements',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'requirements',
    @source_query_template = 'SELECT *
FROM public.requirements
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_party_appointment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_party_appointment',
    @source_query_template = 'SELECT *
FROM public.now_party_appointment
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.underground_exploration_detail',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'underground_exploration_detail',
    @source_query_template = 'SELECT *
FROM public.underground_exploration_detail',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.bond_document_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'bond_document_type',
    @source_query_template = 'SELECT *
FROM public.bond_document_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_followup_investigation_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_followup_investigation_type',
    @source_query_template = 'SELECT *
FROM public.mine_incident_followup_investigation_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.user_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'user_version',
    @source_query_template = 'SELECT *
FROM public.user_version
WHERE update_timestamp >= @from_date
  AND update_timestamp < @to_date',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.exploration_surface_drilling',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'exploration_surface_drilling',
    @source_query_template = 'SELECT *
FROM public.exploration_surface_drilling',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.variance_document_category_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'variance_document_category_code',
    @source_query_template = 'SELECT *
FROM public.variance_document_category_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds_nris',
    @source_system = 'mds',
    @source_entity = 'nris.inspection',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'nris_inspection',
    @source_query_template = 'SELECT *
FROM nris.inspection',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_document_sub_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_document_sub_type',
    @source_query_template = 'SELECT *
FROM public.now_application_document_sub_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit',
    @source_query_template = 'SELECT *
FROM public.permit
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.equipment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'equipment',
    @source_query_template = 'SELECT *
FROM public.equipment
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_condition_category',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_condition_category',
    @source_query_template = 'SELECT *
FROM public.permit_condition_category
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_document_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_document_version',
    @source_query_template = 'SELECT *
FROM public.mine_document_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_condition_review_assignment_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_condition_review_assignment_version',
    @source_query_template = 'SELECT *
FROM public.permit_condition_review_assignment_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.minespace_user_mds_mine_access',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'minespace_user_mds_mine_access',
    @source_query_template = 'SELECT *
FROM public.minespace_user_mds_mine_access',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.building_detail',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'building_detail',
    @source_query_template = 'SELECT *
FROM public.building_detail',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.reclamation_invoice',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'reclamation_invoice',
    @source_query_template = 'SELECT *
FROM public.reclamation_invoice
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_review_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_review_type',
    @source_query_template = 'SELECT *
FROM public.now_application_review_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_contact',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_contact',
    @source_query_template = 'SELECT *
FROM public.project_summary_contact
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.etl_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'etl_status',
    @source_query_template = 'SELECT *
FROM public.etl_status',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.emli_contact',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'emli_contact',
    @source_query_template = 'SELECT *
FROM public.emli_contact
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.party_orgbook_entity',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'party_orgbook_entity',
    @source_query_template = 'SELECT *
FROM public.party_orgbook_entity
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.bond_history',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'bond_history',
    @source_query_template = 'SELECT *
FROM public.bond_history
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.address_type_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'address_type_code',
    @source_query_template = 'SELECT *
FROM public.address_type_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.municipality',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'municipality',
    @source_query_template = 'SELECT *
FROM public.municipality
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_permit_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_permit_type',
    @source_query_template = 'SELECT *
FROM public.project_summary_permit_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.party_verifiable_credential_connection',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'party_verifiable_credential_connection',
    @source_query_template = 'SELECT *
FROM public.party_verifiable_credential_connection
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.major_mine_application_document_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'major_mine_application_document_type',
    @source_query_template = 'SELECT *
FROM public.major_mine_application_document_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_amendment_orgbook_publish_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_amendment_orgbook_publish_status',
    @source_query_template = 'SELECT *
FROM public.permit_amendment_orgbook_publish_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_document_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_document_type',
    @source_query_template = 'SELECT *
FROM public.now_application_document_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_due_date_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_due_date_type',
    @source_query_template = 'SELECT *
FROM public.mine_report_due_date_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_condition_tag',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_condition_tag',
    @source_query_template = 'SELECT *
FROM public.permit_condition_tag
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.surface_bulk_sample',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'surface_bulk_sample',
    @source_query_template = 'SELECT *
FROM public.surface_bulk_sample',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.activity_summary',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'activity_summary',
    @source_query_template = 'SELECT *
FROM public.activity_summary
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.tsf_operating_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'tsf_operating_status',
    @source_query_template = 'SELECT *
FROM public.tsf_operating_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_note',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_note',
    @source_query_template = 'SELECT *
FROM public.mine_incident_note
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_decision_package_document_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_decision_package_document_type',
    @source_query_template = 'SELECT *
FROM public.project_decision_package_document_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.regional_contact',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'regional_contact',
    @source_query_template = 'SELECT *
FROM public.regional_contact',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.activity_detail',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'activity_detail',
    @source_query_template = 'SELECT *
FROM public.activity_detail
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds_nris',
    @source_system = 'mds',
    @source_entity = 'nris.location',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'nris_location',
    @source_query_template = 'SELECT *
FROM nris.location',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.ams_final_application_document_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'ams_final_application_document_type',
    @source_query_template = 'SELECT *
FROM public.ams_final_application_document_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_permit_requirement_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_permit_requirement_version',
    @source_query_template = 'SELECT *
FROM public.mine_report_permit_requirement_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.notice_of_work_tier',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'notice_of_work_tier',
    @source_query_template = 'SELECT *
FROM public.notice_of_work_tier
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.party',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'party',
    @source_query_template = 'SELECT *
FROM public.party
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_MTA.MTA_TENURE_EVENT_XREF',
    @source_system = 'MTOPROD',
    @source_entity = 'MTA.MTA_TENURE_EVENT_XREF',
    @source_connection_string = 'nrkdb02.bcgov:1521/mtoprod.nrs.bcgov',
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net/',
    @target_schema = 'bronze',
    @target_table = 'MTA_TENURE_EVENT_XREF',
    @source_query_template = '
SELECT *
FROM MTA.MTA_TENURE t
INNER JOIN MTA.MTA_TENURE_EVENT_XREF x
    ON t.TENURE_NUMBER_ID = x.TENURE_NUMBER_ID
INNER JOIN MTA.MTA_EVENT e
    ON x.EVENT_NUMBER_ID = e.EVENT_NUMBER_ID',
    @watermark_column = 'TENURE_NUMBER_ID',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_document_xref',
    @source_query_template = 'SELECT *
FROM public.mine_incident_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_document_xref',
    @source_query_template = 'SELECT *
FROM public.project_summary_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_MTA.MTA_EVENT',
    @source_system = 'MTOPROD',
    @source_entity = 'MTA.MTA_EVENT',
    @source_connection_string = 'nrkdb02.bcgov:1521/mtoprod.nrs.bcgov',
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net/',
    @target_schema = 'bronze',
    @target_table = 'MTA_EVENT',
    @source_query_template = 'SELECT * FROM MTA.MTA_EVENT',
    @watermark_column = 'EVENT_NUMBER_ID',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_document_bundle',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_document_bundle',
    @source_query_template = 'SELECT *
FROM public.mine_document_bundle
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_category',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_category',
    @source_query_template = 'SELECT *
FROM public.mine_report_category
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.unit_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'unit_type',
    @source_query_template = 'SELECT *
FROM public.unit_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report',
    @source_query_template = 'SELECT *
FROM public.mine_report
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.activity_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'activity_type',
    @source_query_template = 'SELECT *
FROM public.activity_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.notice_of_departure_contact',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'notice_of_departure_contact',
    @source_query_template = 'SELECT *
FROM public.notice_of_departure_contact
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_authorization',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_authorization',
    @source_query_template = 'SELECT *
FROM public.project_summary_authorization
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.minespace_user_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'minespace_user_document_xref',
    @source_query_template = 'SELECT *
FROM public.minespace_user_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.minespace_user_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'minespace_user_version',
    @source_query_template = 'SELECT *
FROM public.minespace_user_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_tenure_type_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_tenure_type_code',
    @source_query_template = 'SELECT *
FROM public.mine_tenure_type_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_identity',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_identity',
    @source_query_template = 'SELECT *
FROM public.now_application_identity
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_status_code',
    @source_query_template = 'SELECT *
FROM public.project_summary_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.variance',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'variance',
    @source_query_template = 'SELECT *
FROM public.variance
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.major_mine_application_document_subtype',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'major_mine_application_document_subtype',
    @source_query_template = 'SELECT *
FROM public.major_mine_application_document_subtype
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit_amendment_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit_amendment_document_xref',
    @source_query_template = 'SELECT *
FROM public.explosives_permit_amendment_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.email_tracking',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'email_tracking',
    @source_query_template = 'SELECT *
FROM public.email_tracking
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.idir_user_detail',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'idir_user_detail',
    @source_query_template = 'SELECT *
FROM public.idir_user_detail
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_req_permit_condition_xref_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_req_permit_condition_xref_version',
    @source_query_template = 'SELECT *
FROM public.mine_report_req_permit_condition_xref_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_permit_requirement',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_permit_requirement',
    @source_query_template = 'SELECT *
FROM public.mine_report_permit_requirement
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.transaction',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'transaction',
    @source_query_template = 'SELECT *
FROM public.transaction',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_type',
    @source_query_template = 'SELECT *
FROM public.mine_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_status',
    @source_query_template = 'SELECT *
FROM public.now_application_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.activity_summary_staging_area_detail_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'activity_summary_staging_area_detail_xref',
    @source_query_template = 'SELECT *
FROM public.activity_summary_staging_area_detail_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_party_appt_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_party_appt_document_xref',
    @source_query_template = 'SELECT *
FROM public.mine_party_appt_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.government_agency_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'government_agency_type',
    @source_query_template = 'SELECT *
FROM public.government_agency_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_conditions_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_conditions_version',
    @source_query_template = 'SELECT *
FROM public.permit_conditions_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_tier_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_tier_version',
    @source_query_template = 'SELECT *
FROM public.now_application_tier_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_region_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_region_code',
    @source_query_template = 'SELECT *
FROM public.mine_region_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_commodity_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_commodity_code',
    @source_query_template = 'SELECT *
FROM public.mine_commodity_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.regions',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'regions',
    @source_query_template = 'SELECT *
FROM public.regions
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.bond',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'bond',
    @source_query_template = 'SELECT *
FROM public.bond
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_party_appt',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_party_appt',
    @source_query_template = 'SELECT *
FROM public.mine_party_appt
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_settling_pond_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_settling_pond_xref',
    @source_query_template = 'SELECT *
FROM public.now_application_settling_pond_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project',
    @source_query_template = 'SELECT *
FROM public.project
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine',
    @source_query_template = 'SELECT
    mine_guid, create_user, create_timestamp, update_user, update_timestamp,
    mine_no, mine_name, mine_note, major_mine_ind, mine_region, deleted_ind,
    union_ind, ohsc_ind, latitude, longitude, mine_location_description,
    legacy_mms_mine_status, exemption_fee_status_code, exemption_fee_status_note,
    mms_alias, mine_no_sequence, government_agency_type_code,
    number_of_contractors, number_of_mine_employees, mine_timezone,
    geom::text AS geom
FROM public.mine
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.state_of_land',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'state_of_land',
    @source_query_template = 'SELECT *
FROM public.state_of_land',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_status_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_status_xref',
    @source_query_template = 'SELECT *
FROM public.mine_status_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit_amendment_magazine',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit_amendment_magazine',
    @source_query_template = 'SELECT *
FROM public.explosives_permit_amendment_magazine
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.party_type_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'party_type_code',
    @source_query_template = 'SELECT *
FROM public.party_type_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary',
    @source_query_template = 'SELECT *
FROM public.project_summary
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.information_requirements_table_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'information_requirements_table_status_code',
    @source_query_template = 'SELECT *
FROM public.information_requirements_table_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.bond_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'bond_status',
    @source_query_template = 'SELECT *
FROM public.bond_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit_magazine',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit_magazine',
    @source_query_template = 'SELECT *
FROM public.explosives_permit_magazine
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.standard_permit_conditions',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'standard_permit_conditions',
    @source_query_template = 'SELECT *
FROM public.standard_permit_conditions
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds_nris',
    @source_system = 'mds',
    @source_entity = 'nris.activity',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'nris_activity',
    @source_query_template = 'SELECT *
FROM nris.activity',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.tmp1',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'tmp1',
    @source_query_template = 'SELECT *
FROM public.tmp1',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.application_source_type_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'application_source_type_code',
    @source_query_template = 'SELECT *
FROM public.application_source_type_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.application_type_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'application_type_code',
    @source_query_template = 'SELECT *
FROM public.application_type_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_determination_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_determination_type',
    @source_query_template = 'SELECT *
FROM public.mine_incident_determination_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_verified_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_verified_status',
    @source_query_template = 'SELECT *
FROM public.mine_verified_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_decision_package_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_decision_package_document_xref',
    @source_query_template = 'SELECT *
FROM public.project_decision_package_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_commodity_tenure_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_commodity_tenure_type',
    @source_query_template = 'SELECT *
FROM public.mine_commodity_tenure_type',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_decision_package_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_decision_package_status_code',
    @source_query_template = 'SELECT *
FROM public.project_decision_package_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.celery_taskmeta',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'celery_taskmeta',
    @source_query_template = 'SELECT *
FROM public.celery_taskmeta',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_condition_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_condition_type',
    @source_query_template = 'SELECT *
FROM public.permit_condition_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.exploration_access',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'exploration_access',
    @source_query_template = 'SELECT *
FROM public.exploration_access',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_work_information',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_work_information',
    @source_query_template = 'SELECT *
FROM public.mine_work_information
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_notification',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_notification',
    @source_query_template = 'SELECT *
FROM public.mine_report_notification',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_category_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_category_xref',
    @source_query_template = 'SELECT *
FROM public.mine_report_category_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.activity_summary_building_detail_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'activity_summary_building_detail_xref',
    @source_query_template = 'SELECT *
FROM public.activity_summary_building_detail_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.regional_contact_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'regional_contact_type',
    @source_query_template = 'SELECT *
FROM public.regional_contact_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.tmp2',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'tmp2',
    @source_query_template = 'SELECT *
FROM public.tmp2',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.compliance_article',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'compliance_article',
    @source_query_template = 'SELECT *
FROM public.compliance_article
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_party_appt_type_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_party_appt_type_code',
    @source_query_template = 'SELECT *
FROM public.mine_party_appt_type_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_comment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_comment',
    @source_query_template = 'SELECT *
FROM public.mine_report_comment
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.exemption_fee_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'exemption_fee_status',
    @source_query_template = 'SELECT *
FROM public.exemption_fee_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds_nris',
    @source_system = 'mds',
    @source_entity = 'nris.document',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'nris_document',
    @source_query_template = 'SELECT *
FROM nris.document',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_operation_status_reason_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_operation_status_reason_code',
    @source_query_template = 'SELECT *
FROM public.mine_operation_status_reason_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_extraction_task',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_extraction_task',
    @source_query_template = 'SELECT *
FROM public.permit_extraction_task
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_operation_status_sub_reason_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_operation_status_sub_reason_code',
    @source_query_template = 'SELECT *
FROM public.mine_operation_status_sub_reason_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.ses_bond_staging',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'ses_bond_staging',
    @source_query_template = 'SELECT *
FROM public.ses_bond_staging',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_condition_review_assignment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_condition_review_assignment',
    @source_query_template = 'SELECT *
FROM public.permit_condition_review_assignment
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_disturbance_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_disturbance_code',
    @source_query_template = 'SELECT *
FROM public.mine_disturbance_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.celery_tasksetmeta',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'celery_tasksetmeta',
    @source_query_template = 'SELECT *
FROM public.celery_tasksetmeta',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.information_requirements_table_document_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'information_requirements_table_document_type',
    @source_query_template = 'SELECT *
FROM public.information_requirements_table_document_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit_document_xref',
    @source_query_template = 'SELECT *
FROM public.explosives_permit_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_document_xref',
    @source_query_template = 'SELECT *
FROM public.mine_report_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_placer_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_placer_xref',
    @source_query_template = 'SELECT *
FROM public.now_application_placer_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.etl_location',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'etl_location',
    @source_query_template = 'SELECT *
FROM public.etl_location',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.address',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'address',
    @source_query_template = 'SELECT *
FROM public.address
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_contact',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_contact',
    @source_query_template = 'SELECT *
FROM public.mine_report_contact',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.irt_requirements_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'irt_requirements_xref',
    @source_query_template = 'SELECT *
FROM public.irt_requirements_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.notice_of_departure_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'notice_of_departure_document_xref',
    @source_query_template = 'SELECT *
FROM public.notice_of_departure_document_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.party_business_role_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'party_business_role_code',
    @source_query_template = 'SELECT *
FROM public.party_business_role_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.consequence_classification_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'consequence_classification_status',
    @source_query_template = 'SELECT *
FROM public.consequence_classification_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_condition_category_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_condition_category_version',
    @source_query_template = 'SELECT *
FROM public.permit_condition_category_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.ams_final_application_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'ams_final_application_version',
    @source_query_template = 'SELECT *
FROM public.ams_final_application_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_category',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_category',
    @source_query_template = 'SELECT *
FROM public.mine_incident_category
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_operation_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_operation_status_code',
    @source_query_template = 'SELECT *
FROM public.mine_operation_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_progress_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_progress_status',
    @source_query_template = 'SELECT *
FROM public.now_application_progress_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_authorization_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_authorization_type',
    @source_query_template = 'SELECT *
FROM public.project_summary_authorization_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.major_mine_application',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'major_mine_application',
    @source_query_template = 'SELECT *
FROM public.major_mine_application
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.dam_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'dam_version',
    @source_query_template = 'SELECT *
FROM public.dam_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.major_mine_application_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'major_mine_application_status_code',
    @source_query_template = 'SELECT *
FROM public.major_mine_application_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.idir_membership',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'idir_membership',
    @source_query_template = 'SELECT *
FROM public.idir_membership
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.underground_exploration',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'underground_exploration',
    @source_query_template = 'SELECT *
FROM public.underground_exploration',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_permit_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_permit_type',
    @source_query_template = 'SELECT *
FROM public.now_application_permit_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_status',
    @source_query_template = 'SELECT *
FROM public.mine_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.major_mine_application_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'major_mine_application_document_xref',
    @source_query_template = 'SELECT *
FROM public.major_mine_application_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_permit_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_permit_xref',
    @source_query_template = 'SELECT *
FROM public.mine_permit_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_definition',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_definition',
    @source_query_template = 'SELECT *
FROM public.mine_report_definition
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'nris.inspection_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net/',
    @target_schema = 'bronze',
    @target_table = 'nris_inspection_status',
    @source_query_template = 'SELECT * FROM nris.inspection_status',
    @watermark_column = NULL,
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_comment',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_comment',
    @source_query_template = 'SELECT *
FROM public.mine_comment
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_condition_tag_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_condition_tag_xref',
    @source_query_template = 'SELECT *
FROM public.permit_condition_tag_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.application_reason_code_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'application_reason_code_xref',
    @source_query_template = 'SELECT *
FROM public.application_reason_code_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.minespace_user_role_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'minespace_user_role_xref',
    @source_query_template = 'SELECT *
FROM public.minespace_user_role_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_amendment_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_amendment_status_code',
    @source_query_template = 'SELECT *
FROM public.permit_amendment_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.information_requirements_table_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'information_requirements_table_document_xref',
    @source_query_template = 'SELECT *
FROM public.information_requirements_table_document_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_tailings_storage_facility_version',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_tailings_storage_facility_version',
    @source_query_template = 'SELECT *
FROM public.mine_tailings_storage_facility_version
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_summary_document_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_summary_document_type',
    @source_query_template = 'SELECT *
FROM public.project_summary_document_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.settling_pond',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'settling_pond',
    @source_query_template = 'SELECT *
FROM public.settling_pond',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.standard_permit_condition_tag_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'standard_permit_condition_tag_xref',
    @source_query_template = 'SELECT *
FROM public.standard_permit_condition_tag_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_document_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_document_xref',
    @source_query_template = 'SELECT *
FROM public.now_application_document_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.dam',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'dam',
    @source_query_template = 'SELECT *
FROM public.dam
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.tmp3',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'tmp3',
    @source_query_template = 'SELECT *
FROM public.tmp3',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.placer_operation',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'placer_operation',
    @source_query_template = 'SELECT *
FROM public.placer_operation',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_delay_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_delay_type',
    @source_query_template = 'SELECT *
FROM public.now_application_delay_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.sand_gravel_quarry_operation',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'sand_gravel_quarry_operation',
    @source_query_template = 'SELECT *
FROM public.sand_gravel_quarry_operation',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_recommendation',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_recommendation',
    @source_query_template = 'SELECT *
FROM public.mine_incident_recommendation
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.minespace_user_role',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'minespace_user_role',
    @source_query_template = 'SELECT *
FROM public.minespace_user_role
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_incident_do_subparagraph',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_incident_do_subparagraph',
    @source_query_template = 'SELECT *
FROM public.mine_incident_do_subparagraph',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.document_template',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'document_template',
    @source_query_template = 'SELECT *
FROM public.document_template
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.blasting_operation',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'blasting_operation',
    @source_query_template = 'SELECT *
FROM public.blasting_operation',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.activity_summary_detail_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'activity_summary_detail_xref',
    @source_query_template = 'SELECT *
FROM public.activity_summary_detail_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds_nris',
    @source_system = 'mds',
    @source_entity = 'nris.contact',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'nris_contact',
    @source_query_template = 'SELECT *
FROM nris.contact',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.variance_application_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'variance_application_status_code',
    @source_query_template = 'SELECT *
FROM public.variance_application_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.explosives_permit_status',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'explosives_permit_status',
    @source_query_template = 'SELECT *
FROM public.explosives_permit_status
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.underground_exploration_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'underground_exploration_type',
    @source_query_template = 'SELECT *
FROM public.underground_exploration_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application',
    @source_query_template = 'SELECT *
FROM public.now_application
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.party_verifiable_credential_mines_act_permit',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'party_verifiable_credential_mines_act_permit',
    @source_query_template = 'SELECT *
FROM public.party_verifiable_credential_mines_act_permit
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_submission',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_submission',
    @source_query_template = 'SELECT *
FROM public.mine_report_submission
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.project_decision_package',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'project_decision_package',
    @source_query_template = 'SELECT *
FROM public.project_decision_package
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.notice_of_work_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'notice_of_work_type',
    @source_query_template = 'SELECT *
FROM public.notice_of_work_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.emli_contact_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'emli_contact_type',
    @source_query_template = 'SELECT *
FROM public.emli_contact_type
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.idir_membership_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'idir_membership_xref',
    @source_query_template = 'SELECT *
FROM public.idir_membership_xref',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_report_definition_compliance_article_xref',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_report_definition_compliance_article_xref',
    @source_query_template = 'SELECT *
FROM public.mine_report_definition_compliance_article_xref
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.required_document_sub_category',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'required_document_sub_category',
    @source_query_template = 'SELECT *
FROM public.required_document_sub_category',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.permit_condition_status_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'permit_condition_status_code',
    @source_query_template = 'SELECT *
FROM public.permit_condition_status_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.mine_tailings_storage_facility',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'mine_tailings_storage_facility',
    @source_query_template = 'SELECT *
FROM public.mine_tailings_storage_facility
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.now_application_review',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'now_application_review',
    @source_query_template = 'SELECT *
FROM public.now_application_review
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.minespace_user_request',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'minespace_user_request',
    @source_query_template = 'SELECT *
FROM public.minespace_user_request
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.flyway_schema_history',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'flyway_schema_history',
    @source_query_template = 'SELECT *
FROM public.flyway_schema_history',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'nris.inspection_type',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net/',
    @target_schema = 'bronze',
    @target_table = 'nris_inspection_type',
    @source_query_template = 'SELECT * FROM nris.inspection_type',
    @watermark_column = NULL,
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.spatial_ref_sys',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'spatial_ref_sys',
    @source_query_template = 'SELECT *
FROM public.spatial_ref_sys',
    @watermark_column = '',
    @load_type = 'FULL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO
EXEC [app].[usp_upsert_pipeline_control]
    @pipeline_name = 'pl_ingest_mds',
    @source_system = 'mds',
    @source_entity = 'public.application_reason_code',
    @source_connection_string = NULL,
    @key_vault_url = 'https://mines-fabric-kv01.vault.azure.net',
    @target_schema = 'bronze',
    @target_table = 'application_reason_code',
    @source_query_template = 'SELECT *
FROM public.application_reason_code
WHERE update_timestamp >= ''@from_date''
  AND update_timestamp < ''@to_date''',
    @watermark_column = 'update_timestamp',
    @load_type = 'INCREMENTAL',
    @load_frequency = NULL,
    @priority = 100,
    @dependency_on = NULL;
GO