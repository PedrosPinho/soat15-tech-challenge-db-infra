# VPC com subnets públicas e privadas em 2 AZs, sem NAT Gateway (restrição de
# orçamento do AWS Academy Learner Lab — ver README e PHASE_3_PLAN.md, Etapa 1.1 no
# repositório da aplicação). Recursos que precisam de internet (nós do EKS) ficam em
# subnet pública com security group restrito; o que só precisa alcançar a VPC (RDS)
# fica em subnet privada, sem rota de saída.

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.name_prefix
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# --- Subnets públicas: uma por AZ. Hospedam os nós do EKS (sem NAT Gateway, então
# precisam de rota direta para o IGW e IP público para alcançar a internet/ECR). ---
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  }
}

# --- Subnets privadas: uma por AZ. Hospedam o RDS (e, no repo auth-lambda, a Lambda
# de autenticação) — só precisam alcançar recursos dentro da VPC. ---
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-private-${var.availability_zones[count.index]}"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Sem rota de internet: não há NAT Gateway (restrição de orçamento do Learner Lab).
# Só carrega a rota local implícita da VPC. Se algum recurso privado precisar
# alcançar um serviço AWS (ex.: SSM), a solução é um VPC Endpoint, não uma rota aqui.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-private"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
