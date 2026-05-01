variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "me-central2"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}