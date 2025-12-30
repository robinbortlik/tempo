import { cn } from "@/lib/utils";

type DateFormat = "short" | "long";

interface DateDisplayProps {
  date: string | Date;
  format?: DateFormat;
  className?: string;
}

const DATE_FORMAT_OPTIONS: Record<DateFormat, Intl.DateTimeFormatOptions> = {
  short: { month: "short", day: "numeric", year: "numeric" }, // Dec 30, 2025
  long: { month: "long", day: "numeric", year: "numeric" }, // December 30, 2025
};

export function DateDisplay({
  date,
  format = "short",
  className,
}: DateDisplayProps) {
  const dateObj = typeof date === "string" ? new Date(date) : date;
  const formattedDate = dateObj.toLocaleDateString(
    "en-US",
    DATE_FORMAT_OPTIONS[format]
  );

  return (
    <span className={cn(className)} data-testid="date-display">
      {formattedDate}
    </span>
  );
}

// Utility function for formatting dates as strings (for non-component use)
export function formatDate(
  date: string | Date,
  format: DateFormat = "short"
): string {
  const dateObj = typeof date === "string" ? new Date(date) : date;
  return dateObj.toLocaleDateString("en-US", DATE_FORMAT_OPTIONS[format]);
}
