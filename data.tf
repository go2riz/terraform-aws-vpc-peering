data "aws_vpc" "requester" {
  id = var.vpc_id
}

data "aws_vpc" "accepter" {
  provider = aws.peer
  id       = var.peer_vpc_id
}

# NOTE: aws_subnet_ids data source was removed in AWS provider v5.
# We use aws_subnets instead. Downstream resources are keyed by stable identifiers
# so changes in returned ordering never cause diffs.
data "aws_subnets" "requester" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Scheme"
    values = ["transit"]
  }
}

data "aws_subnet" "requester" {
  # Key by subnet ID to avoid index-based churn.
  for_each = local.requester_subnet_id_set
  id       = each.key
}

data "aws_subnets" "accepter_public" {
  provider = aws.peer

  filter {
    name   = "vpc-id"
    values = [var.peer_vpc_id]
  }

  filter {
    name   = "tag:Scheme"
    values = ["public"]
  }
}

data "aws_subnets" "accepter_private" {
  provider = aws.peer

  filter {
    name   = "vpc-id"
    values = [var.peer_vpc_id]
  }

  filter {
    name   = "tag:Scheme"
    values = ["private"]
  }
}

data "aws_subnets" "accepter_secure" {
  provider = aws.peer

  filter {
    name   = "vpc-id"
    values = [var.peer_vpc_id]
  }

  filter {
    name   = "tag:Scheme"
    values = ["secure"]
  }
}

data "aws_route_table" "accepter_public" {
  provider  = aws.peer
  for_each  = local.accepter_public_subnet_id_set
  subnet_id = each.key
}

data "aws_route_table" "accepter_private" {
  provider  = aws.peer
  for_each  = local.accepter_private_subnet_id_set
  subnet_id = each.key
}

data "aws_route_table" "accepter_secure" {
  provider  = aws.peer
  for_each  = local.accepter_secure_subnet_id_set
  subnet_id = each.key
}

data "aws_route_table" "requester" {
  for_each  = local.requester_subnet_id_set
  subnet_id = each.key
}

data "aws_network_acls" "accepter_public" {
  provider = aws.peer
  vpc_id   = var.peer_vpc_id

  tags = {
    Scheme = "public"
  }
}

data "aws_network_acls" "accepter_private" {
  provider = aws.peer
  vpc_id   = var.peer_vpc_id

  tags = {
    Scheme = "private"
  }
}

data "aws_network_acls" "accepter_secure" {
  provider = aws.peer
  vpc_id   = var.peer_vpc_id

  tags = {
    Scheme = "secure"
  }
}

data "aws_network_acls" "requester" {
  vpc_id = var.vpc_id

  tags = {
    Scheme = "transit"
  }
}

# NOTE: The AWS provider exposes `aws_network_acls` (plural) as a data source.
# There is no supported singular `aws_network_acl` data source.
#
# We therefore *don't* attempt to read existing NACL entries to preserve rule numbers.
# Rule numbers are generated deterministically in `locals.tf`.
