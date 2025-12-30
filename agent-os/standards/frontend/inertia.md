## Inertia.js Standards

### Page Props Pattern
- Define explicit interface for page props
- Include flash messages in interface
- Use index signature for additional props

```tsx
interface PageProps {
  invoices: Invoice[];
  clients: Client[];
  filters: Filters;
  flash: {
    notice?: string;
    alert?: string;
  };
  [key: string]: unknown;
}

export default function InvoicesIndex() {
  const { invoices, clients, filters, flash } = usePage<PageProps>().props;
  // ...
}
```

### Navigation with router
```tsx
import { router } from "@inertiajs/react";

// Simple navigation
router.visit("/invoices");

// Navigation with query params
const params = new URLSearchParams();
params.set("status", "draft");
router.visit(`/invoices?${params.toString()}`);

// POST request
router.post("/invoices", { invoice: data });

// PUT request
router.put(`/invoices/${id}`, { invoice: data });

// DELETE request
router.delete(`/invoices/${id}`);
```

### Flash Message Handling
```tsx
import { useEffect } from "react";
import { toast } from "sonner";

export default function Page() {
  const { flash } = usePage<PageProps>().props;

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  return (
    <>
      <Toaster position="top-right" />
      {/* page content */}
    </>
  );
}
```

### Head Component for SEO
```tsx
import { Head } from "@inertiajs/react";

export default function InvoicesIndex() {
  return (
    <>
      <Head title="Invoices" />
      {/* page content */}
    </>
  );
}
```

### Links with Inertia
```tsx
import { Link } from "@inertiajs/react";

// Use Link for SPA navigation
<Link href="/invoices" className="text-stone-600 hover:text-stone-900">
  View All
</Link>

// Use router.visit for programmatic navigation
const handleClick = () => {
  router.visit(`/invoices/${id}`);
};
```

### Form Submissions
```tsx
// Method 1: Using router directly
const handleSubmit = (data: FormData) => {
  router.post("/invoices", { invoice: data });
};

// Method 2: With callbacks
router.post("/invoices", { invoice: data }, {
  onSuccess: () => {
    // Redirect handled by Rails
  },
  onError: (errors) => {
    // Handle validation errors
    console.error(errors);
  },
  preserveScroll: true,
});
```

### Preserving State on Navigation
```tsx
// Preserve scroll position
router.visit("/invoices", { preserveScroll: true });

// Preserve component state
router.visit("/invoices", { preserveState: true });
```

### Loading States
```tsx
import { router } from "@inertiajs/react";
import { useState, useEffect } from "react";

// Track navigation loading
const [isNavigating, setIsNavigating] = useState(false);

useEffect(() => {
  const startHandler = () => setIsNavigating(true);
  const finishHandler = () => setIsNavigating(false);

  router.on("start", startHandler);
  router.on("finish", finishHandler);

  return () => {
    // Cleanup
  };
}, []);
```
