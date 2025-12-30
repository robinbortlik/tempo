## Service Layer Standards

### Service Structure
- Place services in `app/services/` directory
- Name services descriptively (e.g., `InvoiceBuilder`, `DashboardStatsService`)
- Use plain Ruby classes (no base class needed for simple services)

```ruby
# Good - service class
class InvoiceBuilder
  attr_reader :client, :period_start, :period_end

  def initialize(client_id:, period_start:, period_end:, **options)
    @client = Client.find(client_id)
    @period_start = parse_date(period_start)
    @period_end = parse_date(period_end)
    @options = options
  end

  def preview
    { client: client_data, entries: entries_data, total: total_amount }
  end

  def create_draft
    # ...
  end

  private

  def parse_date(value)
    value.is_a?(String) ? Date.parse(value) : value
  end
end
```

### Result Pattern
- Return hash with `success:` boolean and data or errors
- Use transactions for multi-step operations
- Rescue specific exceptions

```ruby
# Good - result pattern
def create_draft
  return { success: false, errors: ["No entries found"] } if entries.empty?

  Invoice.transaction do
    invoice.save!
    entries.update_all(invoice_id: invoice.id)
    invoice.calculate_totals!
  end

  { success: true, invoice: invoice }
rescue ActiveRecord::RecordInvalid => e
  { success: false, errors: e.record.errors.full_messages }
end
```

### Query Services
- Use for complex data aggregation
- Return structured data for frontend consumption
- Memoize expensive calculations

```ruby
# Good - stats service
class DashboardStatsService
  def initialize(user:, period:)
    @user = user
    @period = period
  end

  def stats
    {
      total_hours: total_hours,
      total_revenue: total_revenue,
      unbilled_amount: unbilled_amount
    }
  end

  private

  def total_hours
    @total_hours ||= time_entries.sum(:hours)
  end

  def time_entries
    @time_entries ||= TimeEntry.where(user: @user).for_period(@period)
  end
end
```

### Service Dependencies
- Pass dependencies through constructor (keyword arguments preferred)
- Parse and validate inputs in constructor
- Provide sensible defaults where appropriate

```ruby
# Good - dependency injection
def initialize(client_id:, period_start:, period_end:, issue_date: nil, due_date: nil)
  @client = Client.find(client_id)
  @issue_date = issue_date || Date.current
  @due_date = due_date || calculate_default_due_date
end
```

### When to Use Services
- Complex business logic spanning multiple models
- Data transformation and aggregation
- External API interactions
- Operations that need transactions

### When NOT to Use Services
- Simple CRUD operations (use model directly)
- Single-model validations (use model validations)
- View formatting (use helpers or frontend)
