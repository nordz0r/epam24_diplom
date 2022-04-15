# Main
## Main config
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.5.0"
    }
  }
  required_version = ">= 1.1.7"
}

provider "aws" {
  region     = "${var.AWS_DEFAULT_REGION}"
  # access_key = "${var.AWS_KEY_ID}"
  # secret_key = "${var.AWS_ACCESS_KEY}"
  default_tags {
    tags = {
      Owner = "andrei_scheglov@epam.com"
      Project = "Diploma"
    }
  }
}

# VPC
## Create VPC
resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  enable_classiclink               = false
  enable_classiclink_dns_support   = false
  assign_generated_ipv6_cidr_block = false
  tags                             = merge(var.tags, { Name = "VPC" })
}

## AZ
data "aws_availability_zones" "available" { }

## Create Subnets
resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.100.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = merge(var.tags, { Name = "Public subnet in ${data.aws_availability_zones.available.names[0]}" })
}


resource "aws_subnet" "public-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.200.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = merge(var.tags, { Name = "Public subnet in ${data.aws_availability_zones.available.names[1]}" })
}


resource "aws_subnet" "private-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = merge(var.tags, {
    Name                              = "Private subnet in ${data.aws_availability_zones.available.names[0]}"
    "kubernetes.io/cluster/eks"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
    })
}


resource "aws_subnet" "private-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.20.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = merge(var.tags, {
    Name                              = "Private subnet in ${data.aws_availability_zones.available.names[0]}"
    "kubernetes.io/cluster/eks"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
    })
}


## Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.vpc.id
  tags       = merge(var.tags, { Name = "Internet Gateway" })
  depends_on = [aws_vpc.vpc]
}


## Nat for Private Networks
resource "aws_eip" "nat-1" {
}

resource "aws_eip" "nat-2" {
}

resource "aws_nat_gateway" "gw-1" {
  allocation_id = aws_eip.nat-1.id
  subnet_id     = aws_subnet.public-1.id
  tags          = merge(var.tags, { Name = "NAT-1" })
}

resource "aws_nat_gateway" "gw-2" {
  allocation_id = aws_eip.nat-2.id
  subnet_id     = aws_subnet.public-2.id
  tags          = merge(var.tags, { Name = "NAT-2" })
}


## Route to Internet Gateway
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { Name = "public-rt" })
}

## Route to NATs
resource "aws_route_table" "private-rt-1" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw-1.id
  }
  tags = merge(var.tags, { Name = "private-rt-1" })
}

resource "aws_route_table" "private-rt-2" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw-2.id
  }
  tags = merge(var.tags, { Name = "private-rt-2" })
}

## Route associations
resource "aws_route_table_association" "public-association-1" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-1.id
}

resource "aws_route_table_association" "public-association-2" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-2.id
}

resource "aws_route_table_association" "private-association-1" {
  route_table_id = aws_route_table.private-rt-1.id
  subnet_id      = aws_subnet.private-1.id
}

resource "aws_route_table_association" "private-association-2" {
  route_table_id = aws_route_table.private-rt-2.id
  subnet_id      = aws_subnet.private-2.id
}


# Modules
## RDS
module "rds" {
  source          = "./modules/rds"
  subnets_private = [aws_subnet.private-1.id, aws_subnet.private-2.id]
  vpc             = aws_vpc.vpc.id
  db_name         = var.db_name
  db_user         = var.db_user
  db_password     = var.db_password
  tags            = var.tags
}


## EKS
module "eks" {
  source          = "./modules/eks"
  subnets_all     = [aws_subnet.private-1.id, aws_subnet.private-2.id, aws_subnet.public-1.id, aws_subnet.public-2.id]
  subnets_private = [aws_subnet.private-1.id, aws_subnet.private-2.id]
  vpc             = aws_vpc.vpc.id
  tags            = var.tags

}

