provider "azurerm" {
  features {
    storage {
      # The storage firewall denies the pipeline's network, so skip data-plane calls.
      data_plane_available = false
    }
  }

  # The pipeline identities can only touch one resource group, so they are not allowed to
  # register Azure resource providers. Registration was done once, by an admin.
  resource_provider_registrations = "none"
}
