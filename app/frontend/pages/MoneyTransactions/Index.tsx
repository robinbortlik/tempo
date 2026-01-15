import { Head, usePage } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Toaster } from "@/components/ui/sonner";
import FilterBar from "./components/FilterBar";
import SummaryBar from "./components/SummaryBar";
import TransactionRow from "./components/TransactionRow";

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

interface Filters {
  year: number;
  month: number | null;
  transaction_type: string | null;
  description: string | null;
}

interface Period {
  year: number;
  month: number | null;
  available_years: number[];
}

interface Summary {
  total_income: number;
  total_expenses: number;
  net_balance: number;
  transaction_count: number;
}

interface PageProps {
  transactions: MoneyTransaction[];
  filters: Filters;
  period: Period;
  summary: Summary;
  flash?: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

interface IndexProps {
  transactions: MoneyTransaction[];
  filters: Filters;
  period: Period;
  summary: Summary;
}

export default function MoneyTransactionsIndex(props?: IndexProps) {
  const pageProps = usePage<PageProps>().props;
  const { transactions, filters, period, summary, flash } = props || pageProps;
  const { t } = useTranslation();
  const [expandedId, setExpandedId] = useState<number | null>(null);

  useEffect(() => {
    if (flash?.notice) {
      toast.success(flash.notice);
    }
    if (flash?.alert) {
      toast.error(flash.alert);
    }
  }, [flash?.notice, flash?.alert]);

  const handleToggleExpand = (id: number) => {
    setExpandedId(expandedId === id ? null : id);
  };

  const hasActiveFilters = filters.transaction_type || filters.description;
  const hasNoTransactions = transactions.length === 0;

  return (
    <>
      <Head title={t("pages.moneyTransactions.title", "Transactions")} />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
        <div className="mb-6 sm:mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-stone-900">
              {t("pages.moneyTransactions.title", "Transactions")}
            </h1>
            <p className="text-stone-500 mt-1">
              {t("pages.moneyTransactions.subtitle", "View and filter your money transactions")}
            </p>
          </div>
        </div>

        {/* Data Section: Filters + Summary + Transactions */}
        <div className="border border-stone-200 rounded-xl overflow-hidden">
          <FilterBar filters={filters} period={period} />

          {/* Summary Stats Bar - only show when there are transactions */}
          {!hasNoTransactions && <SummaryBar summary={summary} />}

          {/* Transactions List */}
          {hasNoTransactions ? (
            <div className="bg-white border-t border-stone-200 p-8 text-center">
              {hasActiveFilters ? (
                <>
                  <p className="text-stone-900 font-medium">
                    {t(
                      "pages.moneyTransactions.noFilterResults",
                      "No transactions match your filters"
                    )}
                  </p>
                  <p className="text-stone-500 mt-1">
                    {t(
                      "pages.moneyTransactions.noFilterResultsDescription",
                      "Try adjusting your filters to see more results."
                    )}
                  </p>
                </>
              ) : (
                <>
                  <p className="text-stone-900 font-medium">
                    {t("pages.moneyTransactions.noTransactions", "No transactions yet")}
                  </p>
                  <p className="text-stone-500 mt-1">
                    {t(
                      "pages.moneyTransactions.noTransactionsDescription",
                      "Transactions will appear here once they are imported."
                    )}
                  </p>
                </>
              )}
            </div>
          ) : (
            <div className="bg-white border-t border-stone-200 divide-y divide-stone-100">
              {transactions.map((transaction) => (
                <TransactionRow
                  key={transaction.id}
                  transaction={transaction}
                  isExpanded={expandedId === transaction.id}
                  onToggle={handleToggleExpand}
                />
              ))}
            </div>
          )}
        </div>
      </div>
    </>
  );
}
