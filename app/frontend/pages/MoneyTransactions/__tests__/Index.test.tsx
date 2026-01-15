import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

// Mock Inertia router
vi.mock("@inertiajs/react", () => ({
  router: {
    get: vi.fn(),
  },
  usePage: () => ({
    props: {
      flash: {},
    },
  }),
  Head: ({ title }: { title: string }) => <title>{title}</title>,
  Link: ({ href, children, className, onClick }: { href: string; children: React.ReactNode; className?: string; onClick?: (e: React.MouseEvent) => void }) => (
    <a href={href} className={className} onClick={onClick}>{children}</a>
  ),
}));

// Mock sonner
vi.mock("sonner", () => ({
  toast: {
    success: vi.fn(),
    error: vi.fn(),
  },
  Toaster: () => null,
}));

// Import components after mocking
import Index from "../Index";
import FilterBar from "../components/FilterBar";
import SummaryBar from "../components/SummaryBar";
import TransactionRow from "../components/TransactionRow";

const mockTransaction = {
  id: 1,
  transacted_on: "2026-01-15",
  counterparty: "Acme Corp",
  description: "Payment for January services",
  amount: 5000,
  currency: "USD",
  transaction_type: "income" as const,
  source: "bank_import",
  reference: "REF-001",
  external_id: "EXT-123",
  invoice_id: 1,
  invoice_number: "INV-2026-001",
};

const mockExpenseTransaction = {
  id: 2,
  transacted_on: "2026-01-10",
  counterparty: "Office Supplies Co",
  description: "Office supplies purchase",
  amount: 150,
  currency: "USD",
  transaction_type: "expense" as const,
  source: "manual",
  reference: null,
  external_id: null,
  invoice_id: null,
  invoice_number: null,
};

const mockFilters = {
  year: 2026,
  month: 1,
  transaction_type: null,
  description: null,
};

const mockPeriod = {
  year: 2026,
  month: 1,
  available_years: [2026, 2025, 2024],
};

const mockSummary = {
  total_income: 5000,
  total_expenses: 150,
  net_balance: 4850,
  transaction_count: 2,
};

describe("MoneyTransactions Index", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("renders page with transactions", () => {
    render(
      <Index
        transactions={[mockTransaction, mockExpenseTransaction]}
        filters={mockFilters}
        period={mockPeriod}
        summary={mockSummary}
      />
    );

    expect(screen.getByText("Acme Corp")).toBeInTheDocument();
    expect(screen.getByText("Office Supplies Co")).toBeInTheDocument();
  });

  it("displays empty state when no transactions exist", () => {
    render(
      <Index
        transactions={[]}
        filters={{ ...mockFilters, transaction_type: null, description: null }}
        period={mockPeriod}
        summary={{ total_income: 0, total_expenses: 0, net_balance: 0, transaction_count: 0 }}
      />
    );

    expect(screen.getByText(/no transactions/i)).toBeInTheDocument();
  });

  it("displays filter state message when filters return no results", () => {
    render(
      <Index
        transactions={[]}
        filters={{ ...mockFilters, transaction_type: "income", description: "nonexistent" }}
        period={mockPeriod}
        summary={{ total_income: 0, total_expenses: 0, net_balance: 0, transaction_count: 0 }}
      />
    );

    expect(screen.getByText(/no transactions match/i)).toBeInTheDocument();
  });
});

describe("FilterBar", () => {
  it("renders year dropdown with available years", () => {
    render(
      <FilterBar filters={mockFilters} period={mockPeriod} />
    );

    expect(screen.getByLabelText(/year/i)).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "2026" })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "2025" })).toBeInTheDocument();
  });

  it("renders month pills with All option", () => {
    render(
      <FilterBar filters={mockFilters} period={mockPeriod} />
    );

    expect(screen.getByRole("button", { name: "All" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Jan" })).toBeInTheDocument();
  });

  it("renders transaction type filter", () => {
    render(
      <FilterBar filters={mockFilters} period={mockPeriod} />
    );

    expect(screen.getByLabelText(/type/i)).toBeInTheDocument();
    expect(screen.getByRole("option", { name: /all/i })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: /income/i })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: /expense/i })).toBeInTheDocument();
  });

  it("triggers navigation when month pill is clicked", async () => {
    const { router } = await import("@inertiajs/react");
    const user = userEvent.setup();

    render(
      <FilterBar filters={mockFilters} period={mockPeriod} />
    );

    await user.click(screen.getByRole("button", { name: "Feb" }));
    expect(router.get).toHaveBeenCalledWith(
      "/money_transactions",
      expect.objectContaining({ year: 2026, month: 2 }),
      expect.objectContaining({ preserveState: true, preserveScroll: true })
    );
  });
});

describe("SummaryBar", () => {
  it("displays income, expenses, net balance and count", () => {
    render(<SummaryBar summary={mockSummary} />);

    expect(screen.getByText(/5.*000/)).toBeInTheDocument();
    expect(screen.getByText(/150/)).toBeInTheDocument();
    expect(screen.getByText(/4.*850/)).toBeInTheDocument();
    expect(screen.getByText(/2/)).toBeInTheDocument();
  });
});

describe("TransactionRow", () => {
  it("displays income transaction with green color", () => {
    render(
      <TransactionRow
        transaction={mockTransaction}
        isExpanded={false}
        onToggle={() => {}}
      />
    );

    expect(screen.getByText("Acme Corp")).toBeInTheDocument();
    const amountElement = screen.getByText(/5.*000/);
    expect(amountElement).toHaveClass("text-green-600");
  });

  it("displays expense transaction with red color", () => {
    render(
      <TransactionRow
        transaction={mockExpenseTransaction}
        isExpanded={false}
        onToggle={() => {}}
      />
    );

    expect(screen.getByText("Office Supplies Co")).toBeInTheDocument();
    const amountElement = screen.getByText(/150/);
    expect(amountElement).toHaveClass("text-red-600");
  });

  it("shows expanded details when clicked", async () => {
    const user = userEvent.setup();
    const onToggle = vi.fn();

    render(
      <TransactionRow
        transaction={mockTransaction}
        isExpanded={false}
        onToggle={onToggle}
      />
    );

    await user.click(screen.getByText("Acme Corp"));
    expect(onToggle).toHaveBeenCalledWith(1);
  });

  it("displays invoice link badge when matched to invoice", () => {
    render(
      <TransactionRow
        transaction={mockTransaction}
        isExpanded={true}
        onToggle={() => {}}
      />
    );

    // Invoice number appears both as badge and as link in expanded section
    const invoiceElements = screen.getAllByText("INV-2026-001");
    expect(invoiceElements.length).toBeGreaterThanOrEqual(1);
  });
});
