# Coding Conventions

**Analysis Date:** 2026-01-12

## Naming Patterns

**Files:**
- `snake_case.rb` - Ruby files (invoice_builder.rb, invoices_controller.rb)
- `PascalCase.tsx` - React page components (Index.tsx, Show.tsx)
- `lowercase.tsx` - shadcn/ui components (button.tsx, input.tsx)
- `*.test.tsx` - Frontend test files
- `*_spec.rb` - Backend test files

**Functions:**
- Ruby: `snake_case` for all methods (e.g., `calculate_totals`, `create_draft`)
- TypeScript: `camelCase` for functions (e.g., `handleSubmit`, `formatCurrency`)
- Event handlers: `handle{Event}` pattern (handleClick, handleSubmit)

**Variables:**
- Ruby: `snake_case` for variables, `@instance_variables` for instance vars
- TypeScript: `camelCase` for variables
- Constants: `SCREAMING_SNAKE_CASE` in both languages

**Types:**
- TypeScript interfaces: `PascalCase` (e.g., `Invoice`, `Client`, `PageHeaderProps`)
- Props interfaces: suffix with `Props` (e.g., `PageHeaderProps`, `ButtonProps`)
- No `I` prefix for interfaces

## Code Style

**Formatting:**
- Prettier for frontend (`.prettierrc`)
- RuboCop for backend (`.rubocop.yml` - rails-omakase preset)
- 2-space indentation in all files
- 80 character line length (Prettier), 100 (RuboCop)

**Quotes & Semicolons:**
- Frontend: Double quotes for strings, semicolons required
- Backend: Double quotes for strings (Rails convention)

**Linting:**
- ESLint for TypeScript/React (`eslint.config.mjs`)
- RuboCop for Ruby (inherits from rubocop-rails-omakase)
- Commands: `npm run lint`, `bundle exec rubocop`

## Import Organization

**Order (TypeScript):**
1. React and external packages (react, @inertiajs/react)
2. Internal modules (@/components, @/lib)
3. Relative imports (./components, ../types)
4. Type imports (import type { })

**Grouping:**
- Blank line between groups
- Alphabetical within groups optional

**Path Aliases:**
- `@/` maps to `app/frontend/`
- Example: `import { Button } from "@/components/ui/button"`

## Error Handling

**Patterns:**
- Ruby: Raise exceptions, catch at controller boundaries
- TypeScript: try/catch for async operations
- Services return result hashes: `{ success: bool, data: ..., errors: [...] }`

**Error Types:**
- Use Rails validations for model errors
- Use Zod for frontend form validation
- Display errors via flash messages (Inertia) or form field errors

## Logging

**Framework:**
- Rails logger (stdout in production)
- No frontend logging library (console.log in development only)

**Patterns:**
- Log state transitions and important operations
- Filter sensitive parameters (`config/initializers/filter_parameter_logging.rb`)
- No console.log in committed frontend code

## Comments

**When to Comment:**
- Explain "why" not "what"
- Document business rules and complex algorithms
- Avoid obvious comments

**JSDoc/TSDoc:**
- Optional for most functions
- Required for complex utility functions

**TODO Comments:**
- Format: `# TODO: description` (Ruby), `// TODO: description` (TS)
- Link to issue if exists

## Function Design

**Size:**
- Keep under 50 lines
- Extract helpers for complex logic

**Parameters:**
- Ruby: Keyword arguments for 2+ params
- TypeScript: Props objects for components, destructuring in params

**Return Values:**
- Ruby services: Return hash with success/data/errors keys
- Controllers: Render Inertia or redirect

## Module Design

**Exports:**
- Named exports preferred in TypeScript
- Default exports for React page components
- Export public API from index files

**Barrel Files:**
- Use index.ts to re-export component APIs
- shadcn/ui components export individually

## Rails Conventions

**Controllers:**
- Use `render inertia: "Page/Name", props: { ... }` pattern
- One controller per resource
- Extract business logic to services

**Models:**
- Singular class names (Invoice, Client)
- Keep models thin - business logic in services
- Use scopes for common queries
- Use enums for status fields

**Services:**
- Descriptive names (InvoiceBuilder, DashboardStatsService)
- No base class inheritance
- Return result hashes, not exceptions

**Serializers:**
- One serializer per model
- Use nested classes for variants (List, ForSelect)
- Transform data for frontend consumption

## React Conventions

**Components:**
- Functional components only
- Props interface defined above component
- Destructure props in function signature

**Hooks:**
- Custom hooks in `lib/` directory
- Use react-hook-form for forms
- Use Inertia hooks for navigation/forms

**Inertia Pattern:**
- Page components receive props from controller
- Use `usePage()` for shared props (auth, flash)
- Use `router.visit()` for navigation

---

*Convention analysis: 2026-01-12*
*Update when patterns change*
