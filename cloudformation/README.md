\# CloudFormation — Private EC2 via SSM (No NAT, No Bastion)



This CloudFormation stack builds the same pattern as the manual/Terraform version:



\- \*\*Private EC2\*\* in \*\*private subnets\*\* (no public IP)

\- Access using \*\*AWS Systems Manager Session Manager\*\* (no bastion, no inbound SG rules)

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

\- EC2 SG: \*\*no inbound rules\*\*, outbound allowed

\- Endpoint SG: allows \*\*HTTPS 443 inbound from EC2 SG\*\*



\### SSM Access

\- EC2 role: `role-prod-ec2-ssm` with `AmazonSSMManagedInstanceCore`

\- SSM connectivity provided by the interface endpoints (no internet required)



---



\## Files

\- `template.yml` — CloudFormation template to deploy the stack



---



\## Deploy (AWS Console)



1\. Switch region to \*\*eu-west-2 (London)\*\*

2\. Go to \*\*CloudFormation → Create stack → With new resources (standard)\*\*

3\. Choose \*\*Upload a template file\*\*

4\. Upload: `cloudformation/template.yml`

5\. Click \*\*Next\*\*

6\. Stack name: `prod-main-ssm-no-nat`

7\. Parameters:

&nbsp;  - Keep defaults unless you already have the IAM role name in use

&nbsp;  - If role already exists, set `Ec2SsmRoleName` to something unique (e.g. `role-prod-ec2-ssm-cfn`)

8\. Click \*\*Next → Next\*\*

9\. Check:

&nbsp;  - ✅ “I acknowledge that AWS CloudFormation might create IAM resources”

10\. Click \*\*Create stack\*\*

11\. Wait for \*\*CREATE\_COMPLETE\*\*



---



\## IMPORTANT: Session Manager logging preference (CloudWatch/KMS gotcha)



Session Manager does \*\*not\*\* require CloudWatch logs.



If your session fails with an error about CloudWatch Logs encryption, fix it here:



\- Systems Manager → Session Manager → Preferences → Edit

\- Set:

&nbsp; - CloudWatch logging: \*\*OFF\*\*

&nbsp; - S3 logging: \*\*OFF\*\*

\- Save, then retry.



---



\## Verify + Connect



\### Verify managed node

\- Systems Manager → \*\*Managed nodes\*\*

\- Instance should show \*\*Online\*\*



\### Connect (Console)

\- Systems Manager → \*\*Session Manager\*\* → Start session → select the instance



\### Connect (CLI)

Copy the instance id from:

\- CloudFormation → Stack → \*\*Outputs\*\* tab → `InstanceId`



Then:

```powershell

aws ssm start-session --target <INSTANCE\_ID> --region eu-west-2

Cost control / Cleanup

Interface VPC Endpoints cost money per hour, so delete when finished:

CloudFormation → Stacks → select prod-main-ssm-no-nat → Delete

Wait until the stack is fully deleted.

Notes

IAM resources are account-wide. If the role name already exists, change the Ec2SsmRoleName parameter.

This stack is intended as a portfolio demo of the “no NAT + endpoints-only SSM access” pattern.


---


