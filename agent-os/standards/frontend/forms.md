## Form Standards

### Form Library Stack
- **Form State:** react-hook-form
- **Validation:** Zod schemas
- **Integration:** @hookform/resolvers/zod

### Basic Form Setup
```tsx
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email address"),
  hourly_rate: z.number().positive("Rate must be positive").optional(),
});

type FormData = z.infer<typeof schema>;

export default function ClientForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: "",
      email: "",
    },
  });

  const onSubmit = (data: FormData) => {
    router.post("/clients", { client: data });
  };

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* fields */}
    </form>
  );
}
```

### Form Fields with Validation
```tsx
// Good - field with error display
<div className="space-y-2">
  <Label htmlFor="name">Name</Label>
  <Input
    id="name"
    {...form.register("name")}
    className={form.formState.errors.name ? "border-red-500" : ""}
  />
  {form.formState.errors.name && (
    <p className="text-sm text-red-500">
      {form.formState.errors.name.message}
    </p>
  )}
</div>
```

### Zod Schema Patterns
```tsx
// Good - common validation patterns
const invoiceSchema = z.object({
  client_id: z.number().positive("Please select a client"),
  period_start: z.string().min(1, "Start date is required"),
  period_end: z.string().min(1, "End date is required"),
  notes: z.string().optional(),
  hourly_rate: z.coerce.number().positive().optional(),
});

// Refinements for cross-field validation
const dateRangeSchema = z.object({
  start_date: z.string(),
  end_date: z.string(),
}).refine(
  (data) => new Date(data.end_date) >= new Date(data.start_date),
  { message: "End date must be after start date", path: ["end_date"] }
);
```

### Inertia Form Submission
```tsx
import { router } from "@inertiajs/react";

const onSubmit = (data: FormData) => {
  router.post("/invoices", {
    invoice: data,
  });
};

// With redirect handling
const onSubmit = (data: FormData) => {
  router.post("/invoices", { invoice: data }, {
    onSuccess: () => {
      // Handle success
    },
    onError: (errors) => {
      // Handle server-side errors
    },
  });
};
```

### Edit Forms with Initial Data
```tsx
interface EditProps {
  client: Client;
}

export default function ClientEdit({ client }: EditProps) {
  const form = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: client.name,
      email: client.email ?? "",
      hourly_rate: client.hourly_rate,
    },
  });

  const onSubmit = (data: FormData) => {
    router.put(`/clients/${client.id}`, { client: data });
  };
  // ...
}
```

### Select Fields
```tsx
// Good - select with options from props
<div className="space-y-2">
  <Label htmlFor="client_id">Client</Label>
  <select
    id="client_id"
    {...form.register("client_id", { valueAsNumber: true })}
    className="w-full rounded-md border border-stone-200 px-3 py-2"
  >
    <option value="">Select a client</option>
    {clients.map((client) => (
      <option key={client.id} value={client.id}>
        {client.name}
      </option>
    ))}
  </select>
</div>
```

### Form Submission State
```tsx
// Good - disable during submission
<Button
  type="submit"
  disabled={form.formState.isSubmitting}
>
  {form.formState.isSubmitting ? "Saving..." : "Save"}
</Button>
```
