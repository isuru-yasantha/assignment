/*==== The VPC ======*/
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-vpc"
    Environment = "${var.environment}"
  }
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.project}-igw"
    Environment = "${var.environment}"
  }
}

/* Elastic IPs for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  count = 2
  depends_on = [aws_internet_gateway.ig]
}

/* NAT GWS */
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.*.id[count.index]
  count = length(var.public_subnets_cidr)
  subnet_id     = aws_subnet.public_subnet.*.id[count.index]
  depends_on    = [aws_internet_gateway.ig]

  tags = {
    Name        = "${var.project}-natgw-${count.index}"
    Environment = "${var.environment}"
  }
}

/* Public subnets */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project}-${element(var.availability_zones, count.index)}-public-subnet"
    Environment = "${var.environment}"
  }
}

/* Private subnets */
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}"
  }
}

/* DB subnets */
resource "aws_subnet" "db_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.db_subnets_cidr)
  cidr_block              = element(var.db_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project}-${element(var.availability_zones, count.index)}-db-subnet"
    Environment = "${var.environment}"
  }
}

/* Routing table for private subnets */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  count = length(var.private_subnets_cidr)
  tags = {
    Name        = "${var.project}-private-route-table-${count.index}"
    Environment = "${var.environment}"
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.project}-public-route-table"
    Environment = "${var.environment}"
  }
}

/* Internet route for public RT */
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

/* Internet route for private RT */
resource "aws_route" "private_nat_gateway" {
  count = length(var.private_subnets_cidr)
  route_table_id         = aws_route_table.private.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.*.id[count.index]
  depends_on    = [aws_nat_gateway.nat]
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-rta" {
  count              = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  route_table_id = aws_route_table.private.*.id[count.index]
}

resource "aws_route_table_association" "private-db-rta" {
  count              = length(var.db_subnets_cidr)
  subnet_id      = aws_subnet.db_subnet.*.id[count.index]
  route_table_id = aws_route_table.private.*.id[count.index]
}

/*==== Security Groups ======*/

/* ALB SG */

resource "aws_security_group" "alb-sg" {
  name        = "${var.project}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]

 ingress { 
      from_port   = 80
      to_port     = 80
      protocol    = "tcp" 
      description = "allow http traffic from the Internet"
      cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    from_port        = "0"
    to_port          = "0"
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  
  tags = {
    Environment = "${var.environment}"
  }
}

/* RDS SG */

resource "aws_security_group" "rds-sg" {
  name        = "${var.project}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc,aws_security_group.service-sg]

  ingress {
     
      from_port   = 5432
      to_port     = 5432 
      protocol    = "tcp"
      description = "allow db connections from ecs sg"
      security_groups = ["${aws_security_group.service-sg.id}"]
    }
  egress {
    from_port        = "0"
    to_port          = "0"
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
   tags = {
    Environment = "${var.environment}"
  }
}

/* ECS Service SG */
resource "aws_security_group" "service-sg" {
  name        = "${var.project}-service-sg"
  description = "Security group for Service"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc,aws_security_group.alb-sg]

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.alb-sg.id}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   tags = {
    Environment = "${var.environment}"
  }
}

/* RDS DB subnet group */

resource "aws_db_subnet_group" "rds_db_subnetgroup" {
  name       = "rds-db-subnet-group"
  subnet_ids = aws_subnet.db_subnet.*.id
  depends_on = [aws_subnet.db_subnet]
   tags = {
    Environment = "${var.environment}"
  }
}