
/*========= VPC =========*/
resource "aws_vpc" "eks_test_vpc2" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true

    tags = {
        Name = "eks_test_vpc2"
    }
}


/*========= SUBNET =========*/
resource "aws_subnet" "eks_pub_subnet" {
    vpc_id            = "${aws_vpc.eks_test_vpc2.id}"
    count             = "${length(var.pub_subnet_cidr)}"
    cidr_block        = "${element(var.pub_subnet_cidr, count.index)}"
    availability_zone = "${element(var.availability_zone, count.index)}"

    tags = {
        Name = "eks_pub_subnet_${count.index}"
    }
}

resource "aws_subnet" "eks_pri_subnet" {
    vpc_id            = "${aws_vpc.eks_test_vpc2.id}"
    count             = "${length(var.pri_subnet_cidr)}"
    cidr_block        = "${element(var.pri_subnet_cidr, count.index)}"
    availability_zone = "${element(var.availability_zone, count.index)}"

    tags = {
        Name = "eks_pri_subnet_${count.index}"
    }
}


/*========= INTERNET GATEWAY =========*/
resource "aws_internet_gateway" "eks_test_igw2" {
    vpc_id = "${aws_vpc.eks_test_vpc2.id}"

    tags = {
      Name = "eks_test_igw2"
    }
}


/*========= NAT GATEWAY =========*/
resource "aws_eip" "nat_eip" {
    count = "${length(var.availability_zone)}"
    vpc   = true
    lifecycle {
        create_before_destroy = true
    }

    tags = {
        Name = "eks_test_eip_${element(var.availability_zone, count.index)}"
    }
}

resource "aws_nat_gateway" "eks_test_ngw" {
    count         = "${length(aws_eip.nat_eip.*.id)}"
    allocation_id = "${element(aws_eip.nat_eip.*.id, count.index)}"
    subnet_id     = "${element(aws_subnet.eks_pub_subnet.*.id, count.index)}"

    tags = {
      Name = "eks_test_ngw_${element(var.availablility_zone, count.index)}"
    }
}


/*========= ROUTE TABLE =========*/
# rt for public subnet
resource "aws_route_table" "eks_test_pub_route2" {
    count  = "${length(var.availability_zone)}"
    vpc_id = "${aws_vpc.eks_test_vpc2.id}"    
}

resource "aws_route_table_association" "route_table_association_1" {
    count          = "${length(var.availability_zone)}"
    subnet_id      = "eks_pub_subnet_${count.index}"
    route_table_id = "${element(aws_route_table.eks_test_pub_route2.*.id, count.index)}"
}

resource "aws_route" "public_igw2" {
    count                  = "${length(var.availability_zone)}"
    route_table_id         = "${element(aws_route_table.eks_test_pub_route2.*.id, count.index)}"
    gateway_id             = "${aws_internet_gateway.eks_test_igw2.id}"
    destination_cidr_block = "0.0.0.0/0"
}


# rt for private subnet
resource "aws_route_table" "eks_test_pri_route2" {
    count  = "${length(var.availability_zone)}"
    vpc_id = "${aws_vpc.eks_test_vpc2.id}"

    tags = {
        Name = "eks_test_pri_${element(var.availability_zone, count.index)}_route2"
    }
}

resource "aws_route_table_association" "route_table_association_2" {
    count          = "${length(var.availability_zone)}"
    subnet_id      = "${element(aws_subnet.eks_pri_subnet.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.eks_test_pri_route2.*.id, count.index)}"
}

resource "aws_route" "private_ngw2" {
    count          = "${length(var.availability_zone)}"
    route_table_id = "${element(aws_route_table.eks_test_pri_route2.*.id, count.index)}"
    gateway_id     = "${element(aws_nat_gateway.eks_test_ngw.*.id, count.index)}"
    destination_cidr_block = "0.0.0.0/0"
}
















