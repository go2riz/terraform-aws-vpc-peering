output "vpc_peering_connection_id" {
  description = "VPC peering connection ID (same ID is visible from both sides once accepted)."
  value       = aws_vpc_peering_connection.requester.id
}

output "accepter_vpc_id" {
  description = "Accepter VPC ID."
  value       = var.peer_vpc_id
}

output "requester_vpc_id" {
  description = "Requester VPC ID."
  value       = var.vpc_id
}