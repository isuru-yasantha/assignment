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

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip1" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

resource "aws_eip" "nat_eip2" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

/* NAT */
resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]

  tags = {
    Name        = "${var.project}-nat1"
    Environment = "${var.environment}"
  }
}

  resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 1)
  depends_on    = [aws_internet_gateway.ig]
    tags = {
    Name        = "${var.project}-nat2"
    Environment = "${var.environment}"
  }
}

/* Public subnet */
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

/* Private subnet */
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

/* DB subnet */
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

/* Routing table for private subnet-1 */
resource "aws_route_table" "private-1" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.project}-private-1-route-table"
    Environment = "${var.environment}"
  }
}

/* Routing table for private subnet-2 */
resource "aws_route_table" "private-2" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.project}-private-2-route-table"
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

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route" "private_nat_gateway-1" {
  route_table_id         = aws_route_table.private-1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat1.id
}

resource "aws_route" "private_nat_gateway-2" {
  route_table_id         = aws_route_table.private-2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat2.id
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-1" {
  subnet_id      = element(aws_subnet.private_subnet.*.id, 0)
  route_table_id = aws_route_table.private-1.id
}

resource "aws_route_table_association" "private-2" {
  subnet_id      = element(aws_subnet.private_subnet.*.id, 1)
  route_table_id = aws_route_table.private-2.id
}

resource "aws_route_table_association" "private-db-1" {
  subnet_id      = element(aws_subnet.db_subnet.*.id, 0)
  route_table_id = aws_route_table.private-1.id
}

resource "aws_route_table_association" "private-db-2" {
  subnet_id      = element(aws_subnet.db_subnet.*.id, 1)
  route_table_id = aws_route_table.private-2.id
}

/*==== Security Groups ======*/

resource "aws_security_group" "ecs-sg" {
  name        = "${var.project}-ecs-sg"
  description = "Security group for ecs cluster"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc,aws_security_group.alb-sg]

  ingress {
      from_port   = 3000
      to_port     = 3000
      protocol    = "TCP"
      description = "allow http traffic from the ALB"
      security_groups = ["${aws_security_group.alb-sg.id}"]
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


resource "aws_security_group" "rds-sg" {
  name        = "${var.project}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc,aws_security_group.ecs-sg]

  ingress {
     
      from_port   = 5432
      to_port     = 5432 
      protocol    = "tcp"
      description = "allow db connections from ecs sg"
      security_groups = ["${aws_security_group.ecs-sg.id}"]
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

resource "aws_db_subnet_group" "rds_db_subnetgroup" {
  name       = "rds-db-subnet-group"
  subnet_ids = [aws_subnet.db_subnet.0.id,aws_subnet.db_subnet.1.id]
  depends_on = [aws_subnet.db_subnet]
   tags = {
    Environment = "${var.environment}"
  }
}