variable "prefix" {
  description = "Prefix"
  default = "tuantm22"
}

variable "resourceGroup" {
  description = "Name of resource"
  default     = "Azuredevops"
}

variable "location" {
  description = "Azure Region"
  default = "East US" 
}

variable "username"{  
  default = "username"
}

variable "password"{
  default= "MyPass@123@321"
}

variable "packerImageId" {
  default = "/subscriptions/df56a173-611b-429d-901a-af369d7d59b5/resourceGroups/Azuredevops/providers/Microsoft.Compute/images/myPackerImage"
}

variable "vmCount"{
  default = "2"
}