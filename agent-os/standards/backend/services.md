## Service Layer Standards

### Service Structure
- Place services in `app/services/` directory
- Name services descriptively (e.g., `InvoiceBuilder`, `ClientStatsService`)
- Use plain Ruby classes (no base class needed for simple services)

```ruby
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

### Stats Services (Batch Loading)
Use stats services to prevent N+1 queries when serializing collections:

```ruby
class ClientStatsService
  def initialize(client)
    @client = client
  end

  def stats
    {
      total_hours: total_hours,
      unbilled_hours: unbilled_hours,
      unbilled_amount: unbilled_amount
    }
  end

  # Class method for batch loading multiple records
  def self.unbilled_stats_for_clients(client_ids)
    return {} if client_ids.empty?

    hours_by_client = WorkEntry.time
      .joins(:project)
      .where(projects: { client_id: client_ids })
      .unbilled
      .group("projects.client_id")
      .sum(:hours)

    amounts_by_client = calculate_amounts_by_client(client_ids)

    client_ids.index_with do |client_id|
      {
        hours: hours_by_client[client_id] || 0,
        amount: amounts_by_client[client_id] || 0
      }
    end
  end

  private

  def unbilled_hours
    @client.work_entries.unbilled.sum(:hours)
  end
end
```

Usage with serializers:
```ruby
# Controller
clients = Client.includes(:projects).to_a
unbilled_stats = ClientStatsService.unbilled_stats_for_clients(clients.map(&:id))

render inertia: "Clients/Index", props: {
  clients: ClientSerializer::List.new(clients, params: { unbilled_stats: unbilled_stats }).serializable_hash
}
```

### Filter Services
Extract complex filtering logic into dedicated services:

```ruby
class WorkEntryFilterService
  def initialize(scope: WorkEntry.all, params: {})
    @scope = scope
    @params = params
  end

  def filter
    @scope = @scope.includes(project: :client).order(date: :desc)
    @scope = filter_by_date_range
    @scope = filter_by_client
    @scope = filter_by_project
    @scope = filter_by_entry_type
    @scope
  end

  def summary
    entries = filter.to_a
    {
      total_hours: entries.select(&:time?).sum { |e| e.hours || 0 },
      total_amount: entries.sum { |e| e.calculated_amount || 0 }
    }
  end

  private

  def filter_by_date_range
    return @scope unless @params[:start_date].present?
    @scope.where("date >= ?", parse_date(@params[:start_date]))
  end

  def filter_by_client
    return @scope unless @params[:client_id].present?
    @scope.joins(:project).where(projects: { client_id: @params[:client_id] })
  end

  def parse_date(value)
    value.is_a?(String) ? Date.parse(value) : value
  end
end
```

### Validation Services
Use for complex deletion or operation validation:

```ruby
class DeletionValidator
  def self.can_delete_client?(client)
    return { valid: false, error: "Cannot delete client with projects." } if client.projects.exists?
    return { valid: false, error: "Cannot delete client with invoices." } if client.invoices.exists?
    { valid: true }
  end

  def self.can_delete_project?(project)
    return { valid: false, error: "Cannot delete project with invoiced entries." } if project.work_entries.invoiced.exists?
    { valid: true }
  end
end
```

### Utility Services
For shared, stateless operations:

```ruby
class LogoService
  def initialize(settings)
    @settings = settings
  end

  def to_data_url
    return nil unless @settings.logo?
    blob = @settings.logo.blob
    "data:#{blob.content_type};base64,#{Base64.strict_encode64(blob.download)}"
  end

  # Convenience class method
  def self.to_data_url(settings)
    new(settings).to_data_url
  end
end
```

### Position Management
For ordering/reordering items:

```ruby
class PositionManager
  def initialize(scope)
    @scope = scope
  end

  def next_position
    @scope.maximum(:position).to_i + 1
  end

  def swap(item1, item2)
    item1.class.transaction do
      temp = [item1.position, item2.position].max + 1000
      item1.update!(position: temp)
      item2.update!(position: item1.position)
      item1.update!(position: item2.position)
    end
  end

  def reorder(item, direction)
    case direction.to_s
    when "up" then move_up(item)
    when "down" then move_down(item)
    else false
    end
  end
end
```

### Service Dependencies
- Pass dependencies through constructor (keyword arguments preferred)
- Parse and validate inputs in constructor
- Provide sensible defaults where appropriate

```ruby
def initialize(client_id:, period_start:, period_end:, issue_date: nil, due_date: nil)
  @client = Client.find(client_id)
  @issue_date = issue_date || Date.current
  @due_date = due_date || calculate_default_due_date
end
```

### When to Use Services

| Use Service For | Don't Use Service For |
|-----------------|----------------------|
| Complex business logic | Simple CRUD operations |
| Multi-model operations | Single-model validations |
| Batch data loading | View formatting |
| External API calls | Simple calculations |
| Transaction-wrapped ops | Getters/setters |
| Complex filtering | Basic queries |
