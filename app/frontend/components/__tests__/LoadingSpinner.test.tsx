import { render, screen } from "@testing-library/react";
import { LoadingSpinner, LoadingSpinnerContainer } from "../LoadingSpinner";

describe("LoadingSpinner", () => {
  it("renders with default medium size", () => {
    render(<LoadingSpinner />);
    const spinner = screen.getByTestId("loading-spinner");
    expect(spinner).toBeInTheDocument();
    expect(spinner).toHaveClass("w-8", "h-8");
  });

  it("renders with small size", () => {
    render(<LoadingSpinner size="sm" />);
    const spinner = screen.getByTestId("loading-spinner");
    expect(spinner).toHaveClass("w-4", "h-4");
  });

  it("renders with large size", () => {
    render(<LoadingSpinner size="lg" />);
    const spinner = screen.getByTestId("loading-spinner");
    expect(spinner).toHaveClass("w-12", "h-12");
  });

  it("has correct animation class", () => {
    render(<LoadingSpinner />);
    const spinner = screen.getByTestId("loading-spinner");
    expect(spinner).toHaveClass("animate-spin");
  });

  it("has correct border colors", () => {
    render(<LoadingSpinner />);
    const spinner = screen.getByTestId("loading-spinner");
    expect(spinner).toHaveClass("border-stone-200", "border-t-stone-600");
  });

  it("has accessibility attributes", () => {
    render(<LoadingSpinner />);
    const spinner = screen.getByRole("status");
    expect(spinner).toHaveAttribute("aria-label", "Loading");
  });

  it("contains screen reader text", () => {
    render(<LoadingSpinner />);
    expect(screen.getByText("Loading...")).toBeInTheDocument();
    expect(screen.getByText("Loading...")).toHaveClass("sr-only");
  });

  it("applies custom className", () => {
    render(<LoadingSpinner className="custom-class" />);
    const spinner = screen.getByTestId("loading-spinner");
    expect(spinner).toHaveClass("custom-class");
  });
});

describe("LoadingSpinnerContainer", () => {
  it("renders a centered container with spinner", () => {
    render(<LoadingSpinnerContainer />);
    const container = screen.getByTestId("loading-spinner-container");
    const spinner = screen.getByTestId("loading-spinner");

    expect(container).toBeInTheDocument();
    expect(spinner).toBeInTheDocument();
    expect(container).toHaveClass("flex", "items-center", "justify-center");
  });

  it("passes size prop to spinner", () => {
    render(<LoadingSpinnerContainer size="lg" />);
    const spinner = screen.getByTestId("loading-spinner");
    expect(spinner).toHaveClass("w-12", "h-12");
  });

  it("applies custom className to container", () => {
    render(<LoadingSpinnerContainer className="custom-container" />);
    const container = screen.getByTestId("loading-spinner-container");
    expect(container).toHaveClass("custom-container");
  });
});
