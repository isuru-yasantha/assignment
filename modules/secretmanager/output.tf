/* Output from the Secret Manager module */

output "secretmanager-id" {
  value = "${aws_secretsmanager_secret.secretmanagerDB.id}"
}