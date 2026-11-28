# tf-agent-lab

Azure infrastructure in Terraform, run through GitHub Actions. Used by the GH-600 prep course.

- `terraform/`: a virtual network, a subnet and a storage account, inside one existing resource group
- `.github/workflows/terraform-ci.yml`: format, validate, lint and security-scan every change
- `docs/azure-pipelines-equivalent.yml`: the same checks as an Azure DevOps pipeline, for comparison

This repository contains no secrets and must never contain any.
- Owner: platform team
