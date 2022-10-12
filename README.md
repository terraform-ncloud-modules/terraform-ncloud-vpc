# Ncloud VPC Terraform module

## **This version of the module requires Terraform version 1.3.0 or later.**

This document describes the Terraform module that creates multiple Ncloud VPCs.

## Variable Declaration

### Structure : `variable.tf`

You need to create `variable.tf` and declare the VPC variable to recognize VPC variable in `terraform.tfvars`. You can change the variable name to whatever you want.

``` hcl
variable "vpcs" {
  type = list(object({
    name            = string
    ipv4_cidr_block = string                          // cidr block

    subnets = optional(list(object({
      name        = string
      usage_type  = optional(string, "GEN")           // GEN (default) | LOADB
      subnet_type = string                            // PUBLIC | PRIVATE, If usage_type is LOADB in the KR region, only PRIVATE is allowed. 
      zone        = string                            // (PUB) KR-1 | KR-2 // (FIN) FKR-1 | FKR-2 // (GOV) KR | KRS
      subnet      = string                            // cidr block
      network_acl = optional(string, "default")       // default (default) | NetworkAclName, If set "default", then "default Network ACL" will be set. 
    })), [])

    // Deprecated
    public_subnets = optional(list(object({
      name        = string
      zone        = string                            // (PUB) KR-1 | KR-2 // (FIN) FKR-1 | FKR-2 // (GOV) KR | KRS
      subnet      = string                            // cidr block
      network_acl = optional(string, "default")       // default (default) | NetworkAclName, If set "default", then "default Network ACL" will be set. 
    })), [])

    // Deprecated
    private_subnets = optional(list(object({
      name        = string
      zone        = string                            // (PUB) KR-1 | KR-2 // (FIN) FKR-1 | FKR-2 // (GOV) KR | KRS
      subnet      = string                            // cidr block
      network_acl = optional(string, "default")       // default (default) | NetworkAclName, If set "default", then "default Network ACL" will be set. 
    })), [])

    // Deprecated
    loadbalancer_subnets = optional(list(object({
      name        = string
      zone        = string                            // (PUB) KR-1 | KR-2 // (FIN) FKR-1 | FKR-2 // (GOV) KR | KRS
      subnet      = string                            // cidr block
      network_acl = optional(string, "default")       // default (default) | NetworkAclName, If set "default", then "default Network ACL" will be set. 
    })), [])

    network_acls = optional(list(object({
      name           = string                         // if set "default", then "default Network ACL rule" will be created
      description    = optional(string, "")           // if name is "default", then description is ignored

      // The order of writing inbound_rules & outbound_rules is as follows.
      // [
      //   priority(number),                                      // 1-199
      //   protocol(string),                                      // TCP | UDP | ICMP
      //   cidr_block(string) | deny_allow_group_name(string),      
      //   port_number(number) | port_range(string),
      //   rule_action(string),                                   // ALLOW | DROP
      //   description(string)
      // ]
      inbound_rules  = optional(list(list(any)), [])
      outbound_rules = optional(list(list(any)), [])
    })), [])

    deny_allow_groups = optional(list(object({
      name        = string
      description = optional(string, "")
      ip_list     = optional(list(string), [])        // IP address (not CIDR)
    })), [])

    access_control_groups = optional(list(object({
      name           = string                         // if set "default", then "default ACG rule" will be created
      description    = optional(string, "")           // if name is "default", then description is ignored

      // The order of writing inbound_rules & outbound_rules is as follows.
      // [
      //   protocol(string),                                      // TCP | UDP | ICMP
      //   cidr_block(string) | access_control_group_name(string),      
      //   port_number(number) | port_range(string),
      //   description(string)
      // ]
      inbound_rules  = optional(list(list(any)), [])
      outbound_rules = optional(list(list(any)), [])
    })), [])

    public_route_tables = optional(list(object({
      name         = string                           
      description  = optional(string, "")             
      subnet_names = optional(list(string), [])    // All subnets not specified in the separately created route table are automatically associated to the "default route table".
    })), [])

    private_route_tables = optional(list(object({
      name         = string                           
      description  = optional(string, "")             
      subnet_names = optional(list(string), [])    // All subnets not specified in the separately created route table are automatically associated to the "default route table".
    })), [])

    nat_gateways = optional(list(object({
      name        = string
      zone        = string                            // KR-1 | KR-2
      route_table = optional(string, "default")       // default (default) | RouteTableName, If set "default", then "default Route Table for private Subnet" will be set.
    })), [])
  }))
  default = []
}

```

## Example : `terraform.tfvars`

You can create `terraform.tfvars` and refer to the sample below to write variable declarations.
File name can be `terraform.tfvars` or anything ending in `.auto.tfvars`

First element creates :
- 1 `VPC` named "foo"
- 2 `Subnets` each for Public & Private & Load Balancer
- 1 `Network ACL` for Load Balnacer Subnets
- 1 `Deny-Allow Group` for Load Balancer Network ACL
- 1 `Access Control Group` each for Public & Private Subnets
- 1 `NAT Gateways` each for KR-1 & KR-2 zone
- 1 `Route Tables` each for KR-1 & KR-2 zone 

Second element creates :
- 1 `VPC` named "bar"
- 1 `Subnets` each for Public & Private
- 1 `Access Control Group` each for Public & Private Subnets
- 1 `NAT Gateways` for KR-1 zone
- 1 `Route Tables` for KR-1 zone
- `Default Network ACL` & `Default Access Control Group` declarations  omitted.

``` hcl
vpcs = [

  {
    name            = "vpc-foo"
    ipv4_cidr_block = "10.0.0.0/16"

    subnets = [
      {
        name        = "sbn-foo-public-1"
        usage_type  = "GEN"
        subnet_type = "PUBLIC"
        zone        = "KR-1"
        subnet      = "10.0.1.0/24"
        network_acl = "default"
      },
      {
        name        = "sbn-foo-public-2"
        usage_type  = "GEN"
        subnet_type = "PUBLIC"
        zone        = "KR-2"
        subnet      = "10.0.2.0/24"
        network_acl = "default"
      },
      {
        name        = "sbn-foo-private-1"
        usage_type  = "GEN"
        subnet_type = "PRIVATE"
        zone        = "KR-1"
        subnet      = "10.0.3.0/24"
        network_acl = "default"
      },
      {
        name        = "sbn-foo-private-2"
        usage_type  = "GEN"
        subnet_type = "PRIVATE"
        zone        = "KR-2"
        subnet      = "10.0.4.0/24"
        network_acl = "default"
      },
      {
        name        = "sbn-foo-lb-1"
        usage_type  = "LOADB"
        subnet_type = "PRIVATE"
        zone        = "KR-1"
        subnet      = "10.0.5.0/24"
        network_acl = "nacl-foo-loadbalancer"
      },
      {
        name        = "sbn-foo-lb-2"
        usage_type  = "LOADB"
        subnet_type = "PRIVATE"
        zone        = "KR-2"
        subnet      = "10.0.6.0/24"
        network_acl = "nacl-foo-loadbalancer"
      }
    ]

    network_acls = [
      {
        name        = "default"
        description = "Default Network ACL for this VPC"
        inbound_rules = []
        outbound_rules = []
      },
      {
        name        = "nacl-foo-loadbalancer"
        description = "Network ACL for loadbalaner subnets"
        inbound_rules = [
          [100, "TCP", "dagrp-foo", 22, "ALLOW", "SSH allow form dagrp-foo"],
          [110, "TCP", "0.0.0.0/0", 22, "ALLOW", "SSH allow form any"]
        ]
        outbound_rules = [
          [110, "TCP", "0.0.0.0/0", "1-65535", "ALLOW", "All allow to any"]
        ]
      }
    ]

    deny_allow_groups = [
      {
        name        = "dagrp-foo"
        description = "foo deny allow group"
        ip_list     = ["10.0.0.1", "10.0.0.2"]
      }
    ]

    access_control_groups = [
      {
        name        = "default"
        description = "Default ACG for this VPC"
        outbound_rules = [
          ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
          ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
        ]
      },
      {
        name        = "acg-foo-public"
        description = "ACG for public servers"
        inbound_rules = [
          ["TCP", "0.0.0.0/0", 22, "SSH allow form any"]
        ]
        outbound_rules = [
          ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
          ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
        ]
      },
      {
        name        = "acg-foo-private"
        description = "ACG for private servers"
        inbound_rules = [
          ["TCP", "acg-foo-public", 22, "SSH allow form acg-foo-public"]
        ]
        outbound_rules = [
          ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
          ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
        ]
      }
    ]

    public_route_tables = []
    private_route_tables = [
      {
        name         = "rt-foo-private-1"
        description  = "Route table for Private, LB subnets on KR-1 zone"
        subnet_names = ["sbn-foo-private-1", "sbn-foo-lb-1"]
      },
      {
        name         = "rt-foo-private-2"
        description  = "Route table for Private, LB subnets on KR-2 zone"
        subnet_names = ["sbn-foo-private-2", "sbn-foo-lb-2"]
      }
    ]

    nat_gateways = [
      {
        name        = "nat-gw-foo-1"
        zone        = "KR-1"
        route_table = "rt-foo-private-1"
      },
      {
        name        = "nat-gw-foo-2"
        zone        = "KR-2"
        route_table = "rt-foo-private-2"
      }
    ]
  },

  {
    name            = "vpc-bar"
    ipv4_cidr_block = "10.10.0.0/16"

    subnets = [
      {
        name        = "sbn-bar-public"
        usage_type  = "GEN"
        subnet_type = "PUBLIC"
        zone        = "KR-1"
        subnet      = "10.10.1.0/24"
        network_acl = "default"
      },
      {
        name        = "sbn-bar-private"
        usage_type  = "GEN"
        subnet_type = "PRIVATE"
        zone        = "KR-1"
        subnet      = "10.10.2.0/24"
        network_acl = "default"
      }
    ]


    access_control_groups = [
      {
        name        = "acg-bar-public"
        description = "ACG for public servers"
        inbound_rules = [
          ["TCP", "0.0.0.0/0", 22, "SSH allow form any"]
        ]
        outbound_rules = [
          ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
          ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
        ]
      },
      {
        name        = "acg-bar-private"
        description = "ACG for private servers"
        inbound_rules = [
          ["TCP", "acg-bar-public", 22, "SSH allow form acg-bar-public"]
        ]
        outbound_rules = [
          ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
          ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
        ]
      }
    ]

    private_route_tables = [
      {
        name         = "rt-bar-private"
        description  = "Route table for Private, LB subnets on KR-1 zone"
        subnet_names = ["sbn-bar-private"]
      }
    ]

    nat_gateways = [
      {
        name        = "nat-gw-bar"
        zone        = "KR-1"
        route_table = "rt-bar-private"
      }
    ]
  }
]

```

## Module Usage

### `main.tf`

Map your VPC variable name to a local VPC variable. VPC module are created using local VPC variables. This eliminates the need to change the variable name reference structure in the VPC module.

``` hcl
locals {
  vpcs = var.vpcs
}
```

Then just copy and paste the module declaration below.

``` hcl
module "vpcs" {
  source = "terraform-ncloud-modules/vpc/ncloud"

  for_each = { for vpc in local.vpcs : vpc.name => vpc }

  name                  = each.value.name
  ipv4_cidr_block       = each.value.ipv4_cidr_block
  subnets               = each.value.subnets
  # public_subnets        = each.value.public_subnets
  # private_subnets       = each.value.private_subnets
  # loadbalancer_subnets  = each.value.loadbalancer_subnets
  network_acls          = each.value.network_acls
  deny_allow_groups     = each.value.deny_allow_groups
  access_control_groups = each.value.access_control_groups
  public_route_tables   = each.value.public_route_tables
  private_route_tables  = each.value.private_route_tables
  nat_gateways          = each.value.nat_gateways
}
```