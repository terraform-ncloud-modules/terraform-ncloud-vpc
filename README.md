# Ncloud VPC Terraform module

## Module Usage

### `main.tf`
#### Single VPC
``` hcl
module "vpc" {
  source = "terraform-ncloud-modules/vpc/ncloud"

  // VPC (Required)
  name            = var.vpc.name
  ipv4_cidr_block = var.vpc.ipv4_cidr_block

  // Subnets (Optional)
  public_subnets       = lookup(var.vpc, "public_subnets", [])
  private_subnets      = lookup(var.vpc, "private_subnets", [])
  loadbalancer_subnets = lookup(var.vpc, "loadbalancer_subnets", [])

  // Network ACLs (Optional)
  network_acls      = lookup(var.vpc, "network_acls", [])
  deny_allow_groups = lookup(var.vpc, "deny_allow_groups", [])

  // Access Control Groups (Optional)
  access_control_groups = lookup(var.vpc, "access_control_groups", [])
  
  // Route Tables (Optional)
  public_route_tables  = lookup(var.vpc, "public_route_tables", [])
  private_route_tables = lookup(var.vpc, "private_route_tables", [])

  // NAT Gateways (Optional)
  nat_gateways = lookup(var.vpc, "nat_gateways", [])
}
```

#### Multiple VPC
``` hcl
module "vpcs" {
  source = "terraform-ncloud-modules/vpc/ncloud"

  for_each = { for vpc in var.vpcs : vpc.name => vpc }

  // VPC (Required)
  name            = each.value.name
  ipv4_cidr_block = each.value.ipv4_cidr_block

  // Subnets (Optional)
  public_subnets       = lookup(each.value, "public_subnets", [])
  private_subnets      = lookup(each.value, "private_subnets", [])
  loadbalancer_subnets = lookup(each.value, "loadbalancer_subnets", [])

  // Network ACLs (Optional)
  network_acls      = lookup(each.value, "network_acls", [])
  deny_allow_groups = lookup(each.value, "deny_allow_groups", [])

  // Access Control Groups (Optional)
  access_control_groups = lookup(each.value, "access_control_groups", [])
  
  // Route Tables (Optional)
  public_route_tables  = lookup(each.value, "public_route_tables", [])
  private_route_tables = lookup(each.value, "private_route_tables", [])

  // NAT Gateways (Optional)
  nat_gateways = lookup(each.value, "nat_gateways", [])
}
```


## Variable Declaration

### `terraform.tfvars`
You can create `terraform.tfvars` and refer to the sample below to write variable specifications.
#### Single VPC
``` hcl
vpc = {
  // VPC declaration
  // Requied
  name            = string
  ipv4_cidr_block = string(cidr)

  // Subnet declaration
  // Optional, Allow multiple
  public_subnets = [      
    {
      name        = string
      zone        = string(zone)    // (PUB) KR-1 | KR-2 // (FIN) FKR-1 | FKR-2 // (GOV) KR | KRS
      subnet      = string(cidr)
      // if set network_acl = default, then "default Network ACL" will be set. 
      network_acl = string          // default | NetworkAclName
    }
  ]
  private_subnets = []         // same as above
  loadbalancer_subnets = []    // same as above

  // Network ACL & Deny Allow Group declaration
  // Optional, Allow multiple
  // The order of writing inbound_rules & outbound_rules is as follows.
  // [priority, protocol, ip_block|deny_allow_group, port_range, rule_action, description]
  network_acls = [
    {
      name        = string
      description = string
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
  deny_allow_groups = [
    {
      name        = string
      description = string
      ip_list     = list(string)  // IP address (not CIDR)
    }
  ]

  // ACG declaration
  // Optional, Allow multiple
  // You can manage ACG within the VPC module or in a separate ACG module(terraform-ncloud-modules/acg/ncloud).
  // The order of writing inbound_rules & outbound_rules is as follows.
  // [protocol, ip_block|source_access_control_group, port_range, description]
  access_control_groups = [
    {
      name        = string
      description = string
      inbound_rules = [
        [
          string,            // TCP | UDP | ICMP
          string,            // CIDR | AccessControlGroupName
          integer|string,    // PortNumber(22) | PortRange(1-65535)
          string
        ]
      ]
      outbound_rules = []    // same as above
    }
  ]

  // Route Table declaration
  // Optional, Allow multiple
  public_route_tables = [
    {
      name         = string
      description  = string
      subnet_names = list(string)    // [ SubnetName ]. It can be empty list []. 
    }
  ]
  private_route_tables = []     // same as above

  // NAT Gateway declaration
  // Optional, Allow multiple
  nat_gateways = [
    {
      name        = string
      zone        = string(zone)      // KR-1 | KR-2
      // if set route_table = default, then "default Route Table for private Subnet" will be set. 
      route_table = string            // default | RouteTableName
    }
  ]
}
```
#### Multiple VPC
``` hcl
vpcs = [
  { },     // same as Single VPC specification
  { }
]
```

#### Example (Single VPC)
``` hcl
vpc = {
  name            = "vpc-sample"
  ipv4_cidr_block = "10.0.0.0/16"

  public_subnets = [
    {
      name        = "sbn-sample-public-1"
      zone        = "KR-1"
      subnet      = "10.0.1.0/24"
      network_acl = "default"
    },
    {
      name        = "sbn-sample-public-2"
      zone        = "KR-2"
      subnet      = "10.0.2.0/24"
      network_acl = "default"
    }
  ]
  private_subnets = [
    {
      name        = "sbn-sample-private-1"
      zone        = "KR-1"
      subnet      = "10.0.3.0/24"
      network_acl = "default"
    },
    {
      name        = "sbn-sample-private-2"
      zone        = "KR-2"
      subnet      = "10.0.4.0/24"
      network_acl = "default"
    }
  ]
  loadbalancer_subnets = [
    {
      name        = "sbn-sample-lb-1"
      zone        = "KR-1"
      subnet      = "10.0.5.0/24"
      network_acl = "nacl-sample-loadbalancer"
    },
    {
      name        = "sbn-sample-lb-2"
      zone        = "KR-2"
      subnet      = "10.0.6.0/24"
      network_acl = "nacl-sample-loadbalancer"
    }
  ]

  network_acls = [
    {
      name        = "nacl-sample-loadbalancer"
      description = "Network ACL for loadbalaner subnets"
      inbound_rules = [
        [100, "TCP", "dagrp-sample", 22, "ALLOW", "SSH allow form dagrp-sample"],
        [110, "TCP", "0.0.0.0/0", 22, "ALLOW", "SSH allow form any"]
      ]
      outbound_rules = [
        [110, "TCP", "0.0.0.0/0", "1-65535", "ALLOW", "All allow to any"]
      ]
    }
  ]

  deny_allow_groups = [
    {
      name        = "dagrp-sample"
      description = "sample deny allow group"
      ip_list     = ["10.0.0.1", "10.0.0.2"]
    }
  ]

  access_control_groups = [
    {
      name        = "acg-sample-public"
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
      name        = "acg-sample-private"
      description = "ACG for private servers"
      inbound_rules = [
        ["TCP", "acg-sample-public", 22, "SSH allow form acg-sample-public"]
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
      name         = "rt-sample-private-1"
      description  = "Route table for Private, LB subnets on KR-1 zone"
      subnet_names = ["sbn-sample-private-1", "sbn-sample-lb-1"]
    },
    {
      name         = "rt-sample-private-2"
      description  = "Route table for Private, LB subnets on KR-2 zone"
      subnet_names = ["sbn-sample-private-2", "sbn-sample-lb-2"]
    }
  ]

  nat_gateways = [
    {
      name        = "nat-gw-sample-1"
      zone        = "KR-1"
      route_table = "rt-sample-private-1"
    },
    {
      name        = "nat-gw-sample-2"
      zone        = "KR-2"
      route_table = "rt-sample-private-2"
    }
  ]
}


```

### `variable.tf`
You also need to create `variable.tf` to enable `terraform.tfvars`
``` hcl
variable "vpc" {}
variable "vpcs" {}
```


