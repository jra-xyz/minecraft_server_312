resource "aws_ecs_cluster" "minecraft" {
  name = "minecraft-cluster"
}

resource "aws_cloudwatch_log_group" "minecraft" {
  name              = "/ecs/minecraft"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "minecraft" {
  family                   = "minecraft"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096

  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "minecraft"
      image     = "itzg/minecraft-server:java25"
      essential = true

      environment = [
        { name = "EULA",    value = "TRUE" },
        { name = "VERSION", value = var.minecraft_version },
        { name = "MEMORY",  value = "3G" },
        { name = "TYPE",    value = "VANILLA" }
      ]

      portMappings = [
        {
          containerPort = 25565
          hostPort      = 25565
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "minecraft-data"
          containerPath = "/data"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.minecraft.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "minecraft"
        }
      }
    }
  ])

  volume {
    name = "minecraft-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.minecraft.id
      transit_encryption = "ENABLED"
    }
  }
}

resource "aws_ecs_service" "minecraft" {
  name            = "minecraft"
  cluster         = aws_ecs_cluster.minecraft.id
  task_definition = aws_ecs_task_definition.minecraft.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.minecraft.id]
    assign_public_ip = true
  }

  depends_on = [time_sleep.efs_ready]
}
