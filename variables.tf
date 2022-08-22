variable "name" {
  type = string
}

variable "ipv4_cidr_block" {
  type = string
}

variable "public_subnets" {
  type    = list(any)
  default = []
}

variable "private_subnets" {
  type    = list(any)
  default = []
}

variable "loadbalancer_subnets" {
  type    = list(any)
  default = []
}

variable "network_acls" {
  type    = list(any)
  default = []
}

variable "deny_allow_groups" {
  type    = list(any)
  default = []
}

variable "public_route_tables" {
  type    = list(any)
  default = []
}

variable "private_route_tables" {
  type    = list(any)
  default = []
}

variable "nat_gateways" {
  type    = list(any)
  default = []
}
