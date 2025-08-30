provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes = {
    config_path = null # Disable loading from local config path
  }

}


provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}




