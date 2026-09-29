# Core Terraform Workflow

The command-line workflow, plans, execution plans, outputs, targeting, debugging, and operational troubleshooting.

## Core CLI Commands

* **`terraform init`**: Prepares a Terraform working directory. It initializes the backend and installs the required providers and modules in the hidden `.terraform` directory. Modules are covered in [Terraform Modules](05-modules.md#terraform-modules).
  * **`terraform init -upgrade`**: Reconsiders provider and module selections and chooses the newest versions allowed by the configured constraints. For providers, it updates `.terraform.lock.hcl`; review the lock-file diff and the next plan before committing an upgrade. See [Dependency Lock File](02-terraform-basics.md#dependency-lock-file-terraformlockhcl).
* **`terraform validate`**: Checks the configuration for syntax errors and internal consistency without accessing remote state or provider APIs. It requires an initialized working directory; use `terraform init -backend=false` first when you want validation without initializing the configured backend.
* **`terraform test`**: Loads `.tftest.hcl` files and executes their `run` blocks and assertions to test root or reusable modules.
* **`terraform fmt`**: Automatically formats your Terraform configuration files into a canonical style and standard indentation.
* **`terraform plan`**: Refreshes resource information by default, compares the configuration with state, and proposes actions. A normal plan does not make the proposed infrastructure changes.
* **`terraform apply`**: Creates a new plan and asks for approval, or executes a previously saved plan. Providers then create, update, or delete objects to move infrastructure toward the configured state.
* **`terraform destroy`**: Creates and applies a special plan that destroys all managed objects associated with the current Terraform configuration and state.
* **`terraform output`**: Displays root-module output values from the latest state snapshot. Use `terraform output <name>` for one value or `terraform output -json` for machine-readable results. Output querying is covered in detail in [Querying Outputs](#querying-outputs).
* **`terraform destroy -target`**: Focuses the destroy operation on a particular resource address. Terraform may also include dependencies, so always review the generated plan carefully.
    * *Syntax:* `<resource_type>.<local_name>`
    * *Example:* `terraform destroy -target=aws_instance.myec2`

Resource addresses are introduced in [Resource Blocks and References](02-terraform-basics.md#resource-blocks-and-references), state in [Configuration, State, and Remote Objects](01-iac-concepts.md#configuration-state-and-remote-objects), and backends in [Terraform Backend](04-state.md#terraform-backend).

> **Note on Removing Resources via Code:** If you delete a resource block and apply the resulting plan, Terraform normally destroys the remote object that is still recorded in state. If Terraform must stop managing an object without destroying it, use a `removed` block with `destroy = false`, explained in [Removed Blocks](04-state.md#removed-blocks).

> **Note on `terraform refresh` (Deprecated):**
> * Its original purpose was to query the cloud provider and update the `terraform.tfstate` file to match the real-world status.
> * Nowadays, when you run `terraform plan` or `terraform apply`, Terraform automatically performs a refresh in the background before calculating changes.
> * To review and record out-of-band changes without changing remote objects, use `terraform plan -refresh-only` followed by `terraform apply -refresh-only`. Local state normally has a `terraform.tfstate.backup`; remote backends use their own storage and versioning behavior.

---


## Saving and Inspecting Execution Plans

In a production CI/CD pipeline, a saved plan lets the apply stage use the same set of proposed actions that was reviewed during the planning stage.

* **`terraform plan -out=<filename>.plan`**: Saves the proposed execution plan to a binary file.
* **`terraform apply <filename>.plan`**: Executes the saved plan directly. It does not require another approval prompt because the actions were previously captured in the saved plan. The plan file is not a state lock and may contain sensitive data.

> **Important:** Binary plan files are not automatically encrypted. Store them as sensitive artifacts. A saved plan can also become stale and fail if the state changes before it is applied.

### Reading the Binary Plan File
Because the `.plan` file is binary, you cannot open it in a text editor.
* **`terraform show <filename>.plan`**: Translates the binary plan into human-readable text in the terminal.
* **`terraform show -json <filename>.plan`**: Outputs the plan in strict JSON format.
  * This is commonly used in automation. You can pipe the JSON into tools like `jq` or pass it to a security scanner for policy evaluation.

---

## Querying Outputs

[Variables and Output Values](02-terraform-basics.md#variables-and-output-values) explains how to declare output values. The commands below retrieve root-module outputs from the latest state snapshot.

* **`terraform output`**: Reads root-module output values from the latest state snapshot through the configured backend. It is useful for querying infrastructure data without running a full `terraform plan` or provider refresh.

---

## Resource Targeting (`-target`)

* **`terraform plan -target=<resource_address>`**
* **`terraform apply -target=<resource_address>`**

HashiCorp recommends `-target` only for exceptional situations, such as recovering from an earlier error or when Terraform explicitly suggests it. It is not a routine deployment, performance, or troubleshooting strategy.

Terraform includes the selected object and anything it depends on, but the resulting plan may not represent every change required by the complete configuration. After a targeted operation, run a normal `terraform plan` to confirm that no additional changes remain.

> **Exam Tip:** `-target` narrows Terraform's focus; it does not create a permanent architectural boundary and cannot fix a dependency cycle.

---

## Resource Replacement and Dependency Visualization

### Forcing Resource Recreation
Sometimes a resource needs replacement even though its provider-managed attributes still match the configuration. For example, Terraform cannot normally detect software changes made manually inside an EC2 operating system because those details are not part of the EC2 resource schema.
* **`terraform apply -replace="<resource_address>"`**: Instructs Terraform to replace a specific resource during the apply, even when no configuration change requires replacement. The lifecycle and provider behavior determine whether Terraform creates the replacement before or after destroying the existing object.
* *Note:* This modern command officially replaces the deprecated `terraform taint` command.
* *Example:* `terraform apply -replace="aws_instance.web_server[0]"`

### Visualizing Dependencies (The DAG)
Terraform determines the exact order to create, modify, or destroy resources by building a mathematical Directed Acyclic Graph (DAG) under the hood.
* **`terraform graph`**: Outputs this visual dependency graph in the raw DOT language format.
* **Generating an Architecture Image:** You can pipe the raw DOT output into a rendering tool such as **Graphviz** to create a visual representation of the dependencies.
  * *Command:* `terraform graph | dot -Tsvg > graph.svg`
  * *(Note: This requires the Graphviz `dot` CLI tool to be installed on your local OS).*

---

## Terraform Logging & Debugging (`TF_LOG`)

When Terraform fails and the standard console output doesn't give you enough information, you can enable detailed execution logging using environment variables.

* **`TF_LOG`**: Controls the verbosity of the logs.
  * *Levels (from least to most verbose):* `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`.
  * Terraform logging is disabled by default. When enabled, `TRACE` is the most verbose logging level and may expose sensitive information.
* **`TF_LOG_PATH`**: By default, logs print to your terminal. You can use this variable to force Terraform to append the logs to a specific file instead.
  * *Setup (Linux/macOS):* `export TF_LOG=TRACE` and `export TF_LOG_PATH=./terraform.log`

---

## Performance Optimization: API Throttling

When managing large configurations, refresh and apply operations may send enough concurrent requests to trigger provider API rate limits. Providers commonly implement retry and backoff behavior, but configuration design and request concurrency still matter.

**Best Practices to Resolve Throttling:**
1. **Decompose large configurations:** Split infrastructure along architectural and ownership boundaries into separate root configurations and state files (e.g., `vpc-network`, `database-tier`, and `frontend-apps`). Splitting one root module into several `.tf` files does not split its state.
2. **Control concurrency when necessary:** The global `-parallelism=<n>` option can reduce simultaneous operations when a provider or API cannot handle Terraform's default concurrency. This may make the run slower.
3. **Review provider-specific retry settings:** Some providers expose retry or rate-limit settings. Use their documented configuration rather than adding arbitrary delays.
4. **Skip refresh only for an exceptional reason:** `terraform plan -refresh=false` skips the normal refresh of managed resources before planning, although data sources and other operations may still call provider APIs.

> **Warning:** With `-refresh=false`, Terraform may miss out-of-band changes and produce an incomplete or incorrect plan. It is not a routine performance optimization.

---
