terraform {
  required_version = ">= 1.0.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">=2.0.0"
    }
  }

  backend "local" {
    path = "state/terraform.tfstate"
  }
}
