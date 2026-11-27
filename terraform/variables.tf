variable "resource_group_name" {
  description = "Existing resource group the pipeline is allowed to manage."
  type        = string
  default     = "rg-gh600-lab"
}

variable "name_prefix" {
  description = "Short, lowercase prefix for resource names."
  type        = string
  default     = "gh600lab"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.name_prefix))
    error_message = "name_prefix must be 3-10 lowercase letters or digits."
  }
}
