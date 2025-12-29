# Implementation Tasks

## Phase 1: Project Foundation

### [x] 1.1 Rails Application Setup
  - [x] 1.1.1 Initialize Rails 8 app with SQLite, skip default JS (will use Inertia)
  - [x] 1.1.2 Configure Solid Queue, Solid Cache, Solid Cable
  - [x] 1.1.3 Add and configure Inertia Rails gem
  - [x] 1.1.4 Setup Vite with React and TypeScript
  - [x] 1.1.5 Install and configure Tailwind CSS
  - [x] 1.1.6 Install and configure shadcn/ui components
  - [X] 1.1.7 Create base Inertia layout with React

### [x] 1.2 Development Environment
  - [x] 1.2.1 Configure ESLint and Prettier for TypeScript/React
  - [x] 1.2.2 Setup RSpec for Rails testing
  - [x] 1.2.3 Setup Vitest for React component testing
  - [x] 1.2.4 Create bin/dev script for concurrent Rails + Vite

---

## Phase 2: Authentication

### [x] 2.1 User Model & Auth
  - [x] 2.1.1 Generate User model (email, password_digest)
  - [x] 2.1.2 Run Rails 8 authentication generator
  - [x] 2.1.3 Add email uniqueness validation and index
  - [x] 2.1.4 Create database seeds with default user

### [x] 2.2 Auth UI
  - [x] 2.2.1 Create Login page component (React + shadcn form)
  - [x] 2.2.2 Create session controller with Inertia responses
  - [x] 2.2.3 Add authenticated route protection (before_action)

---

## Phase 3: Core Data Models

### [] 3.1 Settings Model
  - [] 3.1.1 Generate Settings model (company_name, address, email, phone, vat_id, company_registration, bank_name, bank_account, bank_swift)
  - [] 3.1.2 Add Active Storage attachment for logo
  - [] 3.1.3 Create Settings singleton pattern (first_or_create)
  - [] 3.1.4 Write model specs for validations

### [] 3.2 Client Model
  - [] 3.2.1 Generate Client model with all fields (name, address, email, contact_person, vat_id, company_registration, bank_details, payment_terms, hourly_rate, currency)
  - [] 3.2.2 Add share_token column with secure default (SecureRandom.uuid)
  - [] 3.2.3 Add validations (name required, hourly_rate > 0, currency format)
  - [] 3.2.4 Add share_token uniqueness index
  - [] 3.2.5 Write model specs

### [] 3.3 Project Model
  - [] 3.3.1 Generate Project model (client_id, name, hourly_rate, active)
  - [] 3.3.2 Add belongs_to :client association
  - [] 3.3.3 Add has_many :projects to Client
  - [] 3.3.4 Add effective_hourly_rate method (project rate || client rate)
  - [] 3.3.5 Add validations and model specs

### [] 3.4 TimeEntry Model
  - [] 3.4.1 Generate TimeEntry model (project_id, date, hours, description, status, invoice_id)
  - [] 3.4.2 Add enum for status (unbilled: 0, invoiced: 1)
  - [] 3.4.3 Add belongs_to :project and optional belongs_to :invoice
  - [] 3.4.4 Add has_many :time_entries to Project
  - [] 3.4.5 Add scopes: unbilled, invoiced, for_date_range(start, end)
  - [] 3.4.6 Add calculated_amount method (hours * project.effective_hourly_rate)
  - [] 3.4.7 Add validations (hours > 0, date required) and model specs

### [] 3.5 Invoice Model
  - [] 3.5.1 Generate Invoice model (client_id, number, status, issue_date, due_date, period_start, period_end, total_hours, total_amount, currency, notes)
  - [] 3.5.2 Add enum for status (draft: 0, final: 1)
  - [] 3.5.3 Add belongs_to :client and has_many :time_entries
  - [] 3.5.4 Add has_many :invoices to Client
  - [] 3.5.5 Create InvoiceNumberGenerator service (YYYY-NNN format)
  - [] 3.5.6 Add before_create callback to set number
  - [] 3.5.7 Add calculate_totals method
  - [] 3.5.8 Add validations and model specs

---

## Phase 4: Settings Feature

### [] 4.1 Settings Backend
  - [] 4.1.1 Create SettingsController with show and update actions
  - [] 4.1.2 Add Inertia render for settings page
  - [] 4.1.3 Handle logo upload via Active Storage
  - [] 4.1.4 Write controller specs

### [] 4.2 Settings UI
  - [] 4.2.1 Create Settings page layout component
  - [] 4.2.2 Create SettingsForm component with all fields
  - [] 4.2.3 Add logo upload with preview
  - [] 4.2.4 Add form validation (client-side)
  - [] 4.2.5 Add success/error toast notifications

---

## Phase 5: Clients Feature

### [] 5.1 Clients Backend
  - [] 5.1.1 Create ClientsController with index action
  - [] 5.1.2 Add show action with associated projects and recent time entries
  - [] 5.1.3 Add create action with Inertia redirect
  - [] 5.1.4 Add update action
  - [] 5.1.5 Add destroy action (with dependent destroy check)
  - [] 5.1.6 Write controller specs for all actions

### [] 5.2 Clients UI
  - [] 5.2.1 Create ClientsIndex page with data table (shadcn)
  - [] 5.2.2 Add columns: name, currency, hourly rate, unbilled hours, actions
  - [] 5.2.3 Create ClientForm component (used for new/edit)
  - [] 5.2.4 Create NewClient page with form
  - [] 5.2.5 Create EditClient page with form
  - [] 5.2.6 Create ClientShow page with tabs (overview, projects, invoices)
  - [] 5.2.7 Add delete confirmation dialog
  - [] 5.2.8 Add share link display/copy button on client show

---

## Phase 6: Projects Feature

### [] 6.1 Projects Backend
  - [] 6.1.1 Create ProjectsController with index action (filterable by client)
  - [] 6.1.2 Add show action with time entries
  - [] 6.1.3 Add create action (nested under client or standalone)
  - [] 6.1.4 Add update action
  - [] 6.1.5 Add destroy action
  - [] 6.1.6 Write controller specs

### [] 6.2 Projects UI
  - [] 6.2.1 Create ProjectsIndex page with grouping by client
  - [] 6.2.2 Create ProjectForm component
  - [] 6.2.3 Create NewProject page (with client pre-selected if from client page)
  - [] 6.2.4 Create EditProject page
  - [] 6.2.5 Create ProjectShow page with time entries list
  - [] 6.2.6 Add active/inactive toggle
  - [] 6.2.7 Add delete confirmation dialog

---

## Phase 7: Time Entries Feature

### [] 7.1 Time Entries Backend
  - [] 7.1.1 Create TimeEntriesController with index action (date-grouped, filterable)
  - [] 7.1.2 Add show action
  - [] 7.1.3 Add create action
  - [] 7.1.4 Add update action (only if unbilled)
  - [] 7.1.5 Add destroy action (only if unbilled)
  - [] 7.1.6 Add bulk operations endpoint (optional)
  - [] 7.1.7 Write controller specs

### [] 7.2 Time Entries UI
  - [] 7.2.1 Create TimeEntriesIndex page with date grouping
  - [] 7.2.2 Create QuickEntryForm component (inline form at top)
  - [] 7.2.3 Create TimeEntryRow component with inline edit capability
  - [] 7.2.4 Add project selector dropdown (grouped by client)
  - [] 7.2.5 Add date picker component
  - [] 7.2.6 Add status badge (unbilled/invoiced)
  - [] 7.2.7 Disable edit/delete for invoiced entries
  - [] 7.2.8 Add filtering by date range, client, project

---

## Phase 8: Invoices Feature

### [] 8.1 Invoice Generation Backend
  - [] 8.1.1 Create InvoicesController with index action (filterable by status, client, year)
  - [] 8.1.2 Add new action (prepare invoice preview data)
  - [] 8.1.3 Create InvoiceBuilder service class
  - [] 8.1.4 InvoiceBuilder: accept client_id, date_range, calculate totals
  - [] 8.1.5 InvoiceBuilder: fetch unbilled time entries for range
  - [] 8.1.6 Add create action (save as draft, associate time entries)
  - [] 8.1.7 Add show action
  - [] 8.1.8 Add update action (only if draft)
  - [] 8.1.9 Add finalize action (mark final, mark entries as invoiced)
  - [] 8.1.10 Add destroy action (only if draft, unassociate entries)
  - [] 8.1.11 Write controller and service specs

### [] 8.2 Invoices UI
  - [] 8.2.1 Create InvoicesIndex page with data table
  - [] 8.2.2 Add columns: number, client, date, status, amount, actions
  - [] 8.2.3 Add status filter tabs (all, draft, final)
  - [] 8.2.4 Create NewInvoice page with client and date range selectors
  - [] 8.2.5 Create InvoicePreview component (shows entries, totals)
  - [] 8.2.6 Create InvoiceShow page with full details
  - [] 8.2.7 Create InvoiceEdit page (for draft invoices)
  - [] 8.2.8 Add finalize confirmation dialog
  - [] 8.2.9 Add delete confirmation dialog (draft only)

### [] 8.3 PDF Generation
  - [] 8.3.1 Install and configure wicked_pdf gem
  - [] 8.3.2 Install wkhtmltopdf binary (development)
  - [] 8.3.3 Create invoice PDF template (HTML/ERB)
  - [] 8.3.4 Add header section (your business details, logo)
  - [] 8.3.5 Add client details section
  - [] 8.3.6 Add invoice metadata (number, dates, period)
  - [] 8.3.7 Add line items table (date, project, description, hours, rate, amount)
  - [] 8.3.8 Add totals section
  - [] 8.3.9 Add footer with payment terms/bank details
  - [] 8.3.10 Add pdf action to InvoicesController
  - [] 8.3.11 Add download PDF button to invoice show page
  - [] 8.3.12 Write PDF generation specs

---

## Phase 9: Dashboard & Analytics

### [] 9.1 Dashboard Backend
  - [] 9.1.1 Create DashboardController with index action
  - [] 9.1.2 Create DashboardStatsService class
  - [] 9.1.3 Calculate hours this week
  - [] 9.1.4 Calculate hours this month
  - [] 9.1.5 Calculate total unbilled hours (all clients)
  - [] 9.1.6 Calculate total unbilled amount (all clients, multi-currency aware)
  - [] 9.1.7 Calculate unbilled breakdown per client
  - [] 9.1.8 Write service specs

### [] 9.2 Charts Data Backend
  - [] 9.2.1 Create ChartsController or extend Dashboard
  - [] 9.2.2 Add time_by_client endpoint (pie chart data)
  - [] 9.2.3 Add time_by_project endpoint (bar chart data)
  - [] 9.2.4 Add earnings_over_time endpoint (line chart data, monthly)
  - [] 9.2.5 Add hours_trend endpoint (monthly hours)
  - [] 9.2.6 Write controller specs

### [] 9.3 Dashboard UI
  - [] 9.3.1 Create Dashboard page layout
  - [] 9.3.2 Create StatCard component (shadcn card)
  - [] 9.3.3 Add stats cards row (hours week/month, unbilled hours/amount)
  - [] 9.3.4 Install Recharts library
  - [] 9.3.5 Create TimeByClientChart component (pie/donut)
  - [] 9.3.6 Create TimeByProjectChart component (bar)
  - [] 9.3.7 Create EarningsChart component (line)
  - [] 9.3.8 Create HoursTrendChart component (line/bar)
  - [] 9.3.9 Create UnbilledByClientTable component
  - [] 9.3.10 Arrange components in responsive grid layout

---

## Phase 10: Client Report Portal

### [] 10.1 Report Portal Backend
  - [] 10.1.1 Create ReportsController (public, no auth)
  - [] 10.1.2 Add show action that finds client by share_token
  - [] 10.1.3 Return 404 for invalid tokens
  - [] 10.1.4 Create ClientReportService class
  - [] 10.1.5 Service: fetch unbilled entries for period (year/month filter)
  - [] 10.1.6 Service: fetch invoiced entries for period
  - [] 10.1.7 Service: calculate totals per project
  - [] 10.1.8 Service: group by project with subtotals
  - [] 10.1.9 Write controller and service specs

### [] 10.2 Report Portal UI
  - [] 10.2.1 Create separate Inertia layout for public pages (no auth nav)
  - [] 10.2.2 Create ClientReport page component
  - [] 10.2.3 Add year/month filter controls
  - [] 10.2.4 Create UnbilledSection component (entries table with totals)
  - [] 10.2.5 Create InvoicedSection component (entries table with totals)
  - [] 10.2.6 Create ProjectGroup component (collapsible, shows entries)
  - [] 10.2.7 Add responsive design for mobile viewing
  - [] 10.2.8 Add print-friendly styles

---

## Phase 11: PWA Support

### [] 11.1 PWA Configuration
  - [] 11.1.1 Create web app manifest (manifest.json)
  - [] 11.1.2 Add app icons in required sizes (192x192, 512x512)
  - [] 11.1.3 Configure manifest in HTML head
  - [] 11.1.4 Create basic service worker for app shell caching
  - [] 11.1.5 Register service worker in React app
  - [] 11.1.6 Add meta tags for iOS Safari support
  - [] 11.1.7 Test installation on desktop Chrome
  - [] 11.1.8 Test installation on mobile

---

## Phase 12: Navigation & Layout

### [] 12.1 App Shell
  - [] 12.1.1 Create AppLayout component with sidebar
  - [] 12.1.2 Create Sidebar component with navigation links
  - [] 12.1.3 Create Header component with user menu
  - [] 12.1.4 Add mobile responsive navigation (hamburger menu)
  - [] 12.1.5 Create Breadcrumb component
  - [] 12.1.6 Add active state styling to nav items
  - [] 12.1.7 Create Toast/notification system (shadcn sonner)

### [] 12.2 Shared Components
  - [] 12.2.1 Create PageHeader component (title + actions)
  - [] 12.2.2 Create EmptyState component
  - [] 12.2.3 Create LoadingSpinner component
  - [] 12.2.4 Create ConfirmDialog component
  - [] 12.2.5 Create CurrencyDisplay component (formats by currency)
  - [] 12.2.6 Create DateDisplay component (consistent date formatting)

---

## Phase 13: Deployment

### [] 13.1 Docker Setup
  - [] 13.1.1 Create Dockerfile for production
  - [] 13.1.2 Add wkhtmltopdf to Docker image
  - [] 13.1.3 Configure multi-stage build (asset compilation)
  - [] 13.1.4 Create .dockerignore file
  - [] 13.1.5 Test local Docker build and run

### [] 13.2 Kamal Configuration
  - [] 13.2.1 Initialize Kamal (kamal init)
  - [] 13.2.2 Configure deploy.yml with server details
  - [] 13.2.3 Configure SQLite volume persistence
  - [] 13.2.4 Configure Active Storage volume
  - [] 13.2.5 Set up environment variables in .kamal/secrets
  - [] 13.2.6 Configure health check endpoint
  - [] 13.2.7 Configure SSL with Traefik
  - [] 13.2.8 Test deployment to VPS
  - [] 13.2.9 Document deployment commands

### [] 13.3 Production Readiness
  - [] 13.3.1 Configure production logging
  - [] 13.3.2 Set up database backups (SQLite file backup)
  - [] 13.3.3 Configure error tracking (optional: Sentry/similar)
  - [] 13.3.4 Add health check endpoint
  - [] 13.3.5 Create production seeds (initial user)
  - [] 13.3.6 Write deployment documentation

---

## Task Dependencies

```
Phase 1 (Foundation)
    ↓
Phase 2 (Auth)
    ↓
Phase 3 (Models) → Phase 12 (Layout/Components)
    ↓                    ↓
Phase 4 (Settings) ←────┘
    ↓
Phase 5 (Clients)
    ↓
Phase 6 (Projects)
    ↓
Phase 7 (Time Entries)
    ↓
Phase 8 (Invoices) ← Phase 9 (Dashboard) can start after Phase 7
    ↓
Phase 10 (Client Portal)
    ↓
Phase 11 (PWA)
    ↓
Phase 13 (Deployment)
```

**Parallel Work Opportunities:**
- Phase 12 (Layout) can be done alongside Phase 3-4
- Phase 9 (Dashboard) can start once Phase 7 (Time Entries) is complete
- Phase 11 (PWA) can be done anytime after Phase 12
- Phase 13 (Deployment) Docker setup can start after Phase 1

---

## Estimated Task Count

| Phase | Task Groups | Subtasks |
|-------|-------------|----------|
| 1. Foundation | 2 | 11 |
| 2. Auth | 2 | 10 |
| 3. Models | 5 | 26 |
| 4. Settings | 2 | 9 |
| 5. Clients | 2 | 14 |
| 6. Projects | 2 | 12 |
| 7. Time Entries | 2 | 16 |
| 8. Invoices | 3 | 23 |
| 9. Dashboard | 3 | 19 |
| 10. Client Portal | 2 | 17 |
| 11. PWA | 1 | 8 |
| 12. Navigation | 2 | 13 |
| 13. Deployment | 3 | 18 |
| **Total** | **31** | **196** |
