# Regional Inventory Module

Reads available AWS Availability Zones through two provider configurations supplied by its caller.

The module declares the configuration names `aws.primary` and `aws.secondary` with `configuration_aliases`. It does not define provider configuration blocks or choose AWS Regions itself.

## Provider Configurations

| Name | Purpose |
| :--- | :--- |
| `aws.primary` | Reads the caller-selected primary Region |
| `aws.secondary` | Reads the caller-selected secondary Region |

## Outputs

| Name | Description |
| :--- | :--- |
| `availability_zones` | Map containing the available zone names returned through each configuration |
