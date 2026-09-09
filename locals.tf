# Prefixo usado nos nomes/tags de recursos. Inclui o workspace do Terraform
# (homolog/prod) porque alguns recursos (identifier do RDS, nome do parâmetro SSM)
# precisam ser únicos por ambiente na mesma conta/região — homolog e main
# compartilham o mesmo código, mas apontam para workspaces diferentes.
locals {
  name_prefix = "${var.project_name}-${terraform.workspace}"
}
