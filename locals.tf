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
  requester_cidrs_sorted = sort(distinct([
    for s in values(data.aws_subnet.requester) : s.cidr_block
  ]))

  # Deterministic rule_number assignment.
  # Keeps legacy numbering (1000 + index) but makes it deterministic.
  generated_peer_rule_numbers = {
    for idx, cidr in local.requester_cidrs_sorted : cidr => 1000 + idx
  }

  # Final per-NACL maps used by NACL rule resources.
  # NOTE: The AWS provider does not have a data source for a single Network ACL
  # entry set (only the plural aws_network_acls), so we intentionally do not try
  # to read existing entries to preserve legacy rule_number mappings.
  accepter_public_peer_rule_numbers  = local.generated_peer_rule_numbers
  accepter_private_peer_rule_numbers = local.generated_peer_rule_numbers
  accepter_secure_peer_rule_numbers  = local.generated_peer_rule_numbers
}
