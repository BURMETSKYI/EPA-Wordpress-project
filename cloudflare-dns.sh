#!/bin/bash
# docs https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-create-dns-record

# Set the subdomain and IP addresses for Cloudflare DNS
domain=S_DOMAIN
elastic_ip_new=NEW_ELASTIC_IP
elastic_ip_old=OLD_ELASTIC_IP

# Cloudflare API and Zone Info 
CF_API=S_CF_API
CF_ZONE_ID=S_CF_ZONE_ID

# Verify Cloudflare API Token
echo "Verifying Cloudflare API token..."
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
    -H "Authorization: Bearer $CF_API" \
    -H "Content-Type:application/json"

# Get the DNS record ID for the green IP
echo "Finding DNS record for green IP..."
dns_record_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?content=$elastic_ip_old" \
    -H "Authorization: Bearer $CF_API" \
    -H "Content-Type: application/json" \
    | jq -r '.result[0].id')

# Delete the DNS record if found
if [ ! -z "$dns_record_id" ]; then
   echo "Deleting DNS record with ID: $dns_record_id"
   curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$dns_record_id" \
        -H "Authorization: Bearer $CF_API" \
        -H "Content-Type: application/json"
   echo "DNS record deleted successfully"
fi

# Create new DNS record with blue IP
echo "Creating new DNS record with blue IP..."
curl --request POST \
 --url https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records \
 --header 'Content-Type: application/json' \
 --header "Authorization: Bearer $CF_API" \
 --data '{
   "content": "'$elastic_ip_new'",
   "name": "'$domain'",
   "proxied": true,
   "type": "A",
   "comment": "Automatically adding an A record",
   "tags": [],
   "ttl": 3600
 }'

echo "DNS update completed!"
