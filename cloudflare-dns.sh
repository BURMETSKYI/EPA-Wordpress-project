#!/bin/bash
# docs https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-create-dns-record

# Set the subdomain and IP address for Cloudflare DNS
domain=S_DOMAIN
elastic_ip=S_ELASTIC_IP
# Verify Cloudflare API Token
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer kWedyJSHRiryz53nkYGalTTglK1XkVxW_yjWM3ib" \
     -H "Content-Type:application/json"

# Cloudflare API and Zone Info

CF_API= S_CF_API
CF_ZONE_ID= S_CF_ZONE_ID

# Create the DNS record in Cloudflare
curl --request POST \
  --url https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $CF_API" \
  --data '{
  "content": "'$elastic_ip'",
  "name": "'$domain'",
  "proxied": true,
  "type": "A",
  "comment": "Automatically adding an A record",
  "tags": [],
  "ttl": 3600
}'

# Proceed to install SSL via Certbot
# sudo bash /root/EPA/wordpress-install.sh
