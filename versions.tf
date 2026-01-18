terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # aws_subnet_ids data source was removed in aws provider v5.
      # This module uses aws_subnets and is compatible with v5+.
      version = ">= 5.0.0, < 7.0.0"

      # This module expects the calling stack to pass an aliased provider
      # for the peer (accepter) account/region as aws.peer.
      configuration_aliases = [aws.peer]
    }
  }
}
