resource "aws_vpc_peering_connection" "requester" {
  peer_vpc_id   = var.peer_vpc_id
  peer_owner_id = var.peer_owner_id
  vpc_id        = var.vpc_id
  peer_region   = var.accepter_region
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  auto_accept               = true
}

# Optional: enable cross-VPC DNS resolution.
#
# Default is disabled to preserve legacy behaviour.
resource "aws_vpc_peering_connection_options" "requester" {
  count = var.enable_remote_vpc_dns_resolution ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  count    = var.enable_remote_vpc_dns_resolution ? 1 : 0
  provider = aws.peer

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}
