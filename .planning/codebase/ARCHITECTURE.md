# Architecture

**Analysis Date:** 2026-01-12

## Pattern Overview

**Overall:** Rails Monolith with Inertia.js SPA (Server-driven Single Page Application)

**Key Characteristics:**
- Full-stack monolith combining Rails backend with React frontend
- Server renders props, frontend resolves page components dynamically
- Single-user application (no multi-tenant isolation)
- Self-contained infrastructure (SQLite + Solid Cache/Queue/Cable)

## Layers

**Presentation Layer (Frontend):**
- Purpose: React 19 + TypeScript SPA rendered via Inertia.js
- Contains: Page components, shared UI components, utilities
- Location: `app/frontend/`
- Entry point: `app/frontend/entrypoints/application.tsx`
- Depends on: Inertia props from Rails controllers
- Used by: End users via browser

**HTTP/API Layer (Controllers):**
- Purpose: Handle HTTP requests, render Inertia responses
- Contains: Rails ActionControllers with Inertia rendering pattern
- Location: `app/controllers/`
- Depends on: Services for business logic, serializers for output
- Used by: Frontend via Inertia requests

**Business Logic Layer (Services):**
- Purpose: Encapsulate complex business operations
- Contains: Plain Ruby service objects (no base class inheritance)
- Location: `app/services/`
- Depends on: Models for data access
- Used by: Controllers

**Data/Domain Layer (Models):**
- Purpose: Database-backed entities with validations and associations
- Contains: ActiveRecord models, enums, scopes, computed properties
- Location: `app/models/`
- Depends on: Database schema
- Used by: Services, controllers, serializers

**Serialization Layer:**
- Purpose: Transform models to JSON for frontend consumption
- Contains: Alba serializers with nested classes
- Location: `app/serializers/`
- Depends on: Models
- Used by: Controllers when rendering Inertia props

## Data Flow

**HTTP Request (Inertia SPA):**

1. User navigates or submits form in React frontend
2. Inertia.js sends XHR request to Rails
3. `config/routes.rb` routes to controller action
4. Controller authenticates via `Authentication` concern
5. Controller calls service object for business logic
6. Service queries/mutates models, returns result
7. Controller serializes data via Alba serializer
8. `render inertia: "Page/Name", props: { ... }` returns JSON
9. Inertia.js resolves page component from `app/frontend/pages/`
10. React renders page with received props

**State Management:**
- Server-side: Database via ActiveRecord, session via cookie
- Client-side: React component state, Inertia page props
- No global state management library (props flow down)

## Key Abstractions

**Service Objects:**
- Purpose: Encapsulate business logic outside controllers
- Examples: `InvoiceBuilder`, `InvoicePdfService`, `DashboardStatsService`, `PaymentQrCodeGenerator`
- Pattern: Stateless, result hash returns `{ success: bool, data: ..., errors: [...] }`
- Location: `app/services/*.rb`

**Serializers:**
- Purpose: Transform ActiveRecord models to JSON
- Examples: `InvoiceSerializer`, `ClientSerializer`, `WorkEntrySerializer`
- Pattern: Alba gem with nested classes (e.g., `InvoiceSerializer::List`)
- Location: `app/serializers/*.rb`

**Page Components:**
- Purpose: Top-level React components corresponding to routes
- Examples: `Invoices/Index.tsx`, `Clients/Show.tsx`, `WorkEntries/Index.tsx`
- Pattern: Receive props from Inertia, render full page
- Location: `app/frontend/pages/{Resource}/{Action}.tsx`

**Enum-Based State Machines:**
- Purpose: Track entity status with defined transitions
- Examples: Invoice status (draft → final), WorkEntry status (unbilled → invoiced)
- Pattern: Rails enum with integer backing
- Location: Model files (`app/models/invoice.rb`, `app/models/work_entry.rb`)

## Entry Points

**CLI Entry:**
- Location: `bin/dev`
- Triggers: Developer runs `bin/dev`
- Responsibilities: Start Rails server + Vite dev server via Foreman

**Rails Application:**
- Location: `config.ru` → `config/application.rb` (class `Tempo::Application`)
- Triggers: HTTP request to server
- Responsibilities: Boot Rails, load initializers, route requests

**React SPA:**
- Location: `app/frontend/entrypoints/application.tsx`
- Triggers: Browser loads page
- Responsibilities: Create Inertia app, resolve page components, register service worker

**Routes:**
- Location: `config/routes.rb`
- Triggers: Matched URL pattern
- Responsibilities: Map URLs to controller actions (54 total routes)

## Error Handling

**Strategy:** Throw exceptions, catch at controller level, render error response

**Patterns:**
- Services return result hashes with success/errors keys
- Controllers check result and redirect/render accordingly
- Model validations prevent invalid data persistence
- Authentication concern redirects unauthenticated requests

## Cross-Cutting Concerns

**Logging:**
- Rails logger to stdout
- Filter parameter logging for sensitive data (`config/initializers/filter_parameter_logging.rb`)

**Validation:**
- Model validations via ActiveRecord
- Form validation via Zod schemas + react-hook-form on frontend

**Authentication:**
- Session-based authentication via bcrypt (`app/controllers/concerns/authentication.rb`)
- Cookie-backed sessions (`app/models/session.rb`)
- Public routes use `allow_unauthenticated_access`

**Internationalization:**
- Backend: Rails I18n (`config/locales/en.yml`, `config/locales/cs.yml`)
- Frontend: i18next + react-i18next (`app/frontend/locales/`)

---

*Architecture analysis: 2026-01-12*
*Update when major patterns change*
