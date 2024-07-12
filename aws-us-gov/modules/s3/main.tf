resource "aws_s3_bucket" "pt-lab-bucket-00" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "pt-lab-bucket-00" {
  bucket = aws_s3_bucket.pt-lab-bucket-00.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.pt-lab-bucket-00.id
  policy = var.bucket_policy
}
