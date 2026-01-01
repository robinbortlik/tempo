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
  const formattedAmount = amount.toLocaleString(undefined, {
    minimumFractionDigits: showDecimals ? 2 : 0,
    maximumFractionDigits: showDecimals ? 2 : 0,
  });
  const symbolAfter = SYMBOL_AFTER_CURRENCIES.has(currency);

  return (
    <span
      className={cn("tabular-nums", className)}
      data-testid="currency-display"
    >
      {symbolAfter ? `${formattedAmount} ${symbol}` : `${symbol}${formattedAmount}`}
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
  const formattedAmount = amount.toLocaleString(undefined, {
    minimumFractionDigits: showDecimals ? 2 : 0,
    maximumFractionDigits: showDecimals ? 2 : 0,
  });
  const symbolAfter = currency && SYMBOL_AFTER_CURRENCIES.has(currency);
  return symbolAfter ? `${formattedAmount} ${symbol}` : `${symbol}${formattedAmount}`;
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
  rate: number | null,
  currency: string | null | undefined
): string {
  if (!rate) return "-";
  const symbol = getCurrencySymbol(currency);
  const symbolAfter = currency && SYMBOL_AFTER_CURRENCIES.has(currency);
  return symbolAfter ? `${rate} ${symbol}/hr` : `${symbol}${rate}/hr`;
}

// Export the currency symbols map for external use
export { CURRENCY_SYMBOLS };
