
# =====================================================
# Variables
# =====================================================

variable "subscription_id" {
  description = "Azure Subscription ID. Set via TF_VAR_subscription_id environment variable."
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "australiaeast"
}
