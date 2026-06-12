# Storage Vault Module

This module provisions an Amazon S3 bucket intended to serve as a secure storage vault for backups and project data.

## Usage

```hcl
module "storage_vault" {
  source = "./modules/storage_vault"

  bucket_prefix = "my-company-backups-"
}
```

## Inputs

| Name            | Type     | Default | Description                                   |
| --------------- | -------- | ------- | --------------------------------------------- |
| `bucket_prefix` | `string` | N/A     | Prefix used when creating the S3 bucket name. |

## Outputs

| Name | Type | Description |
|---|---|---|
| `bucket_id` | `string` | The name of the S3 bucket |
| `bucket_arn` | `string` | The ARN of the bucket |
| `bucket_domain_name` | `string` | The bucket domain name |
