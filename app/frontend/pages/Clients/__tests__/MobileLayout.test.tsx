import { render, screen } from "@testing-library/react";
import { describe, it, expect, vi, beforeEach } from "vitest";

// Mock Inertia
vi.mock("@inertiajs/react", () => ({
  Head: ({ title }: { title: string }) => <title>{title}</title>,
  usePage: vi.fn(),
  router: {
    visit: vi.fn(),
    delete: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
  },
  useForm: vi.fn(() => ({
    data: {
      name: "",
      email: "",
      address: "",
      contact_person: "",
      vat_id: "",
      company_registration: "",
      bank_details: "",
      payment_terms: "",
      hourly_rate: "",
      currency: "",
      default_vat_rate: "",
    },
    setData: vi.fn(),
  })),
}));

import { usePage } from "@inertiajs/react";
import ClientsIndex from "../Index";
import ClientShow from "../Show";

const mockUsePage = usePage as ReturnType<typeof vi.fn>;

describe("Clients Mobile Layout", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("Clients/Index", () => {
    it("renders mobile card view on mobile", () => {
      mockUsePage.mockReturnValue({
        props: {
          clients: [
            {
              id: 1,
              name: "Acme Corp",
              email: "acme@example.com",
              currency: "EUR",
              hourly_rate: 100,
              unbilled_hours: 10,
              unbilled_amount: 1000,
              projects_count: 3,
            },
          ],
          flash: {},
        },
      });

      render(<ClientsIndex />);

      // Mobile card list should exist with block md:hidden class
      const mobileList = document.querySelector(".block.md\\:hidden");
      expect(mobileList).toBeInTheDocument();

      // Desktop table should have hidden md:block class
      const desktopTable = document.querySelector(".hidden.md\\:block");
      expect(desktopTable).toBeInTheDocument();
    });
  });

  describe("Clients/Show", () => {
    const mockShowProps = {
      props: {
        client: {
          id: 1,
          name: "Acme Corp",
          email: "acme@example.com",
          address: "123 Main St",
          contact_person: "John Doe",
          vat_id: "VAT123",
          company_registration: "REG123",
          bank_details: "Bank info",
          payment_terms: "Net 30",
          hourly_rate: 100,
          currency: "EUR",
          share_token: "abc123",
          sharing_enabled: true,
        },
        projects: [],
        stats: {
          total_hours: 100,
          total_invoiced: 10000,
          unbilled_hours: 10,
          unbilled_amount: 1000,
        },
        flash: {},
      },
    };

    it("renders stats grid with responsive columns (grid-cols-2 md:grid-cols-4)", () => {
      mockUsePage.mockReturnValue(mockShowProps);

      render(<ClientShow />);

      // Stats grid should have grid-cols-2 md:grid-cols-4 classes
      const statsGrid = document.querySelector(
        ".grid.grid-cols-2.md\\:grid-cols-4"
      );
      expect(statsGrid).toBeInTheDocument();
    });

    it("renders details grid with responsive columns (grid-cols-1 md:grid-cols-2)", () => {
      mockUsePage.mockReturnValue(mockShowProps);

      render(<ClientShow />);

      // Details grid should have grid-cols-1 md:grid-cols-2 classes
      const detailsGrid = document.querySelector(
        ".grid.grid-cols-1.md\\:grid-cols-2"
      );
      expect(detailsGrid).toBeInTheDocument();
    });
  });

  describe("PageHeader", () => {
    it("uses PageHeader component with stacking on mobile", () => {
      mockUsePage.mockReturnValue({
        props: {
          clients: [],
          flash: {},
        },
      });

      render(<ClientsIndex />);

      // PageHeader should be present with responsive flex layout
      const pageHeader = screen.getByTestId("page-header");
      expect(pageHeader).toBeInTheDocument();
      expect(pageHeader).toHaveClass("flex-col");
      expect(pageHeader).toHaveClass("md:flex-row");
    });
  });
});
