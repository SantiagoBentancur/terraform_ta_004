resource "aws_vpc" "main" {
  cidr_block = var.vpc_cdr

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
  cidr_block        = var.cdr_pub_subnet_1

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
  cidr_block        = var.cdr_pub_subnet_2

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
  cidr_block        = var.cdr_app_1

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
  cidr_block        = var.cdr_app_2

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
  cidr_block        = var.cdr_db_1

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
  cidr_block        = var.cdr_db_2

  tags = {
    Name        = "${var.env}-db-2"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}
