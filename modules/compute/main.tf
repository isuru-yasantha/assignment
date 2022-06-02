resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.project}-${var.environment}-ecs-cluster"
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.project}-${var.environment}-cw-logs"

}

data "template_file" "env_vars" {
  template = "${file("${path.module}/env_vars.json")}"
  vars = {
    rds-endpoint = "${var.rds-endpoint}"
  }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.project}-${var.environment}-task"
  container_definitions = jsonencode([
    {
      name = "${var.project}-${var.environment}-container"
      image = "${var.imageurl}"
      command = ["serve"]
      environment = [
       {
    "name": "VTT_DBUSER",
    "value": "dbadmin"
},
{
    "name": "VTT_DBPASSWORD",
    "value": "ktAL0wqj9Ek" 
},
{
    "name": "VTT_DBNAME",
    "value": "app" 
},
{
    "name": "VTT_DBPORT",
    "value": "5432" 
},
{
    "name": "VTT_DBHOST",
    "value": "${var.rds-endpoint}" 
},
{
    "name": "VTT_LISTENHOST",
    "value": "0.0.0.0" 
},
{
    "name": "VTT_LISTENPORT",
    "value": "3000" 
}
      ],
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "echo hello"
        ],
        "interval": 5,
        "timeout": 5,
        "retries": 2
      }    
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "${aws_cloudwatch_log_group.log-group.id}"
          awslogs-region = "${var.region}"
          awslogs-stream-prefix = "${var.project}-${var.environment}"
        }
      },
       portMappings = [
        {
          containerPort = 3000
          protocol = "tcp"
          hostPort = 3000
        }
      ]
     
      cpu = 256
      memory = 512
      networkMode = "awsvpc"
    },
 ])


  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = "${var.ecstaskexecution_iam_role_arn}"
  task_role_arn            = "${var.ecstaskexecution_iam_role_arn}"

}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.project}-${var.environment}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = aws_ecs_task_definition.aws-ecs-task.arn
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true
  network_configuration {
    subnets          = [element(var.private_subnets_id,0), element(var.private_subnets_id,1)]
    assign_public_ip = false
    security_groups = ["${var.service_sg_id}"]
  }

  load_balancer {
    target_group_arn = "${var.target_group_arn}"
    container_name   = "${var.project}-${var.environment}-container"
    container_port   = 3000
  }
}


resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.aws-ecs-cluster.name}/${aws_ecs_service.aws-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "${var.project}-${var.environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${var.project}-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}