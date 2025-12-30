# Invoicing

Personal time tracking and invoicing application for independent developers working with multiple clients.

## Tech Stack

- **Backend:** Rails 8.1 with Ruby 3.3
- **Frontend:** React 19 + TypeScript via Inertia.js
- **UI:** Tailwind CSS + shadcn/ui (Radix primitives)
- **Database:** SQLite3 with Solid Cache/Queue/Cable
- **Testing:** RSpec (backend), Vitest (frontend)
- **PDF:** Grover (Puppeteer-based)

## Project Structure

```
app/
├── controllers/        # Rails controllers (render inertia: pages)
├── models/             # ActiveRecord models
├── services/           # Service objects (InvoiceBuilder, etc.)
├── frontend/
│   ├── components/     # Shared React components + ui/ (shadcn)
│   ├── pages/          # Inertia page components by resource
│   └── lib/            # Utility functions
└── views/              # ERB layouts, PDF templates, mailers
spec/                   # RSpec tests (models, services, requests)
```

## Commands

```bash
# Development
bin/dev                        # Start Rails + Vite dev servers

# Backend tests
bundle exec rspec              # All tests
bundle exec rspec spec/models  # Model tests only

# Frontend
npm test                       # Vitest watch mode
npm run test:run               # Single run
npm run typecheck              # TypeScript check
npm run lint:fix               # ESLint + auto-fix

# Build & deploy
npm run build                  # Production frontend build
docker compose up              # Run containerized
```

## Standards

Before writing or modifying code, read the relevant standards in `agent-os/standards/`:

| Area | File |
|------|------|
| Tech stack overview | `global/tech-stack.md` |
| Coding style | `global/coding-style.md` |
| Project conventions | `global/conventions.md` |
| Controllers | `backend/controllers.md` |
| Models | `backend/models.md` |
| Services | `backend/services.md` |
| React components | `frontend/components.md` |
| Forms (react-hook-form + Zod) | `frontend/forms.md` |
| Inertia patterns | `frontend/inertia.md` |
| Test writing | `testing/test-writing.md` |

## Key Patterns

- **Inertia rendering:** Controllers use `render inertia: "Resource/Page", props: { ... }`
- **Page components:** Located at `app/frontend/pages/{Resource}/{Action}.tsx`
- **Service objects:** Business logic in `app/services/` (e.g., `InvoiceBuilder`)
- **Forms:** react-hook-form with Zod schemas for validation
- **UI components:** Import from `@/components/ui/` (shadcn pattern)

## Database

Single-user app with these core models:
- `User` - Authentication (bcrypt)
- `Client` - Customer with share token for public reports
- `Project` - Belongs to client, has hourly rate
- `TimeEntry` - Daily work log (unbilled/invoiced status)
- `Invoice` - Generated from time entries with PDF export
- `Setting` - Business details (singleton)
