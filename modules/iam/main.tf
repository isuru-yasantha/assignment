data "aws_iam_policy_document" "ecs_iam_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecstaskexecution_iam_role" {
  name               = "ecstaskexecutionIamRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_iam_policy.json

  tags = {
      project = "${var.project}"
      environment = "${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_iam_role_attachment" {
  role       = "${aws_iam_role.ecstaskexecution_iam_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  depends_on = [aws_iam_role.ecstaskexecution_iam_role]
}

resource "aws_iam_instance_profile" "ecstaskexecution_iam_role" {
  #name = "ecstaskexecutionIamRole"
  role = "${aws_iam_role.ecstaskexecution_iam_role.name}"
  depends_on = [aws_iam_role.ecstaskexecution_iam_role]
}