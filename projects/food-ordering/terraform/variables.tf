variable "profile" {
  description = "active profile name form the spring boot application and take as prefiexed"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources in."
  type        = string
  default     = "ap-southeast-1"
}

variable "eks_cluster_name" {
  type = string
}

variable "eks_cluster_auth" {
  type = string
}

//bucket varibale 
variable "bucket_name" {
  type = string
}

variable "cluster_oidc_url" {
  description = "arn:aws:iam::592867232570:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E sample data"
  type        = string

}

variable "irsa_role_name" {
  type = string
}

variable "bucket_policy_name" {
  type = string

}


variable "aws_account_id" {
  description = "User account ID"
  type        = string
}


variable "helm_repository" {
  description = "repo url created for host application helm chart"
  type        = string
}





