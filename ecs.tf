/**
 * Elastic Container Service (ecs)
 * This component is required to create the Fargate ECS service. It will create a Fargate cluster
 * based on the application name and environment. It will create a "Task Definition", which is required
 * to run a Docker container, https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html.
 * Next it creates a ECS Service, https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html
 * It attaches the Load Balancer created in `lb.tf` to the service, and sets up the networking required.
 * It also creates a role with the correct permissions. And lastly, ensures that logs are captured in CloudWatch.
 *
 * When building for the first time, it will install a "default backend", which is a simple web service that just
 * responds with a HTTP 200 OK. It's important to uncomment the lines noted below after you have successfully
 * migrated the real application containers to the task definition.
 */

locals {
  ecs_cluster_arn  = var.ecs_cluster_name != "" ? data.aws_ecs_cluster.app[0].arn : aws_ecs_cluster.app[0].arn
  ecs_cluster_id   = var.ecs_cluster_name != "" ? data.aws_ecs_cluster.app[0].id : aws_ecs_cluster.app[0].id
  ecs_cluster_name = var.ecs_cluster_name != "" ? data.aws_ecs_cluster.app[0].cluster_name : aws_ecs_cluster.app[0].name
}

data "aws_ecs_cluster" "app" {
  count = var.ecs_cluster_name != "" ? 1 : 0

  cluster_name = var.ecs_cluster_name
}

resource "aws_ecs_cluster" "app" {
  count = var.ecs_cluster_name == "" ? 1 : 0

  name = "${var.app}-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}

resource "aws_appautoscaling_target" "app_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${local.ecs_cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu_units
  memory                   = var.memory_size
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  # defined in role.tf
  task_role_arn = aws_iam_role.app_role.arn

  container_definitions = var.container_definitions != "" ? var.container_definitions : module.task_definition.json_map_encoded_list

  runtime_platform {
    operating_system_family = var.operating_system_family
    cpu_architecture        = var.cpu_architecture
  }

  tags = var.tags

  // great explanation of how this works:
  // https://stackoverflow.com/questions/68272156/terraform-ecs-task-definition-dynamic-nested-efs-volumes

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.volume_name

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration

        content {
          file_system_id = efs_volume_configuration.value.efs_file_system_id
          root_directory = efs_volume_configuration.value.root_directory
        }
      }
    }
  }
}


module "task_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "v0.58.1"

  container_name  = var.container_name
  container_image = var.container_image
  essential       = true

  port_mappings = [
    {
      protocol      = "tcp"
      containerPort = var.container_port
      hostPort      = var.container_port
    }
  ]

  environment = [
    {
      name  = "PORT"
      value = var.container_port
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "/fargate/service/${var.app}-${var.environment}",
      awslogs-region        = data.aws_region.current.name
      awslogs-stream-prefix = "ecs"
    }
  }

}

resource "aws_ecs_service" "app" {
  name            = "${var.app}-${var.environment}"
  cluster         = local.ecs_cluster_id
  #launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.replicas

  platform_version = var.platform_version

  network_configuration {
    security_groups = [aws_security_group.nsg_task.id]
    subnets         = var.fargate_subnets
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  tags                    = var.tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  depends_on = [aws_alb_listener.http]

  capacity_provider_strategy  {
    capacity_provider = "FARGATE"
    weight = local.fargate_percentage
    base = var.fixed_non_spot_count
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight = var.spot_percentage
  }

  deployment_maximum_percent = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
}

locals {
  fargate_percentage = 100 - var.spot_percentage
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.app}-${var.environment}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

variable "logs_retention_in_days" {
  type        = number
  default     = 90
  description = "Specifies the number of days you want to retain log events"
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/${var.app}-${var.environment}"
  retention_in_days = var.logs_retention_in_days
  tags              = var.tags
}



# The name of the ecs cluster that was created or referenced 
output "ecs_cluster_name" {
  value = local.ecs_cluster_name
}

# The arn of the ecs cluster that was created or referenced 
output "ecs_cluster_arn" {
  value = local.ecs_cluster_arn
}

# The arn of the fargate ecs service that was created
output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

# The arn of the role used by ecs when starting the task
output "ecs_execution_role_arn" {
  value=aws_iam_role.ecsTaskExecutionRole.arn
}

# The name of the role used by ecs when starting the task
output "ecs_execution_role_name" {
  value=aws_iam_role.ecsTaskExecutionRole.name
}