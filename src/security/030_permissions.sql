-- =============================================================================
-- src/security/030_permissions.sql
-- Grants warehouse access to the pipeline service principal and workspace
-- identity (and any additional users added below).
--
-- Idempotent: GRANT is a no-op when the permission already exists, so this
-- file is safe to run on every deployment.
--
-- Each principal is wrapped in TRY/CATCH so a missing/renamed principal
-- prints a warning instead of aborting the whole deployment (the runner
-- uses sqlcmd -b, which would otherwise stop at the first error).
--
-- NOTE — environment branches: principal names differ per environment (e.g.
-- the workspace identity is named after the workspace, which includes the
-- env). Since dev / test / main are independent branches in this repo, each
-- branch carries its own copy of this file with that environment's names.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Service principal: pipeline / infra automation
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN TRY
    GRANT CONNECT TO [sp-ef74b0-infra-master];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::app TO [sp-ef74b0-infra-master];
    GRANT EXECUTE ON SCHEMA::app TO [sp-ef74b0-infra-master];
    GRANT ALTER   ON SCHEMA::app TO [sp-ef74b0-infra-master];

    -- Data-plane access for the medallion layers
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::bronze TO [sp-ef74b0-infra-master];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::silver TO [sp-ef74b0-infra-master];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::gold   TO [sp-ef74b0-infra-master];
    GRANT ALTER ON SCHEMA::bronze TO [sp-ef74b0-infra-master];
    GRANT ALTER ON SCHEMA::silver TO [sp-ef74b0-infra-master];
    GRANT ALTER ON SCHEMA::gold   TO [sp-ef74b0-infra-master];

    PRINT 'Granted: sp-ef74b0-infra-master';
END TRY
BEGIN CATCH
    PRINT CONCAT('WARNING: grants for [sp-ef74b0-infra-master] failed: ', ERROR_MESSAGE());
END CATCH;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- Workspace identity (system-assigned identity of the Fabric workspace,
-- used by workspace-native items like pipelines and copy jobs)
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN TRY
    GRANT CONNECT TO [mines-data-platform-fabricws-dev-1];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::app TO [mines-data-platform-fabricws-dev-1];
    GRANT EXECUTE ON SCHEMA::app TO [mines-data-platform-fabricws-dev-1];
    GRANT ALTER   ON SCHEMA::app TO [mines-data-platform-fabricws-dev-1];

    -- Data-plane access for the medallion layers
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::bronze TO [mines-data-platform-fabricws-dev-1];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::silver TO [mines-data-platform-fabricws-dev-1];
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::gold   TO [mines-data-platform-fabricws-dev-1];
    GRANT ALTER ON SCHEMA::bronze TO [mines-data-platform-fabricws-dev-1];
    GRANT ALTER ON SCHEMA::silver TO [mines-data-platform-fabricws-dev-1];
    GRANT ALTER ON SCHEMA::gold   TO [mines-data-platform-fabricws-dev-1];

    PRINT 'Granted: mines-data-platform-fabricws-dev-1';
END TRY
BEGIN CATCH
    PRINT CONCAT('WARNING: grants for [mines-data-platform-fabricws-dev-1] failed: ', ERROR_MESSAGE());
END CATCH;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- Additional users
--
-- Add one TRY/CATCH block per user, following the pattern above. Use the
-- user's full Entra UPN as the principal name, e.g.:
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