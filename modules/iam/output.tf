/* Output value from the IAM module */

output "ecstaskexecution_iam_role_arn" {
  value = "${aws_iam_role.ecstaskexecution_iam_role.arn}"
}