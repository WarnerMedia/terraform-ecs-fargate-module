<!-- BEGIN_TF_DOCS -->
# Terraform ECS Fargate

A module used for provisioning web or api application stacks on [AWS ECS Fargate][fargate]. The majority of the module has been adapted from [this template][fargate-template].

![diagram](diagram.png)

## Example
This will spin up a new ECS cluster and fargate service running a simple default container image.

```
module "fargate" {
  source = "git@github.com:warnermedia/terraform-ecs-fargate-module/?ref=v4.2.0"

  app                   = "mywebsite"
  environment           = "main"
  tags                  = var.tags
  container_port        = 8000
  vpc                   = "vpc-a1b2c3der"
  create_public_ip      = true
  load_balancer_subnets = ["subnet-0ba9...","subnet-abcde"]
  fargate_subnets       = ["subnet-9ba0...","subnet-edcba"]

  health_check = "/"
}
```

## Usage and link to base

It is recommended that you store your terraform state in a safe location. If the `create_cicd_user` variable is enabled, the state file will contain your aws key id and secret. The easiest method would be to use [S3 state][s3-state].

If you would like a ready to use template for this module, it's state bucket as well as CICD templates. Check out [fargate-create][fargate-create]

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app"></a> [app](#input\_app) | The application's name | `string` | n/a | yes |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port the container will listen on, used for load balancer health check Best practice is that this value is higher than 1024 so the container processes isn't running at root. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment that is being built | `string` | n/a | yes |
| <a name="input_fargate_subnets"></a> [fargate\_subnets](#input\_fargate\_subnets) | These are the subnet ids that the containers will use | `list(any)` | n/a | yes |
| <a name="input_load_balancer_subnets"></a> [load\_balancer\_subnets](#input\_load\_balancer\_subnets) | These are the subnet ids that the load balancer will use | `list(any)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the infrastructure | `map(string)` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | The VPC to use for the Fargate cluster | `any` | n/a | yes |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | The ARN for the SSL certificate, if this is not blank it will use it instead of requesting a dns validated ACM certificate | `string` | `""` | no |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | This is the json formatted container definition for the task. By default, a definition with the indicated container image and cloudwatch logging will be provided. Setting this will override the defaults allowing configuration like environment variables to be set. We recommend using this module to help build the json rather than doing it in a large string: https://registry.terraform.io/modules/cloudposse/ecs-container-definition/aws/latest | `string` | `""` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The default docker image to deploy with the infrastructure. Note that you can use the fargate CLI for application concerns like deploying actual application images and environment variables on top of the infrastructure provisioned by this template https://github.com/turnerlabs/fargate note that the source for the turner default backend image is here: https://github.com/turnerlabs/turner-defaultbackend | `string` | `"ghcr.io/warnermedia/fargate-default-backend:v0.9.0"` | no |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | The name of the container to run | `string` | `"app"` | no |
| <a name="input_cpu_architecture"></a> [cpu\_architecture](#input\_cpu\_architecture) | The CPU Architecture X86\_64 or ARM64 for Graviton, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform | `string` | `"X86_64"` | no |
| <a name="input_cpu_units"></a> [cpu\_units](#input\_cpu\_units) | See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size | `number` | `256` | no |
| <a name="input_create_cicd_user"></a> [create\_cicd\_user](#input\_create\_cicd\_user) | Should the module create an iam user with permissions tuned for cicd (cicf.tf) | `bool` | `false` | no |
| <a name="input_create_ecs_dashboard"></a> [create\_ecs\_dashboard](#input\_create\_ecs\_dashboard) | Log the ECS events happening in fargate and create a cloudwatch dashboard that shows these messages | `bool` | `false` | no |
| <a name="input_create_performance_dashboard"></a> [create\_performance\_dashboard](#input\_create\_performance\_dashboard) | Create a cloudwatch dashboard containing popular performance metrics about fargate | `bool` | `true` | no |
| <a name="input_create_public_ip"></a> [create\_public\_ip](#input\_create\_public\_ip) | Whether the load balancer is available on the public internet. The containers will always get subnet ips. | `bool` | `false` | no |
| <a name="input_custom_default_alb_cidr_blocks"></a> [custom\_default\_alb\_cidr\_blocks](#input\_custom\_default\_alb\_cidr\_blocks) | This is the default list of cidr blocks that will be allowed to access the ALB on http and/or https | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_default_ecr"></a> [default\_ecr](#input\_default\_ecr) | The name of the elastic container registry in this account that the CICD user will be given write permission | `string` | `""` | no |
| <a name="input_deregistration_delay"></a> [deregistration\_delay](#input\_deregistration\_delay) | The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused | `string` | `"30"` | no |
| <a name="input_do_https_redirect"></a> [do\_https\_redirect](#input\_do\_https\_redirect) | Should the service do http to https redirects, or just standard http hosting? This is done via alb rules https://aws.amazon.com/premiumsupport/knowledge-center/elb-redirect-http-to-https-using-alb/ | `bool` | `false` | no |
| <a name="input_do_performance_autoscaling"></a> [do\_performance\_autoscaling](#input\_do\_performance\_autoscaling) | Should the fargate service scale up and down with cpu usage | `bool` | `false` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The domain for r53 registration, leave blank to indicate not using route53 | `string` | `""` | no |
| <a name="input_ecs_autoscale_max_instances"></a> [ecs\_autoscale\_max\_instances](#input\_ecs\_autoscale\_max\_instances) | The maximum number of containers that should be running when scaling up | `number` | `4` | no |
| <a name="input_ecs_autoscale_min_instances"></a> [ecs\_autoscale\_min\_instances](#input\_ecs\_autoscale\_min\_instances) | The minimum number of containers that should be running. Must be at least 1. For production, consider using at least "2". | `number` | `1` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of an existing ECS cluster, if left blank it will create one with the app and environment values | `string` | `""` | no |
| <a name="input_ecs_lambda_runtime"></a> [ecs\_lambda\_runtime](#input\_ecs\_lambda\_runtime) | The lambda runtime for the ecs dashboard, provided here so that it is easy to update to the latest supported | `string` | `"nodejs14.x"` | no |
| <a name="input_fixed_non_spot_count"></a> [fixed\_non\_spot\_count](#input\_fixed\_non\_spot\_count) | How many tasks are required stay normal fargate (non-spot) instances despite the percentages | `number` | `1` | no |
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | The path to the health check for the load balancer to know if the container(s) are ready | `string` | `"/"` | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | How often to check the liveliness of the container | `string` | `"30"` | no |
| <a name="input_health_check_matcher"></a> [health\_check\_matcher](#input\_health\_check\_matcher) | What HTTP response code to listen for | `string` | `"200"` | no |
| <a name="input_health_check_timeout"></a> [health\_check\_timeout](#input\_health\_check\_timeout) | How long to wait for the response on the health check path | `string` | `"10"` | no |
| <a name="input_https_port"></a> [https\_port](#input\_https\_port) | The port to listen on for HTTPS (if it is enabled), always use 443 | `string` | `"443"` | no |
| <a name="input_lb_access_logs_expiration_days"></a> [lb\_access\_logs\_expiration\_days](#input\_lb\_access\_logs\_expiration\_days) | How many days worth of load balancer logs to keep in s3 | `string` | `"3"` | no |
| <a name="input_lb_port"></a> [lb\_port](#input\_lb\_port) | The port the standard http load balancer will listen on | `string` | `"80"` | no |
| <a name="input_lb_protocol"></a> [lb\_protocol](#input\_lb\_protocol) | The load balancer protocol | `string` | `"HTTP"` | no |
| <a name="input_logs_retention_in_days"></a> [logs\_retention\_in\_days](#input\_logs\_retention\_in\_days) | Specifies the number of days you want to retain log events | `number` | `90` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size | `number` | `512` | no |
| <a name="input_operating_system_family"></a> [operating\_system\_family](#input\_operating\_system\_family) | The OS Family of the task, see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform | `string` | `"LINUX"` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | The fargate platform version. These version numbers are different between linux and windows, make sure to use the correct value or leave it at LATEST: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html | `string` | `"LATEST"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | How many containers to run | `number` | `1` | no |
| <a name="input_scaling_cpu_high_threshold"></a> [scaling\_cpu\_high\_threshold](#input\_scaling\_cpu\_high\_threshold) | If the average CPU utilization over a minute rises to this threshold, the number of containers will be increased (but not above ecs\_autoscale\_max\_instances). | `string` | `"80"` | no |
| <a name="input_scaling_cpu_low_threshold"></a> [scaling\_cpu\_low\_threshold](#input\_scaling\_cpu\_low\_threshold) | If the average CPU utilization over a minute drops to this threshold, the number of containers will be reduced (but not below ecs\_autoscale\_min\_instances). | `string` | `"20"` | no |
| <a name="input_secrets_manager"></a> [secrets\_manager](#input\_secrets\_manager) | indicates if a secrets manager | `bool` | `false` | no |
| <a name="input_secrets_manager_recovery_window_in_days"></a> [secrets\_manager\_recovery\_window\_in\_days](#input\_secrets\_manager\_recovery\_window\_in\_days) | Number of days that secrets manager will wait before fully deleting a secret, set to 0 to delete immediately https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret#recovery_window_in_days | `number` | `7` | no |
| <a name="input_secrets_users"></a> [secrets\_users](#input\_secrets\_users) | A list of users that will have full access to the secrets manager and its kms key, the current user applying the terraform will have access as well. | `list(any)` | `[]` | no |
| <a name="input_spot_percentage"></a> [spot\_percentage](#input\_spot\_percentage) | The percentage of tasks in the service that should run as spot instances. This also works for ARM/Graviton, but beware, some regions don't have any capacity or support for ARM spot | `number` | `0` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | This is the policy that controls the specifics about TLS/SSL versions and supported ciphers. This default will only support TLS 1.2 https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies | `string` | `"ELBSecurityPolicy-TLS-1-2-Ext-2018-06"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_nsg_id"></a> [alb\_nsg\_id](#output\_alb\_nsg\_id) | This is the network security group id (sg-blah) for the ALB. This could be useful if you needed to directly add new rules |
| <a name="output_cicd_keys"></a> [cicd\_keys](#output\_cicd\_keys) | A command to run that can extract the AWS keys for the CICD user to use in a build system (remove the \ in the select section |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | The arn of the ecs cluster that was created or referenced |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | The name of the ecs cluster that was created or referenced |
| <a name="output_ecs_service_name"></a> [ecs\_service\_name](#output\_ecs\_service\_name) | The arn of the fargate ecs service that was created |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | The fully qualified domain name created if dns based ACM is enabled |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | The arn of the load balancer |
| <a name="output_lb_dns"></a> [lb\_dns](#output\_lb\_dns) | The load balancer DNS name |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | The arn of the created secret manager (if enabled) |
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | The short name id of the created secret manager (if enabled) |

[fargate]: https://aws.amazon.com/fargate/
[fargate-template]: https://github.com/turnerlabs/terraform-ecs-fargate
[s3-state]: https://www.terraform.io/language/settings/backends/s3
[fargate-create]: https://github.com/turnerlabs/fargate-create
<!-- END_TF_DOCS -->