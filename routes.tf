resource "aws_route" "accepter_public" {
  provider = aws.peer
  count    = length(local.accepter_public_route_table_ids)

  route_table_id            = local.accepter_public_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.requester.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id
}

resource "aws_route" "accepter_private" {
  provider = aws.peer
  count    = length(local.accepter_private_route_table_ids)

  route_table_id            = local.accepter_private_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.requester.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id
}

resource "aws_route" "accepter_secure" {
  provider = aws.peer
  count    = length(local.accepter_secure_route_table_ids)

  route_table_id            = local.accepter_secure_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.requester.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id
}

resource "aws_route" "requester" {
  count = length(local.requester_route_table_ids)

  route_table_id            = local.requester_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.accepter.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
}
