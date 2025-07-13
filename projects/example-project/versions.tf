terraform {
  required_version = ">= 1.12.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.3.0"
    }
  }

  backend "s3" {
    bucket       = var.backend_bucket
    key          = var.backend_key
    region       = var.backend_region
    use_lockfile = true
  }
}
