# Restrição do AWS Academy Learner Lab: região fixa (ver ADR/RFC no repo da
# aplicação, docs/architecture/rfcs/RFC-001-escolha-da-nuvem.md).
variable "aws_region" {
  description = "Região AWS (fixa, restrição do Learner Lab)"
  type        = string
  default     = "us-east-1"
}

# IAM está bloqueado no Learner Lab: não é possível criar roles dedicadas.
# LabRole é a única role disponível, usada em tudo (ver ADR-006 no repo da
# aplicação). O ARN é estável para esta conta/enrollment do Learner Lab.
variable "lab_role_arn" {
  description = "ARN da LabRole pré-criada pelo AWS Academy Learner Lab"
  type        = string
  default     = "arn:aws:iam::442534931336:role/LabRole"
}

variable "project_name" {
  description = "Prefixo usado no nome dos recursos"
  type        = string
  default     = "soat15-tc"
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "AZs usadas pelas subnets (2 AZs, requisito de subnet group do RDS)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_instance_class" {
  description = "Classe da instância RDS (orçamento do Learner Lab)"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Nome do banco de dados PostgreSQL"
  type        = string
  default     = "oficina"
}

variable "db_username" {
  description = "Usuário master do RDS"
  type        = string
  default     = "oficina"
}
