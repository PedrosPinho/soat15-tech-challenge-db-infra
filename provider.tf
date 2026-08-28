provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "soat15-tech-challenge"
      Repository  = "db-infra"
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    }
  }
}
