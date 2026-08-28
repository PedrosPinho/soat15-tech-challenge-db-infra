# Consumidos pelos repos soat15-tech-challenge-k8s-infra e
# soat15-tech-challenge-auth-lambda via terraform_remote_state (ver README).

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas (uma por AZ) — nós do EKS"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas (uma por AZ) — RDS e Lambda de autenticação"
  value       = aws_subnet.private[*].id
}

output "db_endpoint" {
  description = "Hostname do RDS (sem porta)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Porta do RDS PostgreSQL"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Nome do banco de dados PostgreSQL"
  value       = aws_db_instance.main.db_name
}

output "db_secret_param_name" {
  description = "Nome do parâmetro SSM (SecureString) com a senha do master user do RDS"
  value       = aws_ssm_parameter.db_password.name
}

output "db_security_group_id" {
  description = "ID do security group do RDS"
  value       = aws_security_group.rds.id
}

output "eks_nodes_security_group_id" {
  description = "ID do security group dos nós do EKS — para o repo k8s-infra anexar ao node group"
  value       = aws_security_group.eks_nodes.id
}

output "lambda_auth_security_group_id" {
  description = "ID do security group placeholder da Lambda de autenticação — para o repo auth-lambda anexar à função"
  value       = aws_security_group.lambda_auth.id
}
