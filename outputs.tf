output "vpc" {
  value = ncloud_vpc.vpc
}


output "subnets" {
  value = merge(ncloud_subnet.subnets, ncloud_subnet.public_subnets, ncloud_subnet.private_subnets, ncloud_subnet.loadbalancer_subnets)
}

// Deprecated. It has been replaced by "subnets"
output "all_subnets" {
  value = merge(ncloud_subnet.subnets, ncloud_subnet.public_subnets, ncloud_subnet.private_subnets, ncloud_subnet.loadbalancer_subnets)
}

output "public_subnets" {
  value = ncloud_subnet.public_subnets
}

output "private_subnets" {
  value = ncloud_subnet.private_subnets
}

output "loadbalancer_subnets" {
  value = ncloud_subnet.loadbalancer_subnets
}

output "network_acls" {
  value = ncloud_network_acl.network_acls
}

output "deny_allow_groups" {
  value = ncloud_network_acl_deny_allow_group.deny_allow_groups
}

output "access_control_groups" {
  value = ncloud_access_control_group.acgs
}

output "all_route_tables" {
  value = merge(ncloud_route_table.public_route_tables, ncloud_route_table.private_route_tables)
}

output "public_route_tables" {
  value = ncloud_route_table.public_route_tables
}

output "private_route_tables" {
  value = ncloud_route_table.private_route_tables
}

output "nat_gateways" {
  value = ncloud_nat_gateway.nat_gateways
}

