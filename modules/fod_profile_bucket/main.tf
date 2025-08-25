# S3 Bucket
resource "aws_s3_bucket" "fod_profile" {
  bucket = var.bucket_name
}


resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.fod_profile.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# IAM Role for IRSA
resource "aws_iam_role" "irsa_role" {
  name = var.irsa_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn # lookup vlaue from the cluster 
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:food-ordering:myapp-sa"
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "s3_upload_policy" {
  name = var.bucket_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"

        ]
        Resource = [
          "${aws_s3_bucket.fod_profile.arn}",
          "${aws_s3_bucket.fod_profile.arn}/*"
        ]
      }
    ]
  })

}

# service role and policy association 
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.irsa_role.name
  policy_arn = aws_iam_policy.s3_upload_policy.arn
}


# Attached policy directly to bucket cause of fully open to public aceess 
resource "aws_s3_bucket_policy" "fod_profile_policy" {
  bucket = aws_s3_bucket.fod_profile.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.irsa_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.fod_profile.arn}",  # ListBucket
          "${aws_s3_bucket.fod_profile.arn}/*" # objects
        ]
      }
    ]
  })
}
