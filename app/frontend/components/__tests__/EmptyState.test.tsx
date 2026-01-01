import { render, screen } from "@testing-library/react";
import { EmptyState } from "../EmptyState";

describe("EmptyState", () => {
  const defaultProps = {
    icon: <span data-testid="test-icon">Icon</span>,
    title: "No Items",
    description: "There are no items to display.",
  };

  it("renders the icon", () => {
    render(<EmptyState {...defaultProps} />);
    expect(screen.getByTestId("test-icon")).toBeInTheDocument();
  });

  it("renders the title", () => {
    render(<EmptyState {...defaultProps} />);
    expect(screen.getByText("No Items")).toBeInTheDocument();
  });

  it("renders the description", () => {
    render(<EmptyState {...defaultProps} />);
    expect(
      screen.getByText("There are no items to display.")
    ).toBeInTheDocument();
  });

  it("renders the action button when provided", () => {
    render(<EmptyState {...defaultProps} action={<button>Add Item</button>} />);
    expect(
      screen.getByRole("button", { name: "Add Item" })
    ).toBeInTheDocument();
  });

  it("does not render action when not provided", () => {
    render(<EmptyState {...defaultProps} />);
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  it("applies custom className", () => {
    render(<EmptyState {...defaultProps} className="custom-class" />);
    const container = screen.getByTestId("empty-state");
    expect(container).toHaveClass("custom-class");
  });

  it("renders icon in a circular container", () => {
    render(<EmptyState {...defaultProps} />);
    const iconContainer = screen.getByTestId("test-icon").parentElement;
    expect(iconContainer).toHaveClass("bg-stone-100", "rounded-full");
  });

  it("applies correct styling to title and description", () => {
    render(<EmptyState {...defaultProps} />);
    const title = screen.getByText("No Items");
    const description = screen.getByText("There are no items to display.");

    expect(title).toHaveClass("font-medium", "text-stone-900");
    expect(description).toHaveClass("text-stone-500", "text-sm");
  });
});
