variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
  default     = "saa-backup-vault-"
  
}

# variable "prevent_destroy" {
#   description = "Whether to prevent the S3 bucket from being destroyed"
#   type        = bool
#   default     = false
  
# }