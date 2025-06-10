output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.natgw[*].id
}

output "aws_internet_gateway_id" {
    value = aws_internet_gateway.igw.id
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.rds.endpoint
}

output "rds_username" {
  value = var.db_username
}

output "rds_password" {
  value     = random_password.db_pass.result
  sensitive = true
}


