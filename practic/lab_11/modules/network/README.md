# Network Module

Creates one VPC, public and private subnets, an Internet Gateway, and separate public and private route tables.

Public subnets receive a default route through the Internet Gateway. Private subnets have no internet route because this learning module intentionally does not create a NAT Gateway.

## Input Contract

Declare these variables in `variables.tf`. The root module supplies the two subnet maps; the other values have defaults that can be overridden by a caller.

| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `project_name` | `string` | `"lab_11"` | Project name used for naming and tagging |
| `environment` | `string` | `"dev"` | Environment name used for naming and tagging |
| `vpc_cidr` | `string` | `"10.0.0.0/24"` | CIDR block assigned to the VPC |
| `public_subnets` | `map(object({ cidr = string, availability_zone = string }))` | none | Public subnet definitions; required from the caller |
| `private_subnets` | `map(object({ cidr = string, availability_zone = string }))` | none | Private subnet definitions; required from the caller |

## Outputs

| Name | Description |
| :--- | :--- |
| `vpc_id` | ID of the VPC |
| `public_subnet_ids` | Public subnet IDs keyed by input name |
| `private_subnet_ids` | Private subnet IDs keyed by input name |

The calling module must provide an AWS provider configuration. This reusable child module declares its provider requirement but does not configure credentials or a Region.
