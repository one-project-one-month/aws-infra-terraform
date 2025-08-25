data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}


# for provider 
data "aws_eks_cluster_auth" "eks" {
  name = var.eks_cluster_name
}
