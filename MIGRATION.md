# Migration: fix ordering churn (count -> for_each)

This module previously used `count` for:

- **Accepter-side** `aws_network_acl_rule` resources that allow requester subnet CIDRs
- `aws_route` resources that add peering routes to route tables

When AWS/provider returns subnet/route-table lists in a different order, `count.index` can shuffle which CIDR/route-table gets attached to each resource index. That shows up in plans as **replacements** (destroy+create) even though the desired end state is logically the same.

## What changed

These resources now use `for_each` with stable keys:

- NACL rules: keyed by `cidr_block`
- Routes: keyed by `route_table_id`

Additionally, accepter-side NACL rule numbers are derived from **sorted requester subnet ids** (not sorted CIDRs). This mirrors how older versions of this module typically assigned rule numbers and helps avoid churn during migration.

If you still see `rule_number` changes after migrating state, you can pin the exact mapping using the optional `peer_rule_numbers` input (CIDR -> rule_number).

## How to migrate an existing stack

1. Update your module source to this version.
2. From your root Terraform working directory (the one that holds the state):

   ```bash
   terraform init -upgrade
   ```

3. Run the state migration script (included in this repo):

   ```bash
   bash path/to/terraform-aws-vpc-peering/scripts/migrate_state_to_foreach.sh
   ```

4. Re-run plan:

   ```bash
   terraform plan
   ```

You should now see the ordering-related replacements disappear (or be greatly reduced).

## Notes

- The script uses `terraform state show` to discover each instance's `cidr_block` / `route_table_id`, then runs the corresponding `terraform state mv` command.
- If your state contains *no* legacy indexed resources (fresh deployment), the script does nothing.

### Optional: Pin rule numbers exactly

If you have existing NACL rules and want to ensure Terraform never reshuffles their `rule_number`, pass the current mapping into the module:

```hcl
peer_rule_numbers = {
  "10.37.128.0/21" = 1000
  "10.37.136.0/21" = 1001
  "10.37.120.0/21" = 1002
}
```

You can copy the mapping from `terraform state show` for any one of the accepter-side NACL rule resources.
