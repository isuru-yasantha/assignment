/* Creating ECS cluster */

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.project}-${var.environment}-ecs-cluster"
}

/* Creating CW log group */

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.project}-${var.environment}-cw-logs"

}

/* ECS Task definition */

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.project}-${var.environment}-task"
  container_definitions = jsonencode([
    {
      name = "${var.project}-${var.environment}-container"
      image = "${var.imageurl}"
      command = ["serve"]
      dependsOn = [
    {
        "containerName": "${var.project}-${var.environment}-init-container",
        "condition": "COMPLETE"
    }
],
      secrets = [
       {
    "name": "VTT_DBPASSWORD",
    "valueFrom": "${var.secretmanager-id}" 
      }
      ],
      environment = [
       {
    "name": "VTT_DBUSER",
    "value": "dbadmin"
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
        "timeout": 15,
        "retries": 2
      },    
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
          containerPort = 3000,
          hostPort = 3000
        }
      ]
     
      cpu = 256
      memory = 512
      networkMode = "awsvpc"
    },
    {
      name = "${var.project}-${var.environment}-init-container"
      image = "${var.imageurl}"
      command = ["updatedb", "-s"]
      secrets = [
       {
    "name": "VTT_DBPASSWORD",
    "valueFrom": "${var.secretmanager-id}" 
      }
      ],
      environment = [
       {
    "name": "VTT_DBUSER",
    "value": "dbadmin"
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
        "timeout": 15,
        "retries": 2
      },    
      essential = false
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "${aws_cloudwatch_log_group.log-group.id}"
          awslogs-region = "${var.region}"
          awslogs-stream-prefix = "${var.project}-${var.environment}-init"
        }
      }
     
      cpu = 256
      memory = 512
      networkMode = "awsvpc"
    }
 ])


  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "1024"
  cpu                      = "512"
  execution_role_arn       = "${var.ecstaskexecution_iam_role_arn}"
  task_role_arn            = "${var.ecstaskexecution_iam_role_arn}"

}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

/* AWS ECS Service */

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.project}-${var.environment}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = aws_ecs_task_definition.aws-ecs-task.arn
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  force_new_deployment = true
  network_configuration {
    subnets          = var.private_subnets_id
    assign_public_ip = false
    security_groups = ["${var.service_sg_id}"]
  }

  /* Attaching to the TG */

  load_balancer {
    target_group_arn = "${var.target_group_arn}"
    container_name   = "${var.project}-${var.environment}-container"
    container_port   = 3000
  }
}

/* Scaling policies */

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 3
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