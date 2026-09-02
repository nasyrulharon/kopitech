# Kopitech — kopitech.my

Teaser site for Kopitech: real price tracking for adventure and travel tech in Malaysia.

Static site (`site/`) served by nginx in Docker. GitHub Actions builds the image and pushes it to Docker Hub; Watchtower on the VPS pulls and redeploys it automatically. Caddy terminates HTTPS for `kopitech.my`.

```
push to main ──▶ GitHub Actions ──▶ Docker Hub (<user>/kopitech:latest) ──▶ Watchtower on VPS ──▶ live
```

## Repo layout

```
site/                 the website (index.html, assets, vendored three.js)
nginx.conf            nginx server config used inside the image
Dockerfile            nginx:alpine + site
docker-compose.yml    production stack: kopitech + caddy + watchtower
Caddyfile             HTTPS + www redirect for kopitech.my
.github/workflows/    build & push to Docker Hub on every push to main
```

## One-time setup

### 1. GitHub secrets

In the repo: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Value |
|---|---|
| `DOCKERHUB_USERNAME` | your Docker Hub username |
| `DOCKERHUB_TOKEN` | a Docker Hub access token (Account settings → Personal access tokens, **Read & Write**) |

Create the `kopitech` repository on Docker Hub first (public is fine), or let the first push create it.

### 2. DNS (kopitech.my)

At your registrar / Exabytes DNS, point the domain at the VPS:

| Type | Name | Value |
|---|---|---|
| A | `@` | `<VPS IPv4>` |
| A | `www` | `<VPS IPv4>` |

Caddy will not be able to get a certificate until these resolve. Check with `dig +short kopitech.my`.

### 3. VPS (Exabytes, Ubuntu/Debian)

```bash
# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

# Firewall: only 22, 80, 443
sudo ufw allow OpenSSH && sudo ufw allow 80 && sudo ufw allow 443 && sudo ufw enable

# Deploy files
mkdir -p ~/kopitech && cd ~/kopitech
curl -fsSLO https://raw.githubusercontent.com/nasyrulharon/kopitech/main/docker-compose.yml
curl -fsSLO https://raw.githubusercontent.com/nasyrulharon/kopitech/main/Caddyfile
echo "DOCKERHUB_USERNAME=<your docker hub username>" > .env

docker compose pull
docker compose up -d
docker compose ps
```

Within a minute `https://kopitech.my` should be live with a valid certificate.

## Day-to-day

Edit anything in `site/`, commit, push to `main`. About 2–4 minutes later:

1. GitHub Actions builds the image (amd64 + arm64) and pushes `:latest` and `:sha-xxxxxxx`.
2. Watchtower (polling every 120 s) sees the new digest, pulls it, and restarts `kopitech` with zero config changes.

Check it landed:

```bash
docker compose logs -f watchtower     # "Found new image" → "Stopping" → "Started"
docker inspect kopitech --format '{{.Image}}'
curl -sI https://kopitech.my | head -1
```

Roll back to a specific build:

```bash
docker compose pull kopitech
docker run -d --rm --name kopitech --network kopitech_web <user>/kopitech:sha-abc1234
```

## Local preview

```bash
docker build -t kopitech:local .
docker run --rm -p 8080:80 kopitech:local
# open http://localhost:8080
```

## Notes

- Fonts load from Google Fonts at runtime; three.js is vendored in `site/vendor/` so the 3D hero has no CDN dependency.
- `/healthz` returns `200 ok` — used by the Docker healthcheck.
- HTML is served with `Cache-Control: no-cache` so a new deploy is visible immediately; static assets cache for 30 days.
- The three channel links in the footer are placeholders (`href="#"`) until the TikTok / Telegram / WhatsApp channels exist.
