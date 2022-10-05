# Multiple VPC Module

This document describes the Terraform module that creates multiple Ncloud VPCs.

## Variable Declaration

### `variable.tf`

You need to create `variable.tf` and declare the VPC variable to recognize VPC variable in `terraform.tfvars`. You can change the variable name to whatever you want.

``` hcl
variable "vpcs" {}
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
]
```

#### Example

``` hcl
vpcs = [
  {
    name            = "vpc-multiple"
    ipv4_cidr_block = "10.0.0.0/16"

    public_subnets = [
      {
        name        = "sbn-multiple-public-1"
        zone        = "KR-1"
        subnet      = "10.0.1.0/24"
        network_acl = "default"
      },
      {
        name        = "sbn-multiple-public-2"
        zone        = "KR-2"
        subnet      = "10.0.2.0/24"
        network_acl = "default"
      }
    ]
    private_subnets = [
      {
        name        = "sbn-multiple-private-1"
        zone        = "KR-1"
        subnet      = "10.0.3.0/24"
        network_acl = "default"
      },
      {
        name        = "sbn-multiple-private-2"
        zone        = "KR-2"
        subnet      = "10.0.4.0/24"
        network_acl = "default"
      }
    ]
    loadbalancer_subnets = [
      {
        name        = "sbn-multiple-lb-1"
        zone        = "KR-1"
        subnet      = "10.0.5.0/24"
        network_acl = "nacl-multiple-loadbalancer"
      },
      {
        name        = "sbn-multiple-lb-2"
        zone        = "KR-2"
        subnet      = "10.0.6.0/24"
        network_acl = "nacl-multiple-loadbalancer"
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
        name        = "nacl-multiple-loadbalancer"
        description = "Network ACL for loadbalaner subnets"
        inbound_rules = [
          [100, "TCP", "dagrp-multiple", 22, "ALLOW", "SSH allow form dagrp-multiple"],
          [110, "TCP", "0.0.0.0/0", 22, "ALLOW", "SSH allow form any"]
        ]
        outbound_rules = [
          [110, "TCP", "0.0.0.0/0", "1-65535", "ALLOW", "All allow to any"]
        ]
      }
    ]

    deny_allow_groups = [
      {
        name        = "dagrp-multiple"
        description = "multiple deny allow group"
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
        name        = "acg-multiple-public"
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
        name        = "acg-multiple-private"
        description = "ACG for private servers"
        inbound_rules = [
          ["TCP", "acg-multiple-public", 22, "SSH allow form acg-multiple-public"]
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
        name         = "rt-multiple-private-1"
        description  = "Route table for Private, LB subnets on KR-1 zone"
        subnet_names = ["sbn-multiple-private-1", "sbn-multiple-lb-1"]
      },
      {
        name         = "rt-multiple-private-2"
        description  = "Route table for Private, LB subnets on KR-2 zone"
        subnet_names = ["sbn-multiple-private-2", "sbn-multiple-lb-2"]
      }
    ]

    nat_gateways = [
      {
        name        = "nat-gw-multiple-1"
        zone        = "KR-1"
        route_table = "rt-multiple-private-1"
      },
      {
        name        = "nat-gw-multiple-2"
        zone        = "KR-2"
        route_table = "rt-multiple-private-2"
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

  public_subnets       = lookup(each.value, "public_subnets", [])
  private_subnets      = lookup(each.value, "private_subnets", [])
  loadbalancer_subnets = lookup(each.value, "loadbalancer_subnets", [])

  network_acls      = lookup(each.value, "network_acls", [])
  deny_allow_groups = lookup(each.value, "deny_allow_groups", [])

  access_control_groups = lookup(each.value, "access_control_groups", [])

  public_route_tables  = lookup(each.value, "public_route_tables", [])
  private_route_tables = lookup(each.value, "private_route_tables", [])

  nat_gateways = lookup(each.value, "nat_gateways", [])
}
```
