# Time Tracking & Invoicing App - Product Definition

## Overview
A personal time tracking and invoicing application for independent developers working with multiple clients. The system enables daily time logging, invoice generation, and provides clients with transparent access to their billing reports.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | Ruby on Rails 8 (Ruby 3.3+) |
| Frontend | React via Inertia.js |
| Styling | Tailwind CSS + shadcn/ui |
| Database | SQLite |
| Background Jobs | Solid Queue (Rails 8) |
| Caching | Solid Cache (Rails 8) |
| WebSockets | Solid Cable (Rails 8) |
| PDF Generation | wicked_pdf + wkhtmltopdf |
| Charts | Recharts |
| Authentication | Rails 8 built-in authentication generator |
| Deployment | Kamal 2 (Docker) |
| Hosting | Standard VPS (Ubuntu/Debian, 1-2GB RAM) |
| PWA | Installable (online-only) |

---

## Data Model

### User
Single-user system with email/password authentication.

| Field | Type | Description |
|-------|------|-------------|
| email | string | Login email |
| password_digest | string | Encrypted password |

### Settings (User Business Details)
Stored in a settings table, displayed on invoice headers.

| Field | Type | Description |
|-------|------|-------------|
| company_name | string | Your business name |
| address | text | Full address |
| email | string | Business contact email |
| phone | string | Contact phone |
| vat_id | string | VAT/Tax identification number |
| company_registration | string | Company registration number |
| bank_name | string | Bank name |
| bank_account | string | Account number / IBAN |
| bank_swift | string | SWIFT/BIC code |
| logo | attachment | Company logo for invoices |

### Client

| Field | Type | Description |
|-------|------|-------------|
| name | string | Client/company name |
| address | text | Full billing address |
| email | string | Primary contact email |
| contact_person | string | Contact person name |
| vat_id | string | Client's VAT/Tax ID |
| company_registration | string | Client's registration number |
| bank_details | text | Client's bank details (if needed) |
| payment_terms | string | e.g., "Net 30", "Due on receipt" |
| hourly_rate | decimal | Default hourly rate for this client |
| currency | string | Currency code (EUR, USD, GBP, etc.) |
| share_token | string | UUID for public report access |
| created_at | datetime | |
| updated_at | datetime | |

### Project

| Field | Type | Description |
|-------|------|-------------|
| client_id | reference | Belongs to Client |
| name | string | Project name |
| hourly_rate | decimal | Optional override (null = use client rate) |
| active | boolean | Whether project is active |
| created_at | datetime | |
| updated_at | datetime | |

### TimeEntry

| Field | Type | Description |
|-------|------|-------------|
| project_id | reference | Belongs to Project |
| date | date | Work date |
| hours | integer | Hours worked |
| description | text | Short summary of work done |
| status | enum | `unbilled` / `invoiced` |
| invoice_id | reference | Belongs to Invoice (when invoiced) |
| created_at | datetime | |
| updated_at | datetime | |

### Invoice

| Field | Type | Description |
|-------|------|-------------|
| client_id | reference | Belongs to Client |
| number | string | Year-prefixed: YYYY-NNN (e.g., 2025-001) |
| status | enum | `draft` / `final` |
| issue_date | date | Invoice issue date |
| due_date | date | Payment due date |
| period_start | date | Billing period start |
| period_end | date | Billing period end |
| total_hours | integer | Sum of included time entries |
| total_amount | decimal | Calculated total |
| currency | string | Copied from client at generation |
| notes | text | Optional invoice notes |
| created_at | datetime | |
| updated_at | datetime | |

---

## Features

### 1. Authentication
- Email/password login (Rails 8 generator)
- Session-based authentication
- Password reset via email

### 2. Settings Management
- Configure your business details
- Upload company logo
- All fields used in invoice header generation

### 3. Client Management
- CRUD operations for clients
- Store full legal/billing details
- Set default hourly rate and currency
- Auto-generated share token for report access

### 4. Project Management
- CRUD operations for projects
- Associate with client
- Optional hourly rate override
- Mark projects as active/inactive

### 5. Time Tracking
- Daily manual entry (end of day workflow)
- Select project from dropdown
- Enter hours (integer) + description (free text)
- View/edit past entries
- Entries start as `unbilled`

### 6. Invoice Generation
**Workflow:**
1. Select client
2. Select date range (defaults to current month)
3. System auto-includes all `unbilled` time entries in range
4. Preview invoice (shows entries, totals, amounts)
5. Save as `draft`
6. Edit draft if needed (add notes, adjust dates)
7. Mark as `final` (immutable, entries marked as `invoiced`)
8. Download PDF

**Invoice Numbering:**
- Format: `YYYY-NNN`
- Resets each year (2025-001, 2025-002... 2026-001...)
- Sequential within year

**PDF Generation:**
- wicked_pdf renders HTML template to PDF
- Includes your business details (header)
- Client billing details
- Line items: date, project, hours, rate, amount
- Totals section
- Template customizable via code (HTML/ERB)

### 7. Client Report Portal (Shareable)
**URL Structure:**
```
/reports/:share_token
```
- UUID-based token, hard to guess
- No authentication required
- Permanent per-client URL

**Features:**
- Filter by year and month
- Two sections:
  - **Unbilled this period**: Current work not yet invoiced
  - **Previously invoiced**: Historical invoiced entries
- Full transparency: entries, hours, rates, amounts
- Totals per project and overall

### 8. Dashboard & Analytics
**Summary Cards:**
- Hours this week
- Hours this month
- Total unbilled hours
- Total unbilled amount (across all clients)

**Charts (Recharts):**
- Time distribution by client (pie/donut)
- Time distribution by project (bar)
- Earnings over time (line chart, monthly)
- Hours per month trend

**Unbilled Overview:**
- Per-client breakdown of unbilled hours/amount

### 9. PWA Support
- Web app manifest for installability
- Service worker for app shell caching
- Installable on desktop/mobile
- Requires internet connection (no offline support)

---

## User Interface Structure

### Navigation
```
Dashboard
Clients
  └── [Client Detail]
      └── Projects
          └── [Project Detail]
Time Entries
Invoices
  └── [Invoice Detail / Edit]
Settings
```

### Key Pages

1. **Dashboard**: Summary cards + charts
2. **Clients List**: Table with name, unbilled hours, last activity
3. **Client Detail**: Info, projects list, recent entries, invoices
4. **Projects List**: Grouped by client or flat view
5. **Time Entries**: Date-grouped list, quick entry form
6. **Invoices List**: Filter by status, client, year
7. **Invoice Detail**: Preview, edit (if draft), download PDF
8. **New Invoice**: Client + date range selector, preview, save
9. **Settings**: Business details form, logo upload
10. **Client Report** (public): Year/month filter, entries, totals

---

## API / Routes Structure

### Authenticated (Inertia)
```
GET    /                     → Dashboard
GET    /clients              → Clients index
POST   /clients              → Create client
GET    /clients/:id          → Client show
PATCH  /clients/:id          → Update client
DELETE /clients/:id          → Delete client

GET    /clients/:id/projects → Projects for client
POST   /projects             → Create project
GET    /projects/:id         → Project show
PATCH  /projects/:id         → Update project
DELETE /projects/:id         → Delete project

GET    /time_entries         → Time entries index
POST   /time_entries         → Create entry
GET    /time_entries/:id     → Entry show
PATCH  /time_entries/:id     → Update entry
DELETE /time_entries/:id     → Delete entry

GET    /invoices             → Invoices index
GET    /invoices/new         → New invoice form
POST   /invoices             → Create invoice (draft)
GET    /invoices/:id         → Invoice show
PATCH  /invoices/:id         → Update invoice (if draft)
POST   /invoices/:id/finalize → Mark as final
GET    /invoices/:id/pdf     → Download PDF

GET    /settings             → Settings form
PATCH  /settings             → Update settings
```

### Public
```
GET    /reports/:share_token → Client report portal
```

---

## Deployment

### Kamal Configuration
- Single server deployment
- Docker containerized app
- SQLite database (persistent volume)
- wkhtmltopdf installed in container
- Traefik for SSL/reverse proxy
- Health checks configured

### Environment Variables
```
RAILS_ENV=production
SECRET_KEY_BASE=<generated>
DATABASE_URL=sqlite3:///rails/storage/production.sqlite3
RAILS_SERVE_STATIC_FILES=true
```

### Docker Requirements
- Ruby 3.3+ base image
- Node.js for asset compilation
- wkhtmltopdf binary
- SQLite3

---

## Future Considerations (Out of Scope for MVP)
- Email invoices directly to clients
- Data export (CSV/JSON)
- Multiple users / team support
- Recurring invoices
- Payment tracking (paid/unpaid status)
- Tax calculation helpers
- Mobile app (native)

---

## Success Criteria
1. Can log time entries daily with minimal friction
2. Can generate professional PDF invoices in under 1 minute
3. Clients can access their transparent billing reports
4. Dashboard provides clear overview of unbilled work
5. Runs reliably on a single VPS with minimal maintenance
6. PWA installable and feels like native app
