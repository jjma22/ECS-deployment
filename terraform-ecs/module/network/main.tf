resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "notes-network"
  }

}

resource "aws_subnet" "public_subnet" {
  count                   = length(var.public-subnet-ips)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public-subnet-ips[count.index]
  availability_zone       = "eu-west-2${var.availability-zone[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id

}

resource "aws_subnet" "private_subnet" {
  count             = length(var.private-subnet-ips)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private-subnet-ips[count.index]
  availability_zone = "eu-west-2${var.availability-zone[count.index]}"
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "a" {
  count          = length(var.private-subnet-ips)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "notes-igw"
  }
}

resource "aws_default_route_table" "public-route" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}
