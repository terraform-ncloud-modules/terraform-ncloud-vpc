resource "ncloud_vpc" "vpc" {
  name            = var.name
  ipv4_cidr_block = var.ipv4_cidr_block
}

resource "ncloud_subnet" "public_subnets" {
  for_each = { for subnet in var.public_subnets : subnet.name => subnet }

  name           = each.value.name
  vpc_no         = ncloud_vpc.vpc.id
  usage_type     = "GEN"
  subnet_type    = "PUBLIC"
  zone           = each.value.zone
  subnet         = each.value.subnet
  network_acl_no = each.value.network_acl == "default" ? ncloud_vpc.vpc.default_network_acl_no : ncloud_network_acl.network_acls[each.value.network_acl].id

}

resource "ncloud_subnet" "private_subnets" {
  for_each = { for subnet in var.private_subnets : subnet.name => subnet }

  name           = each.value.name
  vpc_no         = ncloud_vpc.vpc.id
  usage_type     = "GEN"
  subnet_type    = "PRIVATE"
  zone           = each.value.zone
  subnet         = each.value.subnet
  network_acl_no = each.value.network_acl == "default" ? ncloud_vpc.vpc.default_network_acl_no : ncloud_network_acl.network_acls[each.value.network_acl].id

}

resource "ncloud_subnet" "loadbalancer_subnets" {
  for_each = { for subnet in var.loadbalancer_subnets : subnet.name => subnet }

  name           = each.value.name
  vpc_no         = ncloud_vpc.vpc.id
  usage_type     = "LOADB"
  subnet_type    = "PRIVATE"
  zone           = each.value.zone
  subnet         = each.value.subnet
  network_acl_no = each.value.network_acl == "default" ? ncloud_vpc.vpc.default_network_acl_no : ncloud_network_acl.network_acls[each.value.network_acl].id

}

locals {
  subnets = merge(ncloud_subnet.public_subnets, ncloud_subnet.private_subnets, ncloud_subnet.loadbalancer_subnets)
}

resource "ncloud_network_acl" "network_acls" {
  for_each = { for network_acl in var.network_acls : network_acl.name => network_acl }

  name        = each.value.name
  vpc_no      = ncloud_vpc.vpc.id
  description = each.value.description
}


resource "ncloud_network_acl_deny_allow_group" "deny_allow_groups" {
  for_each = { for dagrp in var.deny_allow_groups : dagrp.name => dagrp }

  name        = each.value.name
  description = each.value.description
  vpc_no      = ncloud_vpc.vpc.id
  ip_list     = each.value.ip_list
}


locals {
  network_acls = { for nacl_key, nacl_value in ncloud_network_acl.network_acls : nacl_key =>
    merge(nacl_value, {
      inbound_rules = [for rule in var.network_acls[index(var.network_acls.*.name, nacl_key)].inbound_rules :
        {
          priority = rule[0]
          protocol = rule[1]
          ip_block = (can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", rule[2]))
            ? rule[2] : null
          )
          deny_allow_group_no = (can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", rule[2]))
            ? null : ncloud_network_acl_deny_allow_group.deny_allow_groups[rule[2]].id
          )
          port_range  = rule[3]
          rule_action = rule[4]
          description = rule[5]
        }
      ]
      outbound_rules = [for rule in var.network_acls[index(var.network_acls.*.name, nacl_key)].outbound_rules :
        {
          priority = rule[0]
          protocol = rule[1]
          ip_block = (can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", rule[2]))
            ? rule[2] : null
          )
          deny_allow_group_no = (can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", rule[2]))
            ? null : ncloud_network_acl_deny_allow_group.deny_allow_groups[rule[2]].id
          )
          port_range  = rule[3]
          rule_action = rule[4]
          description = rule[5]
        }
      ]
    })
  }
}

resource "ncloud_network_acl_rule" "nacl_rules" {
  for_each = local.network_acls

  network_acl_no = each.value.id

  dynamic "inbound" {
    for_each = each.value.inbound_rules
    content {
      priority            = inbound.value.priority
      protocol            = inbound.value.protocol
      ip_block            = inbound.value.ip_block
      deny_allow_group_no = inbound.value.deny_allow_group_no
      port_range          = inbound.value.port_range
      rule_action         = inbound.value.rule_action
      description         = inbound.value.description
    }
  }

  dynamic "outbound" {
    for_each = each.value.outbound_rules
    content {
      priority            = outbound.value.priority
      protocol            = outbound.value.protocol
      ip_block            = outbound.value.ip_block
      deny_allow_group_no = outbound.value.deny_allow_group_no
      port_range          = outbound.value.port_range
      rule_action         = outbound.value.rule_action
      description         = outbound.value.description
    }
  }
}


resource "ncloud_route_table" "public_route_tables" {
  for_each = { for route_table in var.public_route_tables : route_table.name => route_table }

  name                  = each.value.name
  vpc_no                = ncloud_vpc.vpc.id
  supported_subnet_type = "PUBLIC"
  description           = each.value.description
}

resource "ncloud_route_table" "private_route_tables" {
  for_each = { for route_table in var.private_route_tables : route_table.name => route_table }

  name                  = each.value.name
  vpc_no                = ncloud_vpc.vpc.id
  supported_subnet_type = "PRIVATE"
  description           = each.value.description
}

locals {
  public_route_tables = { for rt_key, rt_value in ncloud_route_table.public_route_tables :
    rt_key => merge(rt_value, {
      subnets = [for subnet_name in var.public_route_tables[index(var.public_route_tables.*.name, rt_value.name)].subnet_names : {
        subnet_name = subnet_name
        subnet_no   = local.subnets[subnet_name].id
      }]
    })
  }
  private_route_tables = { for rt_key, rt_value in ncloud_route_table.private_route_tables :
    rt_key => merge(rt_value, { subnets = [for subnet_name in var.private_route_tables[index(var.private_route_tables.*.name, rt_value.name)].subnet_names : {
      subnet_name = subnet_name
      subnet_no   = local.subnets[subnet_name].id
      }]
    })
  }
  route_tables = merge(local.public_route_tables, local.private_route_tables)
  route_table_associations = merge([
    for rt_key, rt_value in local.route_tables : {
      for subnet in rt_value.subnets :
      "${rt_key}_${subnet.subnet_name}" => merge({
        for att_key, att_value in rt_value : att_key => att_value if att_key != "subnets"
        }, { subnet = subnet }
      )
    }
  ]...)
}

resource "ncloud_route_table_association" "route_table_associations" {
  for_each = local.route_table_associations

  route_table_no = each.value.route_table_no
  subnet_no      = each.value.subnet.subnet_no
}


resource "ncloud_nat_gateway" "nat_gateways" {
  for_each = { for nat_gateway in var.nat_gateways : nat_gateway.name => nat_gateway }

  name   = each.value.name
  vpc_no = ncloud_vpc.vpc.id
  zone   = each.value.zone
}

locals {
  nat_gateways = { for nat_gw_key, nat_gw_value in ncloud_nat_gateway.nat_gateways : nat_gw_key =>
    merge(nat_gw_value, {
      route_table = (
        var.nat_gateways[index(var.nat_gateways.*.name, nat_gw_value.name)].route_table == "default" ? {
          route_table_name = "default"
          route_table_no   = ncloud_vpc.vpc.default_private_route_table_no
          } : {
          route_table_name = var.nat_gateways[index(var.nat_gateways.*.name, nat_gw_value.name)].route_table
          route_table_no   = local.route_tables[var.nat_gateways[index(var.nat_gateways.*.name, nat_gw_value.name)].route_table].id
        }
      )
    })
  }
}

resource "ncloud_route" "nat_gateway_routes" {
  for_each = local.nat_gateways

  route_table_no         = each.value.route_table.route_table_no
  destination_cidr_block = "0.0.0.0/0"
  target_type            = "NATGW"
  target_name            = each.value.name
  target_no              = each.value.id
}


