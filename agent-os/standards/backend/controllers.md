## Rails Controller Standards (Inertia.js)

### Controller Structure
- Inherit from `ApplicationController`
- Keep controllers thin - delegate logic to services
- Use `render inertia:` for page rendering
- Use Alba serializers for JSON data (see `backend/serializers.md`)

```ruby
class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy]

  def index
    render inertia: "Invoices/Index", props: {
      invoices: InvoiceSerializer::List.new(filtered_invoices).serializable_hash,
      clients: ClientSerializer::ForFilter.new(Client.order(:name)).serializable_hash,
      filters: current_filters
    }
  end

  def show
    render inertia: "Invoices/Show", props: {
      invoice: InvoiceSerializer.new(@invoice).serializable_hash,
      line_items: InvoiceLineItemSerializer.new(@invoice.line_items).serializable_hash
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

### Props Preparation with Serializers
- Use Alba serializers instead of inline `*_json` methods
- Use `serializable_hash` for Inertia props
- Pass context via `params:` option when needed

```ruby
def index
  clients = Client.includes(:projects).to_a
  unbilled_stats = ClientStatsService.unbilled_stats_for_clients(clients.map(&:id))

  render inertia: "Clients/Index", props: {
    clients: ClientSerializer::List.new(clients, params: { unbilled_stats: unbilled_stats }).serializable_hash
  }
end

def new
  render inertia: "Clients/New", props: {
    client: ClientSerializer::Empty.serializable_hash
  }
end
```

### Strong Parameters
- Always use `params.require().permit()`
- Whitelist only necessary attributes
- Create separate param methods for create/update if different

```ruby
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
- Use `.to_sentence` for multiple error messages
- Flash messages are automatically passed to Inertia props

```ruby
if result[:success]
  redirect_to invoice_path(result[:invoice]), notice: "Invoice created successfully."
else
  redirect_to new_invoice_path, alert: result[:errors].to_sentence
end

# For model errors
if @client.save
  redirect_to client_path(@client), notice: "Client created successfully."
else
  redirect_to new_client_path, alert: @client.errors.full_messages.to_sentence
end
```

### Service Delegation
- Delegate complex operations to service objects
- Controllers should only orchestrate, not implement logic
- Use stats services for batch loading to avoid N+1 queries

```ruby
def create
  builder = InvoiceBuilder.new(
    client_id: invoice_params[:client_id],
    period_start: invoice_params[:period_start],
    period_end: invoice_params[:period_end]
  )
  result = builder.create_draft
  # ...
end

def index
  # Use stats service for batch loading
  unbilled_stats = ClientStatsService.unbilled_stats_for_clients(clients.map(&:id))
  # Pass to serializer via params
end
```

### State Guards
- Check model state before operations
- Return early with error messages
- Use concerns for shared guard logic

```ruby
# Using inline guard
def edit
  unless @invoice.draft?
    redirect_to invoice_path(@invoice), alert: "Cannot edit a finalized invoice."
    return
  end
  # ...
end

# Or use before_action with concern
include DraftInvoiceOnly
before_action :require_draft_invoice, only: [:update, :destroy]
```

### Deletion Validation
- Use DeletionValidator service for complex deletion checks
- Return structured error messages

```ruby
def destroy
  result = DeletionValidator.can_delete_client?(@client)

  if result[:valid]
    @client.destroy
    redirect_to clients_path, notice: "Client deleted successfully."
  else
    redirect_to client_path(@client), alert: result[:error]
  end
end
```

### PDF Generation
- Use dedicated PDF service for generation
- Pass controller reference for render_to_string

```ruby
def pdf
  pdf_service = InvoicePdfService.new(invoice: @invoice, controller: self)

  send_data pdf_service.generate,
            filename: pdf_service.filename,
            type: "application/pdf",
            disposition: "attachment"
end
```
