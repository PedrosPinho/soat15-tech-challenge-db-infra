# Security groups. IAM está bloqueado no Learner Lab (ver ADR-006 no repo da
# aplicação), então segurança de rede por SG/porta/origem é a principal linha de
# defesa disponível — reforçado aqui de propósito, não só por padrão de boas práticas.

# --- SG dos nós do EKS ---
# Vive aqui (não no repo k8s-infra) porque o SG do RDS precisa referenciá-lo já na
# criação, e este repositório é aplicado primeiro. Exportado via output para o
# k8s-infra consumir por terraform_remote_state e anexar aos nós do node group.
resource "aws_security_group" "eks_nodes" {
  name        = "${local.name_prefix}-eks-nodes"
  description = "Nos do EKS (subnets publicas, sem NAT). Referenciado por soat15-tech-challenge-k8s-infra via remote state."
  vpc_id      = aws_vpc.main.id

  # Nós em subnet pública, sem NAT: egress amplo é o que permite alcançar
  # ECR/internet/API do EKS. Ingress específico (kubelet, NodePort, etc.) é
  # adicionado pelo repo k8s-infra, que tem o contexto de quais portas o cluster usa.
  egress {
    description = "Egress amplo: nos precisam alcancar ECR, internet e o control plane do EKS (sem NAT Gateway)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Trafego entre os proprios nos do cluster (comunicacao pod-a-pod, kubelet)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  tags = {
    Name = "${local.name_prefix}-eks-nodes"
  }
}

# --- SG placeholder da Lambda de autenticação ---
# DECISÃO (ver README): criado aqui, não no repo auth-lambda. O SG do RDS precisa
# liberar ingress para o SG da Lambda desde a criação, e db-infra é o primeiro
# repositório aplicado — se o SG vivesse em auth-lambda, o RDS teria que ser
# recriado/atualizado depois que auth-lambda existisse, ou auth-lambda teria que
# rodar antes da própria VPC. Criar o SG (recurso "vazio", sem custo) aqui e deixar
# só a função Lambda em si no repo auth-lambda evita essa dependência circular.
resource "aws_security_group" "lambda_auth" {
  name        = "${local.name_prefix}-lambda-auth"
  description = "Placeholder para a Lambda de autenticacao por CPF (recurso Lambda vive em soat15-tech-challenge-auth-lambda)"
  vpc_id      = aws_vpc.main.id

  # A Lambda é cliente do RDS, nunca recebe conexão de entrada — só egress importa.
  egress {
    description = "Egress amplo: lambda precisa alcancar o RDS (5432) e servicos AWS (SSM), sem NAT Gateway"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-lambda-auth"
  }
}

# --- SG do RDS ---
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds"
  description = "RDS PostgreSQL: aceita 5432 apenas dos nos do EKS e da Lambda de autenticacao"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL a partir dos nos do EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  ingress {
    description     = "PostgreSQL a partir da Lambda de autenticacao"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_auth.id]
  }

  # RDS normalmente nao inicia conexoes de saida; egress amplo aqui e uma
  # simplificacao sem risco pratico (nao ha rota de saida a explorar sem trafego
  # de entrada correspondente).
  egress {
    description = "Egress amplo (simplificacao; sem impacto pratico de seguranca)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-rds"
  }
}
