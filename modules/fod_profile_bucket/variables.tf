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
