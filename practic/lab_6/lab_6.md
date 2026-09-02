# Lab 6: Terraform Console and Collection Transformations

## Objective

Strengthen normal Terraform expression operations for exam preparation. Use only `terraform console` to inspect and transform the provided local values. No cloud resources are created.

> **Status:** Completed.

## Concepts to Practice

* `terraform console`
* `for` expressions and filtering
* List, set, map, and object transformations
* `flatten()`, `compact()`, `distinct()`, `merge()`, `split()`, and `join()`
* `tolist()`, `tomap()`, and `toset()`

## Prerequisites

* Review [Collection Functions](../../README.md#collection-functions), [String and Conversion Functions](../../README.md#string-and-conversion-functions), [`for` Expressions](../../README.md#for-expressions), and [Local Values](../../README.md#local-values-locals).

> **No-Cost Lab:** This exercise evaluates local values and expressions only. It does not configure a provider or create remote infrastructure.

## Getting Started

From the `console/` directory, prepare the configuration and open the console:

```bash
cd console
terraform fmt -check
terraform init
terraform validate
terraform console
```

Enter each expression at the `>` prompt. Try the challenge before opening its solution. Enter `exit` to leave the console.

---

## Exercise 1: Uppercase Server Names

Using `local.server_names`, return all names in uppercase.

<details>
<summary>Solution</summary>

```hcl
[for name in local.server_names : upper(name)]
```
</details>

## Exercise 2: Add Index Prefixes

Using `local.availability_zones`, return `["0-us-east-1a", "1-us-east-1b", "2-us-east-1c"]`.

<details>
<summary>Solution</summary>

```hcl
[for index, az in local.availability_zones : "${index}-${az}"]
```
</details>

## Exercise 3: Convert a List to a Map

Using `local.services`, create a map whose service names are keys and values are `"enabled"`.

<details>
<summary>Solution</summary>

```hcl
{ for service in local.services : service => "enabled" }
```
</details>

## Exercise 4: Filter Enabled Users

Using `local.users_enabled`, return only enabled usernames as a list.

<details>
<summary>Solution</summary>

```hcl
[for name, enabled in local.users_enabled : name if enabled]
```
</details>

## Exercise 5: Extract Object Attributes

Using `local.instances`, return only the instance names.

<details>
<summary>Solution</summary>

```hcl
[for instance in local.instances : instance.name]
```
</details>

## Exercise 6: Build a Map from Objects

Using `local.instances`, map each instance name to its instance type.

<details>
<summary>Solution</summary>

```hcl
{ for instance in local.instances : instance.name => instance.type }
```
</details>

## Exercise 7: Flatten Nested Subnet Lists

Return one flat list from `local.nested_subnets`.

<details>
<summary>Solution</summary>

```hcl
flatten(local.nested_subnets)
```
</details>

## Exercise 8: Flatten Environment Services

Using `local.environment_services`, return a flat list such as `dev-api`, `dev-worker`, and `prod-frontend`.

<details>
<summary>Solution</summary>

```hcl
flatten([
  for environment, services in local.environment_services : [
    for service in services : "${environment}-${service}"
  ]
])
```
</details>

## Exercise 9: Remove Empty Strings

Remove empty strings from `local.names_with_empty_values`.

<details>
<summary>Solution</summary>

```hcl
compact(local.names_with_empty_values)
```
</details>

## Exercise 10: Remove Duplicates

Return each region in `local.regions_with_duplicates` once while preserving list order.

<details>
<summary>Solution</summary>

```hcl
distinct(local.regions_with_duplicates)
```
</details>

## Exercise 11: Split a CSV String

Convert `local.allowed_ports_csv` into a list of strings.

<details>
<summary>Solution</summary>

```hcl
split(",", local.allowed_ports_csv)
```
</details>

## Exercise 12: Join a List into a String

Using `local.tag_words`, return `terraform-aws-practice`.

<details>
<summary>Solution</summary>

```hcl
join("-", local.tag_words)
```
</details>

## Exercise 13: Merge Default and Custom Tags

Merge `local.default_tags` and `local.custom_tags`. Custom tags must override duplicate keys.

<details>
<summary>Solution</summary>

```hcl
merge(local.default_tags, local.custom_tags)
```
</details>

## Exercise 14: Add a Common Tag to Every Server

Add `env = "dev"` to each object in `local.servers`.

<details>
<summary>Solution</summary>

```hcl
{
  for name, config in local.servers :
  name => merge(config, { env = "dev" })
}
```
</details>

## Exercise 15: Convert a Set to a List

Convert `local.security_groups` into a list.

<details>
<summary>Solution</summary>

```hcl
tolist(local.security_groups)
```
</details>

## Exercise 16: Convert a List to a Set

Convert `local.duplicate_names` into a set to remove duplicates.

<details>
<summary>Solution</summary>

```hcl
toset(local.duplicate_names)
```
</details>

## Exercise 17: Convert an Object to a Map

Convert `local.config_object` into a map.

<details>
<summary>Solution</summary>

```hcl
tomap(local.config_object)
```
</details>

## Exercise 18: Filter Ports

Return only values greater than `1000` from `local.ports`.

<details>
<summary>Solution</summary>

```hcl
[for port in local.ports : port if port > 1000]
```
</details>

## Exercise 19: Create Security Group Rule Names

Using `local.security_group_rules`, return `["tcp-80", "tcp-443", "udp-53"]`.

<details>
<summary>Solution</summary>

```hcl
[for rule in local.security_group_rules : "${rule.protocol}-${rule.port}"]
```
</details>

## Exercise 20: Flatten Users and Roles

Using `local.team_roles`, return a flat list containing one `user` and one `role` per assignment.

<details>
<summary>Solution</summary>

```hcl
flatten([
  for user, roles in local.team_roles : [
    for role in roles : {
      user = user
      role = role
    }
  ]
])
```
</details>

---

## Completion Check

You have completed the lab when you can explain:

1. The difference between transforming and filtering a collection.
2. Why nested `for` expressions often need `flatten()`.
3. Why the argument order passed to `merge()` matters.
4. When list, set, and map conversions are useful with `for_each`.
