# Codebase Structure

**Analysis Date:** 2026-01-12

## Directory Layout

```
invoicing/
├── app/                        # Rails application root
│   ├── frontend/              # React 19 + TypeScript SPA
│   │   ├── entrypoints/       # Vite entry points
│   │   ├── pages/             # Inertia page components
│   │   ├── components/        # Shared React components + ui/
│   │   ├── lib/               # Utility functions
│   │   ├── types/             # TypeScript type definitions
│   │   ├── styles/            # CSS (Tailwind entry)
│   │   ├── locales/           # i18n translation files
│   │   └── test/              # Test setup
│   ├── controllers/           # Rails ActionControllers
│   ├── models/                # ActiveRecord models
│   ├── services/              # Business logic service objects
│   ├── serializers/           # Alba JSON serializers
│   ├── views/                 # ERB templates (layouts, PDF)
│   ├── mailers/               # ActionMailer classes
│   ├── jobs/                  # ActiveJob classes
│   └── helpers/               # View helpers
├── config/                    # Rails configuration
│   ├── initializers/          # App initialization
│   ├── locales/               # Rails I18n files
│   └── environments/          # Environment configs
├── db/                        # Database
│   ├── migrate/               # Migration files
│   └── schema.rb              # Current schema
├── spec/                      # RSpec tests
│   ├── factories/             # FactoryBot factories
│   ├── models/                # Model specs
│   ├── services/              # Service specs
│   ├── requests/              # Controller specs
│   └── support/               # Test helpers
├── bin/                       # Executable scripts
├── agent-os/                  # Project standards
│   └── standards/             # Coding standards docs
└── .planning/                 # Project planning docs
```

## Directory Purposes

**app/frontend/**
- Purpose: React 19 + TypeScript single-page application
- Contains: Page components, shared components, utilities, styles
- Key files: `entrypoints/application.tsx` (SPA entry point)
- Subdirectories:
  - `pages/` - One folder per resource (Invoices/, Clients/, etc.)
  - `components/ui/` - shadcn/ui Radix components
  - `lib/` - Utility functions (i18n, utils)

**app/controllers/**
- Purpose: Handle HTTP requests, render Inertia responses
- Contains: One controller per resource
- Key files: `invoices_controller.rb`, `work_entries_controller.rb`
- Subdirectories: `concerns/` (authentication, draft_invoice_only)

**app/models/**
- Purpose: ActiveRecord entities with validations and associations
- Contains: User, Client, Project, WorkEntry, Invoice, InvoiceLineItem, Setting
- Key files: `invoice.rb`, `work_entry.rb`, `client.rb`
- Subdirectories: `concerns/` (model concerns)

**app/services/**
- Purpose: Business logic encapsulation
- Contains: Service objects for complex operations
- Key files: `invoice_builder.rb`, `invoice_pdf_service.rb`, `dashboard_stats_service.rb`

**app/serializers/**
- Purpose: JSON transformation for Inertia props
- Contains: Alba serializers with nested variants
- Key files: `invoice_serializer.rb`, `client_serializer.rb`

**spec/**
- Purpose: RSpec test suite
- Contains: Model, service, request, system specs
- Key files: `rails_helper.rb`, `spec_helper.rb`
- Subdirectories: `factories/` (FactoryBot), `support/` (helpers)

## Key File Locations

**Entry Points:**
- `config.ru` - Rack application entry
- `bin/dev` - Development server launcher
- `app/frontend/entrypoints/application.tsx` - React SPA entry

**Configuration:**
- `config/routes.rb` - Route definitions
- `config/application.rb` - Rails app class (Tempo::Application)
- `tsconfig.json` - TypeScript configuration
- `vite.config.ts` - Vite bundler configuration
- `tailwind.config.js` - Tailwind CSS configuration
- `config/initializers/inertia.rb` - Inertia configuration

**Core Logic:**
- `app/services/invoice_builder.rb` - Invoice creation logic
- `app/services/invoice_pdf_service.rb` - PDF generation
- `app/services/dashboard_stats_service.rb` - Analytics
- `app/services/payment_qr_code_generator.rb` - QR code generation

**Testing:**
- `spec/` - RSpec backend tests
- `app/frontend/**/__tests__/` - Vitest frontend tests
- `vitest.config.ts` - Vitest configuration

**Documentation:**
- `CLAUDE.md` - Project instructions for Claude
- `agent-os/standards/` - Coding standards

## Naming Conventions

**Files:**
- `snake_case.rb` - Ruby files (models, services, controllers)
- `PascalCase.tsx` - React page components
- `lowercase.tsx` - shadcn/ui components (button.tsx, input.tsx)
- `*.test.tsx` - Frontend test files
- `*_spec.rb` - Backend test files

**Directories:**
- `PascalCase/` - React page folders (Invoices/, Clients/)
- `snake_case/` - Ruby directories (controllers/, services/)
- `__tests__/` - Frontend test directories

**Special Patterns:**
- `{Resource}/Index.tsx` - List pages
- `{Resource}/Show.tsx` - Detail pages
- `{Resource}/New.tsx` - Create forms
- `{Resource}/Edit.tsx` - Edit forms
- `{Resource}/Form.tsx` - Shared form component

## Where to Add New Code

**New Feature:**
- Primary code: `app/frontend/pages/{Resource}/`
- Controller: `app/controllers/{resource}_controller.rb`
- Service: `app/services/{feature}_service.rb`
- Tests: `spec/` (backend), `app/frontend/**/__tests__/` (frontend)

**New Component/Module:**
- Shared component: `app/frontend/components/`
- UI component: `app/frontend/components/ui/`
- Page-specific: `app/frontend/pages/{Resource}/components/`
- Types: `app/frontend/types/`

**New Route/Command:**
- Definition: `config/routes.rb`
- Controller: `app/controllers/`
- Page: `app/frontend/pages/`

**Utilities:**
- Frontend helpers: `app/frontend/lib/`
- Backend helpers: `app/helpers/`
- Type definitions: `app/frontend/types/`

## Special Directories

**app/frontend/**
- Purpose: Vite-bundled React application
- Source: Processed by Vite, output to public/
- Committed: Yes

**db/migrate/**
- Purpose: Database migration files
- Source: Generated by `rails generate migration`
- Committed: Yes

**node_modules/**
- Purpose: npm dependencies
- Source: Auto-generated by `npm install`
- Committed: No (in .gitignore)

**public/vite/**
- Purpose: Vite build output
- Source: Generated by `npm run build`
- Committed: No (in .gitignore)

**.planning/**
- Purpose: Project planning and codebase documentation
- Source: Generated by GSD workflow
- Committed: Yes

---

*Structure analysis: 2026-01-12*
*Update when directory structure changes*
