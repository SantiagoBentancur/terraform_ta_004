# ALB SECURITY GROUP
# Allows public HTTP/HTTPS traffic into the load balancer.
resource "aws_security_group" "alb" {
  name        = "${var.env}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.env}-alb-sg"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }

}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# APP SECURITY GROUP
resource "aws_security_group" "app" {
  name        = "${var.env}-app-sg"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.env}-app-sg"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_app_all_traffic_ipv4" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# DB SECURITY GROUP
resource "aws_security_group" "db" {
  name        = "${var.env}-db-sg"
  description = "Security group for DBs"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.env}-db-sg"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "allow_db_all_traffic_ipv4" {
  security_group_id = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol       = "-1"
}