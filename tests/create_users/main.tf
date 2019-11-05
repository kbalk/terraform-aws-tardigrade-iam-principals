provider aws {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "terraform_remote_state" "prereq" {
  backend = "local"
  config = {
    path = "prereq/terraform.tfstate"
  }
}

locals {
  test_id = length(data.terraform_remote_state.prereq.outputs) > 0 ? data.terraform_remote_state.prereq.outputs.random_string.result : ""

  policy_arns = length(data.terraform_remote_state.prereq.outputs) > 0 ? [for policy in data.terraform_remote_state.prereq.outputs.policies : policy.arn] : []

  inline_policies = [
    {
      name     = "tardigrade-alpha-${local.test_id}"
      template = "policies/template.json"
    },
    {
      name     = "tardigrade-beta-${local.test_id}"
      template = "policies/template.json"
    },
  ]

  user_base = {
    policy_arns          = []
    inline_policies      = []
    force_destroy        = null
    path                 = null
    permissions_boundary = null
    tags                 = {}
  }
}

module "create_users" {
  source = "../../modules/users/"
  providers = {
    aws = aws
  }

  template_paths = ["${path.module}/../templates/"]
  template_vars = {
    "account_id" = data.aws_caller_identity.current.account_id
    "partition"  = data.aws_partition.current.partition
    "region"     = data.aws_region.current.name
  }

  force_destroy        = true
  path                 = "/tardigrade/"
  permissions_boundary = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/tardigrade-alpha-create-users-test"
  tags = {
    Test = "true"
  }

  users = [
    merge(local.user_base, {
      name                 = "tardigrade-user-alpha-${local.test_id}"
      policy_arns          = local.policy_arns
      inline_policies      = local.inline_policies
      force_destroy        = false
      path                 = "/tardigrade/alpha/"
      permissions_boundary = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/tardigrade/tardigrade-beta-create-users-test"
      tags = {
        Env = "tardigrade"
      }
    }),
    merge(local.user_base, {
      name            = "tardigrade-user-beta-${local.test_id}"
      policy_arns     = local.policy_arns
      inline_policies = local.inline_policies
    }),
    merge(local.user_base, {
      name        = "tardigrade-user-chi-${local.test_id}"
      policy_arns = local.policy_arns
    }),
    merge(local.user_base, {
      name            = "tardigrade-user-delta-${local.test_id}"
      inline_policies = local.inline_policies
    }),
    merge(local.user_base, {
      name = "tardigrade-user-epsilon-${local.test_id}"
    }),
  ]
}

output "create_users" {
  value = module.create_users
}
