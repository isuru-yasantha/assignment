output "secretmanager-id" {
  value = "${aws_secretsmanager_secret.secretmanagerDB.id}"
}