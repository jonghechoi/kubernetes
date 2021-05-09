
variable "vpc_cidr" {
    type = string
}

variable "pub_subnet_cidr" {
    type = list(string)
}

variable "pri_subnet_cidr" {
    type = list(string)
}

variable "availability_zone" {
    type = list(string)
}
