terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm"; version = "~> 4.0" }
    tls = { source = "hashicorp/tls"; version = "~> 4.0" }
  }
  backend "azurerm" {}  # Pipeline configures this
}

provider "azurerm" {
  features {}
}

# ... your VM resources unchanged ...