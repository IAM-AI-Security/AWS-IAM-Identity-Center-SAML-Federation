# Identity Federation Governance Strategy: Why SAML Alone Is Not an Architecture

**Go Cloud Architects | Architecture Brief**
© 2026 Go Cloud Architects — curtis@igasecurityconsulting.com

---

## The Business Problem

Every enterprise with AWS accounts and an identity provider has done some version of SAML federation. Okta connected to AWS, a handful of permission sets created, access provisioned to the teams that asked loudest, and then the project is declared complete. Six months later, nobody remembers exactly what was provisioned, to whom, or why the AdministratorAccess permission set has a 12-hour session duration.

Federation is treated as a connectivity project. Connect the IdP to the service provider, verify that users can log in, and move on. What gets left behind is the governance model: who owns the permission sets, how do they change, how do you know when they have drifted from policy, and how do you produce audit evidence when an examiner asks.

The result is standing privilege at enterprise scale. Users with AdministratorAccess that they rarely need but always have. Session durations set to the maximum because it was convenient at the time and nobody reviewed them since. Permission sets that were created for a specific project and are now assigned to everyone in the engineering org. Terraform state that was last applied two years ago and no longer reflects what is actually deployed.

A 2026 KPMG analysis found that traditional identity governance, built on periodic attestation and manual processes, cannot keep pace with the rate at which cloud access patterns change. The problem in federation governance is not connecting the IdP. Every organization has done that. The problem is what happens to the access model after the connection is made.

---

## Why Existing Approaches Fail

The standard enterprise response to federation governance failure is a periodic access review. Once a quarter, a spreadsheet is circulated, managers certify that their team members still need their access, and the certifications are filed as audit evidence. This process has three predictable failure modes.

The first is rubber-stamp certification. Managers approve access they do not understand because the alternative is investigating each entry, which takes time they do not have. The rubber-stamp problem is well documented in IGA research and has no process solution. It requires architectural controls that make over-privileged access structurally impossible rather than periodically reviewed.

The second is configuration drift. Terraform-managed permission sets that are not continuously applied against a known-good state diverge over time. Direct console changes, emergency access grants that were never cleaned up, and manual permission set assignments accumulate outside the version-controlled state. By the time an examiner asks for evidence that access is managed to policy, the Terraform state and the actual AWS configuration no longer match.

The third is session duration negligence. Session duration is the primary ZSP control in a SAML federation model. It determines how long a credential remains valid after issuance, which determines the window of exposure if that credential is compromised. Most enterprises set session durations once during initial configuration and never revisit them. A 12-hour AdministratorAccess session issued to an engineer who needs five minutes of elevated access is not a security control. It is standing privilege with an extra authentication step.

---

## Design Principles

This implementation is built on four principles that address each of these failure modes directly.

**Zero Standing Privilege through session duration governance.** Session durations are the architectural enforcement mechanism for ZSP in a federation model. AdministratorAccess sessions expire in one hour. SecurityAudit sessions expire in two hours. ReadOnly sessions expire in four hours. These are not default values. They are policy decisions encoded in Terraform and version-controlled alongside every other infrastructure decision.

**Terraform as policy enforcement, not just provisioning.** The Terraform configuration in this repository is not a deployment artifact. It is the policy. Every permission set, every assignment, and every session duration is defined in code, reviewed through version control, and applied against a known-good state. A direct console change that is not reflected in Terraform state is detectable drift, not invisible configuration.

**Least privilege through role separation.** Permission sets map to operational personas, not individuals. Auditors receive ReadOnly. PAM and security engineers receive SecurityAudit. Cloud administrators receive AdministratorAccess with the shortest session duration. The assignment model is group-based, not user-based. Individual access is derived from group membership managed in the IdP, not from direct assignments in AWS.

**Version control as audit evidence.** Every change to the access model goes through a pull request, is reviewed, and produces a commit record. When an SOX ITGC examiner asks for evidence that privileged access changes are reviewed and approved, the answer is a Git history, not a manual log entry.

---

## Architecture Decisions

**Why AWS IAM Identity Center over IAM users and roles**

Traditional AWS IAM users with long-lived access keys are the NHI governance failure mode at the workforce layer. A user with a 90-day access key that they rotate inconsistently and store in their home directory is not a security model. IAM Identity Center issues temporary credentials with session-duration controls enforced at the platform layer. There is no persistent access key to manage, rotate, or accidentally commit to a repository.

**Why Okta as the IdP**

The decision to use an external IdP rather than IAM Identity Center's built-in directory reflects enterprise reality. Identity lifecycle management provisioning, deprovisioning, group membership, MFA policy belongs in a dedicated identity platform. IAM Identity Center handles the AWS-side authorization model. Okta handles the identity lifecycle. The integration boundary is the SAML 2.0 trust. Each system does what it is designed to do.

**Why Terraform for permission set management**

Permission sets managed through the AWS console are invisible to version control, produce no change history, and create no audit trail. Terraform-managed permission sets are code. They can be reviewed, approved, tested in a non-production environment, and applied through a controlled pipeline. The Terraform state file is the source of truth for what is deployed. Drift detection is a terraform plan away.

**Why 1-hour AdministratorAccess session duration**

The session duration for AdministratorAccess is the most consequential security decision in this implementation. A compromised session token is valid for the duration of its session. One hour limits the exploitation window to a period short enough that most incident response processes can contain the exposure before the session would have expired naturally. This is the same ZSP principle applied to human credentials that Workload Identity Manager applies to machine certificates.

---

## Security Controls

| Control | Implementation | Purpose |
|---|---|---|
| Session duration limits | Terraform-managed per permission set | Enforces ZSP, limits credential exposure window |
| Group-based assignments | Okta group membership drives AWS access | Eliminates direct individual assignments, centralizes lifecycle in IdP |
| Version-controlled state | All permission sets in Terraform | Detectable drift, auditable change history |
| External IdP MFA | Okta MFA policy enforced at authentication | No AWS console access without MFA |
| Least privilege permission sets | Role-separated by operational persona | No user holds more access than their function requires |
| Temporary credentials | IAM Identity Center session tokens | No long-lived access keys for workforce access |

---

## Compliance Mapping

| Control Objective | Framework | Implementation |
|---|---|---|
| Privileged access management | NIST CSF PR.AC-4 | Permission sets scoped by role, session durations enforced at platform layer |
| Access change management | SOX ITGC | All permission set changes version-controlled, reviewed, and committed before apply |
| Least privilege enforcement | NIST SP 800-207 Zero Trust | Group-based assignments, role-separated permission sets, no direct individual grants |
| Audit trail for privileged access | FFIEC IT Examination Handbook | Git history provides timestamped change record, AWS CloudTrail captures session events |
| Identity lifecycle management | NIST CSF PR.AC-1 | Deprovisioning managed in Okta, propagated to AWS through SAML group membership |
| Standing privilege elimination | Zero Standing Privilege | Session-based temporary credentials, no persistent access keys for workforce |

---

## Business Impact

The business case for federation governance is not security posture alone. It is operational cost reduction, audit efficiency, and the ability to scale cloud access without scaling the team that manages it.

An access model managed through Terraform and version control eliminates the manual work of per-user permission management. New engineer onboarding is a group membership change in Okta. Access is provisioned, scoped, and session-limited without a cloud administrator touching the AWS console. Offboarding is a group removal in Okta. The AWS access disappears with the next session expiry.

SOX ITGC audits for privileged access are a recurring cost for every financial services organization operating in AWS. An auditor asking for evidence that privileged access is reviewed and managed to policy receives a Git history showing every permission set change, who approved it, when it was applied, and what the before and after state was. This is audit-ready evidence that a console-managed environment cannot produce.

The session duration model reduces the standing privilege exposure window without requiring JIT elevation infrastructure. An administrator who needs elevated access authenticates through Okta, receives a one-hour session, and completes their work. The session expires. There is no privileged access to review because there is no standing access to accumulate.

---

## Future Roadmap

**Phase 2: JIT Elevation**
Extend the model with just-in-time elevation for AdministratorAccess. Rather than assigning AdministratorAccess as a standing permission set, require an approval workflow in ServiceNow or Okta Workflows before the elevated session is issued. Elevation is time-bound, logged, and requires documented justification. This removes standing AdministratorAccess entirely from the model.

**Phase 3: Permission Set Drift Detection**
Integrate automated Terraform plan execution on a scheduled basis to detect configuration drift between the version-controlled state and the actual AWS deployment. Drift findings generate a ServiceNow ticket and trigger review. This closes the gap between periodic access reviews and continuous compliance verification.

**Phase 4: Multi-Account Scaling**
Extend the Terraform model to manage permission set assignments across a multi-account AWS Organizations structure using delegated administration. A single Terraform configuration governs access across development, staging, and production accounts with environment-specific permission set assignments enforced as code.

**Phase 5: Entitlement Intelligence**
Integrate with the IAM Privilege Drift Detection Agent to analyze actual usage patterns against assigned permission sets. Permission sets that are consistently over-provisioned relative to actual usage patterns generate remediation recommendations. The access model converges toward actual operational need rather than initial estimate.

---

*Sources: KPMG Cybersecurity Considerations 2026; NIST SP 800-207 Zero Trust Architecture; NIST CSF 2.0; FFIEC IT Examination Handbook; SOX ITGC Access Control Guidance; CyberArk Identity Security Threat Landscape Report.*
