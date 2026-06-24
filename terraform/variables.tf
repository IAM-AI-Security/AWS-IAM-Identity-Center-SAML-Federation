variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "okta_org_url" {
  description = "Okta organization URL"
  type        = string
  default     = "https://your-org.okta.com"
}

variable "permission_sets" {
  description = "Permission sets to create in IAM Identity Center"
  type = map(object({
    description      = string
    managed_policies = list(string)
    session_duration = string
  }))
  default = {
    "ReadOnlyAccess" = {
      description      = "Read-only access for auditors and compliance team"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      session_duration = "PT4H"
    }
    "SecurityAudit" = {
      description      = "Security audit access for PAM and identity team"
      managed_policies = ["arn:aws:iam::aws:policy/SecurityAudit"]
      session_duration = "PT2H"
    }
    "AdministratorAccess" = {
      description      = "Full admin access - requires ZSP JIT elevation"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      session_duration = "PT1H"
    }
  }
}

variable "project_tags" {
  description = "Standard tags for all resources"
  type        = map(string)
  default = {
    Project     = "AWS-SAML-Federation"
    Environment = "Production"
    Owner       = "Go-Cloud-Architects"
    Purpose     = "NHI-Identity-Federation-Demo"
  }
}
