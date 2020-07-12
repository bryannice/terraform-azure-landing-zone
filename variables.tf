variable "subscription_owner" {
  type        = string
  default     = ""
  description = "Owner of the subscription. "
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "The name of the resource group in which to create the storage account. Changing this forces a new resource to be created."
}

variable "location" {
  type        = string
  default     = ""
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

variable "storage_account_name" {
  type        = string
  default     = ""
  description = "Specifies the name of the storage account. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group."
}

variable "terraform_version" {
  type        = string
  default     = ""
  description = "This specifies the earliest version that the module is compatible with."
}