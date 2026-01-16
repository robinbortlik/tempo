import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import i18n from "@/lib/i18n";

// Mock Inertia
vi.mock("@inertiajs/react", () => ({
  router: {
    post: vi.fn(),
    patch: vi.fn(),
    visit: vi.fn(),
  },
  usePage: () => ({
    props: {
      settings: {
        id: 1,
        company_name: "Test Company",
        address: null,
        email: null,
        phone: null,
        vat_id: null,
        company_registration: null,
        invoice_message: null,
        logo_url: null,
        main_currency: "CZK",
      },
      bankAccounts: [],
      locale: "en",
      flash: {},
    },
  }),
  useForm: () => ({
    data: {
      company_name: "Test Company",
      address: "",
      email: "",
      phone: "",
      vat_id: "",
      company_registration: "",
      invoice_message: "",
      logo: null,
      main_currency: "CZK",
    },
    setData: vi.fn(),
  }),
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

import SettingsShow from "../Show";

describe("Settings Main Currency", () => {
  beforeEach(async () => {
    vi.clearAllMocks();
    await i18n.changeLanguage("en");
  });

  it("renders main currency dropdown in preferences section", () => {
    render(<SettingsShow />);

    expect(screen.getByLabelText("Main Currency")).toBeInTheDocument();
    expect(screen.getByTestId("main-currency-selector")).toBeInTheDocument();
  });

  it("displays all supported currency options", async () => {
    render(<SettingsShow />);

    const select = screen.getByTestId("main-currency-selector");
    expect(select).toBeInTheDocument();

    // Check that all currency options are available
    expect(screen.getByRole("option", { name: /CZK/i })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: /EUR/i })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: /USD/i })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: /GBP/i })).toBeInTheDocument();
  });
});
