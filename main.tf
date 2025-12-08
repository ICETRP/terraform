# ================================================
# CLEAN Azure VM – works perfectly in Azure DevOps
# ================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # ←←← REMOTE STATE (will be configured by pipeline) ←←←
  backend "azurerm" {
    # empty on purpose – pipeline fills this in
  }
}

# ←←← NO provider block here anymore! Let the service connection do the work ←←←
provider "azurerm" {
  features {}
}