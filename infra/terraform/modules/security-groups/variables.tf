variable "name_prefix" {
  description = "SG name prefix (e.g., tracker-dev)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where SGs are created."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all SGs."
  type        = map(string)
  default     = {}
}
