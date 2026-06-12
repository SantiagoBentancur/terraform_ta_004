# Web Cluster Module

This module provisions a cluster of EC2 instances across specified availability zones. It automatically manages an internal security group that permits incoming HTTP and SSH traffic to all instances within the cluster.

## Example Usage

```hcl
module "web_cluster" {
  source = "./modules/web-cluster"

  name          = "production"
  region        = "us-east-1"
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"

  target_zones = [
    "us-east-1a",
    "us-east-1b"
  ]
}
```

## Inputs

| Name            | Type           | Default | Description                                                                  |
| --------------- | -------------- | ------- | ---------------------------------------------------------------------------- |
| `name`          | `string`       | `""`    | Name to be used on EC2 instances created.                                    |
| `region`        | `string`       | `null`  | Region where the resources will be managed. Defaults to the provider region. |
| `ami`           | `string`       | `null`  | ID of the AMI to use for the instances.                                      |
| `instance_type` | `string`       | N/A     | EC2 instance type.                                                           |
| `target_zones`  | `list(string)` | N/A     | Target Availability Zones for the EC2 instances.                             |

## Outputs

| Name                           | Type          | Description                                    |
| ------------------------------ | ------------- | ---------------------------------------------- |
| `production_cluster_inventory` | `map(string)` | A map where the keys are the Availability Zones and the values are the public IP addresses of the EC2 instances created in that zone.|

