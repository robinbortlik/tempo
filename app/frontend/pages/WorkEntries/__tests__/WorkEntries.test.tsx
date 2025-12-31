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
  start_date: null,
  end_date: null,
  client_id: null,
  project_id: null,
  entry_type: null,
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
      />
    );

    expect(screen.getByLabelText("Entry Type")).toBeInTheDocument();
    expect(
      screen.getByRole("option", { name: "All Types" })
    ).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "Time" })).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "Fixed" })).toBeInTheDocument();
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

    expect(screen.getByText("8")).toBeInTheDocument();
    expect(screen.getByText("h")).toBeInTheDocument();
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

  it("displays type badge", () => {
    render(
      <WorkEntryRow
        entry={mockTimeEntry}
        projects={mockProjects}
        onDelete={vi.fn()}
      />
    );

    expect(screen.getByText("Time")).toBeInTheDocument();
  });

  it("handles string hours values from backend (decimal serialization)", () => {
    // Rails returns decimal values as strings, test that Number() conversion works
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

    expect(screen.getByText("8.5")).toBeInTheDocument();
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
