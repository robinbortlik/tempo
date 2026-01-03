## Alba Serializer Standards

### Overview
Use Alba serializers for JSON serialization instead of inline controller methods. Alba provides consistent, testable, and reusable serialization.

### File Organization
```
app/serializers/
├── client_serializer.rb
├── project_serializer.rb
├── work_entry_serializer.rb
├── invoice_serializer.rb
├── invoice_line_item_serializer.rb
└── settings_serializer.rb
```

### Basic Serializer Structure
```ruby
class ClientSerializer
  include Alba::Resource

  # Define attributes to serialize
  attributes :id, :name, :email, :currency, :hourly_rate

  # Custom attribute with transformation
  attribute :default_vat_rate do |client|
    client.default_vat_rate&.to_f
  end
end
```

### Nested Serializer Classes
Use nested classes for different serialization contexts:

```ruby
class ClientSerializer
  include Alba::Resource

  # Full detail - for show/edit pages
  attributes :id, :name, :address, :email, :currency, :hourly_rate

  # List view - minimal data for index pages
  class List
    include Alba::Resource
    attributes :id, :name, :email, :currency
  end

  # Empty defaults - for new record forms
  class Empty
    DEFAULTS = {
      id: nil,
      name: "",
      email: "",
      currency: ""
    }.freeze

    def self.serializable_hash = DEFAULTS
    def self.to_h = DEFAULTS
  end

  # Filter dropdown - minimal for select options
  class ForFilter
    include Alba::Resource
    attributes :id, :name
  end

  # Select with more context
  class ForSelect
    include Alba::Resource
    attributes :id, :name, :hourly_rate, :currency
  end
end
```

### Passing Context with params
Use `params:` option to pass context to serializers:

```ruby
# Controller
unbilled_stats = ClientStatsService.unbilled_stats_for_clients(clients.map(&:id))
ClientSerializer::List.new(clients, params: { unbilled_stats: unbilled_stats }).serializable_hash

# Serializer
class List
  include Alba::Resource
  attributes :id, :name

  attribute :unbilled_hours do |client|
    params[:unbilled_stats]&.dig(client.id, :hours) || 0
  end
end
```

### Serializing Collections vs Single Objects
```ruby
# Collection - returns Array
ClientSerializer::List.new(clients).serializable_hash

# Single object - returns Hash
ClientSerializer.new(client).serializable_hash

# Empty/nil objects - use PORO class
ClientSerializer::Empty.serializable_hash
```

### Grouped Data Serializers
For complex nested structures:

```ruby
class ProjectSerializer
  class GroupedByClient
    include Alba::Resource

    attribute :client do |data|
      {
        id: data[:client].id,
        name: data[:client].name,
        currency: data[:client].currency
      }
    end

    attribute :projects do |data|
      data[:projects].map do |project|
        {
          id: project.id,
          name: project.name,
          unbilled_hours: params[:unbilled_stats]&.dig(project.id) || 0
        }
      end
    end
  end
end

# Usage
data = { client: client, projects: client_projects }
ProjectSerializer::GroupedByClient.new(data, params: { unbilled_stats: stats }).serializable_hash
```

### Alba Configuration
Configure Alba in initializer:

```ruby
# config/initializers/alba.rb
Alba.backend = :active_support
Alba.inflector = :active_support
```

### Key Patterns
| Pattern | Usage |
|---------|-------|
| `params[:key]` | Access context passed via `params:` option |
| `serializable_hash` | Returns Array for collections, Hash for single objects |
| `Empty` class | PORO for nil/empty objects (Alba doesn't handle nil) |
| Nested classes | Different views: `List`, `ForFilter`, `ForSelect` |
| Numeric conversion | Use `&.to_f` for decimals passed to frontend |

### Common Mistakes to Avoid
```ruby
# Wrong - don't pass context as keyword args
Serializer.new(data, unbilled_stats: stats)

# Correct - use params: option
Serializer.new(data, params: { unbilled_stats: stats })

# Wrong - Alba can't serialize nil
Serializer.new(nil).serializable_hash

# Correct - use PORO for empty defaults
Serializer::Empty.serializable_hash

# Wrong - no to_a method
Serializer.new(collection).to_a

# Correct - use serializable_hash
Serializer.new(collection).serializable_hash
```
