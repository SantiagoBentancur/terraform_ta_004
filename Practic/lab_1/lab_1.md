# 🛠️ Lab 1: The Informant Server (Dynamic Image & Mapping)

## Objective
Configure a foundational Terraform deployment that dynamically queries the cloud provider's marketplace for the latest operating system image and maps customized environment tags to the target deployment using structural map lookups.

## Requirements

### 1. Provider
* Configure the HashiCorp AWS provider to target the standard `us-east-1` region.

### 2. Variables
* **`environment`**: Create a map variable named `environment` containing two distinct environment keys: `dev` mapping to `"Development"` and `prod` mapping to `"Production"`.

### 3. Data Source
* Use the `aws_ami` data source block to dynamically scan and isolate the latest official **Amazon Linux 2** operating system image without relying on hardcoded static Image IDs.

### 4. EC2 Resource (`aws_instance`)
* **Compute Engine**: Provision a baseline virtual machine (`aws_instance`) running a standard cloud-tier size specification (`t3.micro`).
* **Dynamic Mapping**: In the `tags` configuration block, assign the value of the `Name` attribute by extracting the associated key value string from the `environment` map passing the exact index value (`"prod"`).

---

## Key Architectural Features
1. **Dynamic AMI Discovery:** Eradicates configuration obsolescence by allowing the orchestration layer to dynamically locate the newest updated kernel patches at runtime.
2. **Key-Value Resource Tagging:** Uses decoupled configuration variables to insulate resource identifiers from hardcoded text strings, enabling rapid environment cloning.
3. **Output Auditing:** Employs an extraction interface layer (`output`) to verify exactly what image identity variables have been located by the search data structures during evaluation phases.

---

## Terraform Code (`lab_1.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

# 1. Dynamic Data Source for AMI Discovery
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 2. Output Block to audit the resolved AMI ID
output "ami_encontrada_id" {
  value = data.aws_ami.amazon_linux_2.id
}

# 3. Map Variable for Environment Identifiers
variable "environment" {
  type        = map(string)
  description = "my env"
  default = {
    dev  = "Development"
    prod = "Production"
  }
}

# 4. Target Compute Resource Provisioning
resource "aws_instance" "ec2_lab1" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  tags = {
    # Extracting the "Production" string from the map using the "prod" key
    Name = var.environment["prod"]
  }
}