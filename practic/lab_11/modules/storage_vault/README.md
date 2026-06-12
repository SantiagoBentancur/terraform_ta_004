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

| Name        | Type     | Description                             |
| ----------- | -------- | --------------------------------------- |
| `bucket_id` | `string` | The name (ID) of the created S3 bucket. |
