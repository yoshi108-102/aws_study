variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "apigw-minimal"
}

variable "powertools_log_level" {
  description = "AWS Lambda Powertools log level (DEBUG/INFO/WARNING/ERROR)"
  type        = string
  default     = "INFO"
}
