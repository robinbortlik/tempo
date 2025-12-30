## Project Conventions

### Directory Structure
```
app/
├── controllers/         # Rails controllers (render inertia: pages)
├── frontend/
│   ├── components/      # Shared React components
│   │   ├── ui/          # shadcn/ui base components
│   │   └── __tests__/   # Component tests
│   ├── entrypoints/     # Vite entry points
│   ├── lib/             # Utility functions
│   ├── pages/           # Inertia page components
│   │   └── {Resource}/  # Resource-specific pages (Index, Show, New, Edit)
│   ├── styles/          # Global CSS (Tailwind)
│   └── test/            # Test setup
├── helpers/             # View helpers (for PDF templates)
├── jobs/                # Solid Queue background jobs
├── models/              # ActiveRecord models
├── services/            # Service objects
└── views/               # ERB templates (layouts, PDF, mailers)
spec/                    # RSpec tests
```

### Naming Conventions

#### Rails
- Controllers: plural `InvoicesController`
- Models: singular `Invoice`
- Tables: plural `invoices`
- Foreign keys: `model_id` (e.g., `client_id`)
- Services: descriptive name `InvoiceBuilder`, `DashboardStatsService`

#### React/TypeScript
- Page components: `{Resource}/Index.tsx`, `{Resource}/Show.tsx`
- Shared components: `PascalCase.tsx` (e.g., `PageHeader.tsx`)
- UI components: lowercase `{component}.tsx` (shadcn pattern)
- Test files: `{Component}.test.tsx` or `__tests__/{Component}.test.tsx`

### Inertia.js Patterns

#### Controller Rendering
```ruby
# Good - render Inertia page with props
def index
  render inertia: "Invoices/Index", props: {
    invoices: invoices_json,
    filters: current_filters
  }
end
```

#### Page Component Structure
```tsx
// Good - Inertia page component
import { Head, usePage } from "@inertiajs/react";

interface PageProps {
  invoices: Invoice[];
  flash: { notice?: string; alert?: string };
  [key: string]: unknown;
}

export default function InvoicesIndex() {
  const { invoices, flash } = usePage<PageProps>().props;
  // ...
}
```

### Environment Configuration
- Use Rails credentials for secrets
- Use environment variables for deployment config
- Never commit sensitive data to version control

### Git Workflow
- Use descriptive commit messages
- Reference issue numbers where applicable
- Keep commits focused on single changes

### Dependencies
- Add gems to appropriate group in Gemfile
- Add npm packages with appropriate flags (dependencies vs devDependencies)
- Document why non-obvious packages are included
