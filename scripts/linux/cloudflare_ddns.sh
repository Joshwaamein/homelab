#!/bin/bash
# Cloudflare DDNS updater for a single A record.
#
# Reads credentials and target zone from /etc/ddns/cloudflare.env (chmod 600,
# root:root). Updates only when the public IP differs from the existing record.
# Designed to run from cron every 15 minutes.
#
# Usage: cloudflare_ddns.sh
# Exit codes:
#   0 success (updated or unchanged)
#   1 missing config
#   2 cloudflare API failure
#
# Required env in /etc/ddns/cloudflare.env:
#   API_TOKEN=<scoped Cloudflare API token, DNS:Edit on the zone>
#   ZONE_ID=<32-hex Cloudflare zone ID>
#   RECORD_NAME=<fqdn this host should publish, e.g. host1.example.com>

set -euo pipefail

ENV_FILE="${ENV_FILE:-/etc/ddns/cloudflare.env}"

if [[ ! -r "$ENV_FILE" ]]; then
    echo "ERROR: env file not readable at $ENV_FILE" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

: "${API_TOKEN:?API_TOKEN missing in $ENV_FILE}"
: "${ZONE_ID:?ZONE_ID missing in $ENV_FILE}"
: "${RECORD_NAME:?RECORD_NAME missing in $ENV_FILE}"

CURRENT_IP=$(curl -fsS --max-time 10 https://api.ipify.org || true)
if [[ -z "$CURRENT_IP" ]]; then
    echo "ERROR: failed to fetch current public IP from api.ipify.org" >&2
    exit 2
fi

DNS_RECORD=$(curl -fsS \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
    || true)
if [[ -z "$DNS_RECORD" ]]; then
    echo "ERROR: cloudflare API returned no response for record lookup" >&2
    exit 2
fi

EXISTING_IP=$(echo "$DNS_RECORD" | jq -r '.result[0].content // empty')
RECORD_ID=$(echo "$DNS_RECORD" | jq -r '.result[0].id // empty')

if [[ -z "$RECORD_ID" ]]; then
    echo "ERROR: no existing A record for $RECORD_NAME in zone $ZONE_ID" >&2
    exit 2
fi

if [[ "$CURRENT_IP" == "$EXISTING_IP" ]]; then
    echo "$(date -Iseconds) IP unchanged ($CURRENT_IP) for $RECORD_NAME"
    exit 0
fi

curl -fsS -X PUT \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$CURRENT_IP\",\"ttl\":1,\"proxied\":false}" \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    >/dev/null

echo "$(date -Iseconds) Updated $RECORD_NAME: $EXISTING_IP -> $CURRENT_IP"
