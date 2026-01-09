import { describe, it, expect, beforeEach, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import i18n from "@/lib/i18n";

// Mock Inertia modules - using hoisted mocks
vi.mock("@inertiajs/react", () => {
  const mockRouter = {
    visit: vi.fn(),
    patch: vi.fn(),
    get: vi.fn(),
    delete: vi.fn(),
    post: vi.fn(),
  };

  return {
    usePage: vi.fn(() => ({
      url: "/",
      props: {
        auth: { user: { email_address: "test@example.com" } },
      },
    })),
    router: mockRouter,
    Link: ({ children, ...props }: { children: React.ReactNode; [key: string]: unknown }) => (
      <a href={props.href as string} data-testid={props["data-testid"] as string}>
        {children}
      </a>
    ),
    useForm: () => ({
      data: {
        company_name: "",
        address: "",
        email: "",
        phone: "",
        vat_id: "",
        company_registration: "",
        bank_name: "",
        bank_account: "",
        bank_swift: "",
        iban: "",
        invoice_message: "",
        logo: null,
      },
      setData: vi.fn(),
      post: vi.fn(),
      patch: vi.fn(),
      processing: false,
      errors: {},
    }),
    Head: () => null,
  };
});

// Import after mocking
import { usePage, router } from "@inertiajs/react";
import Sidebar from "../Sidebar";

describe("Task Group 3: UI Component Translations", () => {
  beforeEach(async () => {
    // Reset to English before each test
    await i18n.changeLanguage("en");
    vi.clearAllMocks();
  });

  describe("Sidebar navigation translations", () => {
    beforeEach(() => {
      vi.mocked(usePage).mockReturnValue({
        url: "/",
        props: {
          auth: { user: { email_address: "test@example.com" } },
          errors: {},
        },
      } as unknown as ReturnType<typeof usePage>);
    });

    it("renders translated navigation labels in English", () => {
      render(<Sidebar />);

      // Check English navigation labels
      expect(screen.getByText("Dashboard")).toBeInTheDocument();
      expect(screen.getByText("Log Work")).toBeInTheDocument();
      expect(screen.getByText("Clients")).toBeInTheDocument();
      expect(screen.getByText("Projects")).toBeInTheDocument();
      expect(screen.getByText("Invoices")).toBeInTheDocument();
      expect(screen.getByText("Settings")).toBeInTheDocument();
      expect(screen.getByText("Sign out")).toBeInTheDocument();
    });

    it("renders translated navigation labels in Czech", async () => {
      await i18n.changeLanguage("cs");
      render(<Sidebar />);

      // Check Czech navigation labels
      expect(screen.getByText("Prehled")).toBeInTheDocument();
      expect(screen.getByText("Zaznamenat praci")).toBeInTheDocument();
      expect(screen.getByText("Klienti")).toBeInTheDocument();
      expect(screen.getByText("Projekty")).toBeInTheDocument();
      expect(screen.getByText("Faktury")).toBeInTheDocument();
      expect(screen.getByText("Nastaveni")).toBeInTheDocument();
      expect(screen.getByText("Odhlasit se")).toBeInTheDocument();
    });
  });

  describe("Language selector functionality", () => {
    it("changes locale when language is selected", async () => {
      vi.mocked(usePage).mockReturnValue({
        url: "/settings",
        props: {
          settings: {
            id: 1,
            company_name: "Test Company",
            address: "",
            email: "",
            phone: "",
            vat_id: "",
            company_registration: "",
            bank_name: "",
            bank_account: "",
            bank_swift: "",
            iban: "",
            invoice_message: "",
            logo_url: null,
          },
          locale: "en",
          flash: {},
          auth: { user: { email_address: "test@example.com" } },
          errors: {},
        },
      } as unknown as ReturnType<typeof usePage>);

      // Import Settings page dynamically
      const { default: SettingsShow } = await import(
        "@/pages/Settings/Show"
      );

      render(<SettingsShow />);

      // Find the language selector
      const languageSelector = screen.getByTestId("language-selector");
      expect(languageSelector).toBeInTheDocument();

      // Current language should be English
      expect((languageSelector as HTMLSelectElement).value).toBe("en");

      // Change language to Czech
      fireEvent.change(languageSelector, { target: { value: "cs" } });

      // Verify router.patch was called to update locale
      expect(router.patch).toHaveBeenCalledWith(
        "/settings/locale",
        { locale: "cs" },
        { preserveScroll: true }
      );

      // Verify i18n language was changed
      expect(i18n.language).toBe("cs");
    });
  });

  describe("Page component translations", () => {
    it("renders dashboard page with translated content", async () => {
      vi.mocked(usePage).mockReturnValue({
        url: "/",
        props: {
          stats: {
            hours_this_week: 20,
            hours_this_month: 80,
            unbilled_hours: 40,
            unbilled_amounts: { EUR: 5000 },
            unbilled_by_client: [],
          },
          charts: {
            time_by_client: [],
            time_by_project: [],
            earnings_over_time: [],
            hours_trend: [],
          },
          flash: {},
          auth: { user: { email_address: "test@example.com" } },
          errors: {},
        },
      } as unknown as ReturnType<typeof usePage>);

      const { default: DashboardIndex } = await import(
        "@/pages/Dashboard/Index"
      );

      // Test English
      await i18n.changeLanguage("en");
      const { rerender } = render(<DashboardIndex />);

      expect(screen.getByText("Dashboard")).toBeInTheDocument();
      expect(screen.getByText("This Week")).toBeInTheDocument();
      expect(screen.getByText("This Month")).toBeInTheDocument();
      expect(screen.getByText("Unbilled Hours")).toBeInTheDocument();

      // Test Czech
      await i18n.changeLanguage("cs");
      rerender(<DashboardIndex />);

      expect(screen.getByText("Prehled")).toBeInTheDocument();
      expect(screen.getByText("Tento tyden")).toBeInTheDocument();
      expect(screen.getByText("Tento mesic")).toBeInTheDocument();
      expect(screen.getByText("Nevyfakturovane hodiny")).toBeInTheDocument();
    });
  });
});
