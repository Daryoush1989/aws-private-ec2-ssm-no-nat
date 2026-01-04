\# Terraform — Private EC2 via SSM (No NAT, No Bastion)



This Terraform config builds a cost-aware AWS networking pattern:



\- \*\*Private EC2\*\* in \*\*private subnets\*\* (no public IP)

\- Access via \*\*AWS Systems Manager Session Manager\*\* (no bastion host)

\- \*\*No NAT Gateway\*\*

\- Uses \*\*Interface VPC Endpoints\*\* for SSM:

&nbsp; - `ssm`

&nbsp; - `ec2messages`

&nbsp; - `ssmmessages`



Region: \*\*eu-west-2 (London)\*\*  

Project prefix: \*\*prod-main\*\*



---



\## What this creates



\### Networking

\- VPC: `prod-main-vpc` — `10.20.0.0/16`

\- Public subnets:

&nbsp; - `10.20.0.0/20` (eu-west-2a)

&nbsp; - `10.20.16.0/20` (eu-west-2b)

\- Private subnets:

&nbsp; - `10.20.128.0/20` (eu-west-2a)

&nbsp; - `10.20.144.0/20` (eu-west-2b)

\- Internet Gateway + public route table route `0.0.0.0/0 → IGW`

\- Two private route tables (local-only) — \*\*no `0.0.0.0/0`\*\* (no NAT)



\### Security

\- EC2 SG: \*\*no inbound rules\*\*

\- Endpoint SG: allows \*\*HTTPS 443 inbound from EC2 SG\*\*



\### SSM Access

\- EC2 role: `role-prod-ec2-ssm` with `AmazonSSMManagedInstanceCore`

\- EC2 can register with SSM via the interface endpoints



---

## Cost control / Cleanup (why we run `terraform destroy`)

This project uses **Interface VPC Endpoints** (for SSM) instead of a NAT Gateway.  
Even though this is cost-optimized, **Interface Endpoints still incur hourly charges**, and EC2 instances can also generate costs.

To avoid charges when you finish testing, tear everything down using Terraform:

```powershell
cd .\terraform
terraform destroy


\## Prerequisites



\### Install tools

\- AWS CLI v2

\- Terraform

\- Session Manager Plugin (for CLI sessions)



Verify:

```powershell

aws --version

terraform -version

session-manager-plugin --version



