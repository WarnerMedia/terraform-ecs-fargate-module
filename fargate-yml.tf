resource "local_file" "fargate_yml" {
  filename = "${var.app}-${var.environment}/fargate.yml"
  content = yamlencode({
    cluster = local.ecs_cluster_name
    service = aws_ecs_service.app.name
  })
}
