# Deployment Guide

This guide covers deploying FutsalApp (FastAPI backend + Next.js frontend) to a production server using Docker Compose, with a GitHub Actions CI/CD pipeline.

## Architecture Overview

```
Internet → Nginx (reverse proxy)
              ├── :80/:443 → Next.js (port 3000)
              └── /api/*   → FastAPI  (port 8000)
                               ├── PostgreSQL (port 5432)
                               ├── Redis      (port 6379)
                               ├── Celery Worker
                               └── Celery Beat
```

---

## 1. Server Setup (Ubuntu/Debian)

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

# Install Docker Compose plugin
sudo apt-get install docker-compose-plugin -y
docker compose version

# Install Nginx (for SSL termination)
sudo apt-get install nginx certbot python3-certbot-nginx -y
```

---

## 2. Repository Secrets (GitHub Actions)

Navigate to **Settings → Secrets and variables → Actions** and add:

| Secret | Description |
|--------|-------------|
| `DO_HOST` | Server IP address |
| `DO_USERNAME` | SSH username (e.g., `deploy`) |
| `DO_SSH_PRIVATE_KEY` | Private SSH key for server access |
| `BACKEND_ENV` | Full contents of backend `.env` |
| `FRONTEND_ENV` | Full contents of frontend `.env.local` |

---

## 3. Docker Compose (`backend/docker-compose.yml`)

```yaml
version: "3.9"
services:
  db:
    image: postgres:16-alpine
    restart: always
    env_file: .env
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    restart: always

  api:
    build: .
    restart: always
    env_file: .env
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis
    command: uvicorn src.main:app --host 0.0.0.0 --port 8000

  celery-worker:
    build: .
    restart: always
    env_file: .env
    depends_on:
      - redis
      - db
    command: celery -A src.apps.core.celery_app worker --loglevel=info --concurrency=4

  celery-beat:
    build: .
    restart: always
    env_file: .env
    depends_on:
      - redis
      - db
    command: celery -A src.apps.core.celery_app beat --loglevel=info

volumes:
  postgres_data:
```

---

## 4. CI/CD Workflow

The workflow at `.github/workflows/ci-cd.yaml` runs on every push to `main`:

1. **Build & lint** — type check, import verification
2. **SSH deploy** — copy new files to server
3. **Migrate** — `docker compose exec api alembic upgrade head`
4. **Restart** — `docker compose up -d --build`

### Sample Workflow

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Write env files
        run: |
          echo "${{ secrets.BACKEND_ENV }}" > backend/.env
          echo "${{ secrets.FRONTEND_ENV }}" > frontend/.env.local

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.DO_HOST }}
          username: ${{ secrets.DO_USERNAME }}
          key: ${{ secrets.DO_SSH_PRIVATE_KEY }}
          script: |
            cd ~/futsalapp
            git pull origin main
            docker compose up -d --build
            docker compose exec api alembic upgrade head
```

---

## 5. Nginx Configuration

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # Next.js frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # FastAPI backend
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # WebSocket
    location /api/v1/ws/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Obtain SSL certificate:
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

---

## 6. Production Environment Variables

Key variables to set in `.env` for production:

```env
DEBUG=False
SECRET_KEY=<random 64-char string>
DATABASE_URL=postgresql+asyncpg://user:pass@db:5432/futsalapp
REDIS_URL=redis://redis:6379/0
ALLOWED_HOSTS=yourdomain.com,api.yourdomain.com

# Payout
PAYOUT_MODE=PLATFORM
PLATFORM_KHALTI_SECRET_KEY=<live key>

# Analytics
POSTHOG_ENABLED=true
POSTHOG_API_KEY=phc_xxxx

# Email
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_HOST_USER=apikey
EMAIL_HOST_PASSWORD=<sendgrid api key>
```

---

## 7. Manual Deployment

```bash
# On the server
git clone https://github.com/your-username/Futsal.git ~/futsalapp
cd ~/futsalapp/backend
cp .env.example .env && nano .env   # fill in production values
docker compose up -d --build
docker compose exec api alembic upgrade head
```

---

## 8. Monitoring & Troubleshooting

```bash
# View all service logs
docker compose logs -f

# View specific service
docker compose logs -f api
docker compose logs -f celery-worker

# Restart a single service
docker compose restart api

# Check running containers
docker compose ps

# Shell into the API container
docker compose exec api bash
```

**Common issues:**

| Problem | Fix |
|---------|-----|
| `alembic upgrade head` fails | Check `DATABASE_URL` in `.env`; ensure `db` container is healthy |
| Celery tasks not running | Verify `REDIS_URL`; check `celery-beat` container logs |
| 502 Bad Gateway | Nginx config pointing to wrong port; check `docker compose ps` |
| `subscription_required` errors | Owner needs active subscription; check `owner_subscriptions` table |
| Payout job not running | Check `celery-beat` logs at 00:00 UTC; verify `PAYOUT_MODE` |


To deploy the application manually, you can follow these steps:

1.  **Generate the Docker Compose file:**

    ```bash
    cd FutsalApi/FutsalApi.AppHost
    aspirate generate --output-format compose --output-path ../../publish
    ```

2.  **Copy the `docker-compose.yml` file to your server.**

3.  **SSH into your server and run the following command:**

    ```bash
    docker-compose up -d
    ```
