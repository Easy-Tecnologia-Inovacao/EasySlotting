#!/usr/bin/env bash
set -euo pipefail
# Run INSIDE the Linux VM. Uses its LAN IPv4 address (no URL or port).
host="${1:-}"
if [[ ! "$host" =~ ^((0|[1-9][0-9]{0,2})\.){3}(0|[1-9][0-9]{0,2})$ ]]; then
  echo "Usage: bash scripts/prepare-staging.sh LINUX_VM_LAN_IPV4" >&2
  exit 1
fi
IFS=. read -r a b c d <<< "$host"
for octet in "$a" "$b" "$c" "$d"; do
  if (( 10#$octet > 255 )); then
    echo "Invalid IPv4 address." >&2
    exit 1
  fi
done
if [[ "$a" == 0 || "$a" == 127 ]] || (( 10#$a >= 224 )); then
  echo "Use the VM's unicast LAN IPv4 address, not loopback or multicast." >&2
  exit 1
fi
command -v openssl >/dev/null || { echo "Install openssl first." >&2; exit 1; }
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target="$project_root/backend/.env.staging"
if [[ -e "$target" || -L "$target" ]]; then
  echo "backend/.env.staging already exists; preserved without changes." >&2
  echo "For an existing installation, edit STAGING_HOST, STAGING_BIND_ADDRESS," >&2
  echo "FRONTEND_URL, API_URL, ALLOWED_HOSTS and ALLOWED_ORIGINS together." >&2
  exit 1
fi
umask 077
db_password="$(openssl rand -hex 32)"
rails_secret="$(openssl rand -hex 64)"
access_secret="$(openssl rand -hex 64)"
refresh_secret="$(openssl rand -hex 64)"
admin_password="$(openssl rand -hex 24)Aa9!"
# noclobber prevents replacing a file created concurrently.
set -C
sed \
  -e "s/^STAGING_HOST=.*/STAGING_HOST=$host/" \
  -e "s/^STAGING_BIND_ADDRESS=.*/STAGING_BIND_ADDRESS=$host/" \
  -e "s|https://localhost:8443|https://$host:8443|g" \
  -e "s/^ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$host/" \
  -e "s/^DB_PASSWORD=.*/DB_PASSWORD=$db_password/" \
  -e "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$rails_secret/" \
  -e "s/^CUSTOMER_JWT_SECRET=.*/CUSTOMER_JWT_SECRET=$access_secret/" \
  -e "s/^CUSTOMER_JWT_REFRESH_SECRET=.*/CUSTOMER_JWT_REFRESH_SECRET=$refresh_secret/" \
  -e "s/^BOOTSTRAP_ADMIN_PASSWORD=.*/BOOTSTRAP_ADMIN_PASSWORD=$admin_password/" \
  "$project_root/backend/.env.staging.example" > "$target"
chmod 600 "$target"
echo "Created private backend/.env.staging (mode 600). No credentials printed."
echo "Staging address: https://$host:8443"
echo "Run Docker Compose as described in docs/staging-local.md."
