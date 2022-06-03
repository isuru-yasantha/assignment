resource "aws_secretsmanager_secret" "secretmanagerDB" {
  name = "${var.project}-${var.environment}-kbsecretmanager"
}

resource "aws_secretsmanager_secret_version" "secretversion" {
  secret_id = aws_secretsmanager_secret.secretmanagerDB.id
  secret_string = "${var.db_password}"
}
 