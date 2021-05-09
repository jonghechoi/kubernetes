provider "aws" {
    region = "ap-northeast-2"
}

/*========= VPC =========*/
resource "aws_vpc" "eks-test-vpc2" {
    cidr_block = "192.168.0.0/16"
    enable_dns_hostnames = true

    tags = {
        Name = "eks-test-vpc2"
    }
}


/*========= SUBNET =========*/
resource "aws_subnet" "eks-test-pri-api-a2" {
    vpc_id = aws_vpc.eks-test-vpc2.id
    cidr_block = "192.168.10.0/24"
    availability_zone = "ap-northeast-2a"

    tags = {
        Name = "eks-test-pri-api-a2"
    }
}

resource "aws_subnet" "eks-test-pri-api-c2" {
    vpc_id = aws_vpc.eks-test-vpc2.id
    cidr_block = "192.168.11.0/24"
    availability_zone = "ap-northeast-2c"

    tags = {
        Name = "eks-test-pri-api-c2"
    }
}

resource "aws_subnet" "eks-test-pub-a2" {
    vpc_id = aws_vpc.eks-test-vpc2.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "ap-northeast-2a"

    tags = {
        Name = "eks-test-pub-a2"
    }
}

resource "aws_subnet" "eks-test-pub-c2" {
    vpc_id = aws_vpc.eks-test-vpc2.id
    cidr_block = "192.168.2.0/24"
    availability_zone = "ap-northeast-2c"

    tags = {
        Name = "eks-test-pub-c2"
    }
}


/*========= INTERNET GATEWAY =========*/
resource "aws_internet_gateway" "eks-test-igw2" {
    vpc_id = aws_vpc.eks-test-vpc2.id

    tags = {
      Name = "eks-test-igw2"
    }
}


/*========= NAT GATEWAY =========*/
resource "aws_eip" "nat-eip-a2" {
    vpc = true
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_eip" "nat-eip-c2" {
    vpc = true
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_nat_gateway" "eks-test-ngw-a2" {
    allocation_id = aws_eip.nat-eip-a2.id
    subnet_id = aws_subnet.eks-test-pub-a2.id

    tags = {
      Name = "eks-test-ngw-a2"
    }
}

resource "aws_nat_gateway" "eks-test-ngw-c2" {
    allocation_id = aws_eip.nat-eip-c2.id
    subnet_id = aws_subnet.eks-test-pub-c2.id

    tags = {
        Name = "eks-test-ngw-c2"
    }
}


/*========= ROUTE TABLE =========*/
# pub-a
resource "aws_route_table" "eks-test-pub-a-route2" {
    vpc_id = aws_vpc.eks-test-vpc2.id

    tags = {
        Name = "eks-test-pub-a-route2"
    }
}

resource "aws_route_table_association" "route_table_association_3" {
    subnet_id = aws_subnet.eks-test-pub-a2.id
    route_table_id = aws_route_table.eks-test-pub-a-route2.id
}

resource "aws_route" "public-a-igw2" {
    route_table_id = aws_route_table.eks-test-pub-a-route2.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-test-igw2.id 
}

# pri-a
resource "aws_route_table" "eks-test-pri-a-route2" {
    vpc_id = aws_vpc.eks-test-vpc2.id
    
    tags = {
        Name = "eks-test-pri-a-route2"
    }
}

resource "aws_route_table_association" "route_table_association_4" {
    subnet_id = aws_subnet.eks-test-pri-api-a2.id
    route_table_id = aws_route_table.eks-test-pri-a-route2.id
}

resource "aws_route" "private-a-nat2" {
    route_table_id = aws_route_table.eks-test-pri-a-route2.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks-test-ngw-a2.id
}

# pub-c
resource "aws_route_table" "eks-test-pub-c-route2" {
    vpc_id = aws_vpc.eks-test-vpc2.id

    tags = {
        Name = "eks-test-pub-c-route2"
    }
}

resource "aws_route_table_association" "route_table_association_1" {
    subnet_id = aws_subnet.eks-test-pub-c2.id
    route_table_id = aws_route_table.eks-test-pub-c-route2.id
}

resource "aws_route" "public-c-igw2" {
    route_table_id = aws_route_table.eks-test-pub-a-route2.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-test-igw2.id 
}

# pri-c
resource "aws_route_table" "eks-test-pri-c-route2" {
    vpc_id = aws_vpc.eks-test-vpc2.id
    
    tags = {
        Name = "eks-test-pri-c-route2"
    }
}

resource "aws_route_table_association" "route_table_association_2" {
    subnet_id = aws_subnet.eks-test-pri-api-c2.id
    route_table_id = aws_route_table.eks-test-pri-c-route2.id
}

resource "aws_route" "private-c-nat2" {
    route_table_id = aws_route_table.eks-test-pri-c-route2.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks-test-ngw-c2.id
}