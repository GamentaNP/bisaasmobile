# Backend deployment runbook — bisaas (Laravel) to a fresh Ubuntu VPS

This is the critical path of the launch: **no tester can get past login until
this server exists.** Copy-paste order matters. Written against the actual
stack of `C:\laragon\www\bisaas` (Laravel ~13.34, PHP ^8.3, PostgreSQL,
Passport PATs, kreait Firebase, many scheduled jobs).

Time: ~2–3 hours first run. Requires: a VPS (2 vCPU / 4 GB is enough to
start), a domain you own pointed at it, and the bisaas repo pushed to a git
remote.

---

## 0. DNS

At the registrar: `A` record `@` → server IP, and `A` record `www` → server
IP. Wait until `ping yourdomain.com` answers before continuing.

## 1. Base packages

```bash
ssh root@SERVER_IP
apt update && apt -y upgrade
apt -y install git curl unzip nginx postgresql redis-server ufw
```

## 2. Firewall

```bash
ufw allow OpenSSH && ufw allow 'Nginx Full' && ufw --force enable
```

## 3. PHP 8.3 FPM + extensions

Laragon parity: pdo_pgsql, bcmath, intl, zip, gd, exif, mbstring, xml, curl.

```bash
add-apt-repository -y ppa:ondrej/php && apt update
apt -y install php8.3-fpm php8.3-cli php8.3-pgsql php8.3-redis php8.3-bcmath \
  php8.3-intl php8.3-zip php8.3-gd php8.3-exif php8.3-mbstring php8.3-xml \
  php8.3-curl php8.3-opcache
# opcache on, JIT off (safe default):
cat >/etc/php/8.3/fpm/conf.d/90-app.ini <<'EOF'
opcache.enable=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
memory_limit=512M
EOF
systemctl restart php8.3-fpm
```

Composer:

```bash
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
```

## 4. PostgreSQL

```bash
sudo -u postgres psql <<'SQL'
CREATE USER bisaas WITH PASSWORD 'CHANGE_ME_STRONG';
CREATE DATABASE bisaas OWNER bisaas ENCODING 'UTF8';
SQL
```

## 5. Deploy user + code

```bash
adduser --disabled-password --gecos "" deploy
usermod -aG www-data deploy
mkdir -p /var/www/bisaas && chown deploy:www-data /var/www/bisaas
sudo -iu deploy
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519   # add the .pub as a read key (or deploy key) on the git host
git clone GIT_REMOTE /var/www/bisaas/current && cd /var/www/bisaas/current
```

```bash
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate
```

Edit `.env` (the mobile-critical keys):

```ini
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com          # the client pins and deep-links against this host
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_DATABASE=bisaas
DB_USERNAME=bisaas
DB_PASSWORD=CHANGE_ME_STRONG
QUEUE_CONNECTION=database               # valid default; move to redis later if needed
CACHE_STORE=database                    # or redis
FILESYSTEM_DISK=local
FIREBASE_CREDENTIALS=/var/www/secrets/firebase-service-account.json
SANCTUM_STATEFUL_DOMAINS=yourdomain.com
SESSION_DOMAIN=.yourdomain.com
# AI provider keys (tutor / calculator) — set the ones the operator chose
# Mail (Mailersend driver is in composer.json)
MAIL_MAILER=mailersend
```

## 6. Firebase service account (server-side push sending)

The client registers FCM tokens (`POST /api/v1/device-tokens`), but **the
server needs credentials to send**. Firebase console → Project settings →
Service accounts → Generate new private key, upload it:

```bash
mkdir -p /var/www/secrets
# scp the json up, then:
chown deploy:deploy /var/www/secrets/firebase-service-account.json && chmod 600 /var/www/secrets/firebase-service-account.json
```

Use the same Firebase project as the app (`bisaas-realtime-123` per
`android/app/google-services.json`).

## 7. Migrate, seed, passport

```bash
php artisan migrate --force
php artisan db:seed --force            # operator decides which seeders; content seeds are big
php artisan passport:keys              # RSA keys for the bearer PATs the mobile app uses
php artisan storage:link               # spatie media-library file URLs
php artisan config:cache && php artisan route:cache && php artisan event:cache
```

## 8. Queue worker + scheduler (systemd)

The scheduler carries ~15 jobs including every-5-minute ones — without it the
economy and AI rollups stop.

```bash
sudo tee /etc/systemd/system/bisaas-queue.service >/dev/null <<'EOF'
[Unit]
Description=bisaas queue worker
After=network.target postgresql.service
[Service]
User=deploy
Restart=always
RestartSec=3
WorkingDirectory=/var/www/bisaas/current
ExecStart=/usr/bin/php /var/www/bisaas/current/artisan queue:work --sleep=1 --tries=3 --max-time=3600
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload && sudo systemctl enable --now bisaas-queue
```

Scheduler — root cron (Laravel's canonical entry):

```bash
sudo crontab -e
# add:
* * * * * cd /var/www/bisaas/current && php artisan schedule:run >> /dev/null 2>&1
```

## 9. Nginx

```bash
sudo tee /etc/nginx/sites-available/bisaas >/dev/null <<'EOF'
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    root /var/www/bisaas/current/public;
    index index.php;
    client_max_body_size 64m;

    location /.well-known/assetlinks.json {
        default_type application/json;
        try_files /assetlinks.json =404;   # put the file in public/.well-known/ — see §11
    }

    location / { try_files $uri $uri/ /index.php?$query_string; }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }
    location ~ /\.(?!well-known) { deny all; }
}
EOF
sudo ln -s /etc/nginx/sites-available/bisaas /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

## 10. TLS

```bash
apt -y install certbot python3-certbot-nginx
certbot --nginx -d yourdomain.com -d www.yourdomain.com --redirect
```

## 11. Android App Links verification (deep links)

`civilcal://` works without this; `https://yourdomain.com` deep links need
the verified statement. Build `assetlinks.json` from the app's signing cert:

```bash
keytool -list -printcert -jarfile app-release.aab    # on the Windows machine
```

Take the SHA-256 of the upload key, then in the bisaas repo create
`public/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.bisaas.bisaasmobile",
    "sha256_cert_fingerprints": ["PASTE_UPLOAD_KEY_SHA256"]
  }
}]
```

Deploy it with the backend and verify:

```bash
curl -s https://yourdomain.com/.well-known/assetlinks.json | python3 -m json.tool
```

## 12. Post-deploy verification (the mobile contract)

Every check must pass before the client is repointed:

```bash
curl -s https://yourdomain.com/api/v1/app/config | python3 -m json.tool   # envelope JSON, success:true
curl -s https://yourdomain.com/api/v1/openapi.json -o /dev/null -w '%{http_code}\n'   # 200
curl -s -X POST https://yourdomain.com/api/v1/auth/login \
  -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d '{"email":"probe@example.com","password":"wrong"}'    # must be JSON error, NOT HTML/Inertia
```

If the login probe returns HTML, `Accept: application/json` routing or the
Inertia middleware chain is wrong for the API surface — fix before Phase B.

## 13. Backups (spatie/laravel-backup is already in composer)

Configure the destination disk in `.env` (S3 or similar), then add to the
scheduler if not already scheduled, and test one restore. A backup that has
never been restored is a hope, not a backup.

## 14. Not required for mobile day-one

Reverb (websockets — web-only feature), Octane (speed optimization, add
later), Stripe/Cashier (when paid plans ship), Mailersend is only needed for
verification mails — set at least a working mailer.

---

## After the server is live — the client flip (this repo, Phase B)

Four small changes, then hardware QA: see `docs/PLAY_STORE_READINESS.md` §1
steps 4–5. Do not flip `env.dart` until §12 above passes.
