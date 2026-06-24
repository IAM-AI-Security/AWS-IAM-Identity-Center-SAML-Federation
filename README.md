# AWS IAM Identity Center SAML Federation

Enterprise SAML 2.0 federation pattern: Okta as external IdP federated with AWS IAM Identity Center, with Terraform-managed permission sets and Zero Standing Privilege session controls.

## The Business Problem

Most enterprises federate identity as a one-time project. Okta connected to AWS, access provisioned broadly, and then forgotten. The result is standing privilege that grows unchecked and federation configurations that drift from policy over time.

This implementation demonstrates the right pattern: Terraform-managed permission sets with ZSP-aligned session controls, version-controlled as code, repeatable across accounts, and auditable for SOX ITGC and FFIEC examination.

---

## Architecture

Okta (IdP) → SAML 2.0 Trust → AWS IAM Identity Center (SP) → Permission Sets → AWS Account

## What This Demonstrates

- External IdP federation using SAML 2.0
- Terraform-managed permission sets with ZSP-aligned session durations
- Least privilege group-based access model
- Non-Human Identity governance pattern applied to workforce federation

## Permission Sets

| Permission Set | Session Duration | Target Persona |
|---|---|---|
| ReadOnlyAccess | 4 hours | Auditors / Compliance |
| SecurityAudit | 2 hours | PAM / Security Engineers |
| AdministratorAccess | 1 hour | Cloud Admins (JIT elevation) |

## Stack

- AWS IAM Identity Center
- Okta Workforce Identity (SAML 2.0 IdP)
- Terraform (AWS Provider 5.x)
- AWS CLI

## Deployment Environment

- AWS Account: Go Cloud Architects consulting environment
- Region: us-east-1
- Identity Store: IAM Identity Center built-in directory with external IdP

## Usage

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Related Projects

- [Conjur K8s JWT Secrets Integration](https://github.com/IAM-AI-Security/Conjur-K8s-Secrets-Integration)
- [IAM Privilege Drift Detection Agent](https://github.com/IAM-AI-Security/IAM-Privilege-Drift-Agent)

