#!/bin/bash
# Issue and install the TLS certificate BEFORE the DNS cutover.
#
# The nginx (HTTP-01) challenge cannot be used here: it requires the domain
# to already resolve to this host, which would force the certificate to be
# issued only after traffic has moved — leaving the new origin serving
# without a valid certificate for as long as issuance takes.
#
# DNS-01 against the Cloudflare API has no such dependency, so the origin is
# fully ready for HTTPS before a single request is routed to it.

set -euo pipefail

EMAIL=S_EMAIL
DOMAIN=S_DOMAIN
CF_API=S_CF_API

# Note: no 'apt upgrade' here. A full upgrade mid-deployment added minutes to
# the cutover window and could pull in a kernel update requiring a reboot.
apt update -y
apt install -y certbot python3-certbot-nginx python3-certbot-dns-cloudflare

# Credentials for the DNS-01 challenge. Root-only: the token can edit the zone.
install -d -m 700 /root/.secrets
umask 077
cat > /root/.secrets/cloudflare.ini <<EOF
dns_cloudflare_api_token = ${CF_API}
EOF
chmod 600 /root/.secrets/cloudflare.ini

# Obtain the certificate via DNS-01 — does not require DNS to point here yet.
# --keep-until-expiring avoids burning Let's Encrypt rate limit on redeploys.
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 30 \
  --non-interactive --agree-tos --email "$EMAIL" \
  -d "$DOMAIN" \
  --keep-until-expiring

# Wire the issued certificate into the nginx server block.
certbot install --nginx --cert-name "$DOMAIN" --non-interactive

# Reload only if the config actually validates.
nginx -t && systemctl reload nginx

# Verify the origin is genuinely serving the certificate before the pipeline
# proceeds to the DNS cutover.
echo "Verifying TLS on the local origin..."
if ! echo | openssl s_client -connect 127.0.0.1:443 -servername "$DOMAIN" 2>/dev/null \
     | openssl x509 -noout -subject > /dev/null 2>&1; then
  echo "ERROR: origin is not serving a certificate for ${DOMAIN} — aborting before cutover"
  exit 1
fi

echo "TLS ready for ${DOMAIN}. Safe to cut DNS over."

# command to test the installation of new certs. You can only install 50 per week per domain.
# certbot renew --dry-run
