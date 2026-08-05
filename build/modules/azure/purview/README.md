# Purview

Creates a Microsoft Purview account, grants a list of principals Root Collection
Admin, and registers the Fabric tenant as a data source with a recurring scan.

## Usage

```hcl
module "purview_01" {
  source = "../modules/azure/purview"

  env             = var.ENVIRONMENT
  prefix          = var.PREFIX
  project         = var.PROJECT
  instance_number = "01"
  location        = var.LOCATION

  resource_group_name = local.purview_rg
  admins              = var.WORKSPACE_OWNERS
  scan_workspace_ids  = [module.fabric_workspace_01.workspace_id]
}
```

Account name follows the repository convention:
`<prefix>-<project>-<suffix><instance>-<env>` → `mcm-mdp-pview01-dev`.

## What Terraform manages, and what it does not

| Layer | Managed by | Resource |
|-------|-----------|----------|
| Purview account | `azurerm` | `azurerm_purview_account` |
| Root Collection Admin | `azapi` | `addRootCollectionAdmin` action |
| ARM RBAC on the account (optional) | `azurerm` | `azurerm_role_assignment` |
| Fabric data source, scan, schedule | REST via `local-exec` | `configure_fabric_scan.sh` |

There is no Terraform provider for the Purview scanning data plane, so the last
row is driven by `configure_fabric_scan.sh` in the same way
`modules/azure/fabric_connection` drives the Fabric connections API. Every call
is an idempotent `PUT`, so re-running an apply is safe. Terraform state holds a
hash of the scan configuration, not the scan itself.

## Permissions

The deploying service principal becomes Root Collection Admin automatically —
Purview assigns that role to whoever creates the account — which is what lets
the same apply go on to register the data source and scan. Everyone in `admins`
is added on top of that.

`enable_rbac_assignments` is off by default because the landing-zone service
principal generally lacks `Microsoft.Authorization/roleAssignments/write`. Turn
it on only if the admins also need to manage the Azure resource itself; catalog
access does not depend on it.

## Manual prerequisites for the Fabric scan

Three steps cannot be expressed in Terraform, and the scan will fail its
connection test until they are done:

1. Create an Entra security group (or reuse one) and add the Purview managed
   identity to it — `purview_identity_principal_id` is emitted as an output for
   exactly this.
2. In the Fabric admin portal → **Tenant settings** → **Admin API settings**,
   enable **Allow service principals to use read-only admin APIs** for that
   group, plus **Enhance admin APIs responses with detailed metadata**.
3. Under **OneLake settings**, enable **Users can access data stored in OneLake
   with apps external to Fabric**.

Microsoft asks for roughly 15 minutes between changing those tenant settings and
running a scan.

## Notes

- **Fabric and Power BI are one connector.** The portal calls the data source
  "Fabric"; on the wire the kind is still `PowerBI`, and the scan kind is
  `PowerBIMsi`. Scanning the tenant brings in Fabric items — lakehouses,
  warehouses, pipelines, notebooks — as well as Power BI items.
- **Registration is tenant-scoped, scans are not.** `scan_workspace_ids`
  narrows the scan to specific workspaces through a scan filter. Scoped scanning
  for Fabric is a preview feature; if a scan comes back with assets from outside
  the intended workspace, check the filter in the portal before assuming the
  workspace ID is wrong.
- **Public network access** is required for the Azure integration runtime. A
  private-only Purview account needs the managed VNet runtime, which this module
  does not configure.
- Empty workspaces are skipped by the scanner, so a brand-new workspace can
  legitimately produce a scan that discovers nothing.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
