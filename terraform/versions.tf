terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.15"
    }
  }

  # Remote state lives in an Azure Storage account. The account details are passed in at
  # `terraform init` time (-backend-config=...), so nothing environment-specific is hard-coded.
  backend "azurerm" {}
}
