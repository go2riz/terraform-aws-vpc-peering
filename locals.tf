locals {
  # Use sets keyed by stable identifiers (subnet/route table ids) so ordering
  # changes from AWS APIs/provider versions never cause diffs.
  requester_subnet_id_set        = toset(data.aws_subnets.requester.ids)
  accepter_public_subnet_id_set  = toset(data.aws_subnets.accepter_public.ids)
  accepter_private_subnet_id_set = toset(data.aws_subnets.accepter_private.ids)
  accepter_secure_subnet_id_set  = toset(data.aws_subnets.accepter_secure.ids)

  # Fail fast if tagging returns multiple NACLs per scheme (legacy code picked the first one).
  requester_nacl_id        = one(data.aws_network_acls.requester.ids)
  accepter_public_nacl_id  = one(data.aws_network_acls.accepter_public.ids)
  accepter_private_nacl_id = one(data.aws_network_acls.accepter_private.ids)
  accepter_secure_nacl_id  = one(data.aws_network_acls.accepter_secure.ids)

  # Route table ids used by the subnets in scope (distinct, then sorted for stable outputs).
  accepter_public_route_table_ids = sort(distinct([
    for rt in values(data.aws_route_table.accepter_public) : rt.route_table_id
  ]))
  accepter_private_route_table_ids = sort(distinct([
    for rt in values(data.aws_route_table.accepter_private) : rt.route_table_id
  ]))
  accepter_secure_route_table_ids = sort(distinct([
    for rt in values(data.aws_route_table.accepter_secure) : rt.route_table_id
  ]))
  requester_route_table_ids = sort(distinct([
    for rt in values(data.aws_route_table.requester) : rt.route_table_id
  ]))

  # CIDR blocks for all requester subnets used for NACL allow rules.
  # IMPORTANT: We intentionally derive the ordering from *sorted subnet ids*
  # (not from sorting CIDRs). This mirrors how older versions of this module
  # typically assigned rule numbers and avoids rule_number churn when moving
  # from count -> for_each keyed by cidr.
  requester_subnet_ids_sorted   = sort(tolist(local.requester_subnet_id_set))
  requester_cidrs_ordered       = [for id in local.requester_subnet_ids_sorted : data.aws_subnet.requester[id].cidr_block]
  requester_cidrs_ordered_dedup = distinct(local.requester_cidrs_ordered)

  # Deterministic rule_number assignment.
  # By default: 1000 + index, using the subnet-id-based ordering above.
  generated_peer_rule_numbers = {
    for idx, cidr in local.requester_cidrs_ordered_dedup : cidr => 1000 + idx
  }

  # Optional override to preserve existing rule_number mappings exactly.
  # If provided, we only take overrides for CIDRs that are currently in-scope.
  peer_rule_numbers_effective = length(var.peer_rule_numbers) > 0 ? {
    for cidr, num in var.peer_rule_numbers : cidr => num
    if contains(local.requester_cidrs_ordered_dedup, cidr)
  } : local.generated_peer_rule_numbers

  # Final per-NACL maps used by NACL rule resources.
  accepter_public_peer_rule_numbers  = local.peer_rule_numbers_effective
  accepter_private_peer_rule_numbers = local.peer_rule_numbers_effective
  accepter_secure_peer_rule_numbers  = local.peer_rule_numbers_effective
}
