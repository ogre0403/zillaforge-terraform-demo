variable "api_endpoint" {
  description = "API endpoint to use with the provider"
  type        = string
  default     = "https://api.trusted-cloud.nchc.org.tw"
}

variable "api_key" {
  description = "API key for zillaforge provider"
  type        = string
  default     = ""
}

variable "project_sys_code" {
  description = "Project system code to use with the provider"
  type        = string
  default     = ""
}

variable "keypair_name" {
  description = "Name of the SSH keypair to inject into the server"
  type        = string
  default     = ""
}

variable "sg_name" {
  description = "Name of the security group to attach to the server"
  type        = string
  default     = ""
}

variable "total" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}