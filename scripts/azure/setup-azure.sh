#!/usr/bin/env bash
# Prep lab 3: one-time Azure setup for passwordless (OIDC) Terraform deploys from GitHub Actions.
# Run in Git Bash after `az login`, as someone who can create app registrations and assign roles.
#
#   bash setup-azure.sh <owner>/<repo> [location]
#
# Creates two resource groups, a state storage account, two app registrations (plan and apply)
# with GitHub federated credentials, and the narrowest role assignments that work.
# Safe to re-run: existing app registrations and federated credentials are reused.
set -euo pipefail
shopt -s inherit_errexit   # make failures inside $(...) stop the script too
# Git Bash on Windows rewrites arguments that start with "/" into Windows paths, which turns an
# Azure scope like /subscriptions/... into C:/Program Files/Git/subscriptions/... Switch that off.
export MSYS_NO_PATHCONV=1
REPO="${1:?usage: setup-azure.sh owner/repo [location]}"
LOCATION="${2:-australiaeast}"
LAB_RG="rg-gh600-lab"
STATE_RG="rg-gh600-tfstate"

SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
STATE_SA="sttfstate$(printf '%s' "$SUB_ID" | md5sum | cut -c1-8)"

echo "== 1. Resource providers (an admin does this once, so the pipeline never needs to)"
for ns in Microsoft.Storage Microsoft.Network; do
  az provider register --namespace "$ns" --wait -o none
  echo "$ns: $(az provider show --namespace "$ns" --query registrationState -o tsv)"
done

echo "== 2. Resource groups"
az group create -n "$STATE_RG" -l "$LOCATION" -o none && echo "$STATE_RG created"
az group create -n "$LAB_RG" -l "$LOCATION" -o none && echo "$LAB_RG created"

echo "== 3. Remote state storage (Entra ID only, no keys, no public blobs)"
az storage account create -n "$STATE_SA" -g "$STATE_RG" -l "$LOCATION" --sku Standard_LRS \
  --min-tls-version TLS1_2 --https-only true --allow-blob-public-access false \
  --allow-shared-key-access false -o none
az storage container-rm create --storage-account "$STATE_SA" -n tfstate -o none
echo "$STATE_SA/tfstate created"
STATE_SCOPE="$(az storage account show -n "$STATE_SA" -g "$STATE_RG" --query id -o tsv)/blobServices/default/containers/tfstate"
LAB_SCOPE=$(az group show -n "$LAB_RG" --query id -o tsv)

make_identity() {  # name, federated subject, workload role, state role
  local app sp
  app=$(az ad app list --display-name "$1" --query "[0].appId" -o tsv)
  if [ -z "$app" ]; then
    app=$(az ad app create --display-name "$1" --query appId -o tsv)
  else
    echo "$1: app registration already exists, reusing it" >&2
  fi
  sp=$(az ad sp show --id "$app" --query id -o tsv 2>/dev/null || az ad sp create --id "$app" --query id -o tsv)
  if [ -z "$(az ad app federated-credential list --id "$app" --query "[?subject=='$2'].name" -o tsv)" ]; then
    az ad app federated-credential create --id "$app" -o none --parameters "{
      \"name\": \"github-$(echo "$2" | tr ':/' '--')\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"$2\",
      \"audiences\": [\"api://AzureADTokenExchange\"]}"
  fi
  az role assignment create --assignee-object-id "$sp" --assignee-principal-type ServicePrincipal \
    --role "$3" --scope "$LAB_SCOPE" -o none
  az role assignment create --assignee-object-id "$sp" --assignee-principal-type ServicePrincipal \
    --role "$4" --scope "$STATE_SCOPE" -o none
  echo "$1: trusted for '$2'; '$3' on $LAB_RG; '$4' on the state container" >&2
  echo "$app"
}

echo "== 4. Identities: one that can only read, one that can deploy"
PLAN_ID=$(make_identity "gh-tf-agent-lab-plan" "repo:$REPO:pull_request" "Reader" "Storage Blob Data Reader")
APPLY_ID=$(make_identity "gh-tf-agent-lab-apply" "repo:$REPO:environment:azure" "Contributor" "Storage Blob Data Contributor")

echo "== 5. Values for GitHub repository variables (IDs, not secrets)"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUB_ID"
echo "AZURE_CLIENT_ID_PLAN=$PLAN_ID"
echo "AZURE_CLIENT_ID_APPLY=$APPLY_ID"
echo "TFSTATE_RG=$STATE_RG"
echo "TFSTATE_SA=$STATE_SA"
