variable "name" {
  description = "See the description in the readme"
  type = string
}

variable "ipv4_cidr_block" {
  description = "See the description in the readme"
  type = string
}

variable "public_subnets" {
  description = "See the description in the readme"
  type    = list(any)
  default = []
}

variable "private_subnets" {
  description = "See the description in the readme"
  type    = list(any)
  default = []
}

variable "loadbalancer_subnets" {
  description = "See the description in the readme"
  type    = list(any)
  default = []
}

variable "network_acls" {
  description = "See the description in the readme"
  type    = list(any)
  default = []
}

variable "deny_allow_groups" {
  description = "See the description in the readme"
  type    = list(any)
  default = []
}

variable "public_route_tables" {
  description = "See the description in the readme"
  type    = list(any)
  default = []
}

variable "private_route_tables" {
  description = "See the description in the readme"
  type    = list(any)
  default = []
}

variable "nat_gateways" {
  description = "See the description in the readme"
  type    = list(any)
  default = []
}
