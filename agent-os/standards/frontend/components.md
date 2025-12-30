## React Component Standards

### Component Structure
- Use function components with TypeScript
- Define props interface above component
- Export as default for page components

```tsx
// Good - component structure
interface InvoiceRowProps {
  invoice: Invoice;
  onSelect: (id: number) => void;
}

export function InvoiceRow({ invoice, onSelect }: InvoiceRowProps) {
  return (
    <tr onClick={() => onSelect(invoice.id)}>
      <td>{invoice.number}</td>
    </tr>
  );
}
```

### Page Components (Inertia)
- Place in `app/frontend/pages/{Resource}/`
- Use `usePage` hook to access props
- Include `Head` component for page title

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

  return (
    <>
      <Head title="Invoices" />
      <div className="p-8">
        {/* content */}
      </div>
    </>
  );
}
```

### Shared Components
- Place in `app/frontend/components/`
- Use named exports for shared components
- Create dedicated test files

```tsx
// Good - shared component
export function PageHeader({ title, description }: PageHeaderProps) {
  return (
    <div className="mb-8">
      <h1 className="text-2xl font-semibold">{title}</h1>
      {description && <p className="text-stone-500 mt-1">{description}</p>}
    </div>
  );
}
```

### UI Components (shadcn/ui)
- Place in `app/frontend/components/ui/`
- Follow shadcn/ui patterns with Radix primitives
- Use `cn()` utility for conditional classes

```tsx
// Good - UI component with variants
import { cn } from "@/lib/utils";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "default" | "destructive" | "outline";
}

export function Button({ className, variant = "default", ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        "px-4 py-2 rounded-lg font-medium",
        variant === "default" && "bg-stone-900 text-white",
        variant === "destructive" && "bg-red-600 text-white",
        className
      )}
      {...props}
    />
  );
}
```

### Props Typing
- Define explicit interfaces for props
- Use TypeScript's utility types when helpful
- Extend HTML element props when wrapping native elements

```tsx
// Good - extending native props
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}
```

### Event Handlers
- Use descriptive handler names (e.g., `handleRowClick`, `handleSubmit`)
- Type event parameters explicitly when needed

```tsx
// Good - event handler
const handleRowClick = (invoiceId: number) => {
  router.visit(`/invoices/${invoiceId}`);
};
```

### Conditional Rendering
- Use early returns for guard clauses
- Use ternary for simple conditions
- Use `&&` for presence checks

```tsx
// Good - conditional rendering
if (!invoice) return null;

return (
  <div>
    {invoice.notes && <p>{invoice.notes}</p>}
    {invoice.status === "draft" ? <DraftBadge /> : <FinalBadge />}
  </div>
);
```
