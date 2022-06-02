output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnets_id" {
  value = aws_subnet.public_subnet.*.id
}

output "private_subnets_id" {
  value = aws_subnet.private_subnet.*.id
}

output "db_subnets_id" {
  value = aws_subnet.db_subnet.*.id
}

output "rds_sg_id" {
  value = "${aws_security_group.rds-sg.id}"
}

output "alb_sg_id" {
  value = "${aws_security_group.alb-sg.id}"
}

output "ecs_sg_id" {
  value = "${aws_security_group.ecs-sg.id}"
}

output "service_sg_id" {
  value = "${aws_security_group.service-sg.id}"
}

output "rds_db_subnetgroup_name" {
  value = "${aws_db_subnet_group.rds_db_subnetgroup.name}"
}