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

  # Default rule_number assignment if no existing NACL rules are found.
  # Keeps legacy numbering (1000 + index) but makes it deterministic.
  generated_peer_rule_numbers = {
    for idx, cidr in local.requester_cidrs_sorted : cidr => 1000 + idx
  }

  # Existing rule_number mappings from NACL entries (if rules already exist).
  # We use these to preserve the existing rule_number<->CIDR association,
  # eliminating replacements when subnet ordering changes.
  _accepter_public_existing_ingress = {
    for e in data.aws_network_acl.accepter_public.ingress : e.cidr_block => e.rule_number
    if e.rule_action == "allow" && tostring(e.protocol) == "-1" && contains(local.requester_cidrs_sorted, e.cidr_block) && e.rule_number >= 1000 && e.rule_number < 2000
  }
  _accepter_public_existing_egress = {
    for e in data.aws_network_acl.accepter_public.egress : e.cidr_block => e.rule_number
    if e.rule_action == "allow" && tostring(e.protocol) == "-1" && contains(local.requester_cidrs_sorted, e.cidr_block) && e.rule_number >= 1000 && e.rule_number < 2000
  }
  accepter_public_existing_rule_numbers = merge(local._accepter_public_existing_ingress, local._accepter_public_existing_egress)

  _accepter_private_existing_ingress = {
    for e in data.aws_network_acl.accepter_private.ingress : e.cidr_block => e.rule_number
    if e.rule_action == "allow" && tostring(e.protocol) == "-1" && contains(local.requester_cidrs_sorted, e.cidr_block) && e.rule_number >= 1000 && e.rule_number < 2000
  }
  _accepter_private_existing_egress = {
    for e in data.aws_network_acl.accepter_private.egress : e.cidr_block => e.rule_number
    if e.rule_action == "allow" && tostring(e.protocol) == "-1" && contains(local.requester_cidrs_sorted, e.cidr_block) && e.rule_number >= 1000 && e.rule_number < 2000
  }
  accepter_private_existing_rule_numbers = merge(local._accepter_private_existing_ingress, local._accepter_private_existing_egress)

  _accepter_secure_existing_ingress = {
    for e in data.aws_network_acl.accepter_secure.ingress : e.cidr_block => e.rule_number
    if e.rule_action == "allow" && tostring(e.protocol) == "-1" && contains(local.requester_cidrs_sorted, e.cidr_block) && e.rule_number >= 1000 && e.rule_number < 2000
  }
  _accepter_secure_existing_egress = {
    for e in data.aws_network_acl.accepter_secure.egress : e.cidr_block => e.rule_number
    if e.rule_action == "allow" && tostring(e.protocol) == "-1" && contains(local.requester_cidrs_sorted, e.cidr_block) && e.rule_number >= 1000 && e.rule_number < 2000
  }
  accepter_secure_existing_rule_numbers = merge(local._accepter_secure_existing_ingress, local._accepter_secure_existing_egress)

  # Final per-NACL maps used by NACL rule resources.
  accepter_public_peer_rule_numbers = {
    for cidr in local.requester_cidrs_sorted : cidr => lookup(local.accepter_public_existing_rule_numbers, cidr, local.generated_peer_rule_numbers[cidr])
  }
  accepter_private_peer_rule_numbers = {
    for cidr in local.requester_cidrs_sorted : cidr => lookup(local.accepter_private_existing_rule_numbers, cidr, local.generated_peer_rule_numbers[cidr])
  }
  accepter_secure_peer_rule_numbers = {
    for cidr in local.requester_cidrs_sorted : cidr => lookup(local.accepter_secure_existing_rule_numbers, cidr, local.generated_peer_rule_numbers[cidr])
  }
}
