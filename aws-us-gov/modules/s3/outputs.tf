output "bucket_name" {
  value = aws_s3_bucket.pt-lab-bucket-00.id
}

output "bucket_arn" {
  value = aws_s3_bucket.pt-lab-bucket-00.arn
}
