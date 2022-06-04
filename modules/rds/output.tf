/* Output from the RDS module */
output "rds-endpoint" {
  value = "${aws_db_instance.postgres_db.address}"
}