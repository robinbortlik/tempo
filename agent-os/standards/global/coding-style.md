## Coding Style Standards

### Ruby Naming Conventions
- Use `snake_case` for methods, variables, and file names
- Use `CamelCase` for classes and modules
- Use `SCREAMING_SNAKE_CASE` for constants
- Prefix boolean methods with `?` (e.g., `draft?`, `final?`)
- Prefix dangerous/mutating methods with `!` (e.g., `save!`, `calculate_totals!`)

### TypeScript Naming Conventions
- Use `PascalCase` for components, interfaces, and types
- Use `camelCase` for functions, variables, and props
- Use `SCREAMING_SNAKE_CASE` for constants
- Prefix interface props with component name (e.g., `PageHeaderProps`)

### Method Organization (Ruby)
- Keep methods small and focused (under 20 lines preferred)
- Extract complex conditionals into named methods
- Use guard clauses for early returns

```ruby
# Good - guard clause
def finalize
  return unless draft?
  return if time_entries.empty?

  perform_finalization
end
```

### Function Organization (TypeScript)
- Keep components focused on a single responsibility
- Extract complex logic into custom hooks or utility functions
- Use early returns for conditional rendering

```tsx
// Good - early return pattern
function InvoiceRow({ invoice }: InvoiceRowProps) {
  if (!invoice) return null;

  return <tr>...</tr>;
}
```

### Ruby Idioms
- Use `&.` (safe navigation) for nil-safe method chains
- Use `||=` for memoization
- Use `dig` for nested hash access
- Prefer `each` over `for` loops

```ruby
# Good
client&.currency
@cached_value ||= expensive_calculation
data.dig(:project, :name)
```

### TypeScript Idioms
- Use optional chaining `?.` for safe property access
- Use nullish coalescing `??` for default values
- Use destructuring for props and objects
- Prefer `const` over `let`

```tsx
// Good
const currency = invoice?.currency ?? 'EUR';
const { id, name } = client;
```

### Automated Formatting
- Ruby: Follow RuboCop Rails Omakase defaults
- TypeScript: Follow Prettier + ESLint configuration
- Keep line length under 100 characters
- Use 2-space indentation for both Ruby and TypeScript

### Remove Dead Code
- Delete unused methods, variables, and imports
- Remove commented-out code blocks
- Clean up unused components and hooks
