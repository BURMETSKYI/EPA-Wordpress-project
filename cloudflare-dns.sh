#!/bin/bash
# Atomic blue/green DNS cutover.
#
# The A record is UPDATED in place (PATCH), never deleted and recreated.
# A delete-then-create sequence leaves the zone with no A record for the
# duration of two API calls — with Cloudflare proxying, visitors hit an
# origin-DNS error for that whole window. PATCH swaps the origin in a
# single operation, so there is no point at which the record is absent.
#
# docs https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-patch-dns-record

set -euo pipefail

# Set the subdomain and IP addresses for Cloudflare DNS
domain=S_DOMAIN
elastic_ip_new=NEW_ELASTIC_IP

# Cloudflare API and Zone Info
CF_API=S_CF_API
CF_ZONE_ID=S_CF_ZONE_ID

CF_BASE="https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records"
AUTH=(-H "Authorization: Bearer ${CF_API}" -H "Content-Type: application/json")

# Verify Cloudflare API token
echo "Verifying Cloudflare API token..."
if ! curl -sf -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" "${AUTH[@]}" \
     | jq -e '.success == true' > /dev/null; then
  echo "ERROR: Cloudflare API token failed verification"
  exit 1
fi

# Find the existing A record by NAME rather than by old IP.
# Looking it up by content breaks whenever the zone has drifted from what
# the pipeline expects; the name is the thing that is actually stable.
echo "Looking up existing A record for ${domain}..."
dns_record_id=$(curl -sf -X GET "${CF_BASE}?type=A&name=${domain}" "${AUTH[@]}" \
    | jq -r '.result[0].id // empty')

if [ -n "$dns_record_id" ]; then
  # ---- Atomic swap: one call, record never disappears ----
  echo "Patching record ${dns_record_id} -> ${elastic_ip_new}"
  response=$(curl -sf -X PATCH "${CF_BASE}/${dns_record_id}" "${AUTH[@]}" \
    --data "$(jq -n --arg ip "$elastic_ip_new" \
      '{content: $ip, comment: "Blue/green cutover"}')")
else
  # First deployment only — no record exists yet, so create one.
  echo "No existing A record found. Creating ${domain} -> ${elastic_ip_new}"
  response=$(curl -sf -X POST "${CF_BASE}" "${AUTH[@]}" \
    --data "$(jq -n --arg ip "$elastic_ip_new" --arg name "$domain" \
      '{content: $ip, name: $name, type: "A", proxied: true, ttl: 1,
        comment: "Created by blue/green pipeline"}')")
fi

if ! echo "$response" | jq -e '.success == true' > /dev/null; then
  echo "ERROR: DNS update failed"
  echo "$response" | jq '.errors'
  exit 1
fi

# Confirm the record now points where we expect before the pipeline moves on.
active_ip=$(echo "$response" | jq -r '.result.content')
if [ "$active_ip" != "$elastic_ip_new" ]; then
  echo "ERROR: record reports ${active_ip}, expected ${elastic_ip_new}"
  exit 1
fi

echo "DNS cutover complete — ${domain} now resolves to ${elastic_ip_new}"
