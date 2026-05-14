# Mines Fabric — Secure Cloud Development Environment

**Status:** Production
**Last updated:** May 2026
**Owner:** Mines Data CI team

---

## Why This Exists

The BC Gov Landing Zone enforces strict policies designed for protecting sensitive data — no public IPs, mandatory private endpoints, NSG-required subnets, secret governance, and more. These policies exist for good reason, but they create real friction for the people building on top of them.

A developer who needs to:
- Browse and update Key Vault secrets
- Test connectivity to a private database
- Run an ad-hoc query against a resource that has no public endpoint
- Deploy Fabric resources behind a VNet gateway

...used to either ask someone with access to do it for them, or run through a multi-hop chain of VPN → bastion → VM → resource. Both options slow people down and create blockers.

**This environment removes that friction without compromising security.** It gives developers a usable, browser-based experience that operates entirely within the private network — no public exposure of any resource, no shared credentials, no manual hosts file edits or token juggling.

---

## The Developer Experience

### What developers see

A developer opens VS Code (or a browser), authenticates with their Microsoft account, and they're working inside the VNet. Their VS Code terminal can run `az`, `psql`, `curl` against private endpoints. A web-based Key Vault Manager UI lets them browse secrets without touching the Azure Portal. Everything feels local but is actually executing on a container deep inside the private network.

The flow they experience:

1. Open VS Code → connect to the named tunnel (one click)
2. Open `http://localhost:8080` (the KV manager UI, auto-forwarded)
3. Sign in with Microsoft device code (one-time per session)
4. Work — browse vaults, edit secrets, run commands, deploy code

No VPN client, no Bastion, no jump VMs, no IP allowlist requests, no shared SP credentials in `.env` files.

### What's actually happening under the hood

When the developer "connects to the tunnel," they're really telling VS Code to bridge their local session through Microsoft's tunnel relay service to a long-running container inside the Azure VNet. From the container's perspective, it has full private network access. From the developer's perspective, they're running locally. The two are stitched together by an outbound-only TLS tunnel that requires no inbound ports on either side.

When they open the Key Vault Manager UI, they're loading HTML/JS served by a small Python web server running on `localhost:8080` inside the container. VS Code's built-in port forwarding (which uses the same tunnel) makes that available to the developer's browser. API calls from the UI route through this Python server, which makes them from the container's network identity — meaning private endpoint traffic just works.

---

## Technology Choices

### VS Code Remote Tunnels

**What it is:** Microsoft's tunnel infrastructure for VS Code. A small CLI (`code tunnel`) registered as an outbound process inside any machine creates a persistent connection to `vscode.dev`. Developers can then connect to that named tunnel via the browser or VS Code desktop.

**Why we use it:** It solves the access problem without opening any inbound ports. The tunnel is outbound-only HTTPS, authenticated against the developer's GitHub or Microsoft account. There's no VPN client to install, no IP allowlists, no shared credentials. Each developer authenticates as themselves.

**Trade-off:** Traffic transits Microsoft's relay servers (TLS end-to-end, but it's their infrastructure). For our use case — internal tooling, not customer data — this is acceptable. The dataplane traffic to actual private resources never leaves our VNet.

### Azure Container Instances (ACI)

**What it is:** Serverless single-container hosting. We use VNet-injected ACI so the container gets an IP inside our VNet without needing AKS or other orchestrators.

**Why we use it:** It's the cheapest and simplest way to run a long-lived Linux process inside a VNet. No node pools, no autoscaling complexity, no patching schedule. It runs, you connect, you do work. When you're done, you can leave it running or stop it.

**Trade-off:** VNet-injected ACI has limitations — no managed identity support, no in-place updates (NSG changes require recreation). We accept these because the simplicity gains outweigh them.

### Microsoft OAuth 2.0 Device Code Flow

**What it is:** A standard OAuth flow designed for devices that can display a short code but can't easily run an interactive browser auth flow.

**Why we use it:** It's the only auth pattern that works cleanly across "headless" containers. The container can't pop up a browser. Tokens are short-lived (1 hour) and tied to the specific developer's identity. Refresh tokens are stored only in memory.

**Why we don't wrap `az login`:** Initially we tried spawning `az login --use-device-code` as a subprocess and capturing the device code from stdout. The Azure CLI detects when it's not attached to a TTY and either writes directly to `/dev/tty` (bypassing pipes) or buffers output until completion — either way, the code never reaches our UI in time. Calling Microsoft's OAuth endpoints directly via REST sidesteps this entirely. We use the public Azure CLI client ID (`04b07795-8ddb-461a-bbee-02f9e1bf7b46`) so no app registration is required.

### Self-hosted Key Vault Manager UI

**What it is:** A small HTML/JS app served by a Python `http.server` running inside the container.

**Why we built it:** The Azure Portal works fine for KV management — but only if you can reach the KV. With public access disabled, the Portal can't talk to our vaults. We needed a Portal-like experience that runs from inside the VNet.

The UI also enforces policy compliance automatically. Landing Zone policy requires every secret to have both a content type and an expiry date. The Azure CLI has a known bug where `--expires` is silently dropped when used with `--file`, leading to confusing 403 errors. The UI uses the KV REST API directly with both fields in the request body, eliminating the foot-gun.

**Why proxy through the server:** The browser running on the developer's laptop can't reach the KV private endpoint directly — the PE has a private IP only routable inside the VNet. By having the Python server proxy the REST calls, the request originates from the container (inside the VNet) and reaches the PE successfully. The browser sees a normal API response.

### Terraform with GitHub Actions

**What it is:** Infrastructure-as-code with declarative state managed in a local backend committed back to the repo.

**Why we use it:** Standard for the platform team. State stays in Git (with `[skip ci]` automation on the apply commit). The workflow uses OIDC-style auth where possible, with a service principal client secret stored as a GitHub secret for resources that don't yet support workload identity federation.

**Important detail:** We deliberately don't declare `ARM_CLIENT_SECRET` as a Terraform variable — it would leak into `terraform.tfstate`. The provider reads it directly from the `ARM_CLIENT_SECRET` environment variable. This was discovered after a state commit triggered GitHub's push protection.

### Fabric VNet Data Gateway

**What it is:** Microsoft Fabric's mechanism for routing Fabric data movement (Copy Jobs, Data Pipelines) through a customer-managed VNet so it can reach private endpoints and on-premise sources.

**Why we use it:** Without it, Fabric can only connect to publicly accessible sources. With it, our Copy Jobs can pull from private PostgreSQL, Azure SQL, Storage, etc., over private endpoints.

**The Power Platform connection:** The gateway is technically built on Power Platform's VNet integration infrastructure (Fabric inherited it from Power BI). This is why the subnet needs the `Microsoft.PowerPlatform/vnetaccesslinks` delegation. You don't need a Power Platform environment or any licenses — just the Azure resource provider registered in your subscription.

---

## Architecture at a Glance

```
Developer Machine                 Microsoft Tunnel              VNet (10.46.21.0/24)
────────────────                  ────────────────              ─────────────────────

 VS Code Desktop  ──┐                                            ┌────────────────────┐
                    │                                            │  ACI subnet (/28)  │
 OR Browser       ──┤                                            │  delegated to ACI  │
                    │     outbound TLS    Microsoft Relay         │                    │
 + KV Manager UI    ├───────────────────► vscode.dev ────────────┼──► Tunnel container│
   (loaded from     │     (no inbound)                            │   • code tunnel    │
    container)      │                                             │   • az CLI         │
                    │                                             │   • Python server  │
 ─────────────────  │                                             │     :8080          │
                                                                  │     /etc/hosts     │
                                                                  └─────────┬──────────┘
                                                                            │ private
                                                                            ▼
                                                                  ┌────────────────────┐
                                                                  │  PE subnet (/28)   │
                                                                  │  non-delegated     │
                                                                  │                    │
                                                                  │  ┌──────────────┐  │
                                                                  │  │ KV Private   │  │
                                                                  │  │ Endpoint     │  │
                                                                  │  │ 10.46.21.x   │  │
                                                                  │  └──────┬───────┘  │
                                                                  └─────────┼──────────┘
                                                                            ▼
                                                                  ┌────────────────────┐
                                                                  │ mines-fabric-kv01  │
                                                                  │ Public access: OFF │
                                                                  └────────────────────┘

                                                                  ┌────────────────────┐
                                                                  │  Fabric GW subnet  │
                                                                  │  delegated to      │
                                                                  │  PowerPlatform     │
                                                                  │                    │
                                                                  │  Fabric VNet GW    │
                                                                  └────────────────────┘
```

Three subnets, each serving a distinct purpose, none capable of being shared:

| Subnet | Delegation | Purpose |
|--------|-----------|---------|
| `mines-fabric-aci-snet` | `Microsoft.ContainerInstance/containerGroups` | Tunnel container + future ACI workloads |
| `mines-fabric-pe-snet` | None (PEs can't share with delegated subnets) | Key Vault and other private endpoints |
| `mines-fabric-gw-snet` | `Microsoft.PowerPlatform/vnetaccesslinks` | Fabric VNet Data Gateway only |

---

## Landing Zone Policies We Address

The BC Gov Landing Zone enforces dozens of policies. These are the ones that materially affected this design and how we address each one.

### 1. No public IP addresses allowed

**Policy:** Public IPs are denied at the management group level. This includes ACI public IPs, Storage public endpoints, KV public access, and any other publicly addressable resource.

**Our approach:** Everything runs VNet-injected or with private endpoints only. The developer connection problem is solved by VS Code Remote Tunnel (outbound-only) rather than inbound exposure.

### 2. All subnets must have an NSG

**Policy:** Subnets created without an NSG are rejected. The platform validates this at creation time.

**Our approach:** The `subnet_allocator` Terraform module creates the subnet and NSG together as a single atomic operation using `azapi_resource`. This avoids the race condition between `azurerm_subnet` and `azurerm_subnet_network_security_group_association` where the subnet exists briefly without an NSG.

### 3. No private DNS zones

**Policy:** Creating `privatelink.*.azure.net` DNS zones is blocked. The Landing Zone manages DNS at the hub level.

**Our approach:** We use `/etc/hosts` entries inside the tunnel container to resolve private endpoint hostnames to their VNet IPs. The KV Manager UI's `HostsManager` exposes this as a managed list — entries tagged with a `# KV_UI_MANAGED` marker so the UI never touches system entries.

Long-term, if the hub adds a private DNS resolver for `privatelink.vaultcore.azure.net`, we can remove the hosts entries entirely. Until then, manual entries are the standard workaround.

### 4. Key Vault secrets must have content type set

**Policy:** Secrets without a `contentType` attribute are denied at write time with `Forbidden: PolicyDefinition 75262d3e-ba4a-4f43-85f8-9f72c090e5e3`.

**Our approach:** The KV Manager UI requires content type in the create/edit form, defaulting to `text/plain`. The REST API call always includes `contentType` in the body.

### 5. Key Vault secrets must have a bounded expiry

**Policy:** Secrets without an `exp` attribute (Unix timestamp) are denied. The maximum allowed validity period is short — we found ~3 months works reliably; longer expiries are sometimes rejected with `342e8053-e12e-4c44-be01-c3c2f318400f`.

**Our approach:** The UI requires an expiry date in the form, defaulting to **today + 3 months**. The Azure CLI has a known bug where `--expires` is silently ignored when `--file` is used, so the UI calls the REST API directly with the expiry in the request body.

### 6. ACI must be VNet-injected (no public ACIs)

**Policy:** ACI with public IPs are denied. VNet integration is required.

**Our approach:** Tunnel container is created with `ip_address_type = "Private"` and `subnet_ids` set to the ACI subnet. Trade-off: VNet-injected ACI doesn't support managed identities, so we use the ACR admin user for image pulls. This is acceptable for our internal tooling since ACR admin credentials are scoped to a single registry and never leave the deployment pipeline.

### 7. ACR must have public access disabled

**Policy:** ACR public network access denied by policy. Pulls must come from inside the VNet or via Private Link.

**Our approach:** ACR created with `public_network_access_enabled = false`. Since our ACI is VNet-injected and the ACR network rule has `bypass = "AzureServices"`, ACI can authenticate and pull images. Developer pushes from CI go through the VNet path via the tunnel container or a future self-hosted runner.

### 8. Subnets cannot be shared between delegated services and private endpoints

**Policy/Constraint:** Azure rejects private endpoints on subnets delegated to other services (`PrivateEndpointCreationNotAllowedAsSubnetIsDelegated`).

**Our approach:** Separate subnet for private endpoints (`mines-fabric-pe-snet`, no delegation, only NSG rules). The subnet allocator carves out a `/28` for it from the same VNet.

### 9. Fabric VNet gateway needs Power Platform delegation

**Policy/Constraint:** Fabric VNet Data Gateways inject into subnets delegated to `Microsoft.PowerPlatform/vnetaccesslinks`. The `Microsoft.PowerPlatform` resource provider must be registered in the subscription.

**Our approach:** Dedicated `/28` subnet with the PowerPlatform delegation, registered the RP via `az provider register --namespace Microsoft.PowerPlatform`. The gateway terraform module passes the subnet metadata in `virtual_network_azure_resource`. Role assignments are managed through the same module so terraform owns gateway access too.

### 10. Service principal client secrets must not leak into state files

**Policy/Best practice:** GitHub push protection blocks commits containing secrets. The platform team mandates rotating any leaked credentials.

**Our approach:** `ARM_CLIENT_SECRET` is intentionally **not** declared as a Terraform variable — provider reads it directly from environment. Workflow sets it via `env:` block but never as `TF_VAR_*`. Discovered the hard way after an earlier commit triggered push protection and required a `git filter-branch` cleanup.

### 11. Storage / API / KV traffic must go through private endpoints

**Policy:** Public network access denied on managed services. Data plane traffic must flow over Private Link.

**Our approach:** Private endpoint per service. DNS resolution via `/etc/hosts` (see policy #3). All API traffic from the KV UI proxies through the container so it traverses the VNet path naturally.

### 12. No managed identity on VNet-injected ACI

**Policy/Limitation:** Azure doesn't support managed identities on container groups deployed into a VNet — this is a platform limitation, not a Landing Zone policy.

**Our approach:** Use ACR admin credentials for image pull. Use OAuth device flow for the developer's authentication — they auth as themselves, not as the container. This is actually preferred from an audit perspective: every action traces back to a real user.

---

## What Makes This Architecture Resilient

**Identity-based access** — Every action is attributable to a specific developer. No shared SP credentials in browser sessions. The container has no long-lived credentials at all; it only holds short-lived access tokens for the current user.

**No standing inbound exposure** — There is no IP address, port, or hostname an external attacker could even attempt to connect to. The only attack surface is the OAuth flow, which is the same surface as any Microsoft account.

**Defence in depth** — Even if an attacker compromised a developer's machine and stole their tunnel session, they would still need to complete a device code flow with that developer's MFA to authenticate to Azure. The tunnel alone doesn't grant any Azure access.

**Policy-aware by design** — The UI enforces the content type + expiry requirements before submitting to KV, so policy errors become validation errors at form time instead of confusing 403s after the fact.

**Auditability** — All KV operations log against the real developer's identity. ACR pulls log against the ACR admin user (acceptable trade-off — only happens during container startup).

**Recreatable** — The entire environment is in Terraform. If something goes wrong, terraform destroy + apply rebuilds from scratch in minutes. There is no state held outside of Git, Azure resources, and the developer's browser session.

---

## Related Pages

- Terraform modules — `modules/azure/*` and `modules/fabric/*`
- KV Manager UI source — `kv-ui/` (deployed to `/app/` in the tunnel container)
- GitHub Actions workflow — `.github/workflows/terraform-apply.yml`
- NSG rules reference and exit code troubleshooting — see operations runbook
