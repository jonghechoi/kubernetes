
/*========= VPC =========*/
provider "aws" {
    region = "ap-northeast-2"
}

resource "aws_vpc" "eks_test_vpc2" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true

    tags = {
        Name = "eks_test_vpc2"
    }
}


/*========= SUBNET =========*/
resource "aws_subnet" "eks_pub_subnet" {
    vpc_id            = aws_vpc.eks_test_vpc2.id
    count             = length(var.pub_subnet_cidr)
    cidr_block        = element(var.pub_subnet_cidr, count.index)
    availability_zone = element(var.availability_zone, count.index)

    tags = {
        Name = "eks_pub_subnet_${count.index}"
    }
}

resource "aws_subnet" "eks_pri_subnet" {
    vpc_id            = aws_vpc.eks_test_vpc2.id
    count             = length(var.pri_subnet_cidr)
    cidr_block        = element(var.pri_subnet_cidr, count.index)
    availability_zone = element(var.availability_zone, count.index)

    tags = {
        Name = "eks_pri_subnet_${count.index}"
    }
}


/*========= INTERNET GATEWAY =========*/
resource "aws_internet_gateway" "eks_test_igw2" {
    vpc_id = aws_vpc.eks_test_vpc2.id

    tags = {
      Name = "eks_test_igw2"
    }
}


/*========= NAT GATEWAY =========*/
resource "aws_eip" "nat_eip" {
    count = length(var.availability_zone)
    vpc   = true
    lifecycle {
        create_before_destroy = true
    }

    tags = {
        Name = "eks_test_eip_${element(var.availability_zone, count.index)}"
    }
}

resource "aws_nat_gateway" "eks_test_ngw" {
    count         = length(aws_eip.nat_eip.*.id)
    allocation_id = element(aws_eip.nat_eip.*.id, count.index)
    subnet_id     = element(aws_subnet.eks_pub_subnet.*.id, count.index)

    tags = {
      Name = "eks_test_ngw_${element(var.availability_zone, count.index)}"
    }
}


/*========= ROUTE TABLE =========*/
# rt for public subnet
resource "aws_route_table" "eks_test_pub_route2" {
    count  = length(var.availability_zone)
    vpc_id = aws_vpc.eks_test_vpc2.id    
}

resource "aws_route_table_association" "route_table_association_1" {
    count          = length(var.availability_zone)
    subnet_id      = element(aws_subnet.eks_pub_subnet.*.id, count.index)
    route_table_id = element(aws_route_table.eks_test_pub_route2.*.id, count.index)
}

resource "aws_route" "public_igw2" {
    count                  = length(var.availability_zone)
    route_table_id         = element(aws_route_table.eks_test_pub_route2.*.id, count.index)
    gateway_id             = aws_internet_gateway.eks_test_igw2.id
    destination_cidr_block = "0.0.0.0/0"
}


# rt for private subnet
resource "aws_route_table" "eks_test_pri_route2" {
    count  = length(var.availability_zone)
    vpc_id = aws_vpc.eks_test_vpc2.id

    tags = {
        Name = "eks_test_pri_${element(var.availability_zone, count.index)}_route2"
    }
}

resource "aws_route_table_association" "route_table_association_2" {
    count          = length(var.availability_zone)
    subnet_id      = element(aws_subnet.eks_pri_subnet.*.id, count.index)
    route_table_id = element(aws_route_table.eks_test_pri_route2.*.id, count.index)
}

resource "aws_route" "private_ngw2" {
    count          = length(var.availability_zone)
    route_table_id = element(aws_route_table.eks_test_pri_route2.*.id, count.index)
    gateway_id     = element(aws_nat_gateway.eks_test_ngw.*.id, count.index)
    destination_cidr_block = "0.0.0.0/0"
}


/*========= SECURITY GROUP =========*/
resource "aws_security_group" "eks_test_sg_1" {
    name_prefix = "worker_group_mgmt_one"
    vpc_id = aws_vpc.eks_test_vpc2.id

    ingress  {
      description = "value"
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      
      cidr_blocks = [ "0.0.0.0/8" ]
    }

    tags = {
      Name = "sg_4_worker_group_mgmt"
    }

}


/*========= EKS =========*/
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.17"
  subnets         = aws_subnet.eks_pri_subnet.*.id
  version = "12.2.0"
  cluster_create_timeout = "1h"
  cluster_endpoint_private_access = true 

  vpc_id = aws_vpc.eks_test_vpc2.id

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.eks_test_sg_1.id]
    },
  ]

#   worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
#   map_roles                            = var.map_roles
#   map_users                            = var.map_users
#   map_accounts                         = var.map_accounts
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}











