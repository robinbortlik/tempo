import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import i18n from "@/lib/i18n";

// Mock Inertia
vi.mock("@inertiajs/react", () => ({
  useForm: vi.fn(() => ({
    data: {
      name: "",
      address: "",
      email: "",
      contact_person: "",
      vat_id: "",
      company_registration: "",
      bank_details: "",
      payment_terms: "",
      hourly_rate: "",
      currency: "",
      default_vat_rate: "",
      locale: "en",
      bank_account_id: "",
    },
    setData: vi.fn(),
  })),
  router: {
    visit: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
  },
}));

import ClientForm from "../Form";

const mockBankAccounts = [
  { id: 1, name: "Primary EUR Account", iban_hint: "...3000" },
  { id: 2, name: "Secondary CZK Account", iban_hint: "...5399" },
];

const emptyClient = {
  id: null,
  name: "",
  address: null,
  email: null,
  contact_person: null,
  vat_id: null,
  company_registration: null,
  bank_details: null,
  payment_terms: null,
  hourly_rate: null,
  currency: null,
  default_vat_rate: null,
  locale: "en",
  bank_account_id: null,
};

describe("ClientForm Bank Account Selector", () => {
  beforeEach(async () => {
    vi.clearAllMocks();
    await i18n.changeLanguage("en");
  });

  it("renders bank account dropdown with available accounts", () => {
    render(<ClientForm client={emptyClient} bankAccounts={mockBankAccounts} />);

    const select = screen.getByLabelText(/bank account/i);
    expect(select).toBeInTheDocument();

    // Check that options are present
    expect(screen.getByText("Use default account")).toBeInTheDocument();
    expect(
      screen.getByText("Primary EUR Account (...3000)")
    ).toBeInTheDocument();
    expect(
      screen.getByText("Secondary CZK Account (...5399)")
    ).toBeInTheDocument();
  });

  it("shows 'Use default account' as placeholder when no selection", () => {
    render(<ClientForm client={emptyClient} bankAccounts={mockBankAccounts} />);

    const select = screen.getByLabelText(/bank account/i) as HTMLSelectElement;
    expect(select.value).toBe("");

    // Placeholder option should be selected
    const selectedOption = select.options[select.selectedIndex];
    expect(selectedOption.text).toBe("Use default account");
  });

  it("displays helper text for bank account selection", () => {
    render(<ClientForm client={emptyClient} bankAccounts={mockBankAccounts} />);

    expect(
      screen.getByText(/select a bank account for this client/i)
    ).toBeInTheDocument();
  });
});
