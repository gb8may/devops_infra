### Network Parameters

resource "aws_vpc" "devops-vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  enable_classiclink = "false"
  tags = {
    Name = "devops-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.devops-vpc.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public"
  }
}

resource "aws_internet_gateway" "main-gw" {
  vpc_id = "${aws_vpc.devops-vpc.id}"

  tags = {
    Name = "devops-vpc"
  }
}

# route tables
resource "aws_route_table" "public-route" {
  vpc_id = "${aws_vpc.devops-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main-gw.id}"
  }

  tags = {
    Name = "public"
  }
}

# route associations public
resource "aws_route_table_association" "public-route-1-a" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public-route.id}"
}
