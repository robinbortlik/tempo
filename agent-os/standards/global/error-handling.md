## Error Handling Standards

### Controller Error Handling
- Rescue specific exceptions, not all StandardError
- Use flash messages for user feedback via Inertia
- Redirect with appropriate messages

```ruby
# Good - controller error handling
def create
  result = InvoiceBuilder.new(...).create_draft

  if result[:success]
    redirect_to invoice_path(result[:invoice]), notice: "Invoice created successfully."
  else
    redirect_to new_invoice_path(params.to_h), alert: result[:errors].first
  end
end
```

### Service Error Handling
- Return structured result objects from services
- Include success/failure status and error messages
- Use transactions for multi-step operations

```ruby
# Good - service result pattern
def create_draft
  return { success: false, errors: ["No unbilled entries found"] } if unbilled_entries.empty?

  Invoice.transaction do
    invoice.save!
    unbilled_entries.update_all(invoice_id: invoice.id)
    invoice.calculate_totals!
  end

  { success: true, invoice: invoice }
rescue ActiveRecord::RecordInvalid => e
  { success: false, errors: e.record.errors.full_messages }
end
```

### Frontend Error Handling
- Use Sonner for toast notifications
- Handle flash messages from Inertia props
- Display user-friendly error messages

```tsx
// Good - flash message handling
import { toast } from "sonner";

useEffect(() => {
  if (flash.notice) {
    toast.success(flash.notice);
  }
  if (flash.alert) {
    toast.error(flash.alert);
  }
}, [flash.notice, flash.alert]);
```

### Form Error Display
- Show validation errors near relevant fields
- Use react-hook-form error state
- Provide clear guidance for fixing errors

```tsx
// Good - form error display
<Input
  {...form.register("email")}
  className={errors.email ? "border-red-500" : ""}
/>
{errors.email && (
  <p className="text-sm text-red-500">{errors.email.message}</p>
)}
```

### State-Based Error Tracking
- Use model states for operation status (draft, final)
- Check state before allowing operations
- Return early with clear error messages

```ruby
# Good - state checking
def finalize
  unless @invoice.draft?
    redirect_to invoice_path(@invoice), alert: "Invoice is already finalized."
    return
  end
  # ...
end
```

### Loading and Error States (Frontend)
- Show loading indicators during async operations
- Handle network errors gracefully
- Provide retry options where appropriate

```tsx
// Good - loading state
const [isSubmitting, setIsSubmitting] = useState(false);

const handleSubmit = async (data: FormData) => {
  setIsSubmitting(true);
  try {
    router.post("/invoices", { data });
  } finally {
    setIsSubmitting(false);
  }
};
```
