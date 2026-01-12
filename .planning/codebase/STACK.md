# Technology Stack

**Analysis Date:** 2026-01-12

## Languages

**Primary:**
- Ruby 3.3.5 - All backend application code (`Gemfile`, `.ruby-version`)
- TypeScript 5.9.3 - All frontend application code (`package.json`, `tsconfig.json`)

**Secondary:**
- JavaScript (ES2020+) - Build scripts, config files
- HTML/ERB - Rails view templates, PDF templates

## Runtime

**Environment:**
- Ruby on Rails 8.1.1 - Backend web framework (`Gemfile.lock`)
- Node.js 22 LTS - Frontend build tooling (`Dockerfile`)
- SQLite3 3.8.0+ - Database (`config/database.yml`)

**Package Manager:**
- Bundler - Ruby dependencies (`Gemfile`, `Gemfile.lock`)
- npm - JavaScript dependencies (`package.json`, `package-lock.json`)

## Frameworks

**Core:**
- Rails 8.1.1 - Backend web framework (`Gemfile`)
- React 19.2.3 - Frontend UI framework (`package.json`)
- Inertia.js 2.3.4 - Server-driven SPA adapter (`package.json`, `config/initializers/inertia.rb`)

**Testing:**
- RSpec - Backend testing with FactoryBot (`Gemfile`)
- Vitest 4.0.16 - Frontend testing (`package.json`, `vitest.config.ts`)
- Testing Library 16.3.1 - React component testing (`package.json`)

**Build/Dev:**
- Vite 5.4.21 - Frontend bundler (`vite.config.ts`, `package.json`)
- Puma 5.0+ - Web server (`Gemfile`)
- Grover 1.2.4 - Puppeteer-based PDF generation (`config/initializers/grover.rb`)

## Key Dependencies

**Critical:**
- react-hook-form 7.69.0 - Form state management (`package.json`)
- Zod 4.2.1 - Schema validation (`package.json`)
- Alba 3.10.0 - JSON serialization (`config/initializers/alba.rb`)
- bcrypt 3.1.7 - Password hashing (`Gemfile`)
- Inertia Rails - Rails adapter for Inertia.js (`Gemfile`)

**Infrastructure:**
- solid_cache 1.0.10 - Database-backed caching (`Gemfile.lock`)
- solid_queue 1.2.4 - Database-backed job queue (`Gemfile.lock`)
- solid_cable 3.0.12 - Database-backed Action Cable (`Gemfile.lock`)

**UI:**
- Tailwind CSS 3.4.19 - Utility-first CSS (`tailwind.config.js`)
- Radix UI primitives - shadcn/ui component library (`package.json`)
- lucide-react 0.562.0 - Icon library (`package.json`)
- recharts 3.6.0 - Charting library (`package.json`)
- sonner 2.0.7 - Toast notifications (`package.json`)
- next-themes 0.4.6 - Dark mode theming (`package.json`)

**Internationalization:**
- i18next 25.7.4 - i18n framework (`package.json`)
- react-i18next 16.5.1 - React i18n binding (`package.json`)
- Rails I18n - Backend localization (`config/locales/`)

**Financial:**
- ibandit 1.27.0 - IBAN validation (`Gemfile.lock`)
- rqrcode 3.1.1 - QR code generation (`Gemfile.lock`)

## Configuration

**Environment:**
- dotenv-rails - Environment variable management (`.env`, `.env.example`)
- Rails credentials - Encrypted secrets (`config/master.key`)
- Required: DATABASE_URL (optional, defaults to SQLite)

**Build:**
- `vite.config.ts` - Vite bundler configuration with React + Ruby plugins
- `tsconfig.json` - TypeScript configuration with `@/` path alias to `app/frontend/`
- `tailwind.config.js` - Tailwind CSS with dark mode, custom brand colors, shadcn/ui theming
- `postcss.config.js` - PostCSS plugins for Tailwind and autoprefixer
- `config/database.yml` - SQLite3 database configuration with per-worktree support

## Platform Requirements

**Development:**
- macOS/Linux/Windows (any platform with Ruby + Node.js)
- Ruby 3.3+
- Node.js 22+
- No external services required (SQLite + Solid Cache/Queue/Cable)

**Production:**
- Docker container via Kamal deployment (`config/deploy.yml`)
- AWS ECR for image registry
- Single server deployment (no external database or queue required)
- Chromium browser for PDF generation

---

*Stack analysis: 2026-01-12*
*Update after major dependency changes*
