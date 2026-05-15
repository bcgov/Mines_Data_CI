# fabric_connection module

Creates a Microsoft Fabric connection for **PostgreSQL** or **Oracle** sources.

The connection can then be referenced by Copy Jobs, Data Pipelines,
Dataflows, etc. via its GUID.

## Usage

```hcl
module "postgres_mds" {
  source = "./modules/fabric_connection"

  display_name    = "postgres-mds-prod"
  connection_type = "PostgreSQL"

  server   = "mds-reporting-pg13-live.postgres.database.azure.com"
  database = "mds"

  username = var.postgres_username
  password = var.postgres_password
}

module "oracle_finance" {
  source = "./modules/fabric_connection"

  display_name    = "oracle-finance-prod"
  connection_type = "Oracle"

  server   = "finance-db-prod.example.com"
  database = "FINPROD"
  port     = 1521

  username = var.oracle_username
  password = var.oracle_password
}
```

## Credentials & rotation

Passwords use Terraform's write-only attribute (`password_wo`).
They are sent to Fabric on create/update but never stored in state.

To rotate a password:
1. Update the `password` variable value
2. Increment `password_version` by 1
3. `terraform apply`

## Private network sources

For databases behind a private endpoint or on-prem, use a VNet or
On-Premises gateway:

```hcl
module "postgres_internal" {
  source = "./modules/fabric_connection"

  display_name      = "postgres-internal"
  connection_type   = "PostgreSQL"
  connectivity_type = "VirtualNetworkGateway"   # or OnPremisesGateway
  gateway_id        = "11111111-1111-1111-1111-111111111111"

  server   = "internal-pg.corp.local"
  database = "warehouse"
  username = var.postgres_username
  password = var.postgres_password
}
```

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `display_name` | Connection display name | string | — |
| `connection_type` | `PostgreSQL` or `Oracle` | string | — |
| `connectivity_type` | `ShareableCloud` / `VirtualNetworkGateway` / `OnPremisesGateway` | string | `ShareableCloud` |
| `gateway_id` | Required if not `ShareableCloud` | string | `null` |
| `server` | Hostname/IP | string | — |
| `database` | Database name | string | — |
| `port` | Port (Oracle only) | number | `null` (default 1521) |
| `username` | Basic auth username | string (sensitive) | — |
| `password` | Basic auth password | string (sensitive, write-only) | — |
| `password_version` | Rotation counter | number | `1` |
| `privacy_level` | Power Query privacy level | string | `Organizational` |
| `connection_encryption` | `Any` / `Encrypted` / `NotEncrypted` | string | `Encrypted` |
| `skip_test_connection` | Skip connection test on create/update | bool | `false` |

## Outputs

| Name | Description |
|---|---|
| `connection_id` | GUID — pass to fabric_copy_job |
| `connection_display_name` | Display name |
| `connection_type` | The source type |
