## ActiveRecord Query Standards

### Prevent N+1 Queries
- Use `includes` for eager loading associations
- Use `joins` when filtering by association data

```ruby
# Good - eager loading
Invoice.includes(:client).order(issue_date: :desc)
TimeEntry.includes(project: :client).where(status: :unbilled)

# Good - join for filtering
TimeEntry.joins(:project).where(projects: { client_id: client.id })
```

### Use Scopes
- Define reusable queries as model scopes
- Chain scopes for complex queries
- Use lambda syntax for scopes with parameters

```ruby
# Good - scope definition
scope :for_year, ->(year) { where("number LIKE ?", "#{year}-%") }
scope :for_client, ->(client) { where(client: client) }
scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }

# Usage
Invoice.for_year(2024).for_client(client)
TimeEntry.unbilled.for_date_range(start_date, end_date)
```

### Select Only Needed Data
- Use `select` to limit columns for performance
- Use `pluck` for simple value extraction
- Use `sum`, `count` for aggregations

```ruby
# Good
TimeEntry.where(project: project).sum(:hours)
Client.order(:name).pluck(:id, :name)
```

### Parameterized Queries
- Never interpolate user input into SQL
- Use hash conditions or `?` placeholders

```ruby
# Good
Invoice.where(status: params[:status])
Invoice.where("number LIKE ?", "#{year}-%")

# Bad - SQL injection risk
Invoice.where("status = '#{params[:status]}'")
```

### Transactions
- Wrap related operations in transactions
- Use `transaction` block for atomicity

```ruby
# Good
Invoice.transaction do
  invoice.save!
  time_entries.update_all(invoice_id: invoice.id)
  invoice.calculate_totals!
end
```

### Batch Operations
- Use `find_each` for large datasets
- Use `update_all` for bulk updates (bypasses callbacks)

```ruby
# Good - batch processing
TimeEntry.unbilled.find_each do |entry|
  process(entry)
end

# Good - bulk update
time_entries.update_all(invoice_id: invoice.id, status: :invoiced)
```

### Ordering
- Always specify explicit ordering for consistent results
- Order by multiple columns when needed

```ruby
# Good
Invoice.order(issue_date: :desc, created_at: :desc)
TimeEntry.order(date: :asc, created_at: :asc)
```
