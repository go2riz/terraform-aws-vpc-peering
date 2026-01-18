data "aws_vpc" "requester" {
  id = var.vpc_id
}

data "aws_vpc" "accepter" {
  provider = aws.peer
  id       = var.peer_vpc_id
}

# NOTE: aws_subnet_ids data source was removed in AWS provider v5.
# We use aws_subnets instead and sort IDs for stable ordering.
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
  count = length(local.requester_subnet_ids)
  id    = local.requester_subnet_ids[count.index]
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
  count     = length(local.accepter_public_subnet_ids)
  subnet_id = local.accepter_public_subnet_ids[count.index]
}

data "aws_route_table" "accepter_private" {
  provider  = aws.peer
  count     = length(local.accepter_private_subnet_ids)
  subnet_id = local.accepter_private_subnet_ids[count.index]
}

data "aws_route_table" "accepter_secure" {
  provider  = aws.peer
  count     = length(local.accepter_secure_subnet_ids)
  subnet_id = local.accepter_secure_subnet_ids[count.index]
}

data "aws_route_table" "requester" {
  count     = length(local.requester_subnet_ids)
  subnet_id = local.requester_subnet_ids[count.index]
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
