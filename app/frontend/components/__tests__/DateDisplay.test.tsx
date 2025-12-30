import { render, screen } from "@testing-library/react";
import { DateDisplay, formatDate } from "../DateDisplay";

describe("DateDisplay", () => {
  it("renders date in short format by default", () => {
    render(<DateDisplay date="2025-12-30" />);
    const display = screen.getByTestId("date-display");
    expect(display).toHaveTextContent("Dec 30, 2025");
  });

  it("renders date in long format when specified", () => {
    render(<DateDisplay date="2025-12-30" format="long" />);
    const display = screen.getByTestId("date-display");
    expect(display).toHaveTextContent("December 30, 2025");
  });

  it("handles Date object input", () => {
    render(<DateDisplay date={new Date(2025, 11, 30)} />);
    const display = screen.getByTestId("date-display");
    expect(display).toHaveTextContent("Dec 30, 2025");
  });

  it("handles different months correctly", () => {
    render(<DateDisplay date="2025-01-15" />);
    expect(screen.getByTestId("date-display")).toHaveTextContent("Jan 15, 2025");
  });

  it("handles single digit days correctly", () => {
    render(<DateDisplay date="2025-03-05" />);
    expect(screen.getByTestId("date-display")).toHaveTextContent("Mar 5, 2025");
  });

  it("applies custom className", () => {
    render(<DateDisplay date="2025-12-30" className="custom-class" />);
    const display = screen.getByTestId("date-display");
    expect(display).toHaveClass("custom-class");
  });

  it("renders all months correctly in short format", () => {
    const months = [
      { date: "2025-01-15", expected: "Jan 15, 2025" },
      { date: "2025-02-15", expected: "Feb 15, 2025" },
      { date: "2025-03-15", expected: "Mar 15, 2025" },
      { date: "2025-04-15", expected: "Apr 15, 2025" },
      { date: "2025-05-15", expected: "May 15, 2025" },
      { date: "2025-06-15", expected: "Jun 15, 2025" },
      { date: "2025-07-15", expected: "Jul 15, 2025" },
      { date: "2025-08-15", expected: "Aug 15, 2025" },
      { date: "2025-09-15", expected: "Sep 15, 2025" },
      { date: "2025-10-15", expected: "Oct 15, 2025" },
      { date: "2025-11-15", expected: "Nov 15, 2025" },
      { date: "2025-12-15", expected: "Dec 15, 2025" },
    ];

    months.forEach(({ date, expected }) => {
      const { unmount } = render(<DateDisplay date={date} />);
      expect(screen.getByTestId("date-display")).toHaveTextContent(expected);
      unmount();
    });
  });

  it("renders all months correctly in long format", () => {
    const months = [
      { date: "2025-01-15", expected: "January 15, 2025" },
      { date: "2025-06-15", expected: "June 15, 2025" },
      { date: "2025-12-15", expected: "December 15, 2025" },
    ];

    months.forEach(({ date, expected }) => {
      const { unmount } = render(<DateDisplay date={date} format="long" />);
      expect(screen.getByTestId("date-display")).toHaveTextContent(expected);
      unmount();
    });
  });
});

describe("formatDate utility", () => {
  it("formats date string in short format", () => {
    expect(formatDate("2025-12-30")).toBe("Dec 30, 2025");
  });

  it("formats date string in long format", () => {
    expect(formatDate("2025-12-30", "long")).toBe("December 30, 2025");
  });

  it("formats Date object", () => {
    expect(formatDate(new Date(2025, 11, 30))).toBe("Dec 30, 2025");
  });
});
