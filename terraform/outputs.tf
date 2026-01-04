output "vpc_id" {
  value = aws_vpc.prod_main.id
}

output "private_instance_id" {
  value = aws_instance.private_ec2.id
}

output "private_instance_private_ip" {
  value = aws_instance.private_ec2.private_ip
}

output "endpoint_ids" {
  value = {
    ssm         = aws_vpc_endpoint.ssm.id
    ec2messages = aws_vpc_endpoint.ec2messages.id
    ssmmessages = aws_vpc_endpoint.ssmmessages.id
  }
}
