# Enable AWS IAM Identity Center (SSO)
data "aws_ssoadmin_instances" "main" {}

locals {
  sso_instance_arn      = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  sso_identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

# Create Permission Sets
resource "aws_ssoadmin_permission_set" "main" {
  for_each = var.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = local.sso_instance_arn
  session_duration = each.value.session_duration

  tags = var.project_tags
}

# Attach Managed Policies to Permission Sets
resource "aws_ssoadmin_managed_policy_attachment" "main" {
  for_each = var.permission_sets

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.main[each.key].arn
  managed_policy_arn = each.value.managed_policies[0]
}

# Create IAM Identity Center Users
resource "aws_identitystore_user" "users" {
  for_each = {
    "pam-auditor" = {
      display_name = "PAM Auditor"
      first_name   = "PAM"
      last_name    = "Auditor"
      email        = "pam-auditor@igasecurityconsulting.com"
    }
    "security-engineer" = {
      display_name = "Security Engineer"
      first_name   = "Security"
      last_name    = "Engineer"
      email        = "security-engineer@igasecurityconsulting.com"
    }
    "cloud-admin" = {
      display_name = "Cloud Admin"
      first_name   = "Cloud"
      last_name    = "Admin"
      email        = "cloud-admin@igasecurityconsulting.com"
    }
  }

  identity_store_id = local.sso_identity_store_id

  display_name = each.value.display_name
  user_name    = each.key

  name {
    given_name  = each.value.first_name
    family_name = each.value.last_name
  }

  emails {
    value   = each.value.email
    type    = "work"
    primary = true
  }
}

# Create Groups aligned to Permission Sets
resource "aws_identitystore_group" "groups" {
  for_each = {
    "AWS-ReadOnly-Users"    = "Read-only access group for auditors"
    "AWS-SecurityAudit"     = "Security audit group for PAM team"
    "AWS-Administrators"    = "Admin group - ZSP JIT elevation required"
  }

  identity_store_id = local.sso_identity_store_id
  display_name      = each.key
  description       = each.value
}

# Assign Users to Groups
resource "aws_identitystore_group_membership" "memberships" {
  for_each = {
    "auditor-readonly" = {
      group_id  = aws_identitystore_group.groups["AWS-ReadOnly-Users"].group_id
      member_id = aws_identitystore_user.users["pam-auditor"].user_id
    }
    "engineer-security" = {
      group_id  = aws_identitystore_group.groups["AWS-SecurityAudit"].group_id
      member_id = aws_identitystore_user.users["security-engineer"].user_id
    }
    "admin-cloud" = {
      group_id  = aws_identitystore_group.groups["AWS-Administrators"].group_id
      member_id = aws_identitystore_user.users["cloud-admin"].user_id
    }
  }

  identity_store_id = local.sso_identity_store_id
  group_id          = each.value.group_id
  member_id         = each.value.member_id
}

# Assign Groups to Permission Sets on the AWS Account
resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each = {
    "readonly-group" = {
      group_name      = "AWS-ReadOnly-Users"
      permission_set  = "ReadOnlyAccess"
    }
    "security-group" = {
      group_name      = "AWS-SecurityAudit"
      permission_set  = "SecurityAudit"
    }
    "admin-group" = {
      group_name      = "AWS-Administrators"
      permission_set  = "AdministratorAccess"
    }
  }

  instance_arn       = local.sso_instance_arn
  target_id          = data.aws_caller_identity.current.account_id
  target_type        = "AWS_ACCOUNT"
  principal_type     = "GROUP"
  principal_id       = aws_identitystore_group.groups[each.value.group_name].group_id
  permission_set_arn = aws_ssoadmin_permission_set.main[each.value.permission_set].arn
}

data "aws_caller_identity" "current" {}
