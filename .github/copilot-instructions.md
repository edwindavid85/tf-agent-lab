# Instructions for Copilot in this repository

<!--
Owner: @edwindavid85
Last reviewed: 2026-11-28
Review rule: update in the same PR whenever a convention below changes.
-->

## What this repo is
Azure infrastructure in Terraform (`terraform/`), deployed by GitHub Actions:
`terraform-plan` on every pull request (read-only identity) and `terraform-apply` from `main`
after a person approves the `azure` environment.

## Conventions
- Resources go in the existing resource group `var.resource_group_name`; never create resource groups.
- Every resource gets `tags = local.tags`.
- Storage accounts: HTTPS only, TLS 1.2, no public blobs, no shared keys, network default Deny,
  and `lifecycle { prevent_destroy = true }`.
- Run `terraform fmt -recursive` and `terraform validate` before you finish.
- Never run `terraform plan` or `apply`, never edit the backend block, never add role assignments.
