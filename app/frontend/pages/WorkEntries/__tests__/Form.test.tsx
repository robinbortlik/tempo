import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

// Mock Inertia router
vi.mock("@inertiajs/react", () => ({
  router: {
    post: vi.fn(),
    patch: vi.fn(),
    visit: vi.fn(),
  },
}));

import WorkEntryForm from "../Form";

const mockProjects = [
  {
    client: { id: 1, name: "Acme Corp", currency: "USD" },
    projects: [{ id: 1, name: "Website Redesign", effective_hourly_rate: 150 }],
  },
];

const baseWorkEntry = {
  id: null,
  date: "",
  hours: null,
  amount: null,
  entry_type: "time",
  description: "",
  project_id: null,
  hourly_rate: null,
  status: "unbilled" as const,
  effective_hourly_rate: 150,
};

describe("WorkEntryForm - Rate Override UI", () => {
  it("does not show collapsible rate section when hours field is empty", () => {
    render(<WorkEntryForm workEntry={baseWorkEntry} projects={mockProjects} />);

    // Rate section should not be visible when no hours
    expect(screen.queryByText(/Rate:/)).not.toBeInTheDocument();
  });

  it("shows collapsible rate section when hours field has value", async () => {
    const user = userEvent.setup();
    render(<WorkEntryForm workEntry={baseWorkEntry} projects={mockProjects} />);

    // Select a project first
    const projectSelect = screen.getByLabelText(/Project/);
    await user.selectOptions(projectSelect, "1");

    // Fill hours
    const hoursInput = screen.getByLabelText("Hours");
    await user.type(hoursInput, "8");

    // Rate section should now be visible
    expect(screen.getByText(/Rate:/)).toBeInTheDocument();
    expect(screen.getByText(/\$150\/h/)).toBeInTheDocument();
    expect(screen.getByText(/from project/)).toBeInTheDocument();
  });

  it("shows rate input field when collapsible is expanded", async () => {
    const user = userEvent.setup();
    render(<WorkEntryForm workEntry={baseWorkEntry} projects={mockProjects} />);

    // Select a project first
    const projectSelect = screen.getByLabelText(/Project/);
    await user.selectOptions(projectSelect, "1");

    // Fill hours
    const hoursInput = screen.getByLabelText("Hours");
    await user.type(hoursInput, "8");

    // Click to expand
    const rateTrigger = screen.getByText(/Rate:/);
    await user.click(rateTrigger);

    // Should show rate input
    expect(screen.getByLabelText(/Hourly Rate Override/)).toBeInTheDocument();
  });

  it("disables rate input when entry is invoiced", async () => {
    const user = userEvent.setup();
    const invoicedEntry = {
      ...baseWorkEntry,
      id: 1,
      hours: 8,
      status: "invoiced" as const,
      project_id: 1,
      hourly_rate: 150,
    };

    render(<WorkEntryForm workEntry={invoicedEntry} projects={mockProjects} />);

    // Rate section should be visible (entry has hours)
    expect(screen.getByText(/Rate:/)).toBeInTheDocument();

    // Click to expand
    const rateTrigger = screen.getByText(/Rate:/);
    await user.click(rateTrigger);

    // Rate input should be disabled
    const rateInput = screen.getByLabelText(/Hourly Rate Override/);
    expect(rateInput).toBeDisabled();
  });
});
