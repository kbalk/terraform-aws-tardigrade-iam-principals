terraform {
  required_version = ">= 0.12"
}

locals {
  policy_arns = distinct(concat(
    var.policy_arns,
    [for policy in module.policies.policies : policy.arn]
  ))

  user_names = distinct(concat(
    var.user_names,
    [for user in module.users.users : user.name]
  ))
}

module "policies" {
  source = "./modules/policies/"

  create_policies = var.create_policies
  template_paths  = var.template_paths
  template_vars   = var.template_vars

  policies = var.policies
}

module "groups" {
  source = "./modules/groups/"

  policy_arns = local.policy_arns
  user_names  = local.user_names

  create_groups  = var.create_groups
  groups         = var.groups
  template_paths = var.template_paths
  template_vars  = var.template_vars
}

module "roles" {
  source = "./modules/roles/"

  policy_arns = local.policy_arns

  create_roles   = var.create_roles
  roles          = var.roles
  tags           = var.tags
  template_paths = var.template_paths
  template_vars  = var.template_vars
}

module "users" {
  source = "./modules/users/"

  policy_arns = local.policy_arns

  create_users   = var.create_users
  tags           = var.tags
  template_paths = var.template_paths
  template_vars  = var.template_vars
  users          = var.users
}
