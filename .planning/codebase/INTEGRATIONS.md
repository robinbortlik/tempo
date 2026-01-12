# External Integrations

**Analysis Date:** 2026-01-12

## APIs & External Services

**Payment Processing:**
- No third-party payment processor
- Direct bank transfer via QR codes only
- IBAN validation using `ibandit` gem (`app/models/setting.rb`)

**Email/SMS:**
- Action Mailer configured (`app/mailers/application_mailer.rb`)
- No external email service configured (defaults to SMTP)

**External APIs:**
- None - Self-contained application

## Data Storage

**Databases:**
- SQLite3 - Primary data store
  - Connection: Local file (`db/development.sqlite3`, `db/production.sqlite3`)
  - Client: ActiveRecord (Rails built-in)
  - Migrations: `db/migrate/`
  - Configuration: `config/database.yml`

**File Storage:**
- Active Storage - Local disk storage (default)
  - Configuration: `config/storage.yml`
  - Buckets: local (development), production (local disk)
  - S3/GCS commented out as options

**Caching:**
- Solid Cache 1.0.10 - Database-backed caching
  - No external Redis required
  - Configuration in Rails initializers

**Job Queue:**
- Solid Queue 1.2.4 - Database-backed background jobs
  - No external Redis required
  - Runs in Puma process (`SOLID_QUEUE_IN_PUMA: true`)

## Authentication & Identity

**Auth Provider:**
- Custom session-based authentication
  - Implementation: bcrypt `has_secure_password` (`app/models/user.rb`)
  - Token storage: Signed cookies
  - Session management: `app/models/session.rb`

**OAuth Integrations:**
- None configured

## Monitoring & Observability

**Error Tracking:**
- None configured (consider adding Sentry)

**Analytics:**
- None - Internal dashboards only via recharts

**Logs:**
- Rails logger to stdout
- No external logging service

## CI/CD & Deployment

**Hosting:**
- Docker container via Kamal
  - Deployment: `config/deploy.yml`
  - Server: Single server (IP configured in .env)
  - Domain: Configured in .env (`KAMAL_DEPLOY_DOMAIN`)

**CI Pipeline:**
- GitHub Actions (assumed from `.github/` directory)
- Workflows: Standard Ruby/Node CI

**Registry:**
- AWS ECR (Elastic Container Registry)
  - Region: eu-central-1
  - Authentication: `aws ecr get-login-password`
  - Configuration: `config/deploy.yml`

## Environment Configuration

**Development:**
- Required env vars: None (defaults work)
- Secrets location: `.env` (gitignored), `config/master.key`
- Services: All local (SQLite, Solid Cache/Queue/Cable)

**Staging:**
- Not configured (single environment deployment)

**Production:**
- Secrets management: `.env` on server, `config/master.key`
- Database: SQLite file on server (persisted via Docker volume)
- SSL: Let's Encrypt via Kamal proxy (`config/deploy.yml`)

## Webhooks & Callbacks

**Incoming:**
- None configured

**Outgoing:**
- None configured

## Payment & Financial Integrations

**QR Code Payment:**
- EPC QR Code (EUR/SEPA) - `app/services/payment_qr_code_generator.rb`
  - European Payments Council standard
  - Generated for Euro currency invoices

- Czech QR Platba (SPAYD) - `app/services/payment_qr_code_generator.rb`
  - Czech bank transfer format
  - Generated for CZK currency invoices

**Bank Details Validation:**
- IBAN validation via `ibandit` gem
  - Location: `app/models/setting.rb`
  - Validates bank account numbers on save

## PDF Generation

**Grover (Puppeteer wrapper):**
- Configuration: `config/initializers/grover.rb`
- Format: A4 with 20mm margins
- Browser: Chromium (`/usr/bin/chromium` in Docker)
- Sandbox: Disabled for Docker environment

**Puppeteer:**
- Version: 24.34.0 (`package.json`)
- Purpose: Headless Chrome/Chromium control

## Internationalization

**Backend:**
- Rails I18n
- Locales: English (`en.yml`), Czech (`cs.yml`)
- Location: `config/locales/`

**Frontend:**
- i18next + react-i18next
- Locales: `app/frontend/locales/en.json`, `app/frontend/locales/cs.json`

## Public Portal

**Client Reports:**
- Unauthenticated access via share token
- Controller: `app/controllers/reports_controller.rb`
- Route: `GET /reports/:share_token`
- Features: Invoice list, PDF download

---

*Integration audit: 2026-01-12*
*Update when adding/removing external services*
