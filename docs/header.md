# Terraform ECS Fargate

A module used for provisioning web or api application stacks on [AWS ECS Fargate][fargate]. The majority of the module has been adapted from [this template][fargate-template].


![diagram](diagram.png)

## Example
This will spin up a new ECS cluster and fargate service running a simple default container image. 

```
module "fargate" {
  !! TODO: update this with final url !!
  source = "git@github.com:warnermediacode/terraform-ecs-fargate-module/"

  app                   = "mywebsite"
  environment           = "main"
  tags                  = var.tags
  container_port        = 8000
  vpc                   = "vpc-a1b2c3der"
  create_public_ip      = true
  load_balancer_subnets = ["subnet-0ba9...","subnet-abcde"]
  fargate_subnets       = ["subnet-9ba0...","subnet-edcba"]

  health_check = "/healthz"
}
```

## Usage and link to base

It is recommended that you store your terraform state in a safe location. If the `create_cicd_user` variable is enabled, the state file will contain your aws key id and secret. The easiest method would be to use [S3 state][s3-state]. This also pairs well with --insert link for base here--
 