import { cn } from "@/lib/utils";

const CURRENCY_SYMBOLS: Record<string, string> = {
  EUR: "\u20AC", // Euro sign
  USD: "$",
  GBP: "\u00A3", // Pound sign
  CZK: "K\u010D", // Kc with caron
};

interface CurrencyDisplayProps {
  amount: number;
  currency: string;
  className?: string;
  showDecimals?: boolean;
}

export function CurrencyDisplay({
  amount,
  currency,
  className,
  showDecimals = true,
}: CurrencyDisplayProps) {
  const symbol = CURRENCY_SYMBOLS[currency] || currency;
  const formattedAmount = amount.toLocaleString(undefined, {
    minimumFractionDigits: showDecimals ? 2 : 0,
    maximumFractionDigits: showDecimals ? 2 : 0,
  });

  return (
    <span className={cn("tabular-nums", className)} data-testid="currency-display">
      {symbol}
      {formattedAmount}
    </span>
  );
}

// Utility function for formatting currency as a string (for non-component use)
export function formatCurrency(
  amount: number,
  currency: string,
  showDecimals = true
): string {
  const symbol = CURRENCY_SYMBOLS[currency] || currency;
  const formattedAmount = amount.toLocaleString(undefined, {
    minimumFractionDigits: showDecimals ? 2 : 0,
    maximumFractionDigits: showDecimals ? 2 : 0,
  });
  return `${symbol}${formattedAmount}`;
}

// Export the currency symbols map for external use
export { CURRENCY_SYMBOLS };
