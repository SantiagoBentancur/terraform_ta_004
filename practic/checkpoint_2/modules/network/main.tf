# VPC and SUBNETS
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = var.az_1
  cidr_block        = var.public_subnet_1_cidr

  tags = {
    Name        = "${var.env}-public-1"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = var.az_2
  cidr_block        = var.public_subnet_2_cidr

  tags = {
    Name        = "${var.env}-public-2"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


resource "aws_subnet" "app_1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = var.az_1
  cidr_block        = var.app_subnet_1_cidr

  tags = {
    Name        = "${var.env}-app-1"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "app_2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = var.az_2
  cidr_block        = var.app_subnet_2_cidr

  tags = {
    Name        = "${var.env}-app-2"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


resource "aws_subnet" "db_1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = var.az_1
  cidr_block        = var.db_subnet_1_cidr

  tags = {
    Name        = "${var.env}-db-1"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "db_2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = var.az_2
  cidr_block        = var.db_subnet_2_cidr

  tags = {
    Name        = "${var.env}-db-2"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# INTERNET GATEWAY, ELASTIC IPS, and NAT GATEWAYS

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.env}-gw"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }

}

resource "aws_eip" "nat_eip_az_1" {
  domain = "vpc"
  tags = {
    Name        = "${var.env}-nat-eip-az-1"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_eip" "nat_eip_az_2" {
  domain = "vpc"
  tags = {
    Name        = "${var.env}-nat-eip-az-2"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_nat_gateway" "nat_az_1" {
  allocation_id = aws_eip.nat_eip_az_1.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name        = "${var.env}-nat-az-1"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }


}

resource "aws_nat_gateway" "nat_az_2" {
  allocation_id = aws_eip.nat_eip_az_2.id
  subnet_id     = aws_subnet.public_2.id

  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name        = "${var.env}-nat-az-2"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


# ROUTE TABLES
# Remember
# 1. Create the route table
# 2. Add a route inside that route table
# 3. Associate/connect the route table to the subnet

# Tier 1
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.env}-Public"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_route.id
}

# Tier 2
resource "aws_route_table" "app_az_1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.env}-app-rt-az-1"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


resource "aws_route" "app_az_1_to_nat" {
  route_table_id         = aws_route_table.app_az_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az_1.id
}

resource "aws_route_table_association" "app_az_1" {
  subnet_id      = aws_subnet.app_1.id
  route_table_id = aws_route_table.app_az_1.id
}


resource "aws_route_table" "app_az_2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.env}-app-rt-az-2"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


resource "aws_route" "app_az_2_to_nat" {
  route_table_id         = aws_route_table.app_az_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az_2.id
}

resource "aws_route_table_association" "app_az_2" {
  subnet_id      = aws_subnet.app_2.id
  route_table_id = aws_route_table.app_az_2.id
}

# Tier 3

resource "aws_route_table" "db_route" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.env}-db"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "db_1_association" {
  subnet_id      = aws_subnet.db_1.id
  route_table_id = aws_route_table.db_route.id
}


resource "aws_route_table_association" "db_2_association" {
  subnet_id      = aws_subnet.db_2.id
  route_table_id = aws_route_table.db_route.id
}
