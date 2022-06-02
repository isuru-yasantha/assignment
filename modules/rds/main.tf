resource "aws_db_instance" "postgres_db" {
    identifier                = "${var.project}-${var.environment}-rds"
    allocated_storage         = var.db_storagesize
    backup_retention_period   = 1
    backup_window             = "01:00-01:30"
    maintenance_window        = "sun:03:00-sun:03:30"
    multi_az                  = true
    engine                    = "postgres"
    engine_version            = "10.20"
    instance_class            = var.db_instancetype
    username                  = var.db_username
    password                  = var.db_password
    db_subnet_group_name      = "${var.rds_db_subnetgroup_name}"
    vpc_security_group_ids    = ["${var.rds_sg_id}"]
    skip_final_snapshot       = true
}