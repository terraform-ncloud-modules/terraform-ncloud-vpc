# Single VPC Module

This document describes the Terraform module that creates single Ncloud VPC.

## Variable Declaration

### `variable.tf`

You need to create `variable.tf` and declare the VPC variable to recognize VPC variable in `terraform.tfvars`. You can change the variable name to whatever you want.

``` hcl
variable "vpc" {}
```

### `terraform.tfvars`

You can create `terraform.tfvars` and refer to the sample below to write variable declarations.
File name can be `terraform.tfvars` or anything ending in `.auto.tfvars`

#### Structure

``` hcl
vpc = {

  // VPC declaration (Requied)
  name            = string
  ipv4_cidr_block = string(cidr)

  // Subnet declaration (Optional, List)
  public_subnets = [      
    {
      name        = string
      zone        = string(zone)   // (PUB) KR-1 | KR-2 // (FIN) FKR-1 | FKR-2 // (GOV) KR | KRS
      subnet      = string(cidr)   
      network_acl = string         // default | NetworkAclName, 
                                   // if set "default", then "default Network ACL" will be set. 
    }
  ]
  private_subnets      = []    // same as above
  loadbalancer_subnets = []    // same as above

  // Network ACL declaration (Optional, List)
  network_acls = [
    {
      name        = string   // if set "default", then "default Network ACL rule" will be created
      description = string

      // The order of writing inbound_rules & outbound_rules is as follows.
      // [priority, protocol, ip_block|deny_allow_group, port_range, rule_action, description]
      inbound_rules = [
        [
          integer,           // 1-199
          string,            // TCP | UDP | ICMP
          string,            // CIDR | DenyAllowGroupName
          integer|string,    // PortNumber(22) | PortRange(1-65535)
          string,            // ALLOW | DROP
          string
        ],
      ]
      outbound_rules = []    // same as above
    }
  ]

  // Deny-Allow Group declaration (Optional, List)
  deny_allow_groups = [
    {
      name        = string
      description = string
      ip_list     = list(string)  // IP address (not CIDR)
    }
  ]

  // ACG declaration (Optional, List)
  // You can manage ACGs within a VPC module, or you can manage them in a separate ACG module.(terraform-ncloud-modules/acg/ncloud).
  access_control_groups = [
    {
      name        = string   // if set "default", then "default ACG rule" will be created
      description = string

      // The order of writing inbound_rules & outbound_rules is as follows.
      // [protocol, ip_block|source_access_control_group, port_range, description]
      inbound_rules = [
        [
          string,            // TCP | UDP | ICMP
          string,            // CIDR | AccessControlGroupName
                             // Set to "default" to set "default ACG" to source_access_control_group.
          integer|string,    // PortNumber(22) | PortRange(1-65535)
          string
        ]
      ]
      outbound_rules = []    // same as above
    }
  ]

  // Route Table declaration (Optional, List)
  public_route_tables = [
    {
      name         = string
      description  = string
      subnet_names = list(string)    // [ SubnetName ]. It can be empty list []. 
    }
  ]
  private_route_tables = []     // same as above

  // NAT Gateway declaration (Optional, List)
  nat_gateways = [
    {
      name        = string
      zone        = string(zone)  // KR-1 | KR-2
      route_table = string        // default | RouteTableName
                                  // if set "default", then "default Route Table for private Subnet" will be set. 
    }
  ]
}
```

#### Example

``` hcl
vpc = {
  name            = "vpc-single"
  ipv4_cidr_block = "10.0.0.0/16"

  public_subnets = [
    {
      name        = "sbn-single-public-1"
      zone        = "KR-1"
      subnet      = "10.0.1.0/24"
      network_acl = "default"
    },
    {
      name        = "sbn-single-public-2"
      zone        = "KR-2"
      subnet      = "10.0.2.0/24"
      network_acl = "default"
    }
  ]
  private_subnets = [
    {
      name        = "sbn-single-private-1"
      zone        = "KR-1"
      subnet      = "10.0.3.0/24"
      network_acl = "default"
    },
    {
      name        = "sbn-single-private-2"
      zone        = "KR-2"
      subnet      = "10.0.4.0/24"
      network_acl = "default"
    }
  ]
  loadbalancer_subnets = [
    {
      name        = "sbn-single-lb-1"
      zone        = "KR-1"
      subnet      = "10.0.5.0/24"
      network_acl = "nacl-single-loadbalancer"
    },
    {
      name        = "sbn-single-lb-2"
      zone        = "KR-2"
      subnet      = "10.0.6.0/24"
      network_acl = "nacl-single-loadbalancer"
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
      name        = "nacl-single-loadbalancer"
      description = "Network ACL for loadbalaner subnets"
      inbound_rules = [
        [100, "TCP", "dagrp-single", 22, "ALLOW", "SSH allow form dagrp-single"],
        [110, "TCP", "0.0.0.0/0", 22, "ALLOW", "SSH allow form any"]
      ]
      outbound_rules = [
        [110, "TCP", "0.0.0.0/0", "1-65535", "ALLOW", "All allow to any"]
      ]
    }
  ]

  deny_allow_groups = [
    {
      name        = "dagrp-single"
      description = "single deny allow group"
      ip_list     = ["10.0.0.1", "10.0.0.2"]
    }
  ]

  access_control_groups = [
    {
      name        = "default"
      description = "Default ACG for this VPC"
      inbound_rules = []
      outbound_rules = [
        ["TCP", "0.0.0.0/0", "1-65535", "All allow to any"],
        ["UDP", "0.0.0.0/0", "1-65535", "All allow to any"]
      ]
    },
    {
      name        = "acg-single-public"
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
      name        = "acg-single-private"
      description = "ACG for private servers"
      inbound_rules = [
        ["TCP", "acg-single-public", 22, "SSH allow form acg-single-public"]
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
      name         = "rt-single-private-1"
      description  = "Route table for Private, LB subnets on KR-1 zone"
      subnet_names = ["sbn-single-private-1", "sbn-single-lb-1"]
    },
    {
      name         = "rt-single-private-2"
      description  = "Route table for Private, LB subnets on KR-2 zone"
      subnet_names = ["sbn-single-private-2", "sbn-single-lb-2"]
    }
  ]

  nat_gateways = [
    {
      name        = "nat-gw-single-1"
      zone        = "KR-1"
      route_table = "rt-single-private-1"
    },
    {
      name        = "nat-gw-single-2"
      zone        = "KR-2"
      route_table = "rt-single-private-2"
    }
  ]
}


```

## Module Usage

### `main.tf`

Map your VPC variable name to a local VPC variable. VPC module are created using local VPC variables. This eliminates the need to change the variable name reference structure in the VPC module.

``` hcl
locals {
  vpc = var.vpc
}
```

Then just copy and paste the module declaration below.

``` hcl
module "vpc" {
  source = "terraform-ncloud-modules/vpc/ncloud"

  name            = local.vpc.name
  ipv4_cidr_block = local.vpc.ipv4_cidr_block

  public_subnets       = lookup(local.vpc, "public_subnets", [])
  private_subnets      = lookup(local.vpc, "private_subnets", [])
  loadbalancer_subnets = lookup(local.vpc, "loadbalancer_subnets", [])

  network_acls      = lookup(local.vpc, "network_acls", [])
  deny_allow_groups = lookup(local.vpc, "deny_allow_groups", [])

  access_control_groups = lookup(local.vpc, "access_control_groups", [])
  
  public_route_tables  = lookup(local.vpc, "public_route_tables", [])
  private_route_tables = lookup(local.vpc, "private_route_tables", [])

  nat_gateways = lookup(local.vpc, "nat_gateways", [])
}
```
