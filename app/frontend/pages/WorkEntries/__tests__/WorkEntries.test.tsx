import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

// Mock Inertia router
vi.mock("@inertiajs/react", () => ({
  router: {
    post: vi.fn(),
    get: vi.fn(),
  },
  usePage: () => ({
    props: {},
  }),
}));

// Import components after mocking
import QuickEntryForm from "../components/QuickEntryForm";
import FilterBar from "../components/FilterBar";
import WorkEntryRow from "../components/WorkEntryRow";
import EntryTypeBadge from "../components/EntryTypeBadge";

const mockProjects = [
  {
    client: { id: 1, name: "Acme Corp", currency: "USD" },
    projects: [{ id: 1, name: "Website Redesign", effective_hourly_rate: 150 }],
  },
];

const mockClients = [{ id: 1, name: "Acme Corp" }];

const mockFilters = {
  client_id: null,
  project_id: null,
  entry_type: null,
};

const mockPeriod = {
  year: 2026,
  month: 1,
  available_years: [2026, 2025, 2024],
};

describe("QuickEntryForm", () => {
  it("renders amount field", () => {
    render(<QuickEntryForm projects={mockProjects} />);

    expect(screen.getByLabelText("Amount")).toBeInTheDocument();
  });

  it("validates at least hours or amount is required", async () => {
    const user = userEvent.setup();
    render(<QuickEntryForm projects={mockProjects} />);

    // Select a project
    const projectSelect = screen.getByRole("combobox");
    await user.selectOptions(projectSelect, "1");

    // Try to submit without hours or amount - button should be disabled
    const submitButton = screen.getByRole("button", { name: /add entry/i });
    expect(submitButton).toBeDisabled();
  });

  it("enables submit when hours is filled", async () => {
    const user = userEvent.setup();
    render(<QuickEntryForm projects={mockProjects} />);

    // Select a project
    const projectSelect = screen.getByRole("combobox");
    await user.selectOptions(projectSelect, "1");

    // Fill hours
    const hoursInput = screen.getByLabelText("Hours");
    await user.type(hoursInput, "2");

    const submitButton = screen.getByRole("button", { name: /add entry/i });
    expect(submitButton).not.toBeDisabled();
  });

  it("enables submit when amount is filled", async () => {
    const user = userEvent.setup();
    render(<QuickEntryForm projects={mockProjects} />);

    // Select a project
    const projectSelect = screen.getByRole("combobox");
    await user.selectOptions(projectSelect, "1");

    // Fill amount
    const amountInput = screen.getByLabelText("Amount");
    await user.type(amountInput, "500");

    const submitButton = screen.getByRole("button", { name: /add entry/i });
    expect(submitButton).not.toBeDisabled();
  });
});

describe("FilterBar", () => {
  it("renders entry_type filter dropdown", () => {
    render(
      <FilterBar
        clients={mockClients}
        projects={mockProjects}
        filters={mockFilters}
        period={mockPeriod}
      />
    );

    expect(screen.getByLabelText("Entry Type")).toBeInTheDocument();
    expect(
      screen.getByRole("option", { name: "All Types" })
    ).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "Time" })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "Fixed" })).toBeInTheDocument();
  });

  it("renders year dropdown with available years", () => {
    render(
      <FilterBar
        clients={mockClients}
        projects={mockProjects}
        filters={mockFilters}
        period={mockPeriod}
      />
    );

    expect(screen.getByLabelText("Year")).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "2026" })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "2025" })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "2024" })).toBeInTheDocument();
  });

  it("renders month pills with All option first", () => {
    render(
      <FilterBar
        clients={mockClients}
        projects={mockProjects}
        filters={mockFilters}
        period={mockPeriod}
      />
    );

    expect(screen.getByRole("button", { name: "All" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Jan" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Dec" })).toBeInTheDocument();
  });

  it("applies selected styling to current month", () => {
    render(
      <FilterBar
        clients={mockClients}
        projects={mockProjects}
        filters={mockFilters}
        period={mockPeriod}
      />
    );

    const janButton = screen.getByRole("button", { name: "Jan" });
    expect(janButton).toHaveClass("bg-stone-900", "text-white");

    const febButton = screen.getByRole("button", { name: "Feb" });
    expect(febButton).toHaveClass("text-stone-500");
  });

  it("triggers navigation when month pill is clicked", async () => {
    const { router } = await import("@inertiajs/react");
    const user = userEvent.setup();

    render(
      <FilterBar
        clients={mockClients}
        projects={mockProjects}
        filters={mockFilters}
        period={mockPeriod}
      />
    );

    await user.click(screen.getByRole("button", { name: "Feb" }));
    expect(router.get).toHaveBeenCalledWith(
      "/work_entries",
      expect.objectContaining({ year: 2026, month: 2 }),
      expect.objectContaining({ preserveState: true, preserveScroll: true })
    );
  });
});

describe("EntryTypeBadge", () => {
  it("displays time badge for time entries", () => {
    render(<EntryTypeBadge entryType="time" />);

    expect(screen.getByText("Time")).toBeInTheDocument();
  });

  it("displays fixed badge for fixed entries", () => {
    render(<EntryTypeBadge entryType="fixed" />);

    expect(screen.getByText("Fixed")).toBeInTheDocument();
  });
});

describe("WorkEntryRow", () => {
  const mockTimeEntry = {
    id: 1,
    date: "2024-01-15",
    hours: 8,
    amount: null,
    hourly_rate: 150,
    entry_type: "time" as const,
    description: "Development work",
    status: "unbilled" as const,
    calculated_amount: 1200,
    project_id: 1,
    project_name: "Website Redesign",
    client_id: 1,
    client_name: "Acme Corp",
    client_currency: "USD",
  };

  const mockFixedEntry = {
    id: 2,
    date: "2024-01-15",
    hours: null,
    amount: 500,
    hourly_rate: null,
    entry_type: "fixed" as const,
    description: "Logo design",
    status: "unbilled" as const,
    calculated_amount: 500,
    project_id: 1,
    project_name: "Website Redesign",
    client_id: 1,
    client_name: "Acme Corp",
    client_currency: "USD",
  };

  it("displays hours for time entries", () => {
    render(
      <WorkEntryRow
        entry={mockTimeEntry}
        projects={mockProjects}
        onDelete={vi.fn()}
      />
    );

    expect(screen.getByText("8h")).toBeInTheDocument();
  });

  it("displays amount for fixed entries", () => {
    render(
      <WorkEntryRow
        entry={mockFixedEntry}
        projects={mockProjects}
        onDelete={vi.fn()}
      />
    );

    expect(screen.getByText("$500")).toBeInTheDocument();
  });

  it("handles string hours values from backend (decimal serialization)", () => {
    // Rails returns decimal values as strings, test that Number() conversion works
    // Hours are now rounded to whole numbers
    const entryWithStringHours = {
      ...mockTimeEntry,
      hours: "8.5" as unknown as number, // Simulating Rails returning string
    };

    render(
      <WorkEntryRow
        entry={entryWithStringHours}
        projects={mockProjects}
        onDelete={vi.fn()}
      />
    );

    expect(screen.getByText("9h")).toBeInTheDocument();
  });

  it("handles string amount values from backend (decimal serialization)", () => {
    // Rails returns decimal values as strings, test that Number() conversion works
    const entryWithStringAmount = {
      ...mockFixedEntry,
      amount: "500.00" as unknown as number, // Simulating Rails returning string
    };

    render(
      <WorkEntryRow
        entry={entryWithStringAmount}
        projects={mockProjects}
        onDelete={vi.fn()}
      />
    );

    expect(screen.getByText("$500")).toBeInTheDocument();
  });
});
