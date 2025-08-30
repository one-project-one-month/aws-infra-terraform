terraform {
  required_version = ">= 1.12.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.3.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
  }

}


