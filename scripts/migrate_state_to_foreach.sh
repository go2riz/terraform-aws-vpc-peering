#!/usr/bin/env bash
set -euo pipefail

# Migrates legacy count/singleton state addresses to the new for_each keyed addresses
# (routes + accepter-side NACL rules).
#
# Run this from the *root* Terraform working directory that uses this module
# (i.e. where your terraform.tfstate lives / where your backend is configured).
#
# Example:
#   terraform init -upgrade
#   bash path/to/terraform-aws-vpc-peering/scripts/migrate_state_to_foreach.sh
#   terraform plan

show_attr() {
  local addr="$1" attr="$2"
  terraform state show -no-color "$addr" | sed -nE "s/^\s*${attr}\s*=\s*\"([^\"]+)\".*/\1/p" | head -n1
}

addr_exists() {
  local addr="$1"
  terraform state list | grep -Fxq "$addr"
}

move_addr_to_keyed() {
  local addr="$1" attr="$2"

  local key
  key="$(show_attr "$addr" "$attr")"
  if [[ -z "$key" ]]; then
    echo "[WARN] Could not read '${attr}' from: $addr (skipping)" >&2
    return 0
  fi

  local base
  base="${addr%\[*\]}"

  # If this is a singleton (no [..] suffix), base == addr.
  local new_addr
  new_addr="${base}[\"${key}\"]"

  if addr_exists "$new_addr"; then
    echo "[INFO] Target already exists, skipping: $addr -> $new_addr" >&2
    return 0
  fi

  echo "terraform state mv '$addr' '$new_addr'"
  terraform state mv "$addr" "$new_addr"
}

move_indexed_to_keyed() {
  local prefix_grep="$1" attr="$2"

  # Find only indexed instances (...[0], ...[1], ...)
  mapfile -t addrs < <(terraform state list | grep -E "${prefix_grep}\\[[0-9]+\\]$" || true)
  if [[ ${#addrs[@]} -eq 0 ]]; then
    return 0
  fi

  for addr in "${addrs[@]}"; do
    move_addr_to_keyed "$addr" "$attr"
  done
}

move_singleton_to_keyed() {
  local prefix_grep="$1" attr="$2"

  # Find singleton instances (...aws_route.requester) with no [index] and no ["key"]
  mapfile -t addrs < <(terraform state list | grep -E "${prefix_grep}$" || true)
  if [[ ${#addrs[@]} -eq 0 ]]; then
    return 0
  fi

  for addr in "${addrs[@]}"; do
    move_addr_to_keyed "$addr" "$attr"
  done
}

move_to_keyed() {
  local prefix_grep="$1" attr="$2"
  move_indexed_to_keyed "$prefix_grep" "$attr"
  move_singleton_to_keyed "$prefix_grep" "$attr"
}

# --- Accepter-side NACL rules: key by cidr_block ---
move_to_keyed "aws_network_acl_rule\\.in_accepter_public_from_requester" "cidr_block"
move_to_keyed "aws_network_acl_rule\\.out_accepter_public_to_requester" "cidr_block"
move_to_keyed "aws_network_acl_rule\\.in_accepter_private_from_requester" "cidr_block"
move_to_keyed "aws_network_acl_rule\\.out_accepter_private_to_requester" "cidr_block"
move_to_keyed "aws_network_acl_rule\\.in_accepter_secure_from_requester" "cidr_block"
move_to_keyed "aws_network_acl_rule\\.out_accepter_secure_to_requester" "cidr_block"

# --- Routes: key by route_table_id ---
move_to_keyed "aws_route\\.accepter_public" "route_table_id"
move_to_keyed "aws_route\\.accepter_private" "route_table_id"
move_to_keyed "aws_route\\.accepter_secure" "route_table_id"
move_to_keyed "aws_route\\.requester" "route_table_id"

echo "[OK] State migration complete. Run: terraform plan"
