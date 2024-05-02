terraform {
   required_version = ">= 0.12"
   required_providers {
      azurerm = ">2.5"
   }
}

provider "azurerm" {
   
   features {}
}
variable "location" {
   type = string
   description = "Region"
   default = "francecenral"
}
