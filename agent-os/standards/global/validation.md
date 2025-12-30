## Validation Standards

### Model Validations (Rails)
- Use ActiveRecord validations for data integrity
- Validate presence, format, uniqueness as needed
- Add custom validators for complex business rules

```ruby
# Good - model validations
validates :number, presence: true, uniqueness: true
validates :currency, format: { with: /\A[A-Z]{3}\z/, message: "must be 3 uppercase letters" },
                     allow_blank: true
validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
validate :period_end_after_period_start
```

### Database Constraints
- Add NOT NULL constraints for required fields
- Use foreign key constraints for referential integrity
- Add unique indexes for uniqueness validations

### Form Validation (Frontend)
- Use Zod schemas for form validation
- Integrate with react-hook-form using `@hookform/resolvers`
- Provide clear, user-friendly error messages

```tsx
// Good - Zod schema with react-hook-form
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";

const invoiceSchema = z.object({
  client_id: z.number().positive("Please select a client"),
  period_start: z.string().min(1, "Start date is required"),
  period_end: z.string().min(1, "End date is required"),
});

type InvoiceForm = z.infer<typeof invoiceSchema>;

const form = useForm<InvoiceForm>({
  resolver: zodResolver(invoiceSchema),
});
```

### Input Sanitization
- Use strong parameters in controllers
- Validate and sanitize user input
- Type check props in TypeScript components

```ruby
# Good - strong parameters
def invoice_params
  params.require(:invoice).permit(
    :client_id,
    :period_start,
    :period_end,
    :issue_date,
    :due_date,
    :notes
  )
end
```

### Custom Validation Methods
- Name validation methods clearly (e.g., `period_end_after_period_start`)
- Return early if dependent values are missing
- Add errors to specific fields

```ruby
# Good - custom validation
def due_date_after_issue_date
  return unless issue_date.present? && due_date.present?

  if due_date < issue_date
    errors.add(:due_date, "must be after or equal to issue date")
  end
end
```

### Business Rule Validation
- Validate complex rules in service objects
- Check state transitions before allowing them
- Return structured error responses

```ruby
# Good - service validation
def create_draft
  return { success: false, errors: ["No unbilled entries found"] } if unbilled_entries.empty?
  # ...
end
```
