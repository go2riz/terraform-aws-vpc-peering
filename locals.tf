locals {
  # Sort to keep subnet ordering stable across provider versions.
  requester_subnet_ids        = sort(data.aws_subnets.requester.ids)
  accepter_public_subnet_ids  = sort(data.aws_subnets.accepter_public.ids)
  accepter_private_subnet_ids = sort(data.aws_subnets.accepter_private.ids)
  accepter_secure_subnet_ids  = sort(data.aws_subnets.accepter_secure.ids)

  # Fail fast if tagging returns multiple NACLs per scheme (legacy code picked the first one).
  requester_nacl_id        = one(data.aws_network_acls.requester.ids)
  accepter_public_nacl_id  = one(data.aws_network_acls.accepter_public.ids)
  accepter_private_nacl_id = one(data.aws_network_acls.accepter_private.ids)
  accepter_secure_nacl_id  = one(data.aws_network_acls.accepter_secure.ids)

  accepter_public_route_table_ids  = distinct(data.aws_route_table.accepter_public[*].route_table_id)
  accepter_private_route_table_ids = distinct(data.aws_route_table.accepter_private[*].route_table_id)
  accepter_secure_route_table_ids  = distinct(data.aws_route_table.accepter_secure[*].route_table_id)
  requester_route_table_ids        = distinct(data.aws_route_table.requester[*].route_table_id)
}
