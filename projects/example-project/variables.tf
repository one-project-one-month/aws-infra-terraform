variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
  default     = "opom-test-s3-terraform"
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default = {
    "env" = "testing"
  }
}
