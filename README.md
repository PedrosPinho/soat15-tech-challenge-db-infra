# soat15-tech-challenge-db-infra

Terraform da camada de dados da Fase 3 do Tech Challenge (SOAT): VPC, RDS PostgreSQL
16 e SSM Parameter Store, num único repositório porque a VPC precisa existir antes de
qualquer outro recurso (RDS, EKS, Lambda em VPC) — ver
[`ADR-003`](https://github.com/PedrosPinho/soat15-tech-challenge-01/blob/main/docs/architecture/adrs/ADR-003-split-quatro-repositorios.md)
no repositório da aplicação.

## Escopo deste repositório

- VPC com subnets públicas e privadas em 2 AZs, sem NAT Gateway (restrição de
  orçamento do AWS Academy Learner Lab)
- `aws_db_instance` PostgreSQL 16, `db.t4g.micro`, sem proteção de exclusão nem
  snapshot final (ver justificativa nas notas abaixo)
- Senha do banco gerada com `random_password` e armazenada em SSM Parameter Store
  (`SecureString`)
- Security groups: RDS só aceita 5432 dos SGs do EKS e da Lambda de autenticação

## Dependências

Nenhuma — este é o primeiro repositório a aplicar. Exporta outputs consumidos por
[`soat15-tech-challenge-k8s-infra`](https://github.com/PedrosPinho/soat15-tech-challenge-k8s-infra)
e [`soat15-tech-challenge-auth-lambda`](https://github.com/PedrosPinho/soat15-tech-challenge-auth-lambda)
via `terraform_remote_state`.

## Estado remoto

Bucket S3 (`soat15-tc-tfstate-442534931336`) e tabela DynamoDB de lock
(`soat15-tc-tfstate-lock`) provisionados manualmente uma única vez, fora do ciclo
`destroy`/`apply` de qualquer repositório — ver `backend.tf`.

## Uso

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Ciclo de sessão do Learner Lab

Credenciais da sessão expiram em ~4h. `terraform apply` no início de cada sessão de
trabalho, `terraform destroy` ao final — ver
[`PHASE_3_EXECUTION_GUIDE.md`](https://github.com/PedrosPinho/soat15-tech-challenge-01/blob/main/docs/PHASE_3_EXECUTION_GUIDE.md)
no repositório da aplicação para o procedimento completo e a ordem entre os 4
repositórios.

## Notas de arquitetura

Decisões, RFCs e ADRs completos vivem no repositório da aplicação principal, em
[`docs/architecture/`](https://github.com/PedrosPinho/soat15-tech-challenge-01/tree/main/docs/architecture)
— em particular
[`RFC-002`](https://github.com/PedrosPinho/soat15-tech-challenge-01/blob/main/docs/architecture/rfcs/RFC-002-banco-de-dados.md)
(por que PostgreSQL) e
[`data-model.md`](https://github.com/PedrosPinho/soat15-tech-challenge-01/blob/main/docs/architecture/data-model.md)
(modelo ER completo).

`deletion_protection = false` e `skip_final_snapshot = true` são o oposto do que se
faria em produção real — obrigatório aqui porque o banco é recriado a cada sessão do
Learner Lab; proteção de exclusão travaria o `destroy` de fim de sessão.
