# Build Steps (AWS Console) — Private EC2 via SSM (No NAT)

Region: eu-west-2 (London)

## Step 1 — VPC
- Create VPC: `prod-main-vpc`
- IPv4 CIDR: `10.20.0.0/16`
- Enable:
  - DNS resolution = ON
  - DNS hostnames = ON

## Step 2 — Subnets
Create 4 subnets:

Public
- `prod-main-subnet-public1-eu-west-2a` — `10.20.0.0/20` (AZ: eu-west-2a)
- `prod-main-subnet-public2-eu-west-2b` — `10.20.16.0/20` (AZ: eu-west-2b)

Private
- `prod-main-subnet-private1-eu-west-2a` — `10.20.128.0/20` (AZ: eu-west-2a)
- `prod-main-subnet-private2-eu-west-2b` — `10.20.144.0/20` (AZ: eu-west-2b)

Subnet setting:
- Turn ON auto-assign public IPv4 ONLY on the two public subnets

## Step 3 — Internet Gateway
- Create IGW: `prod-main-igw`
- Attach it to: `prod-main-vpc`

## Step 4 — Route Tables
Create 3 route tables:
- `prod-main-rtb-public`
- `prod-main-rtb-private1-eu-west-2a`
- `prod-main-rtb-private2-eu-west-2b`

## Step 5 — Routes + Associations
Public route table (`prod-main-rtb-public`)
- Add route: `0.0.0.0/0` → `prod-main-igw`
- Associate subnets:
  - `prod-main-subnet-public1-eu-west-2a`
  - `prod-main-subnet-public2-eu-west-2b`

Private route tables
- Do NOT add `0.0.0.0/0`
- Associate:
  - `prod-main-rtb-private1-eu-west-2a` → `prod-main-subnet-private1-eu-west-2a`
  - `prod-main-rtb-private2-eu-west-2b` → `prod-main-subnet-private2-eu-west-2b`

## Step 6 — Security Groups
Create:
1) EC2 private SG: `sg-prod-private-app`
- Inbound: none
- Outbound: allow all (for now)

2) Endpoint SG: `vpce-ssm`
- Inbound: HTTPS 443 from `sg-prod-private-app`
- Outbound: allow all

## Step 7 — VPC Interface Endpoints (3)
Create these Interface endpoints in `prod-main-vpc`:
- `com.amazonaws.eu-west-2.ssm`
- `com.amazonaws.eu-west-2.ec2messages`
- `com.amazonaws.eu-west-2.ssmmessages`

Settings for each endpoint:
- Type: Interface
- Subnets: BOTH private subnets
- Private DNS: Enabled
- Security group: `vpce-ssm`
- Policy: Full access

## Step 8 — IAM Role for EC2 (SSM)
Create role: `role-prod-ec2-ssm`
- Trusted entity: EC2
- Attach policy: `AmazonSSMManagedInstanceCore`

## Step 9 — Launch Private EC2
Launch instance: `prod-main-ec2-private-1`
- AMI: Amazon Linux 2023
- Subnet: a private subnet
- Auto-assign public IP: Disabled
- Security group: `sg-prod-private-app`
- IAM instance profile: `role-prod-ec2-ssm`

## Step 10 — Connect using Session Manager
- Systems Manager → Session Manager → Start session
- Or CLI:
  `aws ssm start-session --target <instance-id> --region eu-west-2`
