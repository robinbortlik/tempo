import { describe, it, expect, vi } from "vitest";
import { render } from "@testing-library/react";

// Mock Inertia router
vi.mock("@inertiajs/react", () => ({
  Head: ({ title }: { title: string }) => <title>{title}</title>,
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
  }),
  usePage: () => ({
    props: {
      settings: {
        id: 1,
        company_name: "Test Company",
        address: "123 Test St",
        email: "test@example.com",
        phone: "555-1234",
        vat_id: "VAT123",
        company_registration: "REG456",
        bank_name: "Test Bank",
        bank_account: "12345678",
        bank_swift: "SWIFT123",
        iban: "DE89370400440532013000",
        invoice_message: "Thank you for your business",
        logo_url: null,
      },
      flash: {},
    },
  }),
  router: {
    post: vi.fn(),
  },
}));

import SettingsShow from "../Show";

describe("Settings mobile layout", () => {
  it("renders form sections at full-width on mobile", () => {
    const { container } = render(<SettingsShow />);

    // The form should have w-full for mobile and md:max-w-2xl for desktop
    const form = container.querySelector("form");
    expect(form).toHaveClass("w-full");
    expect(form).toHaveClass("md:max-w-2xl");

    // Check that the main container has mobile-first padding
    const mainDiv = container.querySelector(".p-4");
    expect(mainDiv).toBeInTheDocument();
  });

  it("renders grid inputs with responsive stacking classes", () => {
    const { container } = render(<SettingsShow />);

    // Find grid containers - they should have responsive classes
    const grids = container.querySelectorAll(".grid-cols-1.md\\:grid-cols-2");
    expect(grids.length).toBeGreaterThan(0);

    // Verify at least one grid has the correct responsive pattern
    const grid = grids[0];
    expect(grid).toHaveClass("grid-cols-1");
    expect(grid).toHaveClass("md:grid-cols-2");
  });
});
