## Tech Stack - Invoicing Application

### Framework & Runtime
- **Backend Framework:** Rails 8.1.1
- **Language:** Ruby 3.x (backend), TypeScript (frontend)
- **Package Manager:** Bundler (gems), npm (JavaScript)

### Frontend Architecture
- **Server-Client Bridge:** Inertia.js with `inertia_rails` gem + `@inertiajs/react`
- **JavaScript Framework:** React 19 with TypeScript
- **CSS Framework:** Tailwind CSS 3.x with `tailwindcss-animate`
- **UI Components:** Radix UI primitives with shadcn/ui patterns
- **Build Tool:** Vite Rails with `vite-plugin-ruby`
- **Icons:** Lucide React
- **Forms:** react-hook-form with Zod validation
- **Charts:** Recharts
- **Notifications:** Sonner (toast notifications)

### Database & Storage
- **Database:** SQLite3 (development/production)
- **ORM:** ActiveRecord
- **Caching:** Solid Cache (database-backed)
- **Background Jobs:** Solid Queue (database-backed)
- **WebSockets:** Solid Cable (database-backed)

### Authentication
- **Session Management:** Rails 8 built-in authentication (bcrypt)
- **Pattern:** Cookie-based sessions with `has_secure_password`

### Testing & Quality
- **Backend Tests:** RSpec with FactoryBot
- **Frontend Tests:** Vitest with React Testing Library
- **Code Coverage:** @vitest/coverage-v8
- **Browser Testing:** Capybara + Selenium WebDriver
- **Linting:** ESLint (TypeScript/React) + RuboCop Rails Omakase
- **Formatting:** Prettier
- **Security Scanning:** Brakeman, bundler-audit

### PDF Generation
- **Library:** Grover (Puppeteer-based PDF generation)
- **Headless Browser:** Puppeteer

### Deployment
- **Container:** Docker with Kamal
- **HTTP Acceleration:** Thruster (asset caching/compression)
- **Web Server:** Puma

### Key Patterns
- **Page Components:** React components in `app/frontend/pages/`
- **Shared Components:** `app/frontend/components/` and `app/frontend/components/ui/`
- **Controller → Frontend:** Inertia `render inertia:` with props
- **Services:** Plain Ruby service objects in `app/services/`
- **Styling:** Utility-first CSS with Tailwind classes
