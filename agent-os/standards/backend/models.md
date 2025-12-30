## ActiveRecord Model Standards

### Model Structure
Order model contents consistently:
1. Associations
2. Enums
3. Callbacks
4. Validations
5. Scopes
6. Class methods
7. Instance methods

```ruby
class Invoice < ApplicationRecord
  # Associations
  belongs_to :client
  has_many :time_entries, dependent: :nullify

  # Enums
  enum :status, { draft: 0, final: 1 }

  # Callbacks
  before_validation :set_invoice_number, on: :create

  # Validations
  validates :number, presence: true, uniqueness: true
  validates :client, presence: true

  # Scopes
  scope :for_year, ->(year) { where("number LIKE ?", "#{year}-%") }
  scope :for_client, ->(client) { where(client: client) }

  # Instance methods
  def calculate_totals
    # ...
  end
end
```

### Enums
- Use integer-backed enums for database efficiency
- Define with symbol keys for cleaner code

```ruby
# Good - integer enum
enum :status, { draft: 0, final: 1 }
enum :billing_status, { unbilled: 0, invoiced: 1 }
```

### Associations
- Always specify `dependent:` option for has_many
- Use `optional: true` for nullable belongs_to
- Use `touch: true` when parent needs cache invalidation

```ruby
# Good
belongs_to :client
belongs_to :project, optional: true
has_many :time_entries, dependent: :nullify
has_many :projects, dependent: :destroy
```

### Scopes
- Use lambdas for all scopes
- Name scopes descriptively
- Chain scopes for complex queries

```ruby
# Good - scope patterns
scope :for_year, ->(year) { where("number LIKE ?", "#{year}-%") }
scope :for_client, ->(client) { where(client: client) }
scope :for_date_range, ->(start_date, end_date) {
  where(date: start_date..end_date)
}
```

### Callbacks
- Use `before_validation` for setting defaults
- Use `after_save` for side effects sparingly
- Avoid complex logic in callbacks

```ruby
# Good - simple callback
before_validation :set_invoice_number, on: :create

private

def set_invoice_number
  self.number ||= InvoiceNumberGenerator.generate
end
```

### Custom Validations
- Define as private methods
- Return early if dependent values missing
- Add errors to specific fields

```ruby
# Good - custom validation
validate :period_end_after_period_start

private

def period_end_after_period_start
  return unless period_start.present? && period_end.present?

  if period_end < period_start
    errors.add(:period_end, "must be after or equal to period start")
  end
end
```

### Calculation Methods
- Provide both `calculate_*` and `calculate_*!` versions
- Return `self` from non-bang version for chaining

```ruby
# Good - calculation pattern
def calculate_totals
  self.total_hours = time_entries.sum(:hours)
  self.total_amount = time_entries.sum { |e| e.calculated_amount || 0 }
  self
end

def calculate_totals!
  calculate_totals
  save!
end
```

### Helper Methods
- Create predicate methods using enum helpers (e.g., `draft?`, `final?`)
- Use delegation for common patterns
