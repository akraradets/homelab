#!/usr/bin/env bash
# ==============================================================================
# TrueNAS SCALE ACME DNS-01 Shell Authenticator for Google Cloud DNS
#
# Invoked by TrueNAS SCALE's Shell ACME Authenticator during certificate orders:
#   $0 set <domain> <fqdn> <token>
#   $0 unset <domain> <fqdn> <token>
#
# Requirements on TrueNAS host: bash, curl, openssl, python3 (all pre-installed)
# Zero external packages (no gcloud SDK, no pip, no jq required).
# ==============================================================================
set -euo pipefail

ACTION="${1:-}"
DOMAIN="${2:-}"
FQDN="${3:-}"
TOKEN="${4:-}"

if [ -z "$ACTION" ] || [ -z "$DOMAIN" ] || [ -z "$FQDN" ] || [ -z "$TOKEN" ]; then
    echo "Usage: $0 <set|unset> <domain> <fqdn> <token>" >&2
    exit 1
fi

# Ensure trailing dot on FQDN for Google Cloud DNS
FQDN_DOT="${FQDN%.}."

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SA_JSON="${SCRIPT_DIR}/gcp-sa.json"
PROJECT_ID="sinsamersuk"
ZONE_NAME="sinsamersuk-net"

if [ ! -f "$SA_JSON" ]; then
    echo "Error: Google Cloud Service Account key not found at $SA_JSON" >&2
    exit 1
fi

# Extract credentials using Python (built-in standard library)
CLIENT_EMAIL=$(python3 -c "import json; print(json.load(open('$SA_JSON'))['client_email'])")
PRIVATE_KEY_FILE=$(mktemp)
python3 -c "import json; print(json.load(open('$SA_JSON'))['private_key'])" > "$PRIVATE_KEY_FILE"
trap 'rm -f "$PRIVATE_KEY_FILE"' EXIT

# Generate Signed JWT for Google Cloud OAuth2
HEADER_B64=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')
NOW=$(date +%s)
EXP=$((NOW + 3600))
CLAIMS="{\"iss\":\"$CLIENT_EMAIL\",\"scope\":\"https://www.googleapis.com/auth/ndev.clouddns.readwrite\",\"aud\":\"https://oauth2.googleapis.com/token\",\"exp\":$EXP,\"iat\":$NOW}"
CLAIMS_B64=$(echo -n "$CLAIMS" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

SIGNATURE=$(echo -n "${HEADER_B64}.${CLAIMS_B64}" | openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')
JWT="${HEADER_B64}.${CLAIMS_B64}.${SIGNATURE}"

# Fetch Access Token from Google OAuth2 endpoint
OAUTH_RESP=$(curl -s -X POST https://oauth2.googleapis.com/token \
    -d "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
    -d "assertion=${JWT}")

ACCESS_TOKEN=$(echo "$OAUTH_RESP" | python3 -c "import json, sys; print(json.load(sys.stdin)['access_token'])")

DNS_ENDPOINT="https://dns.googleapis.com/dns/v1/projects/${PROJECT_ID}/managedZones/${ZONE_NAME}/changes"

if [ "$ACTION" = "set" ]; then
    echo "Adding ACME DNS-01 TXT record for $FQDN_DOT..."
    BODY=$(python3 -c "import json; print(json.dumps({'additions': [{'name': '$FQDN_DOT', 'type': 'TXT', 'ttl': 60, 'rrdatas': ['\"$TOKEN\"']}]}))")
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$BODY" \
        "$DNS_ENDPOINT")
    if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
        echo "Failed to create TXT record on Google Cloud DNS (HTTP $HTTP_CODE)" >&2
        exit 1
    fi
    echo "Successfully created TXT record on Google Cloud DNS."
elif [ "$ACTION" = "unset" ]; then
    echo "Removing ACME DNS-01 TXT record for $FQDN_DOT..."
    BODY=$(python3 -c "import json; print(json.dumps({'deletions': [{'name': '$FQDN_DOT', 'type': 'TXT', 'ttl': 60, 'rrdatas': ['\"$TOKEN\"']}]}))")
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$BODY" \
        "$DNS_ENDPOINT")
    if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
        echo "Warning: Failed to delete TXT record on Google Cloud DNS (HTTP $HTTP_CODE)" >&2
    fi
    echo "Successfully removed TXT record from Google Cloud DNS."
else
    echo "Unknown action: $ACTION. Expected 'set' or 'unset'." >&2
    exit 1
fi
