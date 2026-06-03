# Private EC2 Access with SSM, No NAT, and No Bastion

## Overview

This project demonstrates how to access a private EC2 instance using AWS Systems Manager Session Manager without a bastion host, public IP address, inbound SSH rule, or NAT Gateway.

The repository includes Terraform, CloudFormation, architecture documentation, troubleshooting notes, and teardown guidance.

## Business Problem

Traditional server administration often relies on SSH, bastion hosts, or public network exposure. For AWS Cloud Engineer and Cloud Support roles, a safer pattern is to keep instances private and use Systems Manager for audited administrative access.

## Architecture

High-level architecture:

```text
Administrator
  -> AWS Systems Manager Session Manager
  -> SSM interface VPC endpoints
  -> Private EC2 instance
```

Network design:

- VPC in `eu-west-2`
- Public subnets for network structure
- Private subnets for the EC2 instance
- No NAT Gateway
- No bastion host
- Interface endpoints for `ssm`, `ec2messages`, and `ssmmessages`
- Private DNS enabled on interface endpoints

## AWS Services Used

- Amazon VPC
- Amazon EC2
- AWS Systems Manager Session Manager
- AWS PrivateLink / Interface VPC Endpoints
- AWS IAM
- Amazon EC2 security groups
- CloudFormation
- Terraform

## Tools Used

- Terraform
- AWS CloudFormation
- Markdown documentation
- Architecture diagram
- Git and GitHub

## Security Features

- EC2 instance has no public IP address.
- EC2 security group has no inbound rules.
- Administrative access uses SSM Session Manager instead of SSH.
- Interface endpoint security group allows HTTPS only from the private EC2 security group.
- IMDSv2 is required in Terraform for the EC2 instance.
- No NAT Gateway reduces unnecessary outbound internet exposure and cost.

## Deployment Summary

The repository provides both Terraform and CloudFormation implementations for the same private-access pattern. The Terraform implementation creates the VPC, subnets, route tables, interface endpoints, IAM role and instance profile, and private EC2 instance.

No AWS deployment commands were run during this README refresh.

## Testing and Validation

Validation should include:

- Confirming the EC2 instance has no public IP address
- Confirming the EC2 security group has no inbound rules
- Confirming SSM managed instance registration
- Starting a Session Manager session through the console or approved tooling
- Confirming no NAT Gateway is required for SSM access

Use placeholders such as `<instance-id>`, `<vpc-id>`, `<subnet-id>`, and `<region>` in public documentation.

## Evidence / Screenshots

The architecture diagram is stored at `docs/architecture.png`. Supporting build and troubleshooting notes are stored under `docs`. The inspected architecture image does not show AWS account IDs or credentials.

## Cost Control

The design intentionally avoids a NAT Gateway, which is often one of the more expensive always-on components in small AWS labs. Interface endpoints still have hourly and data processing costs, so they should be removed when the lab is complete.

## Cleanup

Follow `docs/teardown.md` after validation. Cleanup should remove the EC2 instance, IAM role and instance profile, interface endpoints, endpoint security groups, route tables, subnets, and VPC resources created for the project.

## Lessons Learned

- Session Manager can replace bastion hosts for many administrative workflows.
- PrivateLink endpoints allow private AWS service access without NAT.
- Removing inbound SSH is a strong security improvement.
- Cost control and security can align when NAT and bastions are avoided.

## Future Improvements

- Add CloudWatch Logs or S3 session logging with KMS encryption.
- Add least-privilege custom IAM policies instead of broad managed policy reliance where appropriate.
- Add Terraform variables for CIDR ranges and environment naming.
- Add a sanitized validation evidence set.
- Add AWS Config or Security Hub checks for private instance posture.
