import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MobileCard } from "../MobileCard";

describe("MobileCard", () => {
  it("renders with title and content", () => {
    render(<MobileCard title="Test Client" subtitle="test@example.com" />);

    expect(screen.getByText("Test Client")).toBeInTheDocument();
    expect(screen.getByText("test@example.com")).toBeInTheDocument();
  });

  it("calls onClick when clicked", async () => {
    const user = userEvent.setup();
    const handleClick = vi.fn();

    render(
      <MobileCard
        title="Clickable Card"
        onClick={handleClick}
      />
    );

    await user.click(screen.getByTestId("mobile-card"));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it("renders secondary details", () => {
    render(
      <MobileCard
        title="Client Name"
        details={[
          { label: "Hours", value: "42" },
          { label: "Amount", value: "$1,234" },
        ]}
      />
    );

    expect(screen.getByText("Hours:")).toBeInTheDocument();
    expect(screen.getByText("42")).toBeInTheDocument();
    expect(screen.getByText("Amount:")).toBeInTheDocument();
    expect(screen.getByText("$1,234")).toBeInTheDocument();
  });

  it("renders action slot", async () => {
    const user = userEvent.setup();
    const handleAction = vi.fn();
    const handleCardClick = vi.fn();

    render(
      <MobileCard
        title="Card with Action"
        onClick={handleCardClick}
        action={<button onClick={handleAction}>Invoice</button>}
      />
    );

    expect(screen.getByRole("button", { name: "Invoice" })).toBeInTheDocument();

    // Click action button - should not trigger card click
    await user.click(screen.getByRole("button", { name: "Invoice" }));
    expect(handleAction).toHaveBeenCalledTimes(1);
    expect(handleCardClick).not.toHaveBeenCalled();
  });
});
