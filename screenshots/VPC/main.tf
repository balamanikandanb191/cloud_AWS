provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "bala_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "Bala-VPC" }
}

resource "aws_internet_gateway" "bala_igw" {
  vpc_id = aws_vpc.bala_vpc.id
  tags   = { Name = "Bala-IGW" }
}

resource "aws_subnet" "bala_public1" {
  vpc_id                  = aws_vpc.bala_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "Bala-Public-Subnet-1" }
}

resource "aws_subnet" "bala_public2" {
  vpc_id                  = aws_vpc.bala_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "Bala-Public-Subnet-2" }
}

resource "aws_subnet" "bala_private1" {
  vpc_id            = aws_vpc.bala_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
  tags              = { Name = "Bala-Private-Subnet-1" }
}

resource "aws_subnet" "bala_private2" {
  vpc_id            = aws_vpc.bala_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
  tags              = { Name = "Bala-Private-Subnet-2" }
}

resource "aws_eip" "bala_nat_eip" {
  tags = { Name = "Bala-NAT-EIP" }
}

resource "aws_nat_gateway" "bala_nat" {
  allocation_id = aws_eip.bala_nat_eip.id
  subnet_id     = aws_subnet.bala_public1.id
  tags          = { Name = "Bala-NAT" }
}

resource "aws_route_table" "bala_public_rt" {
  vpc_id = aws_vpc.bala_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bala_igw.id
  }

  tags = { Name = "Bala-Public-RT" }
}

resource "aws_route_table" "bala_private_rt" {
  vpc_id = aws_vpc.bala_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.bala_nat.id
  }

  tags = { Name = "Bala-Private-RT" }
}

resource "aws_route_table_association" "bala_public1_assoc" {
  subnet_id      = aws_subnet.bala_public1.id
  route_table_id = aws_route_table.bala_public_rt.id
}

resource "aws_route_table_association" "bala_public2_assoc" {
  subnet_id      = aws_subnet.bala_public2.id
  route_table_id = aws_route_table.bala_public_rt.id
}

resource "aws_route_table_association" "bala_private1_assoc" {
  subnet_id      = aws_subnet.bala_private1.id
  route_table_id = aws_route_table.bala_private_rt.id
}

resource "aws_route_table_association" "bala_private2_assoc" {
  subnet_id      = aws_subnet.bala_private2.id
  route_table_id = aws_route_table.bala_private_rt.id
}
