import { useTranslation } from "react-i18next";
import { Link } from "@inertiajs/react";
import i18n from "@/lib/i18n";
import { formatCurrency } from "@/components/CurrencyDisplay";

interface MoneyTransaction {
  id: number;
  transacted_on: string;
  counterparty: string | null;
  description: string | null;
  amount: number;
  currency: string;
  transaction_type: "income" | "expense";
  source: string;
  reference: string | null;
  external_id: string | null;
  invoice_id: number | null;
  invoice_number: string | null;
}

interface TransactionRowProps {
  transaction: MoneyTransaction;
  isExpanded: boolean;
  onToggle: (id: number) => void;
}

function formatShortDate(dateStr: string, locale: string): string {
  const date = new Date(dateStr);
  const localeMap: Record<string, string> = { en: "en-US", cs: "cs-CZ" };
  const dateLocale = localeMap[locale] || "en-US";

  return date.toLocaleDateString(dateLocale, {
    month: "short",
    day: "numeric",
  });
}

function truncateText(text: string | null, maxLength: number): string {
  if (!text) return "";
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + "...";
}

export default function TransactionRow({
  transaction,
  isExpanded,
  onToggle,
}: TransactionRowProps) {
  const { t } = useTranslation();
  const isIncome = transaction.transaction_type === "income";
  const amountColorClass = isIncome ? "text-green-600" : "text-red-600";

  return (
    <div
      className={`
        group/row relative
        transition-colors duration-150
        hover:bg-stone-50
        bg-white
        cursor-pointer
      `}
      onClick={() => onToggle(transaction.id)}
      data-testid={`transaction-row-${transaction.id}`}
    >
      {/* Main Row Content */}
      <div className="flex flex-col sm:flex-row sm:items-center px-4 py-3 gap-2 sm:gap-4">
        {/* Date */}
        <div className="w-full sm:w-16 shrink-0">
          <span className="text-sm font-medium text-stone-500 tabular-nums">
            {formatShortDate(transaction.transacted_on, i18n.language)}
          </span>
        </div>

        {/* Counterparty and Description */}
        <div className="flex-1 min-w-0 flex items-center gap-3">
          <span className="text-sm font-medium text-stone-700">
            {transaction.counterparty || t("common.noDescription", "Unknown")}
          </span>
          {transaction.description && (
            <>
              <span className="text-stone-300">-</span>
              <span className="text-sm text-stone-500 truncate">
                {truncateText(transaction.description, 50)}
              </span>
            </>
          )}
        </div>

        {/* Amount and Type */}
        <div className="flex flex-wrap items-center justify-between sm:justify-end gap-2 sm:gap-4 w-full sm:w-auto sm:shrink-0">
          <div className="flex items-center gap-2">
            {/* Invoice Badge */}
            {transaction.invoice_number && (
              <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-50 text-blue-700">
                {transaction.invoice_number}
              </span>
            )}
            {/* Type Badge */}
            <span
              className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                isIncome
                  ? "bg-green-50 text-green-700"
                  : "bg-red-50 text-red-700"
              }`}
            >
              {isIncome
                ? t("pages.moneyTransactions.filter.income", "Income")
                : t("pages.moneyTransactions.filter.expense", "Expense")}
            </span>
          </div>
          {/* Amount */}
          <span
            className={`text-sm font-semibold tabular-nums ${amountColorClass}`}
          >
            {isIncome ? "+" : "-"}
            {formatCurrency(
              Math.abs(transaction.amount),
              transaction.currency,
              false
            )}
          </span>
          {/* Expand Icon */}
          <svg
            className={`w-4 h-4 text-stone-400 transition-transform ${
              isExpanded ? "rotate-180" : ""
            }`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 9l-7 7-7-7"
            />
          </svg>
        </div>
      </div>

      {/* Expanded Details */}
      {isExpanded && (
        <div className="px-4 pb-4 pt-1 border-t border-stone-100 bg-stone-50/50">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
            {transaction.counterparty && (
              <div>
                <span className="text-stone-500 block">
                  {t(
                    "pages.moneyTransactions.row.counterparty",
                    "Counterparty"
                  )}
                </span>
                <span className="text-stone-900 font-medium">
                  {transaction.counterparty}
                </span>
              </div>
            )}
            {transaction.description && (
              <div className="sm:col-span-2">
                <span className="text-stone-500 block">
                  {t("common.description", "Description")}
                </span>
                <span className="text-stone-900">
                  {transaction.description}
                </span>
              </div>
            )}
            <div>
              <span className="text-stone-500 block">
                {t("pages.moneyTransactions.row.source", "Source")}
              </span>
              <span className="text-stone-900">{transaction.source}</span>
            </div>
            {transaction.reference && (
              <div>
                <span className="text-stone-500 block">
                  {t("pages.moneyTransactions.row.reference", "Reference")}
                </span>
                <span className="text-stone-900 font-mono text-xs">
                  {transaction.reference}
                </span>
              </div>
            )}
            {transaction.external_id && (
              <div>
                <span className="text-stone-500 block">
                  {t("pages.moneyTransactions.row.externalId", "External ID")}
                </span>
                <span className="text-stone-900 font-mono text-xs">
                  {transaction.external_id}
                </span>
              </div>
            )}
            {transaction.invoice_id && transaction.invoice_number && (
              <div>
                <span className="text-stone-500 block">
                  {t(
                    "pages.moneyTransactions.row.linkedInvoice",
                    "Linked Invoice"
                  )}
                </span>
                <Link
                  href={`/invoices/${transaction.invoice_id}`}
                  className="text-blue-600 hover:text-blue-800 font-medium"
                  onClick={(e) => e.stopPropagation()}
                >
                  {transaction.invoice_number}
                </Link>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
