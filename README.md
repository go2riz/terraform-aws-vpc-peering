# terraform-aws-vpc-peering (upgraded for Terraform 1.x)

This module creates an AWS VPC peering connection between:

* **Requester** VPC (current AWS provider)
* **Accepter** VPC (aliased provider `aws.peer`)

It also adds:

* Routes in route tables discovered from subnets tagged by `Scheme`
* Network ACL rules to allow traffic between the two VPC CIDR blocks

## Requirements

* Terraform: >= 1.0
* AWS provider: >= 5.0

## Provider Configuration

This module expects you to pass two AWS provider configurations:

* `aws` (requester account/region)
* `aws.peer` (accepter account/region)

Example:

```hcl
provider "aws" {
  region = "ap-southeast-2"
}

provider "aws" {
  alias  = "peer"
  region = "ap-southeast-2"

  # assume_role, profile, etc. for the peer account goes here
}

module "vpc_peering" {
  source = "./terraform-aws-vpc-peering"

  providers = {
    aws      = aws
    aws.peer = aws.peer
  }

  vpc_id          = "vpc-REQUESTER"
  peer_vpc_id     = "vpc-ACCEPTER"
  peer_owner_id   = "123456789012"
  accepter_region = "ap-southeast-2"
  serial          = 0

  # Optional
  enable_remote_vpc_dns_resolution = false
}
```

## Tagging conventions used by this module

This module looks for subnets and Network ACLs using the `Scheme` tag:

Requester (current provider):

* Subnets: `Scheme = transit`
* Network ACL: `Scheme = transit`

Accepter (aliased provider):

* Subnets: `Scheme = public`, `private`, `secure`
* Network ACLs: `Scheme = public`, `private`, `secure`

If your VPCs use different tagging, you will need to adapt the filters.

## Upgrade notes from v0.2.1

* Removed the deprecated `aws_subnet_ids` data source (removed in AWS provider v5) and replaced it with `aws_subnets`.
* Removed the empty `provider "aws" { alias = "peer" }` block from the module and replaced it with `configuration_aliases = [aws.peer]` in `versions.tf`.
* Replaced legacy interpolation-only syntax (`"${...}"`) with Terraform 1.x HCL.
* Added optional peering DNS resolution support (`enable_remote_vpc_dns_resolution`). Default is `false` to preserve legacy behaviour.
* Added `one(...)` to ensure exactly one Network ACL is matched per `Scheme`.

## Ordering-churn fix (recommended)

Newer AWS provider versions (and AWS APIs) can return subnet/route table lists in a different order.
If resources are created with `count`, that can lead to noisy plans that want to **replace** NACL rules
and routes even though the logical configuration didn't change.

This module now uses `for_each` keyed by **CIDR** (NACL rules) and **route table id** (routes) to avoid
that churn.

If you are upgrading an existing deployment, follow **MIGRATION.md** to move state addresses so you
don't recreate live rules/routes.