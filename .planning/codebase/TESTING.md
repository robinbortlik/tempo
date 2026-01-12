# Testing Patterns

**Analysis Date:** 2026-01-12

## Test Framework

**Runner (Backend):**
- RSpec with Rails integration
- Config: `spec/spec_helper.rb`, `spec/rails_helper.rb`

**Runner (Frontend):**
- Vitest 4.0.16
- Config: `vitest.config.ts` (jsdom environment, globals enabled)

**Assertion Library:**
- RSpec: Built-in matchers (expect, should)
- Vitest: Built-in expect + @testing-library/jest-dom matchers

**Run Commands:**
```bash
# Backend
bundle exec rspec                    # Run all tests
bundle exec rspec spec/models        # Model tests only
bundle exec rspec spec/services/invoice_builder_spec.rb  # Single file

# Frontend
npm test                             # Watch mode
npm run test:run                     # Single run
npm run test:coverage                # Coverage report
```

## Test File Organization

**Location (Backend):**
- `spec/**/*_spec.rb` - RSpec test files
- Tests mirror source structure (spec/models/, spec/services/, spec/requests/)

**Location (Frontend):**
- `app/frontend/components/__tests__/*.test.tsx` - Component tests
- `app/frontend/components/ui/*.test.tsx` - Co-located UI tests
- `app/frontend/lib/__tests__/*.test.ts` - Utility tests

**Naming:**
- Backend: `{model}_spec.rb`, `{service}_spec.rb`
- Frontend: `{Component}.test.tsx`

**Structure:**
```
spec/
├── factories/        # FactoryBot factories
├── models/           # Model specs
├── services/         # Service specs
├── requests/         # Controller/request specs
├── system/           # Integration tests
├── serializers/      # Serializer specs
├── support/          # Shared helpers
└── fixtures/         # Test data
```

## Test Structure

**Suite Organization (RSpec):**
```ruby
RSpec.describe Invoice, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:client) }
    it { is_expected.to have_many(:line_items) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_uniqueness_of(:number) }
  end

  describe "#calculate_totals" do
    let(:invoice) { create(:invoice) }

    it "sums line item amounts" do
      invoice.calculate_totals
      expect(invoice.total_amount).to eq(expected_amount)
    end
  end
end
```

**Suite Organization (Vitest):**
```tsx
import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { PageHeader } from "../PageHeader";

describe("PageHeader", () => {
  it("renders title", () => {
    render(<PageHeader title="Invoices" />);
    expect(screen.getByText("Invoices")).toBeInTheDocument();
  });

  it("renders children when provided", () => {
    render(<PageHeader title="Test"><button>Action</button></PageHeader>);
    expect(screen.getByRole("button")).toBeInTheDocument();
  });
});
```

**Patterns:**
- Use `let` for lazy-evaluated test data
- Use `let!` for eager-evaluated setup
- Use `beforeEach` for per-test setup
- Use `vi.fn()` for mocking in Vitest

## Mocking

**Framework (Backend):**
- RSpec mocks and doubles
- FactoryBot for test data

**Framework (Frontend):**
- Vitest built-in mocking (`vi.fn()`, `vi.mock()`)

**Patterns (Vitest):**
```tsx
import { vi } from "vitest";

// Mock function
const handleClick = vi.fn();

// Mock module
vi.mock("@inertiajs/react", () => ({
  usePage: vi.fn(() => ({ props: { auth: {} } })),
}));
```

**What to Mock:**
- External APIs and services
- Browser APIs (matchMedia, ResizeObserver)
- Complex dependencies

**What NOT to Mock:**
- Internal pure functions
- Simple utilities
- Component props

## Fixtures and Factories

**Test Data (Backend):**
```ruby
# spec/factories/invoices.rb
FactoryBot.define do
  factory :invoice do
    association :client
    sequence(:number) { |n| "2024-#{n.to_s.rjust(3, '0')}" }
    status { :draft }
    issue_date { Date.current }
    due_date { 30.days.from_now }

    trait :final do
      status { :final }
    end
  end
end

# In specs
let(:invoice) { create(:invoice) }
let(:final_invoice) { create(:invoice, :final) }
```

**Test Data (Frontend):**
```tsx
// Factory functions in test files
const createMockInvoice = (overrides = {}) => ({
  id: 1,
  number: "2024-001",
  status: "draft",
  ...overrides,
});
```

**Location:**
- Backend: `spec/factories/`
- Frontend: Inline in test files or shared fixtures

## Coverage

**Requirements:**
- No enforced coverage target
- Focus on critical paths (services, business logic)

**Configuration:**
- Frontend: Vitest coverage via v8 (`@vitest/coverage-v8`)
- Reporters: text, json, html

**View Coverage:**
```bash
npm run test:coverage
open coverage/index.html
```

## Test Types

**Unit Tests:**
- Scope: Single function/class in isolation
- Mocking: Mock external dependencies
- Speed: Fast (<100ms per test)
- Examples: `spec/models/`, `spec/services/`, `app/frontend/lib/__tests__/`

**Integration Tests:**
- Scope: Multiple modules together
- Mocking: Mock only external boundaries
- Examples: `spec/requests/`, `spec/serializers/`

**System Tests:**
- Scope: Full user flows
- Framework: Capybara with Selenium
- Location: `spec/system/`

**E2E Tests:**
- Not currently configured
- Consider Playwright for browser automation

## Common Patterns

**Async Testing (Vitest):**
```tsx
it("handles async operation", async () => {
  const user = userEvent.setup();
  await user.click(screen.getByRole("button"));
  expect(handleClick).toHaveBeenCalled();
});
```

**Error Testing (RSpec):**
```ruby
it "raises error on invalid input" do
  expect { service.call(nil) }.to raise_error(ArgumentError)
end
```

**Error Testing (Vitest):**
```tsx
it("throws on invalid input", () => {
  expect(() => parseDate("invalid")).toThrow();
});
```

**Request Testing (RSpec):**
```ruby
RSpec.describe "Invoices", type: :request do
  before { sign_in }

  describe "GET /invoices" do
    it "returns success" do
      get invoices_path
      expect(response).to have_http_status(:success)
    end
  end
end
```

**Snapshot Testing:**
- Not currently used
- Prefer explicit assertions for clarity

## Test Setup

**Backend Setup (`spec/rails_helper.rb`):**
- FactoryBot configuration
- Database cleaner strategy
- Authentication helpers

**Frontend Setup (`app/frontend/test/setup.ts`):**
- Imports `@testing-library/jest-dom`
- Mocks `window.matchMedia`
- Mocks `ResizeObserver`

---

*Testing analysis: 2026-01-12*
*Update when test patterns change*
