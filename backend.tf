# Estado remoto: bucket S3 + trava DynamoDB provisionados manualmente no bootstrap
# da Fase 3 (fora do ciclo destroy/apply de qualquer um dos 4 repositórios — ver
# PHASE_3_EXECUTION_GUIDE.md do repositório da aplicação, Passo 1).
terraform {
  backend "s3" {
    bucket         = "soat15-tc-tfstate-442534931336"
    key            = "db-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "soat15-tc-tfstate-lock"
    encrypt        = true
  }
}
