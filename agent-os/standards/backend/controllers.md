## Rails Controller Standards (Inertia.js)

### Controller Structure
- Inherit from `ApplicationController`
- Keep controllers thin - delegate logic to services
- Use `render inertia:` for page rendering

```ruby
# Good - Inertia controller pattern
class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy]

  def index
    render inertia: "Invoices/Index", props: {
      invoices: invoices_json,
      filters: current_filters
    }
  end

  def show
    render inertia: "Invoices/Show", props: {
      invoice: invoice_json(@invoice),
      time_entries: time_entries_json(@invoice)
    }
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end
end
```

### RESTful Actions
- Use standard REST actions: index, show, new, create, edit, update, destroy
- Add custom actions sparingly (e.g., `finalize`, `pdf`)
- Use member routes for record-specific actions

### Props Preparation
- Prepare all data for React components in controller
- Create `*_json` helper methods for consistent serialization
- Include only necessary data to minimize payload

```ruby
# Good - JSON serialization methods
private

def invoices_json
  filtered_invoices.map do |invoice|
    {
      id: invoice.id,
      number: invoice.number,
      status: invoice.status,
      client_name: invoice.client.name,
      total_amount: invoice.total_amount
    }
  end
end
```

### Strong Parameters
- Always use `params.require().permit()`
- Whitelist only necessary attributes
- Create separate param methods for create/update if different

```ruby
# Good - separate param methods
def invoice_params
  params.require(:invoice).permit(:client_id, :period_start, :period_end, :notes)
end

def update_invoice_params
  params.require(:invoice).permit(:issue_date, :due_date, :notes)
end
```

### Redirects and Flash Messages
- Use `redirect_to` with `notice:` for success
- Use `redirect_to` with `alert:` for errors
- Flash messages are automatically passed to Inertia props

```ruby
# Good - flash messages
if result[:success]
  redirect_to invoice_path(result[:invoice]), notice: "Invoice created successfully."
else
  redirect_to new_invoice_path, alert: result[:errors].first
end
```

### Service Delegation
- Delegate complex operations to service objects
- Controllers should only orchestrate, not implement logic

```ruby
# Good - service delegation
def create
  builder = InvoiceBuilder.new(
    client_id: invoice_params[:client_id],
    period_start: invoice_params[:period_start],
    period_end: invoice_params[:period_end]
  )
  result = builder.create_draft
  # ...
end
```

### State Guards
- Check model state before operations
- Return early with error messages

```ruby
# Good - state guard
def edit
  unless @invoice.draft?
    redirect_to invoice_path(@invoice), alert: "Cannot edit a finalized invoice."
    return
  end
  # ...
end
```
