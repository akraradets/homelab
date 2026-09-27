#!/usr/bin/env bash
# ==============================================================================
# Homelab Credential Bootstrap Script
#
# Fetches all credentials and API tokens from Google Cloud (Project: sinsamersuk)
# and populates git-ignored local credential files for Terraform:
# 1. terraform/gcp/credentials.json (GCP Service Account Key)
# 2. terraform/proxmox/terraform.tfvars (Proxmox API Token from Secret Manager)
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ID="sinsamersuk"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}=== Homelab Credential Bootstrap ===${NC}"

# 1. Check gcloud CLI
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# 2. Verify gcloud authentication
if ! gcloud auth print-access-token >/dev/null 2>&1; then
    echo -e "${YELLOW}Not authenticated with gcloud. Launching login...${NC}"
    gcloud auth login
fi

gcloud config set project "$PROJECT_ID" >/dev/null 2>&1

# 3. Service Account Key for terraform/gcp
GCP_CREDS="$REPO_ROOT/terraform/gcp/credentials.json"
if [ ! -f "$GCP_CREDS" ]; then
    echo -e "${BLUE}-> Generating GCP Service Account key for terraform/gcp...${NC}"
    gcloud iam service-accounts keys create "$GCP_CREDS" \
        --iam-account="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com" \
        --project="$PROJECT_ID"
    chmod 600 "$GCP_CREDS"
    echo -e "${GREEN}✓ Created $GCP_CREDS${NC}"
else
    echo -e "${GREEN}✓ GCP Service Account credentials already exist: $GCP_CREDS${NC}"
fi

# 4. Proxmox API Token from Secret Manager for terraform/proxmox
PROXMOX_TFVARS="$REPO_ROOT/terraform/proxmox/terraform.tfvars"
echo -e "${BLUE}-> Fetching Proxmox API token from GCP Secret Manager...${NC}"
PVE_TOKEN=$(gcloud secrets versions access latest --secret=pve-api-token --project="$PROJECT_ID")

cat <<EOF > "$PROXMOX_TFVARS"
# ==============================================================================
# Proxmox Terraform Variables (DO NOT COMMIT)
# Generated automatically by scripts/bootstrap.sh from GCP Secret Manager
# ==============================================================================
proxmox_api_token = "$PVE_TOKEN"
EOF

chmod 600 "$PROXMOX_TFVARS"
echo -e "${GREEN}✓ Generated $PROXMOX_TFVARS${NC}"

echo ""
echo -e "${GREEN}=== Bootstrap Successful! ===${NC}"
echo -e "You can now run standard Terraform commands without inline secret flags:"
echo -e "  cd terraform/gcp && terraform plan"
echo -e "  cd terraform/proxmox && terraform plan"
