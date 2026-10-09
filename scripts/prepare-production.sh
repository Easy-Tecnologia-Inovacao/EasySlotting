#!/usr/bin/env bash
set -euo pipefail
domain="${1:-}"
email="${2:-}"
if (( ${#domain} > 253 )) || [[ ! "$domain" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$ ]]; then
  echo "Usage: bash scripts/prepare-production.sh app.yourdomain.com admin@yourdomain.com" >&2
  exit 1
fi
if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo "Provide a valid administrator/certificate contact email." >&2
  exit 1
fi
command -v openssl >/dev/null || { echo "Install openssl first." >&2; exit 1; }
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target="$project_root/backend/.env.production"
if [[ -e "$target" || -L "$target" ]]; then
  echo "backend/.env.production already exists; preserved without changes." >&2
  exit 1
fi
umask 077
db_password="$(openssl rand -hex 32)"
rails_secret="$(openssl rand -hex 64)"
access_secret="$(openssl rand -hex 64)"
refresh_secret="$(openssl rand -hex 64)"
admin_password="$(openssl rand -hex 24)Aa9!"
set -C
sed \
  -e "s/^APP_DOMAIN=.*/APP_DOMAIN=$domain/" \
  -e "s/^ACME_EMAIL=.*/ACME_EMAIL=$email/" \
  -e "s|^FRONTEND_URL=.*|FRONTEND_URL=https://$domain|" \
  -e "s|^API_URL=.*|API_URL=https://$domain|" \
  -e "s/^ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$domain/" \
  -e "s|^ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=https://$domain|" \
  -e "s/^DB_PASSWORD=.*/DB_PASSWORD=$db_password/" \
  -e "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$rails_secret/" \
  -e "s/^CUSTOMER_JWT_SECRET=.*/CUSTOMER_JWT_SECRET=$access_secret/" \
  -e "s/^CUSTOMER_JWT_REFRESH_SECRET=.*/CUSTOMER_JWT_REFRESH_SECRET=$refresh_secret/" \
  -e "s/^BOOTSTRAP_ADMIN_EMAIL=.*/BOOTSTRAP_ADMIN_EMAIL=$email/" \
  -e "s/^BOOTSTRAP_ADMIN_PASSWORD=.*/BOOTSTRAP_ADMIN_PASSWORD=$admin_password/" \
  "$project_root/backend/.env.production.example" > "$target"
chmod 600 "$target"
echo "Created private backend/.env.production (mode 600). No credentials printed."
echo "Complete SMTP/remitente configuration BEFORE deployment. See docs/hostinger-vps.md."
