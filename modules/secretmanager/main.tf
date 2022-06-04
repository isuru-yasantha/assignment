/* Creating AWS Secret Manager secrets for store DB password  */

resource "aws_secretsmanager_secret" "secretmanagerDB" {
  name = "${var.project}-${var.environment}-secretmanagerApp"
}

resource "aws_secretsmanager_secret_version" "secretversion" {
  secret_id = aws_secretsmanager_secret.secretmanagerDB.id
  secret_string = "${var.db_password}"
}
 