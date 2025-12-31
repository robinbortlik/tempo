import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

// Mock Inertia router
vi.mock("@inertiajs/react", () => ({
  router: {
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
    get: vi.fn(),
    visit: vi.fn(),
  },
  usePage: () => ({
    props: {},
  }),
  useForm: () => ({
    data: {},
    setData: vi.fn(),
  }),
}));

// Import components after mocking
import InvoicePreview from "../components/InvoicePreview";
import LineItemEditor from "../components/LineItemEditor";
import LineItemDisplay from "../components/LineItemDisplay";

const mockLineItems = [
  {
    id: 1,
    line_type: "time_aggregate" as const,
    description: "Website Redesign - 20h @ $150.00/h",
    quantity: 20,
    unit_price: 150,
    amount: 3000,
    position: 0,
    project_id: 1,
    project_name: "Website Redesign",
    work_entry_ids: [1, 2, 3],
  },
  {
    id: 2,
    line_type: "fixed" as const,
    description: "Logo design deliverable",
    quantity: null,
    unit_price: null,
    amount: 500,
    position: 1,
    project_id: 1,
    project_name: "Website Redesign",
    work_entry_ids: [4],
  },
];

describe("InvoicePreview", () => {
  it("displays line items grouped by project", () => {
    render(
      <InvoicePreview
        lineItems={mockLineItems}
        totalHours={20}
        totalAmount={3500}
        currency="USD"
      />
    );

    // Should show the time aggregate line
    expect(
      screen.getByText("Website Redesign - 20h @ $150.00/h")
    ).toBeInTheDocument();

    // Should show the fixed line item
    expect(screen.getByText("Logo design deliverable")).toBeInTheDocument();

    // Should show totals (appears in header, project group, and totals section)
    expect(screen.getAllByText("$3,500.00").length).toBeGreaterThan(0);
  });

  it("displays empty state when no line items", () => {
    render(
      <InvoicePreview
        lineItems={[]}
        totalHours={0}
        totalAmount={0}
        currency="USD"
      />
    );

    expect(
      screen.getByText(/no unbilled work entries found/i)
    ).toBeInTheDocument();
  });

  it("distinguishes between time aggregate and fixed line items", () => {
    render(
      <InvoicePreview
        lineItems={mockLineItems}
        totalHours={20}
        totalAmount={3500}
        currency="USD"
      />
    );

    // Time aggregate should show hours and rate
    expect(screen.getByText("20h")).toBeInTheDocument();
    expect(screen.getByText("$150.00/h")).toBeInTheDocument();

    // Fixed item should show just description and amount
    const fixedRow = screen
      .getByText("Logo design deliverable")
      .closest("tr");
    expect(fixedRow).toBeInTheDocument();
    expect(within(fixedRow!).getByText("$500.00")).toBeInTheDocument();
  });
});

describe("LineItemEditor", () => {
  const mockLineItem = {
    id: 1,
    line_type: "fixed" as const,
    description: "Logo design deliverable",
    quantity: null,
    unit_price: null,
    amount: 500,
    position: 0,
    work_entry_ids: [],
  };

  it("allows editing description and amount", async () => {
    const onSave = vi.fn();
    const user = userEvent.setup();

    render(
      <LineItemEditor
        lineItem={mockLineItem}
        currency="USD"
        onSave={onSave}
        onCancel={vi.fn()}
      />
    );

    // Should have editable inputs
    const descriptionInput = screen.getByLabelText("Description");
    const amountInput = screen.getByLabelText("Amount");

    expect(descriptionInput).toHaveValue("Logo design deliverable");
    expect(amountInput).toHaveValue(500);

    // Edit description
    await user.clear(descriptionInput);
    await user.type(descriptionInput, "Updated description");

    // Edit amount
    await user.clear(amountInput);
    await user.type(amountInput, "750");

    // Save
    await user.click(screen.getByRole("button", { name: /save/i }));

    expect(onSave).toHaveBeenCalledWith({
      description: "Updated description",
      amount: 750,
    });
  });

  it("has cancel button that calls onCancel", async () => {
    const onCancel = vi.fn();
    const user = userEvent.setup();

    render(
      <LineItemEditor
        lineItem={mockLineItem}
        currency="USD"
        onSave={vi.fn()}
        onCancel={onCancel}
      />
    );

    await user.click(screen.getByRole("button", { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });
});

describe("LineItemDisplay", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const mockLineItem = {
    id: 1,
    line_type: "fixed" as const,
    description: "Logo design deliverable",
    quantity: null,
    unit_price: null,
    amount: 500,
    position: 0,
    work_entry_ids: [1],
  };

  it("shows edit and remove buttons in draft mode", () => {
    render(
      <LineItemDisplay
        lineItem={mockLineItem}
        currency="USD"
        isDraft={true}
        isFirst={true}
        isLast={true}
        onEdit={vi.fn()}
        onRemove={vi.fn()}
        onMoveUp={vi.fn()}
        onMoveDown={vi.fn()}
      />
    );

    expect(screen.getByRole("button", { name: /edit/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /remove/i })).toBeInTheDocument();
  });

  it("hides edit buttons when not in draft mode", () => {
    render(
      <LineItemDisplay
        lineItem={mockLineItem}
        currency="USD"
        isDraft={false}
        isFirst={true}
        isLast={true}
        onEdit={vi.fn()}
        onRemove={vi.fn()}
        onMoveUp={vi.fn()}
        onMoveDown={vi.fn()}
      />
    );

    expect(
      screen.queryByRole("button", { name: /edit/i })
    ).not.toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: /remove/i })
    ).not.toBeInTheDocument();
  });

  it("shows reorder buttons with correct disabled states", () => {
    render(
      <LineItemDisplay
        lineItem={mockLineItem}
        currency="USD"
        isDraft={true}
        isFirst={true}
        isLast={false}
        onEdit={vi.fn()}
        onRemove={vi.fn()}
        onMoveUp={vi.fn()}
        onMoveDown={vi.fn()}
      />
    );

    const moveUpButton = screen.getByRole("button", { name: /move up/i });
    const moveDownButton = screen.getByRole("button", { name: /move down/i });

    // First item: move up should be disabled
    expect(moveUpButton).toBeDisabled();
    expect(moveDownButton).not.toBeDisabled();
  });

  it("calls onRemove when remove button is clicked", async () => {
    const onRemove = vi.fn();
    const user = userEvent.setup();

    render(
      <LineItemDisplay
        lineItem={mockLineItem}
        currency="USD"
        isDraft={true}
        isFirst={true}
        isLast={true}
        onEdit={vi.fn()}
        onRemove={onRemove}
        onMoveUp={vi.fn()}
        onMoveDown={vi.fn()}
      />
    );

    await user.click(screen.getByRole("button", { name: /remove/i }));
    expect(onRemove).toHaveBeenCalledWith(mockLineItem.id);
  });
});
