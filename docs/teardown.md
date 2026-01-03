# Teardown / Cost Control Checklist

This project avoids NAT Gateways (major cost), but VPC Interface Endpoints can still cost money per hour.
Delete resources when finished.

## Recommended deletion order (safe + avoids dependency errors)

### 1) Terminate EC2
- EC2 → Instances → select `prod-main-ec2-private-1` → Instance state → Terminate

### 2) Delete VPC Endpoints (important: these cost per hour)
- VPC → Endpoints
- Delete:
  - com.amazonaws.eu-west-2.ssm
  - com.amazonaws.eu-west-2.ec2messages
  - com.amazonaws.eu-west-2.ssmmessages

### 3) Delete Security Groups (if not in use)
- EC2 → Security Groups
- Delete:
  - `vpce-ssm`
  - `sg-prod-private-app`

If it won’t delete, something is still attached (usually an endpoint ENI or an instance).

### 4) Delete custom Route Tables (not the “main” route table)
- VPC → Route Tables
- Ensure subnets are not associated (AWS will block if still associated)
- Delete:
  - `prod-main-rtb-public`
  - `prod-main-rtb-private1-eu-west-2a`
  - `prod-main-rtb-private2-eu-west-2b`

### 5) Detach and delete Internet Gateway
- VPC → Internet gateways
- Select `prod-main-igw`
- Actions → Detach from VPC
- Actions → Delete internet gateway

### 6) Delete Subnets
- VPC → Subnets
- Delete the 4 subnets:
  - public1 (2a), public2 (2b), private1 (2a), private2 (2b)

### 7) Delete the VPC
- VPC → Your VPCs
- Select `prod-main-vpc`
- Actions → Delete VPC

## Extra notes
- Interface endpoints can leave ENIs behind briefly; wait a couple minutes then retry SG deletes if blocked.
- IAM role does not cost money, but you can delete it if you want:
  IAM → Roles → `role-prod-ec2-ssm` → Delete
