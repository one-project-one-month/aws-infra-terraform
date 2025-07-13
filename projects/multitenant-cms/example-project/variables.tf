variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
}

variable "region" {
  description = "AWS region to deploy resources in."
  type        = string
  default     = "ap-southeast-1"
}
variable "backend_bucket" {
  description = "The name of the S3 bucket for the Terraform backend."
  type        = string
}

variable "backend_key" {
  description = "The path within the S3 bucket for the Terraform state file."
  type        = string
}

variable "backend_region" {
  description = "The AWS region for the S3 backend bucket."
  type        = string
  default     = "ap-southeast-1"
}
