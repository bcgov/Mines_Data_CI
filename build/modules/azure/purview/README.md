# Purview

Registers the Fabric tenant as a Purview data source with a recurring scan, and
grants a list of principals Root Collection Admin. Attaches to the tenant's
existing Purview account by default; can create one where the tenant has none.

## One account per tenant

A Microsoft Entra tenant may hold exactly one Purview account. Creating a second
fails at the ARM layer:

```
Error: creating Account ... unexpected status 409 (409 Conflict) with error:
35001: Validation failed for <name>. An Enterprise Tenant-level Purview Account
already exists for tenant with ID: <tenant>.
```

So `create_account` defaults to `false` and the module discovers the account
instead. The Fabric data source and scan are named from the workspace
convention (`mcm-mdp-fabric01-dev`), not the account name, so each environment
gets its own entry under the shared account.

Find the existing account:

```bash
az graph query -q "Resources | where type =~ 'microsoft.purview/accounts' | project name, resourceGroup, subscriptionId, location"
```

Discovery covers only the subscription Terraform is authenticated against. If
the account lives in another subscription, the deploying principal needs Reader
on it and `purview_account_name` must be set. If the subscription holds more
than one account, the module stops and asks which to use rather than guessing.

Set `create_account = true` only for a tenant with no account, or one holding
pre-existing quota for several. Additional accounts otherwise require a quota
increase from Microsoft support.

## Usage

```hcl
module "purview_01" {
  source = "../modules/azure/purview"

  env             = var.ENVIRONMENT
  prefix          = var.PREFIX
  project         = var.PROJECT
  instance_number = "01"
  location        = var.LOCATION

  purview_account_name = var.PURVIEW_ACCOUNT_NAME # null = discover
  admins               = var.WORKSPACE_OWNERS
  scan_workspace_ids   = [module.fabric_workspace_01.workspace_id]
}
```

## What Terraform manages, and what it does not

| Layer | Managed by | Resource |
|-------|-----------|----------|
| Account discovery | `azurerm` | `azurerm_resources`, `azurerm_purview_account` data sources |
| Account creation (opt-in) | `azurerm` | `azurerm_purview_account` |
| Root Collection Admin | REST via `local-exec` | `add_root_collection_admins.sh` |
| ARM RBAC on the account (optional) | `azurerm` | `azurerm_role_assignment` |
| Fabric data source, scan, schedule | REST via `local-exec` | `configure_fabric_scan.sh` |

There is no Terraform provider for the Purview scanning data plane, so the last
row is driven by `configure_fabric_scan.sh` in the same way
`modules/azure/fabric_connection` drives the Fabric connections API. Every call
is an idempotent `PUT`, so re-running an apply is safe. Terraform state holds a
hash of the scan configuration, not the scan itself.

Attaching to an existing account does not modify it — network posture,
identity and tags stay as their owner set them. Only collection admins, the data
source and the scan are added.

### Why admin grants are not an `azapi_resource_action`

Each `addRootCollectionAdmin` call rewrites the root collection's metadata
policy under optimistic concurrency. One `azapi_resource_action` per admin means
Terraform issues them in parallel, they all read the same entity tag, and the
losers fail:

```
400 / 1002 — The payload is invalid.
             Error: The entity Etag did not match in artifact store.
```

`add_root_collection_admins.sh` makes the calls one at a time with a settle gap
between them, and retries the etag collision with exponential backoff. It also
retries 409/429/5xx, which is what a freshly created account returns while its
root collection policy is still being written. A genuinely malformed payload or
a 403 fails immediately rather than burning six attempts.

## Permissions

The deploying service principal needs, on the Purview account:

- `Microsoft.Purview/accounts/read` — Reader is enough for discovery.
- `Microsoft.Purview/accounts/addRootCollectionAdmin/action` — carried by Owner
  and Contributor. Without it the admin grants fail with 403.
- Root Collection Admin in the catalog itself, to register the data source and
  scan. `include_deploying_principal_as_admin` (default true) grants this via
  the action above. On an account created here it is redundant — the creator
  gets the role automatically — but on someone else's account it is the step
  that makes the data plane usable.

If the principal cannot be granted the ARM action, ask a current collection
admin to add it under **Data Map → Collections → Root → Role assignments**, then
set `include_deploying_principal_as_admin = false`.

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
- **Shared account, shared blast radius.** Root Collection Admin on a
  tenant-level account is admin over every collection in it, including
  collections owned by other teams. If that is too broad, have a collection
  admin create a dedicated collection for this platform, pass its name as
  `collection_name`, and grant admins on that collection through the portal
  instead — set `admins = []` and
  `include_deploying_principal_as_admin = false` once the deploying principal
  has Data Source Admin there.
- **Public network access** applies only when creating an account. A
  private-only Purview account needs the managed VNet runtime, which this module
  does not configure.
- Empty workspaces are skipped by the scanner, so a brand-new workspace can
  legitimately produce a scan that discovers nothing.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
