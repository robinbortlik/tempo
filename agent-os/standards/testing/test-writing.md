## Testing Standards

### Test Stack
- **Backend:** RSpec with FactoryBot
- **Frontend:** Vitest with React Testing Library
- **Browser:** Capybara with Selenium WebDriver

---

## RSpec (Backend)

### Test Organization
```
spec/
├── factories/        # FactoryBot factories
├── models/           # Model specs
├── services/         # Service specs
├── requests/         # Request/controller specs
└── support/          # Shared helpers
```

### FactoryBot Usage
```ruby
# spec/factories/invoices.rb
FactoryBot.define do
  factory :invoice do
    association :client
    status { :draft }
    sequence(:number) { |n| "2024-#{n.to_s.rjust(4, '0')}" }
    issue_date { Date.current }
    due_date { 30.days.from_now }
  end
end

# In specs
let(:invoice) { create(:invoice) }
let(:draft_invoice) { create(:invoice, status: :draft) }
```

### RSpec Structure
```ruby
RSpec.describe Invoice, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_uniqueness_of(:number) }
  end

  describe "#calculate_totals" do
    let(:invoice) { create(:invoice) }
    let!(:time_entries) { create_list(:time_entry, 3, invoice: invoice, hours: 2) }

    it "sums time entry hours" do
      invoice.calculate_totals
      expect(invoice.total_hours).to eq(6)
    end
  end
end
```

### Service Specs
```ruby
RSpec.describe InvoiceBuilder do
  let(:client) { create(:client) }
  let(:project) { create(:project, client: client) }
  let!(:time_entries) { create_list(:time_entry, 2, project: project, status: :unbilled) }

  subject(:builder) do
    described_class.new(
      client_id: client.id,
      period_start: 1.month.ago,
      period_end: Date.current
    )
  end

  describe "#create_draft" do
    it "creates an invoice" do
      result = builder.create_draft
      expect(result[:success]).to be true
      expect(result[:invoice]).to be_persisted
    end

    it "associates time entries" do
      result = builder.create_draft
      expect(result[:invoice].time_entries.count).to eq(2)
    end
  end
end
```

### Request Specs
```ruby
RSpec.describe "Invoices", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /invoices" do
    it "returns success" do
      get invoices_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /invoices" do
    let(:client) { create(:client) }
    let(:valid_params) do
      { invoice: { client_id: client.id, period_start: 1.month.ago, period_end: Date.current } }
    end

    it "creates invoice and redirects" do
      post invoices_path, params: valid_params
      expect(response).to redirect_to(invoice_path(Invoice.last))
    end
  end
end
```

---

## Vitest (Frontend)

### Test Organization
```
app/frontend/
├── components/
│   ├── __tests__/           # Component tests
│   │   ├── PageHeader.test.tsx
│   │   └── EmptyState.test.tsx
│   └── ui/
│       └── button.test.tsx  # Co-located UI tests
└── test/
    └── setup.ts             # Test setup
```

### Component Test Structure
```tsx
import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { PageHeader } from "../PageHeader";

describe("PageHeader", () => {
  it("renders title", () => {
    render(<PageHeader title="Invoices" />);
    expect(screen.getByText("Invoices")).toBeInTheDocument();
  });

  it("renders description when provided", () => {
    render(<PageHeader title="Invoices" description="Manage invoices" />);
    expect(screen.getByText("Manage invoices")).toBeInTheDocument();
  });

  it("does not render description when not provided", () => {
    render(<PageHeader title="Invoices" />);
    expect(screen.queryByText("Manage")).not.toBeInTheDocument();
  });
});
```

### Testing User Interactions
```tsx
import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ConfirmDialog } from "../ConfirmDialog";

describe("ConfirmDialog", () => {
  it("calls onConfirm when confirmed", async () => {
    const user = userEvent.setup();
    const onConfirm = vi.fn();

    render(
      <ConfirmDialog
        open={true}
        title="Delete?"
        onConfirm={onConfirm}
        onCancel={() => {}}
      />
    );

    await user.click(screen.getByRole("button", { name: /confirm/i }));
    expect(onConfirm).toHaveBeenCalledTimes(1);
  });
});
```

### Testing with Props
```tsx
describe("CurrencyDisplay", () => {
  it("formats EUR correctly", () => {
    render(<CurrencyDisplay amount={1234.56} currency="EUR" />);
    expect(screen.getByText(/€1,234\.56/)).toBeInTheDocument();
  });

  it("handles null amount", () => {
    render(<CurrencyDisplay amount={null} currency="EUR" />);
    expect(screen.getByText("—")).toBeInTheDocument();
  });
});
```

### Running Tests
```bash
# Backend
bundle exec rspec
bundle exec rspec spec/models/
bundle exec rspec spec/services/invoice_builder_spec.rb

# Frontend
npm test
npm run test:run
npm run test:coverage
```

---

## General Guidelines

### What to Test
- Model validations and business logic
- Service object behavior
- Controller/request flows
- Component rendering and interactions
- Critical user flows

### What NOT to Test
- Simple getters/setters
- Framework behavior (Rails/React internals)
- Third-party library functionality
- Trivial UI that's just passthrough
