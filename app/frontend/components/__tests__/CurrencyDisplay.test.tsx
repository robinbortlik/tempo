import { render, screen } from "@testing-library/react";
import {
  CurrencyDisplay,
  formatCurrency,
  CURRENCY_SYMBOLS,
} from "../CurrencyDisplay";

describe("CurrencyDisplay", () => {
  it("renders EUR currency with symbol", () => {
    render(<CurrencyDisplay amount={1000} currency="EUR" />);
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveTextContent("\u20AC1,000.00");
  });

  it("renders USD currency with symbol", () => {
    render(<CurrencyDisplay amount={1000} currency="USD" />);
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveTextContent("$1,000.00");
  });

  it("renders GBP currency with symbol", () => {
    render(<CurrencyDisplay amount={1000} currency="GBP" />);
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveTextContent("\u00A31,000.00");
  });

  it("renders CZK currency with symbol", () => {
    render(<CurrencyDisplay amount={1000} currency="CZK" />);
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveTextContent("K\u010D1,000.00");
  });

  it("falls back to currency code for unknown currencies", () => {
    render(<CurrencyDisplay amount={1000} currency="JPY" />);
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveTextContent("JPY1,000.00");
  });

  it("formats large numbers with separators", () => {
    render(<CurrencyDisplay amount={1234567.89} currency="EUR" />);
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveTextContent("\u20AC1,234,567.89");
  });

  it("formats zero amount", () => {
    render(<CurrencyDisplay amount={0} currency="EUR" />);
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveTextContent("\u20AC0.00");
  });

  it("formats negative amounts", () => {
    render(<CurrencyDisplay amount={-500.5} currency="USD" />);
    const display = screen.getByTestId("currency-display");
    // toLocaleString formats negative numbers as "$-500.50"
    expect(display).toHaveTextContent("$-500.50");
  });

  it("hides decimals when showDecimals is false", () => {
    render(
      <CurrencyDisplay amount={1234.56} currency="EUR" showDecimals={false} />
    );
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveTextContent("\u20AC1,235");
  });

  it("applies tabular-nums class by default", () => {
    render(<CurrencyDisplay amount={1000} currency="EUR" />);
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveClass("tabular-nums");
  });

  it("applies custom className", () => {
    render(
      <CurrencyDisplay amount={1000} currency="EUR" className="custom-class" />
    );
    const display = screen.getByTestId("currency-display");
    expect(display).toHaveClass("custom-class");
  });
});

describe("formatCurrency utility", () => {
  it("formats EUR correctly", () => {
    expect(formatCurrency(1000, "EUR")).toBe("\u20AC1,000.00");
  });

  it("formats USD correctly", () => {
    expect(formatCurrency(1000, "USD")).toBe("$1,000.00");
  });

  it("formats without decimals when specified", () => {
    expect(formatCurrency(1234.56, "EUR", false)).toBe("\u20AC1,235");
  });
});

describe("CURRENCY_SYMBOLS", () => {
  it("exports currency symbols map", () => {
    expect(CURRENCY_SYMBOLS.EUR).toBe("\u20AC");
    expect(CURRENCY_SYMBOLS.USD).toBe("$");
    expect(CURRENCY_SYMBOLS.GBP).toBe("\u00A3");
    expect(CURRENCY_SYMBOLS.CZK).toBe("K\u010D");
  });
});
