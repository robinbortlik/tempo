## Rails Migration Standards

### Migration Naming
- Use descriptive names: `AddStatusToInvoices`, `CreateTimeEntries`
- Prefix with action: Add, Remove, Create, Change

### Reversible Migrations
- Always implement `change` method (auto-reversible) when possible
- Use `up`/`down` only when `change` can't auto-reverse

```ruby
# Good - reversible migration
class AddStatusToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :status, :integer, default: 0, null: false
    add_index :invoices, :status
  end
end
```

### Small, Focused Migrations
- One logical change per migration
- Separate schema changes from data migrations

### Index Management
- Add indexes for foreign keys
- Add indexes for columns used in WHERE, ORDER BY

```ruby
# Good - indexes
add_index :time_entries, :project_id
add_index :time_entries, :date
add_index :invoices, [:client_id, :status]
```

### Column Defaults
- Set sensible defaults for new columns
- Use `null: false` with defaults for required fields

```ruby
# Good - default values
add_column :invoices, :status, :integer, default: 0, null: false
add_column :time_entries, :hours, :decimal, precision: 5, scale: 2, default: 0
```

### Data Types
- Use `decimal` for financial amounts (not `float`)
- Use `integer` for enums
- Use `datetime` for timestamps, `date` for date-only values

```ruby
# Good - financial columns
add_column :invoices, :total_amount, :decimal, precision: 10, scale: 2
add_column :clients, :hourly_rate, :decimal, precision: 8, scale: 2
```

### Foreign Keys
- Add foreign key constraints for referential integrity
- Consider `on_delete` behavior

```ruby
# Good - foreign key
add_foreign_key :time_entries, :projects
add_foreign_key :invoices, :clients
```

### Never Modify Deployed Migrations
- Create new migrations to fix issues
- Never edit migrations that have been run in production
