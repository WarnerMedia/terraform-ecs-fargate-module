# The application's name
variable "app" {
  type = string
}

# The name of the elastic container registry in this account 
#  that the CICD user will be given write permission
variable "default_ecr" {
  type = string
  default = ""
}

# The name of the container to run
variable "container_name" {
  default = "app"
}

# The environment that is being built
variable "environment" {
  type = string
}

# Name of an existing ECS cluster, if left blank it will create one with the app and environment values
variable "ecs_cluster_name" {
  type = string
  default = ""
}

# Should the module create an iam user with permissions tuned for cicd (cicf.tf)
variable "create_cicd_user" {
  type    = bool
  default = false
}

# Tags for the infrastructure
variable "tags" {
  type = map(string)
}

# The port the container will listen on, used for load balancer health check
# Best practice is that this value is higher than 1024 so the container processes
# isn't running at root.
variable "container_port" {
  type = string
}

# The VPC to use for the Fargate cluster
variable "vpc" {
}

# These are the subnet ids that the load balancer will use
variable "load_balancer_subnets" {
  type = list
}

# These are the subnet ids that the containers will use
variable "fargate_subnets" {
  type = list
}

# The port the standard http load balancer will listen on
variable "lb_port" {
  default = "80"
}

# The load balancer protocol
variable "lb_protocol" {
  default = "HTTP"
}

# Should the service do http to https redirects, or just standard http hosting? This is done via alb rules 
#  https://aws.amazon.com/premiumsupport/knowledge-center/elb-redirect-http-to-https-using-alb/
variable do_https_redirect {
  type    = bool
  default = false
}

# Whether the load balancer is available on the public internet. The containers will always get subnet ips.
variable "create_public_ip" {
  type    = bool
  default = false
}

# The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
variable "deregistration_delay" {
  default = "30"
}

# The path to the health check for the load balancer to know if the container(s) are ready
variable "health_check" {
  default = "/"
}

# How often to check the liveliness of the container
variable "health_check_interval" {
  default = "30"
}

# How long to wait for the response on the health check path
variable "health_check_timeout" {
  default = "10"
}

# What HTTP response code to listen for
variable "health_check_matcher" {
  default = "200"
}

# How many days worth of load balancer logs to keep in s3
variable "lb_access_logs_expiration_days" {
  default = "3"
}

# Create a cloudwatch dashboard containing popular performance metrics about fargate
variable "create_performance_dashboard" {
  type    = bool
  default = true
}

# Log the ECS events happening in fargate and create a cloudwatch dashboard that shows these messages
variable "create_ecs_dashboard" {
  type    = bool
  default = false
}

# The lambda runtime for the ecs dashboard, provided here so that it is easy to update to the latest supported
variable "ecs_lambda_runtime" {
  type    = string
  default = "nodejs14.x"
}

# The port to listen on for HTTPS (if it is enabled), always use 443
variable "https_port" {
  default = "443"
}

# The ARN for the SSL certificate, if this is not blank it will use it instead of requesting a dns validated ACM certificate
variable "certificate_arn" {
  default = ""
}

# The domain for r53 registration, leave blank to indicate not using route53 
variable "domain" {
  default = ""
}

# This is the policy that controls the specifics about TLS/SSL versions and supported ciphers. This default will only support TLS 1.2
#  https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
variable "ssl_policy" {
  type=string
  default="ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

#indicates if a secrets manager 
variable "secrets_manager" {
  type    = bool
  default = false
}

# Number of days that secrets manager will wait before fully deleting a secret, set to 0 to delete immediately
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret#recovery_window_in_days
variable "secrets_manager_recovery_window_in_days" {
  type    = number
  default = 7
}

# A list of users that will have full access to the secrets manager and its kms key, the current user applying the terraform 
#  will have access as well.
variable "secrets_users" {
  type = list
  default = []
}

# How many containers to run
variable "replicas" {
  type    = number
  default = 1
}

# The default docker image to deploy with the infrastructure.
# Note that you can use the fargate CLI for application concerns
# like deploying actual application images and environment variables
# on top of the infrastructure provisioned by this template
# https://github.com/turnerlabs/fargate
# note that the source for the turner default backend image is here:
# https://github.com/turnerlabs/turner-defaultbackend
variable "container_image" {
  default = "ghcr.io/warnermedia/fargate-default-backend:v0.9.0"
}

# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
variable "cpu_units" {
  type    = number
  default = 256
}

# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
variable "memory_size" {
  type    = number
  default = 512
}

# This is the json formatted container definition for the task. By default, a definition with the indicated
#  container image and cloudwatch logging will be provided. Setting this will override the defaults allowing 
#  configuration like environment variables to be set. We recommend using this module to help build the json 
#  rather than doing it in a large string: https://registry.terraform.io/modules/cloudposse/ecs-container-definition/aws/latest
variable "container_definitions" {
  type = string
  default = ""
}


# Should the fargate service scale up and down with cpu usage
variable "do_performance_autoscaling" {
  type = bool
  default = false
}

# If the average CPU utilization over a minute drops to this threshold,
# the number of containers will be reduced (but not below ecs_autoscale_min_instances).
variable "scaling_cpu_low_threshold" {
  default = "20"
}

# If the average CPU utilization over a minute rises to this threshold,
# the number of containers will be increased (but not above ecs_autoscale_max_instances).
variable "scaling_cpu_high_threshold" {
  default = "80"
}

# The minimum number of containers that should be running.
# Must be at least 1.
# For production, consider using at least "2".
variable "ecs_autoscale_min_instances" {
  type = number
  default = 1
}

# The maximum number of containers that should be running when scaling up
variable "ecs_autoscale_max_instances" {
  type = number
  default = 4
}

# The OS Family of the task, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform 
variable "operating_system_family" {
  type = string
  default = "LINUX"
}

# The CPU Architecture, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform
variable "cpu_architecture" {
  type = string
  default = "X86_64"
}

# The fargate platform version. These version numbers are different between linux and windows, make sure to use the correct
#  value or leave it at LATEST: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html
variable "platform_version" {
  type = string
  default = "LATEST"
}
