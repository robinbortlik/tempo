import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import i18n from "@/lib/i18n";

// Mock fetch
const mockFetch = vi.fn();

(globalThis as any).fetch = mockFetch;

// Mock sonner
vi.mock("sonner", () => ({
  toast: {
    success: vi.fn(),
    error: vi.fn(),
  },
}));

import { BankAccountsSection } from "../components/BankAccountsSection";

const mockBankAccounts = [
  {
    id: 1,
    name: "Primary EUR Account",
    bank_name: "Revolut",
    bank_account: "123456789",
    bank_swift: "REVOLT21",
    iban: "DE89370400440532013000",
    is_default: true,
  },
  {
    id: 2,
    name: "Secondary CZK Account",
    bank_name: "Fio Banka",
    bank_account: "987654321",
    bank_swift: "FIOBCZPP",
    iban: "CZ6508000000192000145399",
    is_default: false,
  },
];

describe("BankAccountsSection", () => {
  beforeEach(async () => {
    vi.clearAllMocks();
    await i18n.changeLanguage("en");
    mockFetch.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ bank_accounts: mockBankAccounts }),
    });
  });

  it("renders list of bank accounts with formatted IBANs", () => {
    render(
      <BankAccountsSection
        bankAccounts={mockBankAccounts}
        onBankAccountsChange={() => {}}
      />
    );

    expect(screen.getByText("Primary EUR Account")).toBeInTheDocument();
    expect(screen.getByText("Secondary CZK Account")).toBeInTheDocument();
    expect(screen.getByText("Revolut")).toBeInTheDocument();
    expect(screen.getByText("Fio Banka")).toBeInTheDocument();
    // IBAN should be formatted with spaces every 4 chars
    expect(screen.getByText("DE89 3704 0044 0532 0130 00")).toBeInTheDocument();
  });

  it("shows Default badge on default account", () => {
    render(
      <BankAccountsSection
        bankAccounts={mockBankAccounts}
        onBankAccountsChange={() => {}}
      />
    );

    const defaultBadges = screen.getAllByText("Default");
    expect(defaultBadges).toHaveLength(1);
  });

  it("opens add account form when Add button is clicked", async () => {
    const user = userEvent.setup();
    render(
      <BankAccountsSection
        bankAccounts={mockBankAccounts}
        onBankAccountsChange={() => {}}
      />
    );

    await user.click(screen.getByRole("button", { name: "Add" }));

    await waitFor(() => {
      expect(screen.getByText("Add Bank Account")).toBeInTheDocument();
    });
  });

  it("disables delete button for sole default account", () => {
    const singleDefaultAccount = [mockBankAccounts[0]];
    render(
      <BankAccountsSection
        bankAccounts={singleDefaultAccount}
        onBankAccountsChange={() => {}}
      />
    );

    const deleteButton = screen.getByRole("button", { name: "Delete" });
    expect(deleteButton).toBeDisabled();
  });

  it("allows delete for non-default accounts when multiple exist", () => {
    render(
      <BankAccountsSection
        bankAccounts={mockBankAccounts}
        onBankAccountsChange={() => {}}
      />
    );

    const deleteButtons = screen.getAllByRole("button", { name: "Delete" });
    // First account is default and sole default - can't delete
    // Second account is not default - can delete
    expect(deleteButtons[1]).not.toBeDisabled();
  });
});
