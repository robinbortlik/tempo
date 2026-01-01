import { cn } from "@/lib/utils";

const CURRENCY_SYMBOLS: Record<string, string> = {
  EUR: "\u20AC", // Euro sign
  USD: "$",
  GBP: "\u00A3", // Pound sign
  CZK: "K\u010D", // Kc with caron
};

// Currencies where the symbol comes after the amount
const SYMBOL_AFTER_CURRENCIES = new Set(["CZK"]);

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
  const numAmount = Math.round(Number(amount) * 100) / 100;
  const formattedAmount = numAmount.toLocaleString("cs-CZ", {
    minimumFractionDigits: showDecimals ? 2 : 0,
    maximumFractionDigits: showDecimals ? 2 : 0,
  });
  const symbolAfter = SYMBOL_AFTER_CURRENCIES.has(currency);

  return (
    <span
      className={cn("tabular-nums", className)}
      data-testid="currency-display"
    >
      {symbolAfter
        ? `${formattedAmount} ${symbol}`
        : `${symbol}${formattedAmount}`}
    </span>
  );
}

// Utility function for formatting currency as a string (for non-component use)
export function formatCurrency(
  amount: number,
  currency: string | null | undefined,
  showDecimals = true
): string {
  const symbol = getCurrencySymbol(currency);
  // Ensure amount is a number and round to avoid floating point issues
  const numAmount = Math.round(Number(amount) * 100) / 100;
  const formattedAmount = numAmount.toLocaleString("cs-CZ", {
    minimumFractionDigits: showDecimals ? 2 : 0,
    maximumFractionDigits: showDecimals ? 2 : 0,
  });
  const symbolAfter = currency && SYMBOL_AFTER_CURRENCIES.has(currency);
  return symbolAfter
    ? `${formattedAmount} ${symbol}`
    : `${symbol}${formattedAmount}`;
}

// Utility function for getting just the currency symbol (for input addons, etc.)
export function getCurrencySymbol(currency: string | null | undefined): string {
  if (!currency) return "$";
  return CURRENCY_SYMBOLS[currency] || currency;
}

// Check if currency symbol should be placed after the amount
export function isSymbolAfter(currency: string | null | undefined): boolean {
  return currency ? SYMBOL_AFTER_CURRENCIES.has(currency) : false;
}

// Utility function for formatting hourly rates (e.g., "$150/hr" or "150 Kč/hr")
export function formatRate(
  rate: number | string | null,
  currency: string | null | undefined,
  showSuffix = true
): string {
  if (!rate) return "-";
  const numRate = typeof rate === "string" ? parseFloat(rate) : rate;
  if (isNaN(numRate)) return "-";
  const symbol = getCurrencySymbol(currency);
  const symbolAfter = currency && SYMBOL_AFTER_CURRENCIES.has(currency);
  const roundedRate = Math.round(numRate);
  const suffix = showSuffix ? "/hr" : "";
  return symbolAfter
    ? `${roundedRate} ${symbol}${suffix}`
    : `${symbol}${roundedRate}${suffix}`;
}

// Utility function for formatting hours (always whole numbers)
export function formatHours(hours: number | string | null): string {
  if (hours === null || hours === undefined) return "0";
  const numHours = typeof hours === "string" ? parseFloat(hours) : hours;
  if (isNaN(numHours)) return "0";
  return Math.round(numHours).toString();
}

// Export the currency symbols map for external use
export { CURRENCY_SYMBOLS };
