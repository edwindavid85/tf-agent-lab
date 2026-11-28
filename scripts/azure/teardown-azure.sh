#!/usr/bin/env bash
# Remove everything setup-azure.sh created. Run in Git Bash after `az login`.
set -euo pipefail
for name in gh-tf-agent-lab-plan gh-tf-agent-lab-apply; do
  for app in $(az ad app list --display-name "$name" --query "[].appId" -o tsv); do
    az ad app delete --id "$app" && echo "deleted app registration $name"
  done
done
for rg in rg-gh600-lab rg-gh600-tfstate; do
  az group delete -n "$rg" --yes --no-wait && echo "deleting resource group $rg"
done
