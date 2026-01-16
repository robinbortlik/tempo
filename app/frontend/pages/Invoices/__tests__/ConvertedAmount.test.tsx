import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import i18n from "@/lib/i18n";

// Mock Inertia
vi.mock("@inertiajs/react", () => ({
  router: {
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
    visit: vi.fn(),
  },
  usePage: vi.fn(),
  Head: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

// Mock sonner
vi.mock("sonner", () => ({
  toast: {
    success: vi.fn(),
    error: vi.fn(),
  },
  Toaster: () => null,
}));

import { usePage } from "@inertiajs/react";
import InvoiceShow from "../Show";

const baseInvoice = {
  id: 1,
  number: "2026-001",
  status: "final" as const,
  issue_date: "2026-01-15",
  due_date: "2026-01-30",
  period_start: "2026-01-01",
  period_end: "2026-01-15",
  total_hours: 10,
  total_amount: 1000,
  subtotal: 1000,
  total_vat: 0,
  grand_total: 1000,
  vat_totals_by_rate: {},
  currency: "EUR",
  notes: null,
  client_id: 1,
  client_name: "Test Client",
  client_address: null,
  client_email: null,
  client_vat_id: null,
  client_company_registration: null,
  client_default_vat_rate: null,
  client_locale: "en",
  paid_at: null,
};

const baseSettings = {
  company_name: "Test Company",
  address: null,
  email: null,
  phone: null,
  vat_id: null,
  company_registration: null,
  invoice_message: null,
  logo_url: null,
};

const basePageProps = {
  invoice: baseInvoice,
  line_items: [],
  settings: baseSettings,
  bank_account: null,
  qr_code: null,
  flash: {},
};

describe("Invoice Show - Converted Amount", () => {
  beforeEach(async () => {
    vi.clearAllMocks();
    await i18n.changeLanguage("en");
  });

  it("displays converted amount when main_currency_amount is present", () => {
    (usePage as ReturnType<typeof vi.fn>).mockReturnValue({
      props: {
        ...basePageProps,
        invoice: {
          ...baseInvoice,
          main_currency_amount: 25000.5,
          main_currency: "CZK",
        },
      },
    });

    render(<InvoiceShow />);

    // Should display the converted amount with CZK currency
    const convertedAmount = screen.getByTestId("converted-amount");
    expect(convertedAmount).toBeInTheDocument();
    // The amount is formatted with locale-specific formatting (25 000,50 Kc)
    expect(convertedAmount.textContent).toContain("25");
    expect(convertedAmount.textContent).toContain("000");
  });

  it("does not display converted amount when main_currency_amount is null", () => {
    (usePage as ReturnType<typeof vi.fn>).mockReturnValue({
      props: {
        ...basePageProps,
        invoice: {
          ...baseInvoice,
          main_currency_amount: null,
          main_currency: "CZK",
        },
      },
    });

    render(<InvoiceShow />);

    expect(screen.queryByTestId("converted-amount")).not.toBeInTheDocument();
  });

  it("does not display converted amount when currencies match", () => {
    (usePage as ReturnType<typeof vi.fn>).mockReturnValue({
      props: {
        ...basePageProps,
        invoice: {
          ...baseInvoice,
          currency: "CZK",
          main_currency_amount: 1000, // Same as grand_total, currencies match
          main_currency: "CZK",
        },
      },
    });

    render(<InvoiceShow />);

    // When currencies match, the converted amount shouldn't be shown
    // because it would be redundant with the grand total
    expect(screen.queryByTestId("converted-amount")).not.toBeInTheDocument();
  });
});
