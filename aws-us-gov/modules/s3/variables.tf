variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "bucket_policy" {
  description = "The JSON policy to attach to the S3 bucket"
  type        = string
}
