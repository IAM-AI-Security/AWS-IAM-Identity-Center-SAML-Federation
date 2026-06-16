output "sso_instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = local.sso_instance_arn
}

output "identity_store_id" {
  description = "IAM Identity Center identity store ID"
  value       = local.sso_identity_store_id
}

output "permission_set_arns" {
  description = "ARNs of created permission sets"
  value       = { for k, v in aws_ssoadmin_permission_set.main : k => v.arn }
}

output "okta_saml_sp_metadata_url" {
  description = "AWS SSO SAML SP metadata URL for Okta configuration"
  value       = "https://portal.sso.us-east-1.amazonaws.com/saml/metadata/${local.sso_instance_arn}"
}
