import { render, screen } from "@testing-library/react";
import { PageHeader } from "../PageHeader";

describe("PageHeader", () => {
  it("renders the title", () => {
    render(<PageHeader title="Test Title" />);
    expect(screen.getByText("Test Title")).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
      "Test Title"
    );
  });

  it("renders the subtitle when provided", () => {
    render(<PageHeader title="Test Title" subtitle="Test Subtitle" />);
    expect(screen.getByText("Test Subtitle")).toBeInTheDocument();
  });

  it("does not render subtitle when not provided", () => {
    render(<PageHeader title="Test Title" />);
    expect(screen.queryByText("Test Subtitle")).not.toBeInTheDocument();
  });

  it("renders children (action buttons)", () => {
    render(
      <PageHeader title="Test Title">
        <button>Action Button</button>
      </PageHeader>
    );
    expect(
      screen.getByRole("button", { name: "Action Button" })
    ).toBeInTheDocument();
  });

  it("applies correct styling classes", () => {
    render(<PageHeader title="Test Title" subtitle="Test Subtitle" />);
    const heading = screen.getByRole("heading", { level: 1 });
    expect(heading).toHaveClass("text-2xl", "font-semibold", "text-stone-900");
  });

  it("applies custom className", () => {
    render(<PageHeader title="Test Title" className="custom-class" />);
    const container = screen.getByTestId("page-header");
    expect(container).toHaveClass("custom-class");
  });

  it("renders with all props", () => {
    render(
      <PageHeader title="Full Test" subtitle="Full Subtitle" className="test">
        <span>Child Element</span>
      </PageHeader>
    );
    expect(screen.getByText("Full Test")).toBeInTheDocument();
    expect(screen.getByText("Full Subtitle")).toBeInTheDocument();
    expect(screen.getByText("Child Element")).toBeInTheDocument();
  });
});
