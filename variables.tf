variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "lambda_zip_file" {
  description = "Path to the Lambda function zip file"
  type        = string
  default     = "lambda_function.zip"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "The Lambda function name"
  type        = string
  default     = "github_webhook_lambda"
}

variable "stage" {
  description = "Stage name to run on"
  type        = string
  default     = "prod"
}

variable "github_visibility" {
  description = "Defines the GitHub repository visibility parameter"
  type        = string
  default     = "private"
}

variable "is_webhook_active" {
  description = "Defines whether or not to set the webhook to be active"
  type        = bool
  default     = true
}
