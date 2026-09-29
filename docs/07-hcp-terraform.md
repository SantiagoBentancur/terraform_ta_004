# HCP Terraform and Terraform Enterprise

Vault integration, HCP Terraform workspaces, runs, governance, and collaboration platforms.

## HashiCorp Vault Basics and Why Vault Matters

HashiCorp Vault is a secrets-management system. It centralizes access to secrets and can provide encryption, access policies, auditing, leases, revocation, and dynamically generated credentials.

### Why Vault Is Important

* **Centralized secret storage:** Applications and automation do not need separate copies of the same secret.
* **Fine-grained access control:** Vault policies determine which identities can read or create particular secrets.
* **Dynamic credentials:** Supported secrets engines can generate short-lived database or cloud credentials when requested.
* **Leases and revocation:** Dynamic secrets can expire automatically or be revoked early.
* **Auditability:** Audit devices record requests made to Vault without exposing secret values in ordinary logs.
* **Secret rotation:** Credentials can be rotated centrally without committing new values to source control.

### Basic Development Workflow

The following workflow is suitable only for local learning. Start the development server in one terminal:

```bash
vault server -dev
```

In a second terminal, copy the development root token printed by the server and run:

```bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="<development-root-token>"
vault status
vault kv put secret/database username="dbadmin" password="example-only"
vault kv get secret/database
```

> **Warning:** Vault development mode stores data in memory, uses a root token, and is not secure for production.

In production, Vault should use persistent storage, TLS, restricted policies, an appropriate authentication method, and enabled audit devices. Human users and automation should authenticate with scoped identities instead of sharing a root token.

---
## Terraform and Vault Integration

The HashiCorp Vault provider lets Terraform read, configure, and request secrets from Vault.

```hcl
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

provider "vault" {
  # VAULT_ADDR and VAULT_TOKEN are read from the environment.
}

data "vault_kv_secret_v2" "database" {
  mount = "secret"
  name  = "database"
}

locals {
  database_username = data.vault_kv_secret_v2.database.data["username"]
}
```

Configure authentication outside the Terraform code:

```bash
export VAULT_ADDR="https://vault.example.com"
export VAULT_TOKEN="<short-lived-token>"
terraform plan
```

### Important State Warning

A normal Vault data source records its retrieved secret data in Terraform state, even if no other resource uses it. Passing that value to a normal resource argument can create additional copies in state. Protect the backend and any saved plan files, and use provider-supported ephemeral resources or write-only arguments when the workflow supports them.

### Dynamic Cloud Credentials

Vault secrets engines can issue short-lived AWS, Azure, Google Cloud, or database credentials. This reduces the lifetime and impact of a leaked credential and allows Vault to revoke it. A production integration should use narrowly scoped Vault policies and an authentication method suitable for the execution environment, such as JWT/OIDC, AppRole, or cloud-native authentication.

---

## HashiCorp Cloud Platform (HCP) Terraform and Terraform Enterprise

**HCP Terraform** is the managed Software as a Service (SaaS) platform for running Terraform collaboratively. **Terraform Enterprise** provides similar collaboration and governance capabilities but runs in infrastructure controlled by the customer.

> **Naming Note:** Course and exam material commonly uses **HCP Terraform** and **Terraform Enterprise**. Current product pages may use the names **IBM HCP Terraform** and **IBM Terraform Enterprise** following IBM's acquisition of HashiCorp. The hosted-versus-self-managed distinction remains the important concept.

Both products build on the Terraform CLI workflow by adding centralized state, remote execution, access control, run history, policy enforcement, and integrations.

### Core Structure

```text
Organization
└── Project
    ├── Workspace
    └── Workspace
```

* **Organization:** The top-level administrative boundary containing users, teams, projects, policies, and shared settings.
* **Project:** Groups related workspaces and provides an access-control boundary for teams.
* **Workspace:** Manages a distinct collection of infrastructure. It contains or references the Terraform configuration, variables, state, run history, and workspace settings.
* Every workspace belongs to exactly one project. New organizations include a default project.

> **Exam Tip:** One HCP Terraform workspace generally represents one Terraform root module and one state file. It is not simply another environment selected with `terraform workspace select`.

### HCP Terraform Workspaces vs. CLI Workspaces

| Concept | Terraform CLI Workspace | HCP Terraform Workspace |
| :--- | :--- | :--- |
| Main purpose | Creates multiple state instances for the same configuration | Manages a distinct infrastructure collection |
| Configuration | Uses the current local working directory | Obtained from VCS or uploaded through the CLI/API |
| State | Separate state for each CLI workspace | State and state history are stored in HCP Terraform |
| Execution | Usually runs locally | Runs remotely by default |
| Collaboration | Limited by itself | Includes permissions, run history, policies, and integrations |

### Run Workflows

HCP Terraform supports three primary workflows:

* **VCS-driven:** The workspace is normally linked to a Git repository and a specific branch. HCP Terraform registers a webhook with the VCS provider. When a commit is pushed or merged to the tracked branch, the webhook queues a run that starts with `terraform plan`. Opening or updating a pull request normally triggers a speculative plan that previews changes but cannot be applied. Directory and branch filters can limit which changes trigger runs.
* **CLI-driven:** Commands such as `terraform plan` and `terraform apply` start remote operations, and their output streams back to the local terminal.
* **API-driven:** Automation uploads configuration versions and controls runs through the HCP Terraform API.

In the VCS workflow, the plan is associated with the exact Git commit that produced it. By default, a successful plan waits for an authorized user to confirm the apply; a workspace can also be configured for automatic apply. Every apply is based on a completed plan. Standard runs are queued and processed in order within each workspace so that concurrent operations do not update the same state simultaneously. Plan-only or speculative runs are an exception: they can run without waiting for the normal workspace run queue and can never be applied.

### Execution Modes

* **Remote execution:** HCP Terraform runs Terraform in a temporary remote environment, providing a consistent execution environment. Many organizations use this as their standard mode.
* **Local execution:** Terraform runs on the user's machine or CI worker while HCP Terraform stores the remote state.
* **Agent execution:** HCP Terraform agents execute runs inside private, isolated, or on-premises networks that the hosted runners cannot reach.

A workspace can inherit its execution mode from its project or explicitly select a supported mode. Therefore, the workspace setting may appear as **Project Default** rather than always being set directly to Remote.

### Air-Gapped Terraform Enterprise

An **air-gapped environment** is an isolated network with no direct Internet access. HCP Terraform is a hosted SaaS product and therefore is not deployed inside an air-gapped network. Organizations that require customer-controlled or disconnected infrastructure can self-host Terraform Enterprise in a restricted or air-gapped environment.

Air-gapped deployments must make all required artifacts available inside the restricted network. This normally includes the Terraform Enterprise license and images, Terraform binaries, providers, modules, and any VCS or other services used during runs. Internal registries and mirrors replace public Internet sources. The exact installation and upgrade artifacts depend on the Terraform Enterprise version and deployment method; older Replicated installations use `.airgap` bundles, so that file format should not be treated as a universal requirement for every deployment.

> **Exam Distinction:** Terraform Enterprise supports self-hosted and air-gapped deployment. HCP Terraform is managed and hosted by HashiCorp. An HCP Terraform agent can reach private infrastructure, but that is not the same as installing the HCP Terraform SaaS control plane in an air-gapped network.

### Connecting with the `cloud` Block

The modern Terraform CLI integration uses a `cloud` block. It connects the current configuration to an HCP Terraform or Terraform Enterprise organization and workspace:

```hcl
terraform {
  cloud {
    organization = "example-organization"

    workspaces {
      name = "network-production"
    }
  }
}
```

Authenticate the CLI before initializing the configuration:

```bash
terraform login
terraform init
terraform plan
```

This preserves a familiar local CLI experience: you type normal Terraform commands and see the output in your terminal. With remote execution, however, Terraform actually runs in HCP Terraform using the remote workspace's variables, credentials, state, and configured Terraform version. The state and run history remain centrally available to the team.

In a CLI-driven workspace, `terraform plan` starts a remote speculative plan and `terraform apply` can start a full remote run. In a VCS-driven workspace, the repository remains the source of truth, so configuration changes and apply runs normally flow through commits and the HCP Terraform UI rather than a CLI-driven `terraform apply`.

The `cloud` block can select one workspace by `name` or select workspaces dynamically using `tags`. It cannot be combined with a `backend` block because both configure where Terraform performs state operations. The older `remote` backend still exists, but the built-in `cloud` integration is preferred for modern Terraform configurations.

### Variables and Credentials

An HCP Terraform workspace can store two kinds of variables:

* **Terraform variables:** Supply values to declared input variables, similar to `.tfvars` values.
* **Environment variables:** Configure the run environment, including provider credentials such as `AWS_ACCESS_KEY_ID`.

Variables can be marked sensitive to redact them from the user interface and ordinary logs. Variable sets can share common values across multiple workspaces or projects.

> **Security Reminder:** Redaction does not guarantee that a value is absent from Terraform state. Continue treating state as sensitive data.

<details>
<summary><strong>Exam Tip — Sharing Third-Party Credentials Across Related Workspaces</strong></summary>

For this exam scenario, there are **three separate actions**:

1. **Organize:** Put the related workspaces in the same project. This creates a logical management and access boundary, but grouping them does **not** share credentials by itself.
2. **Store securely:** Create a variable set containing the shared credentials and mark secret values as sensitive.
3. **Distribute:** Assign that variable set to the project so its current and future workspaces and Stacks receive the values, or assign it only to the specific workspaces that require them.

```text
Project: Application
├── app-development
├── app-staging
└── app-production
         ▲
         │
Sensitive variable set
```

HCP Terraform can provide variables at these commonly tested scopes:

| Scope | How to Configure It | Who Receives the Values? |
| :--- | :--- | :--- |
| **Single workspace** | Define variables directly in the workspace | Only that workspace |
| **Selected workspaces** | Assign a variable set to chosen workspaces | Only the selected workspaces |
| **Project** | Assign a variable set to a project | Current and future workspaces and Stacks in that project |
| **Global** | Mark a variable set global | Applicable current and future workspaces and Stacks in that organization |

All of these scopes remain inside one HCP Terraform organization. Choose the narrowest scope that satisfies the requirement.

Common distractors:

* A **run trigger** queues a run in another workspace; it does not distribute credentials.
* A **run task** calls an external service during a run; it does not synchronize workspace variables.
* Do not commit credentials to a shared `.tfvars` file.
* A variable set does not span separate HCP Terraform organizations.

</details>

### Plans, Collaboration, and Governance

HCP Terraform has multiple editions, including Free and paid plans such as Essentials, Standard, and Premium. The editions provide different limits and capabilities. Core collaboration features are broadly available, while advanced governance, security, health, and scale capabilities are associated with particular editions. Always check the current plan comparison instead of assuming every feature is included in every plan.

Depending on the selected edition, HCP Terraform can provide:

* Remote state storage, state history, and state locking
* Team-based permissions and project-level access control
* VCS integration and remote run history
* Private module and provider registries
* Policy enforcement with Sentinel or OPA
* Run tasks that integrate external security or compliance systems
* Notifications, cost estimates, drift detection, and continuous validation

### Automating Workspace Runs and External Checks

HCP Terraform can automate two different parts of a collaborative workflow:

* **Coordinate dependent workspaces:** When one workspace successfully applies shared infrastructure, another workspace may need to run against the new result.
* **Evaluate a run with an external system:** A security, cost, compliance, or image-validation service may need to inspect a run before or after Terraform performs an operation.

HCP Terraform provides a different feature for each requirement:

```text
Need another workspace to run?       → Run trigger
Need an external service to check?   → Run task
```

Neither feature distributes credentials or directly shares infrastructure values. Use variable sets for shared variables and credentials, and use outputs or another publication mechanism for cross-workspace data.

#### Run Triggers: Workspace-to-Workspace Automation

A **run trigger** automatically queues a run in a destination workspace after a source workspace completes a successful apply.

```text
Networking workspace
successful apply
        │
        ▼
Run trigger
        │
        ▼
Application workspace
queues its own run
```

The destination workspace executes its own workflow using its own configuration, variables, credentials, state, Terraform version, policies, and permissions. The trigger does not copy the source plan, changes, outputs, or credentials.

A queued destination run does not necessarily apply automatically. The destination workspace first creates its own plan and evaluates its run tasks and policies. If auto-apply is disabled, it waits for authorized confirmation; if auto-apply is enabled, it can apply after all required checks pass.

Run triggers can form an intentional chain:

```text
network apply
      ↓
application run and apply
      ↓
monitoring run
```

Only explicitly connected workspaces participate. Use `tfe_outputs`, a data source, or another publication mechanism when the destination also needs values produced by the source workspace.

#### Run Tasks: External Integrations During a Run

A **run task** sends run-related information to an external service at a configured stage. The external service evaluates the information and returns a pass or fail result to HCP Terraform.

```text
HCP Terraform run
        │
        ▼
External security, cost, compliance,
image-validation, or custom service
        │
        ▼
Passed or failed result
```

Run tasks can execute at these stages:

* **Pre-plan:** Before Terraform creates the plan.
* **Post-plan:** After Terraform creates the plan.
* **Pre-apply:** Before Terraform applies the plan.
* **Post-apply:** After Terraform completes the apply.

Their enforcement level determines the effect of failure:

| Enforcement | Failure Result |
| :--- | :--- |
| **Advisory** | Reports a warning but does not block completion |
| **Mandatory** | Can stop the run and prevent it from continuing |

| Requirement | Correct Feature |
| :--- | :--- |
| Queue a downstream workspace run | **Run trigger** |
| Call an external security or cost system | **Run task** |
| Share values between workspaces | **`tfe_outputs`** or another publication mechanism |
| Share variables or credentials | **Variable set** |
| Evaluate policy as code | **Sentinel or OPA policy set** |

> **Exam Memory Rule:** A run **trigger** connects workspace to workspace. A run **task** connects an HCP Terraform run to an external service.

See the official [run trigger documentation](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings#run-triggers) and [run task documentation](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/run-tasks).

### Explorer

HCP Terraform **Explorer** provides organization-wide visibility across workspaces. Authorized users can build, filter, sort, and save queries that help identify workspace ownership and usage patterns instead of opening each workspace separately.

Explorer's documented views include:

* **Workspaces:** Workspace details, run status, checks, drift, and related metadata.
* **Modules:** Which module versions workspaces use.
* **Providers:** Which provider versions workspaces use.
* **Terraform versions:** Which Terraform CLI versions workspaces use.

This makes Explorer the relevant exam answer when a question asks which HCP Terraform feature searches or analyzes information across an organization's workspaces. Do not confuse it with a workspace's state view, which inspects resources for one workspace, or infrastructure search and import, which discovers unmanaged remote objects for import.

Explorer requires sufficiently broad read access, such as organization-owner or **View all workspaces** access. Its query results can be eventually consistent, so very recent changes may take time to appear. See the official [Explorer documentation](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/explorer).

### Editions and Pricing

HCP Terraform offers Free and paid cloud editions. Paid editions provide progressively broader collaboration, governance, security, and lifecycle-management capabilities. Terraform Enterprise is the self-managed offering and uses contract pricing.

Pricing, usage limits, and the features assigned to each edition can change. Always consult the official [IBM HashiCorp pricing page](https://www.hashicorp.com/en/pricing) and [HCP Terraform plans documentation](https://developer.hashicorp.com/terraform/cloud-docs/overview) before making purchasing or architectural decisions.

| Offering | General Purpose |
| :--- | :--- |
| **Free** | Learning, evaluation, and smaller teams using core remote workflows |
| **Essentials** | Professional teams adopting centralized infrastructure workflows |
| **Standard** | Organizations requiring broader standardization and lifecycle management |
| **Premium** | Organizations requiring advanced governance, security, and self-service capabilities |
| **Terraform Enterprise** | Self-managed deployment for customer-controlled, regulated, private, or air-gapped environments |

Paid cloud editions generally build on the capabilities of lower editions, but exact entitlements should be verified against the current plans documentation.

### Managed-Resource Billing Concept

HCP Terraform usage-based billing is based on managed resources recorded in Terraform state. The durable distinctions are:

* Each resource instance created with `count` or `for_each` is counted separately.
* Data sources are not managed resources.
* `null_resource` and `terraform_data` are excluded from the managed-resource count.
* Usage-based billing may use the highest concurrent managed-resource count during each billing hour.
* Contracted plans may use separately negotiated terms.

> **Exam Focus:** Know that billing and plan selection occur at the organization level, paid editions generally build on lower editions, Resources Under Management (RUM) counts managed resource instances rather than workspaces or users, and Terraform Enterprise is the self-managed offering. Verify current commercial details instead of memorizing exact prices.

### Sentinel Policy as Code

**Sentinel** is HashiCorp's policy-as-code framework. HCP Terraform and Terraform Enterprise can evaluate Sentinel policies against the Terraform configuration, state, and generated plan **after `terraform plan` and before `terraform apply`**. This allows an organization to enforce rules before infrastructure changes are made.

Common policies can require mandatory tags, restrict cloud regions or machine sizes, prevent public access, or require approved Terraform versions.

Policies are grouped into **policy sets**, which can be assigned to selected workspaces or applied more broadly. Sentinel has three enforcement levels:

| Enforcement Level | Result When the Policy Fails |
| :--- | :--- |
| **Advisory** | Reports the failure but allows the run to continue |
| **Soft mandatory** | Blocks the run unless an authorized user overrides it; the override is recorded |
| **Hard mandatory** | Blocks the run. It is not normally overridden at the individual-policy level, although an administrator can explicitly configure the containing policy set to permit authorized overrides. |

> **Exam Tip:** Sentinel does not provision infrastructure. It is a governance checkpoint in the run workflow between the plan and apply stages. Sentinel availability and policy-set limits depend on the HCP Terraform edition.

### Key Exam Distinctions

* HCP Terraform is the hosted SaaS offering; Terraform Enterprise is customer-managed.
* A workspace combines configuration, variables, state, settings, and run history for one infrastructure collection.
* Remote execution and remote state storage are related but separate capabilities.
* A speculative plan previews changes and cannot apply them.
* A VCS-linked workspace normally watches a Git branch: commits trigger runs, and pull requests trigger speculative plans.
* VCS-, CLI-, and API-driven workflows all use HCP Terraform workspaces.
* Projects group workspaces and help scope team permissions.
* Sentinel evaluates policy after the plan and before the apply.
* Terraform Enterprise, rather than HCP Terraform SaaS, is the option for air-gapped deployment.

---
