# 🚀 Production Deployment Guide

**OpenScan Indígenas - Document Digitization System**

**Version:** 3.0.0
**Last Updated:** 2025-10-07
**Audience:** DevOps Engineers, System Administrators

---

## 📋 Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Infrastructure Requirements](#infrastructure-requirements)
3. [Backend Deployment (Paperless-ngx)](#backend-deployment)
4. [Mobile App Build & Release](#mobile-app-build--release)
5. [Security Configuration](#security-configuration)
6. [Database Setup](#database-setup)
7. [Monitoring & Logging](#monitoring--logging)
8. [Backup & Disaster Recovery](#backup--disaster-recovery)
9. [Post-Deployment Validation](#post-deployment-validation)
10. [Troubleshooting](#troubleshooting)

---

## 🔒 Pre-Deployment Checklist

### Critical Items (Must Complete)

- [ ] **Production URLs Configured**
  - Update `lib/core/config/production_config.dart`
  - Set `paperlessProductionUrl` to actual domain
  - Update `supportEmail` with real email address

- [ ] **SSL Certificate Obtained**
  - Purchase or generate Let's Encrypt certificate
  - Install on production server
  - Verify HTTPS working correctly

- [ ] **Certificate Pinning Configured**
  - Run: `./scripts/generate_cert_fingerprint.sh your-domain.com`
  - Add fingerprints to `production_config.dart`
  - Include backup certificate

- [ ] **Security Audit Passed**
  - Review `SECURITY_AUDIT.md`
  - Address all HIGH severity issues
  - Document accepted risks

- [ ] **Testing Completed**
  - All unit tests passing (>90% coverage)
  - Integration tests completed
  - User acceptance testing (UAT) done

- [ ] **Legal Compliance**
  - Privacy policy published
  - Terms of service published
  - Data protection impact assessment completed

### Recommended Items

- [ ] Load testing completed
- [ ] Backup procedures tested
- [ ] Monitoring dashboards configured
- [ ] Team training completed
- [ ] Rollback plan documented

---

## 🏗️ Infrastructure Requirements

### Backend Server (Paperless-ngx)

**Minimum Specifications:**
- **CPU:** 4 cores (8 recommended for OCR)
- **RAM:** 8 GB (16 GB recommended)
- **Storage:** 500 GB SSD (expandable)
- **OS:** Ubuntu 22.04 LTS or Docker container

**Network:**
- **Bandwidth:** 100 Mbps symmetrical
- **Public IP:** Static IP required
- **Ports:** 443 (HTTPS), 80 (HTTP redirect)

**Software Stack:**
- Paperless-ngx v2.0+
- PostgreSQL 15+
- Redis 7+
- Nginx (reverse proxy)
- Docker & Docker Compose (recommended)

### Mobile App Infrastructure

**Play Store:**
- Google Developer Account ($25 one-time)
- App signing key (handled by Google Play)
- Privacy policy URL hosted

**Optional:**
- CDN for static assets (Cloudflare)
- Analytics server (if not using local-only)

### Database Server

**PostgreSQL Configuration:**
```sql
-- Recommended settings for Paperless-ngx
shared_buffers = 2GB
effective_cache_size = 6GB
maintenance_work_mem = 512MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1  # For SSD
effective_io_concurrency = 200
work_mem = 10MB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 4
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
```

---

## 🖥️ Backend Deployment (Paperless-ngx)

### Option 1: Docker Deployment (Recommended)

#### 1. Install Docker

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose -y

# Add user to docker group
sudo usermod -aG docker $USER
```

#### 2. Create Docker Compose Configuration

Create `docker-compose.yml`:

```yaml
version: "3.8"

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    networks:
      - paperless

  # Redis Cache
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - paperless

  # Paperless-ngx Application
  paperless:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    restart: unless-stopped
    depends_on:
      - postgres
      - redis
    ports:
      - "8000:8000"
    volumes:
      - data:/usr/src/paperless/data
      - media:/usr/src/paperless/media
      - export:/usr/src/paperless/export
      - consume:/usr/src/paperless/consume
    environment:
      PAPERLESS_REDIS: redis://redis:6379
      PAPERLESS_DBHOST: postgres
      PAPERLESS_DBNAME: paperless
      PAPERLESS_DBUSER: paperless
      PAPERLESS_DBPASS: ${POSTGRES_PASSWORD}
      PAPERLESS_SECRET_KEY: ${SECRET_KEY}
      PAPERLESS_URL: https://paperless.your-domain.com
      PAPERLESS_OCR_LANGUAGE: spa+eng
      PAPERLESS_TIME_ZONE: America/Bogota
      PAPERLESS_ALLOWED_HOSTS: paperless.your-domain.com
      PAPERLESS_CORS_ALLOWED_HOSTS: https://paperless.your-domain.com
      PAPERLESS_CSRF_TRUSTED_ORIGINS: https://paperless.your-domain.com
      # Security
      PAPERLESS_ENABLE_HTTP_REMOTE_USER: false
      PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME: ''
      # Performance
      PAPERLESS_TASK_WORKERS: 4
      PAPERLESS_THREADS_PER_WORKER: 2
    networks:
      - paperless

volumes:
  pgdata:
  data:
  media:
  export:
  consume:

networks:
  paperless:
    driver: bridge
```

#### 3. Create Environment File

Create `.env`:

```bash
# Generate strong passwords:
# openssl rand -base64 32

POSTGRES_PASSWORD=your_secure_password_here
SECRET_KEY=your_secret_key_here
```

#### 4. Deploy

```bash
# Start services
docker-compose up -d

# Check logs
docker-compose logs -f paperless

# Create superuser
docker-compose exec paperless python3 manage.py createsuperuser
```

### Option 2: Bare Metal Deployment

See [Paperless-ngx Documentation](https://docs.paperless-ngx.com/setup/) for detailed instructions.

---

## 📱 Mobile App Build & Release

### 1. Configure Build Environment

```bash
# Install Flutter (if not already installed)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor

# Get dependencies
flutter pub get
```

### 2. Update Configuration

Edit `lib/core/config/production_config.dart`:

```dart
static const String paperlessProductionUrl = 'https://paperless.your-domain.com';
static const String supportEmail = 'support@your-domain.com';
static const List<String> certificateFingerprints = [
  'sha256/YOUR_CERTIFICATE_FINGERPRINT_HERE',
  'sha256/BACKUP_CERTIFICATE_FINGERPRINT',
];
```

### 3. Generate Certificate Fingerprints

```bash
# Extract from your server
./scripts/generate_cert_fingerprint.sh paperless.your-domain.com

# Copy fingerprints to production_config.dart
```

### 4. Build Release APK

```bash
# Clean previous builds
flutter clean
flutter pub get

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Build app bundle (for Play Store)
flutter build appbundle --release
```

### 5. Sign APK

```bash
# Create keystore (first time only)
keytool -genkey -v -keystore openscan-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias openscan

# Create key.properties
cat > android/key.properties <<EOF
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=openscan
storeFile=../../openscan-release-key.jks
EOF

# Build signed APK
flutter build apk --release --shrink --obfuscate
```

### 6. Upload to Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new application
3. Fill app details, screenshots, descriptions
4. Upload `app-release.aab` from `build/app/outputs/bundle/release/`
5. Complete store listing
6. Submit for review

---

## 🔐 Security Configuration

### SSL/TLS Certificate Setup

#### Option A: Let's Encrypt (Free, Automated)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificate
sudo certbot --nginx -d paperless.your-domain.com

# Auto-renewal (runs twice daily)
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

#### Option B: Commercial Certificate

1. Purchase from certificate authority (DigiCert, Sectigo, etc.)
2. Generate CSR:
   ```bash
   openssl req -new -newkey rsa:2048 -nodes \
     -keyout server.key -out server.csr
   ```
3. Submit CSR to CA
4. Install certificate:
   ```bash
   sudo cp server.crt /etc/ssl/certs/
   sudo cp server.key /etc/ssl/private/
   sudo chmod 600 /etc/ssl/private/server.key
   ```

### Nginx Configuration

Create `/etc/nginx/sites-available/paperless`:

```nginx
# HTTP -> HTTPS redirect
server {
    listen 80;
    server_name paperless.your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name paperless.your-domain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/paperless.your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/paperless.your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # File Upload Limits
    client_max_body_size 100M;

    # Proxy to Paperless
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/paperless /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Firewall Configuration

```bash
# UFW (Ubuntu)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable

# Fail2ban (brute force protection)
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

---

## 🗄️ Database Setup

### Initial Setup

```bash
# Enter PostgreSQL
docker-compose exec postgres psql -U paperless

# Create additional users (read-only for analytics)
CREATE USER analytics_readonly WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE paperless TO analytics_readonly;
GRANT USAGE ON SCHEMA public TO analytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_readonly;
```

### Backup Configuration

Create backup script `/usr/local/bin/backup-paperless.sh`:

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/backups/paperless"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup database
docker-compose exec -T postgres pg_dump -U paperless paperless | \
  gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Backup media files
tar -czf "$BACKUP_DIR/media_$DATE.tar.gz" -C /var/lib/docker/volumes paperless_media

# Backup configuration
cp docker-compose.yml "$BACKUP_DIR/config_$DATE.yml"

# Remove old backups
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.yml" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $DATE"
```

Schedule with cron:

```bash
# Run daily at 2 AM
0 2 * * * /usr/local/bin/backup-paperless.sh >> /var/log/paperless-backup.log 2>&1
```

---

## 📊 Monitoring & Logging

### Application Monitoring

**Paperless-ngx Built-in:**

Access admin panel: `https://paperless.your-domain.com/admin/`

- View document processing queue
- Check failed tasks
- Monitor storage usage

### System Monitoring

**Install Prometheus + Grafana:**

```bash
# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*

# Configure prometheus.yml
./prometheus --config.file=prometheus.yml

# Install Grafana
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt update && sudo apt install grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Log Aggregation

**Centralized Logging with Loki:**

```yaml
# docker-compose.yml additions
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers
    command: -config.file=/etc/promtail/config.yml
```

### Alerting

Configure alerts in Grafana for:

- **Disk usage > 80%**
- **CPU usage > 90% for 5 minutes**
- **Memory usage > 90%**
- **Failed uploads > 10 in 1 hour**
- **SSL certificate expires in < 30 days**

---

## 💾 Backup & Disaster Recovery

### Backup Strategy

**3-2-1 Rule:**
- 3 copies of data
- 2 different media types
- 1 offsite backup

**Implementation:**

1. **Local backups** (daily): NAS or external drive
2. **Cloud backups** (weekly): AWS S3, Google Cloud Storage, or Backblaze
3. **Offsite backups** (monthly): Physical storage at different location

### Automated Cloud Backup

```bash
# Install AWS CLI
sudo apt install awscli -y

# Configure credentials
aws configure

# Sync backups to S3
aws s3 sync /backups/paperless s3://your-bucket/paperless-backups/ \
  --storage-class GLACIER_IR \
  --exclude "*.tmp"
```

### Disaster Recovery Plan

**RTO (Recovery Time Objective):** 4 hours
**RPO (Recovery Point Objective):** 24 hours

**Recovery Steps:**

1. **Provision new server** (30 min)
2. **Install Docker + dependencies** (15 min)
3. **Restore database** (60 min)
   ```bash
   gunzip -c db_backup.sql.gz | docker-compose exec -T postgres psql -U paperless
   ```
4. **Restore media files** (90 min)
   ```bash
   tar -xzf media_backup.tar.gz -C /var/lib/docker/volumes/paperless_media
   ```
5. **Restore configuration** (15 min)
6. **Verify application** (30 min)
7. **Update DNS** (30 min propagation)

**Test Recovery:** Quarterly

---

## ✅ Post-Deployment Validation

### Automated Validation Script

Create `scripts/validate-deployment.sh`:

```bash
#!/bin/bash

echo "🔍 Validating Production Deployment..."

# 1. Check HTTPS
echo "1. Checking HTTPS..."
curl -sS https://paperless.your-domain.com > /dev/null && echo "✅ HTTPS OK" || echo "❌ HTTPS FAILED"

# 2. Check SSL Certificate
echo "2. Checking SSL Certificate..."
echo | openssl s_client -connect paperless.your-domain.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# 3. Check API endpoint
echo "3. Checking API..."
curl -sS https://paperless.your-domain.com/api/ > /dev/null && echo "✅ API OK" || echo "❌ API FAILED"

# 4. Check database connectivity
echo "4. Checking Database..."
docker-compose exec -T postgres pg_isready -U paperless && echo "✅ DB OK" || echo "❌ DB FAILED"

# 5. Check disk space
echo "5. Checking Disk Space..."
df -h | grep -E "/$|/data"

# 6. Check Docker containers
echo "6. Checking Docker Containers..."
docker-compose ps

# 7. Test mobile app connectivity
echo "7. Test Mobile App Connection:"
echo "   Open app and attempt login"

echo "✅ Validation complete!"
```

### Manual Validation Checklist

- [ ] Web interface accessible via HTTPS
- [ ] SSL certificate valid and trusted
- [ ] Login with test credentials works
- [ ] Document upload successful
- [ ] OCR processing working
- [ ] Search functionality operational
- [ ] Mobile app can connect and sync
- [ ] Background sync working
- [ ] Error reporting functional
- [ ] Monitoring dashboards showing data
- [ ] Backups running on schedule

---

## 🔧 Troubleshooting

### Common Issues

#### Issue: "HTTPS Required in Production" Error

**Solution:**
```dart
// Verify production_config.dart
static const String paperlessProductionUrl = 'https://...'; // Must start with https://
```

#### Issue: "Certificate Validation Failed"

**Cause:** Certificate pinning mismatch

**Solution:**
```bash
# Regenerate fingerprint
./scripts/generate_cert_fingerprint.sh your-domain.com

# Update production_config.dart with new fingerprint
# Rebuild and deploy app
```

#### Issue: Upload Fails with "Network Error"

**Diagnosis:**
```bash
# Check server logs
docker-compose logs paperless | tail -100

# Check network connectivity
curl -v https://paperless.your-domain.com/api/

# Check firewall
sudo ufw status
```

#### Issue: Database Connection Failed

**Solution:**
```bash
# Restart PostgreSQL
docker-compose restart postgres

# Check database status
docker-compose exec postgres pg_isready

# Check logs
docker-compose logs postgres
```

#### Issue: High CPU Usage

**Solution:**
```bash
# Check OCR queue
docker-compose exec paperless python3 manage.py document_consumption_status

# Reduce worker count in docker-compose.yml
PAPERLESS_TASK_WORKERS: 2  # Reduce from 4

# Restart
docker-compose restart paperless
```

### Emergency Contacts

- **DevOps Lead:** devops@your-org.com
- **Security Team:** security@your-org.com
- **On-Call:** +1-XXX-XXX-XXXX
- **Support:** support@your-domain.com

---

## 📚 Additional Resources

- [Paperless-ngx Documentation](https://docs.paperless-ngx.com/)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Project Security Audit](./SECURITY_AUDIT.md)
- [API Documentation](./API.md)

---

## 📝 Deployment Log Template

```markdown
# Deployment Log - [DATE]

**Deployed By:** [NAME]
**Version:** 3.0.0
**Environment:** Production

## Pre-Deployment
- [ ] Backups completed
- [ ] Team notified
- [ ] Maintenance window scheduled

## Deployment Steps
1. [TIME] - Backend deployed
2. [TIME] - Database migrated
3. [TIME] - App released to Play Store
4. [TIME] - DNS updated

## Post-Deployment
- [ ] Validation tests passed
- [ ] Monitoring confirmed
- [ ] No critical errors
- [ ] Team notified of completion

## Issues Encountered
[None / Description]

## Rollback Plan
[If needed, document rollback steps]
```

---

**Document Version:** 1.0
**Maintained By:** DevOps Team
**Next Review:** 2025-11-07
