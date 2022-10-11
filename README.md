# Ncloud VPC Terraform module

This document describes the Terraform module that creates multiple Ncloud VPCs.

## Variable Declaration

### `variable.tf`

You need to create `variable.tf` and declare the VPC variable to recognize VPC variable in `terraform.tfvars`. You can change the variable name to whatever you want.

``` hcl
variable "vpcs" { default = [] }
```

### `terraform.tfvars`

You can create `terraform.tfvars` and refer to the sample below to write variable declarations.
File name can be `terraform.tfvars` or anything ending in `.auto.tfvars`

#### Structure

``` hcl
vpcs = [
  {
    // VPC declaration (Requied)
    name            = string
    ipv4_cidr_block = string(cidr)  

    // Subnet declaration (Optional, List)
    subnets = [      
      {
        name        = string
        usage_type  = "GEN"          // GEN | LOADB
        subnet_type = "PRIVATE"      // PUBLIC | PRIVATE 
                                     // If usage_type is LOADB in the KR region, only PRIVATE is allowed.
        zone        = string(zone)   // (PUB) KR-1 | KR-2 // (FIN) FKR-1 | FKR-2 // (GOV) KR | KRS
        subnet      = string(cidr)   
        network_acl = string         // default | NetworkAclName, 
                                     // if set "default", then "default Network ACL" will be set. 
      }
    ]

    // Deprecated
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
]
```

#### Example

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
        inbound_rules = []
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

  name            = each.value.name
  ipv4_cidr_block = each.value.ipv4_cidr_block

  subnets = lookup(each.value, "subnets", [])

  // Deprecated. It has been replaced by "subnets"
  // public_subnets       = lookup(each.value, "public_subnets", [])
  // private_subnets      = lookup(each.value, "private_subnets", [])
  // loadbalancer_subnets = lookup(each.value, "loadbalancer_subnets", [])

  network_acls      = lookup(each.value, "network_acls", [])
  deny_allow_groups = lookup(each.value, "deny_allow_groups", [])

  access_control_groups = lookup(each.value, "access_control_groups", [])

  public_route_tables  = lookup(each.value, "public_route_tables", [])
  private_route_tables = lookup(each.value, "private_route_tables", [])

  nat_gateways = lookup(each.value, "nat_gateways", [])
}
```