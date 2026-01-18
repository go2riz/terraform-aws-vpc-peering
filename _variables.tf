variable "peer_vpc_id" {
  description = "VPC ID of accepter"
  type        = string
}

variable "peer_owner_id" {
  description = "Account ID of accepter"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID of requester"
  type        = string
}

variable "serial" {
  default     = 0
  description = "Number of this peering, distinct from others, to avoid conflict with NACL rule number"
  type        = number
}

variable "accepter_region" {
  description = "Region of acccepter"
  type        = string
}

variable "enable_remote_vpc_dns_resolution" {
  description = "Enable DNS resolution across the peering connection on both requester and accepter sides."
  type        = bool
  default     = false
}

variable "peer_rule_numbers" {
  description = "Optional override map of requester subnet CIDR -> rule_number for accepter-side peer allow NACL rules. If empty, rule numbers are generated as 1000 + index based on sorted requester subnet ids."
  type        = map(number)
  default     = {}
}