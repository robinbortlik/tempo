import { useTranslation } from "react-i18next";
import { formatCurrency } from "@/components/CurrencyDisplay";

interface Summary {
  total_income: number;
  total_expenses: number;
  net_balance: number;
  transaction_count: number;
}

interface SummaryBarProps {
  summary: Summary;
}

export default function SummaryBar({ summary }: SummaryBarProps) {
  const { t } = useTranslation();

  return (
    <div className="bg-stone-50 border-t border-stone-200 px-4 sm:px-6 py-3">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-8">
        <div className="flex flex-wrap items-center gap-4 sm:gap-8">
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-stone-500">
              {t("pages.moneyTransactions.summary.totalIncome", "Total Income")}
            </span>
            <span className="text-lg font-bold text-green-600 tabular-nums">
              {formatCurrency(Number(summary.total_income || 0), "USD", false)}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-stone-500">
              {t("pages.moneyTransactions.summary.totalExpenses", "Total Expenses")}
            </span>
            <span className="text-lg font-bold text-red-600 tabular-nums">
              {formatCurrency(Number(summary.total_expenses || 0), "USD", false)}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-stone-500">
              {t("pages.moneyTransactions.summary.netBalance", "Net Balance")}
            </span>
            <span
              className={`text-lg font-bold tabular-nums ${
                summary.net_balance >= 0 ? "text-green-600" : "text-red-600"
              }`}
            >
              {formatCurrency(Number(summary.net_balance || 0), "USD", false)}
            </span>
          </div>
        </div>
        <div className="flex items-center gap-6 text-sm text-stone-500">
          <span>
            {t("pages.moneyTransactions.summary.transactionCount", "{{count}} transactions", {
              count: summary.transaction_count || 0,
            })}
          </span>
        </div>
      </div>
    </div>
  );
}
