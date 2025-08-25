# look up form cluster for refrencing irsa role provision 
data "aws_iam_openid_connect_provider" "eks" {
  arn = var.cluster_oidc_url
}
