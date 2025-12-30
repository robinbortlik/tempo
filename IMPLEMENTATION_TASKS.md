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

### [x] 3.1 Settings Model
  - [x] 3.1.1 Generate Settings model (company_name, address, email, phone, vat_id, company_registration, bank_name, bank_account, bank_swift)
  - [x] 3.1.2 Add Active Storage attachment for logo
  - [x] 3.1.3 Create Settings singleton pattern (first_or_create)
  - [x] 3.1.4 Write model specs for validations

### [x] 3.2 Client Model
  - [x] 3.2.1 Generate Client model with all fields (name, address, email, contact_person, vat_id, company_registration, bank_details, payment_terms, hourly_rate, currency)
  - [x] 3.2.2 Add share_token column with secure default (SecureRandom.uuid)
  - [x] 3.2.3 Add validations (name required, hourly_rate > 0, currency format)
  - [x] 3.2.4 Add share_token uniqueness index
  - [x] 3.2.5 Write model specs

### [x] 3.3 Project Model
  - [x] 3.3.1 Generate Project model (client_id, name, hourly_rate, active)
  - [x] 3.3.2 Add belongs_to :client association
  - [x] 3.3.3 Add has_many :projects to Client
  - [x] 3.3.4 Add effective_hourly_rate method (project rate || client rate)
  - [x] 3.3.5 Add validations and model specs

### [x] 3.4 TimeEntry Model
  - [x] 3.4.1 Generate TimeEntry model (project_id, date, hours, description, status, invoice_id)
  - [x] 3.4.2 Add enum for status (unbilled: 0, invoiced: 1)
  - [x] 3.4.3 Add belongs_to :project and optional belongs_to :invoice
  - [x] 3.4.4 Add has_many :time_entries to Project
  - [x] 3.4.5 Add scopes: unbilled, invoiced, for_date_range(start, end)
  - [x] 3.4.6 Add calculated_amount method (hours * project.effective_hourly_rate)
  - [x] 3.4.7 Add validations (hours > 0, date required) and model specs

### [x] 3.5 Invoice Model
  - [x] 3.5.1 Generate Invoice model (client_id, number, status, issue_date, due_date, period_start, period_end, total_hours, total_amount, currency, notes)
  - [x] 3.5.2 Add enum for status (draft: 0, final: 1)
  - [x] 3.5.3 Add belongs_to :client and has_many :time_entries
  - [x] 3.5.4 Add has_many :invoices to Client
  - [x] 3.5.5 Create InvoiceNumberGenerator service (YYYY-NNN format)
  - [x] 3.5.6 Add before_create callback to set number
  - [x] 3.5.7 Add calculate_totals method
  - [x] 3.5.8 Add validations and model specs

---

## Phase 4: Settings Feature

### [x] 4.1 Settings Backend
  - [x] 4.1.1 Create SettingsController with show and update actions
  - [x] 4.1.2 Add Inertia render for settings page
  - [x] 4.1.3 Handle logo upload via Active Storage
  - [x] 4.1.4 Write controller specs

### [x] 4.2 Settings UI
  - [x] 4.2.1 Create Settings page layout component
  - [x] 4.2.2 Create SettingsForm component with all fields
  - [x] 4.2.3 Add logo upload with preview
  - [x] 4.2.4 Add form validation (client-side)
  - [x] 4.2.5 Add success/error toast notifications

---

## Phase 5: Clients Feature

### [x] 5.1 Clients Backend
  - [x] 5.1.1 Create ClientsController with index action
  - [x] 5.1.2 Add show action with associated projects and recent time entries
  - [x] 5.1.3 Add create action with Inertia redirect
  - [x] 5.1.4 Add update action
  - [x] 5.1.5 Add destroy action (with dependent destroy check)
  - [x] 5.1.6 Write controller specs for all actions

### [x] 5.2 Clients UI
  - [x] 5.2.1 Create ClientsIndex page with data table (shadcn)
  - [x] 5.2.2 Add columns: name, currency, hourly rate, unbilled hours, actions
  - [x] 5.2.3 Create ClientForm component (used for new/edit)
  - [x] 5.2.4 Create NewClient page with form
  - [x] 5.2.5 Create EditClient page with form
  - [x] 5.2.6 Create ClientShow page with tabs (overview, projects, invoices)
  - [x] 5.2.7 Add delete confirmation dialog
  - [x] 5.2.8 Add share link display/copy button on client show

---

## Phase 6: Projects Feature

### [x] 6.1 Projects Backend
  - [x] 6.1.1 Create ProjectsController with index action (filterable by client)
  - [x] 6.1.2 Add show action with time entries
  - [x] 6.1.3 Add create action (nested under client or standalone)
  - [x] 6.1.4 Add update action
  - [x] 6.1.5 Add destroy action
  - [x] 6.1.6 Write controller specs

### [x] 6.2 Projects UI
  - [x] 6.2.1 Create ProjectsIndex page with grouping by client
  - [x] 6.2.2 Create ProjectForm component
  - [x] 6.2.3 Create NewProject page (with client pre-selected if from client page)
  - [x] 6.2.4 Create EditProject page
  - [x] 6.2.5 Create ProjectShow page with time entries list
  - [x] 6.2.6 Add active/inactive toggle
  - [x] 6.2.7 Add delete confirmation dialog

---

## Phase 7: Time Entries Feature

### [x] 7.1 Time Entries Backend
  - [x] 7.1.1 Create TimeEntriesController with index action (date-grouped, filterable)
  - [x] 7.1.2 Add show action
  - [x] 7.1.3 Add create action
  - [x] 7.1.4 Add update action (only if unbilled)
  - [x] 7.1.5 Add destroy action (only if unbilled)
  - [x] 7.1.6 Add bulk operations endpoint (optional)
  - [x] 7.1.7 Write controller specs

### [x] 7.2 Time Entries UI
  - [x] 7.2.1 Create TimeEntriesIndex page with date grouping
  - [x] 7.2.2 Create QuickEntryForm component (inline form at top)
  - [x] 7.2.3 Create TimeEntryRow component with inline edit capability
  - [x] 7.2.4 Add project selector dropdown (grouped by client)
  - [x] 7.2.5 Add date picker component
  - [x] 7.2.6 Add status badge (unbilled/invoiced)
  - [x] 7.2.7 Disable edit/delete for invoiced entries
  - [x] 7.2.8 Add filtering by date range, client, project

---

## Phase 8: Invoices Feature

### [x] 8.1 Invoice Generation Backend
  - [x] 8.1.1 Create InvoicesController with index action (filterable by status, client, year)
  - [x] 8.1.2 Add new action (prepare invoice preview data)
  - [x] 8.1.3 Create InvoiceBuilder service class
  - [x] 8.1.4 InvoiceBuilder: accept client_id, date_range, calculate totals
  - [x] 8.1.5 InvoiceBuilder: fetch unbilled time entries for range
  - [x] 8.1.6 Add create action (save as draft, associate time entries)
  - [x] 8.1.7 Add show action
  - [x] 8.1.8 Add update action (only if draft)
  - [x] 8.1.9 Add finalize action (mark final, mark entries as invoiced)
  - [x] 8.1.10 Add destroy action (only if draft, unassociate entries)
  - [x] 8.1.11 Write controller and service specs

### [x] 8.2 Invoices UI
  - [x] 8.2.1 Create InvoicesIndex page with data table
  - [x] 8.2.2 Add columns: number, client, date, status, amount, actions
  - [x] 8.2.3 Add status filter tabs (all, draft, final)
  - [x] 8.2.4 Create NewInvoice page with client and date range selectors
  - [x] 8.2.5 Create InvoicePreview component (shows entries, totals)
  - [x] 8.2.6 Create InvoiceShow page with full details
  - [x] 8.2.7 Create InvoiceEdit page (for draft invoices)
  - [x] 8.2.8 Add finalize confirmation dialog
  - [x] 8.2.9 Add delete confirmation dialog (draft only)

### [x] 8.3 PDF Generation
  - [x] 8.3.1 Install and configure wicked_pdf gem
  - [x] 8.3.2 Install wkhtmltopdf binary (development)
  - [x] 8.3.3 Create invoice PDF template (HTML/ERB)
  - [x] 8.3.4 Add header section (your business details, logo)
  - [x] 8.3.5 Add client details section
  - [x] 8.3.6 Add invoice metadata (number, dates, period)
  - [x] 8.3.7 Add line items table (date, project, description, hours, rate, amount)
  - [x] 8.3.8 Add totals section
  - [x] 8.3.9 Add footer with payment terms/bank details
  - [x] 8.3.10 Add pdf action to InvoicesController
  - [x] 8.3.11 Add download PDF button to invoice show page
  - [x] 8.3.12 Write PDF generation specs

---

## Phase 9: Dashboard & Analytics

### [x] 9.1 Dashboard Backend
  - [x] 9.1.1 Create DashboardController with index action
  - [x] 9.1.2 Create DashboardStatsService class
  - [x] 9.1.3 Calculate hours this week
  - [x] 9.1.4 Calculate hours this month
  - [x] 9.1.5 Calculate total unbilled hours (all clients)
  - [x] 9.1.6 Calculate total unbilled amount (all clients, multi-currency aware)
  - [x] 9.1.7 Calculate unbilled breakdown per client
  - [x] 9.1.8 Write service specs

### [] 9.2 Charts Data Backend
  - [x] 9.2.1 Create ChartsController or extend Dashboard
  - [x] 9.2.2 Add time_by_client endpoint (pie chart data)
  - [x] 9.2.3 Add time_by_project endpoint (bar chart data)
  - [x] 9.2.4 Add earnings_over_time endpoint (line chart data, monthly)
  - [x] 9.2.5 Add hours_trend endpoint (monthly hours)
  - [x] 9.2.6 Write controller specs

### [x] 9.3 Dashboard UI
  - [x] 9.3.1 Create Dashboard page layout
  - [x] 9.3.2 Create StatCard component (shadcn card)
  - [x] 9.3.3 Add stats cards row (hours week/month, unbilled hours/amount)
  - [x] 9.3.4 Install Recharts library
  - [x] 9.3.5 Create TimeByClientChart component (pie/donut)
  - [x] 9.3.6 Create TimeByProjectChart component (bar)
  - [x] 9.3.7 Create EarningsChart component (line)
  - [x] 9.3.8 Create HoursTrendChart component (line/bar)
  - [x] 9.3.9 Create UnbilledByClientTable component
  - [x] 9.3.10 Arrange components in responsive grid layout

---

## Phase 10: Client Report Portal

### [x] 10.1 Report Portal Backend
  - [x] 10.1.1 Create ReportsController (public, no auth)
  - [x] 10.1.2 Add show action that finds client by share_token
  - [x] 10.1.3 Return 404 for invalid tokens
  - [x] 10.1.4 Create ClientReportService class
  - [x] 10.1.5 Service: fetch unbilled entries for period (year/month filter)
  - [x] 10.1.6 Service: fetch invoiced entries for period
  - [x] 10.1.7 Service: calculate totals per project
  - [x] 10.1.8 Service: group by project with subtotals
  - [x] 10.1.9 Write controller and service specs

### [x] 10.2 Report Portal UI
  - [x] 10.2.1 Create separate Inertia layout for public pages (no auth nav)
  - [x] 10.2.2 Create ClientReport page component
  - [x] 10.2.3 Add year/month filter controls
  - [x] 10.2.4 Create UnbilledSection component (entries table with totals)
  - [x] 10.2.5 Create InvoicedSection component (entries table with totals)
  - [x] 10.2.6 Create ProjectGroup component (collapsible, shows entries)
  - [x] 10.2.7 Add responsive design for mobile viewing
  - [x] 10.2.8 Add print-friendly styles

---

## Phase 11: PWA Support

### [x] 11.1 PWA Configuration
  - [x] 11.1.1 Create web app manifest (manifest.json)
  - [x] 11.1.2 Add app icons in required sizes (192x192, 512x512)
  - [x] 11.1.3 Configure manifest in HTML head
  - [x] 11.1.4 Create basic service worker for app shell caching
  - [x] 11.1.5 Register service worker in React app
  - [x] 11.1.6 Add meta tags for iOS Safari support
  - [x] 11.1.7 Test installation on desktop Chrome
  - [x] 11.1.8 Test installation on mobile

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
