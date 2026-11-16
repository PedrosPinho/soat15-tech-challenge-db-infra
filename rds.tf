# RDS PostgreSQL 16. Parâmetros de orçamento/ciclo de sessão do Learner Lab
# (backup_retention_period = 0, deletion_protection = false, skip_final_snapshot =
# true) são intencionais — ver README, seção "Notas de arquitetura".

resource "random_password" "db" {
  length  = 24
  special = true
  # RDS não aceita "/", "@", '"' nem espaço na senha do master user — restringe o
  # conjunto de especiais aos permitidos.
  override_special = "!#$%^*()-_=+[]{}<>?"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/${terraform.workspace}/db/password"
  description = "Senha do master user do RDS PostgreSQL (${local.name_prefix})"
  type        = "SecureString"
  value       = random_password.db.result

  tags = {
    Name = "${local.name_prefix}-db-password"
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Subnets privadas para o RDS (sem NAT Gateway, sem exposicao publica)"
  subnet_ids  = aws_subnet.private[*].id

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-db"

  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false

  # Restrições do Learner Lab (ver README): o banco é recriado a cada sessão via
  # destroy/apply, então proteção de exclusão e snapshot final travariam o destroy.
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true

  tags = {
    Name = "${local.name_prefix}-db"
  }
}

# --- Roles por serviço (Fase 4, ADR-012) -----------------------------------------------
# Um database e um role por serviço na MESMA instância: `oficina_os`/`os_service` e
# `oficina_billing`/`billing_service`. O Terraform só gera as senhas e as guarda no SSM; a
# criação dos databases/roles é feita pelo script idempotente `scripts/db-bootstrap.sql`,
# executado como Job do Kubernetes pelo pipeline do OS Service (o runner do GitHub não
# alcança o RDS em subnet privada, então o provider `postgresql` do Terraform não serve).
# Só alfanuméricos: a senha entra em URL de conexão e em `psql -v` sem precisar de escape.
locals {
  service_db_roles = toset(["os-service", "billing-service"])
}

resource "random_password" "service_db" {
  for_each = local.service_db_roles

  length  = 24
  special = false
}

resource "aws_ssm_parameter" "service_db_password" {
  for_each = local.service_db_roles

  name        = "/${var.project_name}/${terraform.workspace}/db/${each.key}-password"
  description = "Senha do role ${replace(each.key, "-", "_")} no RDS PostgreSQL (${local.name_prefix})"
  type        = "SecureString"
  value       = random_password.service_db[each.key].result

  tags = {
    Name = "${local.name_prefix}-${each.key}-db-password"
  }
}
