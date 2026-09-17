-- =============================================================================
-- src/security/030_permissions.sql
-- Grants warehouse access to the pipeline service principal and workspace
-- identity (and any additional users added below).
--
-- Idempotent: GRANT is a no-op when the permission already exists, so this
-- file is safe to run on every deployment.
--
-- ENVIRONMENT-AGNOSTIC: the same file is used on dev, test and main. Principal
-- names come from sqlcmd scripting variables, supplied as environment
-- variables by .github/workflows/warehouse.yml:
--   $(WORKSPACE_IDENTITY_NAME)  display name of this environment's Fabric
--                               workspace (read from terraform-<env>.tfstate);
--                               the workspace identity carries that name
--   $(PIPELINE_SP_NAME)         GitHub Environment variable PIPELINE_SP_NAME
-- If either is missing, sqlcmd aborts with "scripting variable not defined".
--
-- The two required principals below RE-THROW on failure so a missing grant
-- fails the deployment instead of hiding behind a warning. Additional users
-- only warn.
-- =============================================================================

PRINT 'Applying permissions: SP=[$(PIPELINE_SP_NAME)], workspace identity=[$(WORKSPACE_IDENTITY_NAME)]';
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- Service principal: pipeline / infra automation (required)
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN TRY
    GRANT CONNECT TO [$(PIPELINE_SP_NAME)];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::app TO [$(PIPELINE_SP_NAME)];
    GRANT EXECUTE ON SCHEMA::app TO [$(PIPELINE_SP_NAME)];
    GRANT ALTER   ON SCHEMA::app TO [$(PIPELINE_SP_NAME)];

    -- Data-plane access for the medallion layers
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::bronze TO [$(PIPELINE_SP_NAME)];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::silver TO [$(PIPELINE_SP_NAME)];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::gold   TO [$(PIPELINE_SP_NAME)];
    GRANT ALTER ON SCHEMA::bronze TO [$(PIPELINE_SP_NAME)];
    GRANT ALTER ON SCHEMA::silver TO [$(PIPELINE_SP_NAME)];
    GRANT ALTER ON SCHEMA::gold   TO [$(PIPELINE_SP_NAME)];

    PRINT 'Granted: $(PIPELINE_SP_NAME)';
END TRY
BEGIN CATCH
    PRINT CONCAT('ERROR: grants for [$(PIPELINE_SP_NAME)] failed: ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- Workspace identity (system-assigned identity of this environment's Fabric
-- workspace, used by workspace-native items like pipelines and copy jobs).
-- Required. The identity must be enabled in Workspace settings.
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN TRY
    GRANT CONNECT TO [$(WORKSPACE_IDENTITY_NAME)];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::app TO [$(WORKSPACE_IDENTITY_NAME)];
    GRANT EXECUTE ON SCHEMA::app TO [$(WORKSPACE_IDENTITY_NAME)];
    GRANT ALTER   ON SCHEMA::app TO [$(WORKSPACE_IDENTITY_NAME)];

    -- Data-plane access for the medallion layers
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::bronze TO [$(WORKSPACE_IDENTITY_NAME)];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::silver TO [$(WORKSPACE_IDENTITY_NAME)];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::gold   TO [$(WORKSPACE_IDENTITY_NAME)];
    GRANT ALTER ON SCHEMA::bronze TO [$(WORKSPACE_IDENTITY_NAME)];
    GRANT ALTER ON SCHEMA::silver TO [$(WORKSPACE_IDENTITY_NAME)];
    GRANT ALTER ON SCHEMA::gold   TO [$(WORKSPACE_IDENTITY_NAME)];

    PRINT 'Granted: $(WORKSPACE_IDENTITY_NAME)';
END TRY
BEGIN CATCH
    PRINT CONCAT('ERROR: grants for [$(WORKSPACE_IDENTITY_NAME)] failed: ', ERROR_MESSAGE());
    PRINT 'Is the workspace identity enabled in Workspace settings for this environment?';
    THROW;
END CATCH;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- Additional users (optional — failures only warn)
--
-- Add one TRY/CATCH block per user. Use the user's full Entra UPN. Grants that
-- should apply to every environment go here directly; environment-specific
-- users can use a sqlcmd variable in the same way as above.
--
-- BEGIN TRY
--     GRANT CONNECT TO [jane.doe@gov.bc.ca];
--     GRANT SELECT ON SCHEMA::gold   TO [jane.doe@gov.bc.ca];   -- read-only reporting
--     GRANT SELECT ON SCHEMA::silver TO [jane.doe@gov.bc.ca];
--     PRINT 'Granted: jane.doe@gov.bc.ca';
-- END TRY
-- BEGIN CATCH
--     PRINT CONCAT('WARNING: grants for [jane.doe@gov.bc.ca] failed: ', ERROR_MESSAGE());
-- END CATCH;
-- GO
--
-- Keep user grants minimal: analysts usually need only SELECT on gold
-- (and maybe silver) — not INSERT/UPDATE/DELETE, and not the app schema.
-- ─────────────────────────────────────────────────────────────────────────────

PRINT 'Permissions deployment complete.';
GO