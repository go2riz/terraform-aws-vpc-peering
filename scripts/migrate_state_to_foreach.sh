#!/usr/bin/env bash
set -euo pipefail

# Migrates legacy count-based state addresses to the new for_each keyed addresses
# introduced in this module (routes + accepter-side NACL rules).
#
# Run this from the *root* Terraform working directory that uses this module
# (i.e. where your terraform.tfstate lives).
#
# Example:
#   terraform init -upgrade
#   bash path/to/scripts/migrate_state_to_foreach.sh
#   terraform plan

show_attr() {
  local addr="$1" attr="$2"
  terraform state show -no-color "$addr" | sed -nE "s/^\s*${attr}\s*=\s*\"([^\"]+)\".*/\1/p" | head -n1
}

move_indexed_to_keyed() {
  local prefix_grep="$1" attr="$2"

  # Find only indexed instances (...[0], ...[1], ...)
  mapfile -t addrs < <(terraform state list | grep -E "${prefix_grep}\\[[0-9]+\\]$" || true)
  if [[ ${#addrs[@]} -eq 0 ]]; then
    return 0
  fi

  for addr in "${addrs[@]}"; do
    local key
    key="$(show_attr "$addr" "$attr")"
    if [[ -z "$key" ]]; then
      echo "[WARN] Could not read '${attr}' from: $addr (skipping)" >&2
      continue
    fi

    local base
    base="${addr%\[*\]}"

    local new_addr
    new_addr="${base}[\"${key}\"]"

    echo "terraform state mv '$addr' '$new_addr'"
    terraform state mv "$addr" "$new_addr"
  done
}

# --- Accepter-side NACL rules: key by cidr_block ---
move_indexed_to_keyed "aws_network_acl_rule\\.in_accepter_public_from_requester" "cidr_block"
move_indexed_to_keyed "aws_network_acl_rule\\.out_accepter_public_to_requester" "cidr_block"
move_indexed_to_keyed "aws_network_acl_rule\\.in_accepter_private_from_requester" "cidr_block"
move_indexed_to_keyed "aws_network_acl_rule\\.out_accepter_private_to_requester" "cidr_block"
move_indexed_to_keyed "aws_network_acl_rule\\.in_accepter_secure_from_requester" "cidr_block"
move_indexed_to_keyed "aws_network_acl_rule\\.out_accepter_secure_to_requester" "cidr_block"

# --- Routes: key by route_table_id ---
move_indexed_to_keyed "aws_route\\.accepter_public" "route_table_id"
move_indexed_to_keyed "aws_route\\.accepter_private" "route_table_id"
move_indexed_to_keyed "aws_route\\.accepter_secure" "route_table_id"
move_indexed_to_keyed "aws_route\\.requester" "route_table_id"

echo "[OK] State migration complete. Run: terraform plan"
