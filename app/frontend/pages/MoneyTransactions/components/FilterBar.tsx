import { router } from "@inertiajs/react";
import { useRef, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";

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

interface FilterBarProps {
  filters: Filters;
  period: Period;
}

export default function FilterBar({ filters, period }: FilterBarProps) {
  const { t } = useTranslation();
  const [searchValue, setSearchValue] = useState(filters.description || "");
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const MONTHS = [
    t("months.jan"),
    t("months.feb"),
    t("months.mar"),
    t("months.apr"),
    t("months.may"),
    t("months.jun"),
    t("months.jul"),
    t("months.aug"),
    t("months.sep"),
    t("months.oct"),
    t("months.nov"),
    t("months.dec"),
  ];

  useEffect(() => {
    setSearchValue(filters.description || "");
  }, [filters.description]);

  const buildParams = (
    overrides: Record<string, string | number | null | undefined>
  ) => {
    const params: Record<string, string | number> = {};

    const year = overrides.year !== undefined ? overrides.year : period.year;
    if (year) params.year = year;

    const month = overrides.month !== undefined ? overrides.month : period.month;
    if (month) params.month = month;

    const transactionType =
      overrides.transaction_type !== undefined
        ? overrides.transaction_type
        : filters.transaction_type;
    if (transactionType) params.transaction_type = transactionType;

    const description =
      overrides.description !== undefined
        ? overrides.description
        : filters.description;
    if (description) params.description = description;

    return params;
  };

  const handleYearChange = (newYear: number) => {
    router.get("/money_transactions", buildParams({ year: newYear }), {
      preserveState: true,
      preserveScroll: true,
    });
  };

  const handleMonthChange = (newMonth: number | null) => {
    router.get("/money_transactions", buildParams({ month: newMonth }), {
      preserveState: true,
      preserveScroll: true,
    });
  };

  const handleTransactionTypeChange = (transactionType: string) => {
    router.get(
      "/money_transactions",
      buildParams({ transaction_type: transactionType || null }),
      {
        preserveState: true,
        preserveScroll: true,
      }
    );
  };

  const handleSearchChange = (value: string) => {
    setSearchValue(value);

    if (debounceRef.current) {
      clearTimeout(debounceRef.current);
    }

    debounceRef.current = setTimeout(() => {
      router.get(
        "/money_transactions",
        buildParams({ description: value || null }),
        {
          preserveState: true,
          preserveScroll: true,
        }
      );
    }, 300);
  };

  const handleClearFilters = () => {
    setSearchValue("");
    router.get("/money_transactions", {}, { preserveState: true });
  };

  const hasFilters =
    filters.transaction_type || filters.description || period.month !== null;

  return (
    <div className="bg-stone-100 px-4 sm:px-6 py-4">
      <div className="flex flex-col gap-4">
        {/* Year and Month Selector */}
        <div className="flex flex-wrap items-center gap-3">
          {/* Year Selector */}
          <select
            id="filter-year"
            value={period.year}
            onChange={(e) => handleYearChange(Number(e.target.value))}
            className="px-3 py-2 bg-white border border-stone-200 rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-stone-900 focus:border-transparent"
            aria-label={t("pages.moneyTransactions.filter.year", "Year")}
          >
            {period.available_years.map((year) => (
              <option key={year} value={year}>
                {year}
              </option>
            ))}
          </select>

          {/* Month Selector */}
          <div className="flex flex-wrap gap-1 bg-stone-100 p-1 rounded-lg border border-stone-200">
            <button
              type="button"
              onClick={() => handleMonthChange(null)}
              className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                period.month === null
                  ? "bg-stone-900 text-white"
                  : "text-stone-500 hover:bg-white"
              }`}
            >
              {t("common.all")}
            </button>
            {MONTHS.map((month, index) => (
              <button
                type="button"
                key={month}
                onClick={() => handleMonthChange(index + 1)}
                className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                  period.month === index + 1
                    ? "bg-stone-900 text-white"
                    : "text-stone-500 hover:bg-white"
                }`}
              >
                {month}
              </button>
            ))}
          </div>
        </div>

        {/* Other Filters */}
        <div className="flex flex-wrap gap-4 items-end">
          <div className="w-full sm:w-36">
            <label
              htmlFor="filter-transaction-type"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              {t("pages.moneyTransactions.filter.transactionType", "Type")}
            </label>
            <select
              id="filter-transaction-type"
              value={filters.transaction_type || ""}
              onChange={(e) => handleTransactionTypeChange(e.target.value)}
              className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
            >
              <option value="">
                {t("pages.moneyTransactions.filter.allTypes", "All Types")}
              </option>
              <option value="income">
                {t("pages.moneyTransactions.filter.income", "Income")}
              </option>
              <option value="expense">
                {t("pages.moneyTransactions.filter.expense", "Expense")}
              </option>
            </select>
          </div>
          <div className="w-full sm:w-64">
            <label
              htmlFor="filter-description"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              {t("pages.moneyTransactions.filter.description", "Description")}
            </label>
            <input
              id="filter-description"
              type="text"
              value={searchValue}
              onChange={(e) => handleSearchChange(e.target.value)}
              placeholder={t(
                "pages.moneyTransactions.filter.searchDescription",
                "Search description..."
              )}
              className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900 placeholder:text-stone-400"
            />
          </div>
          {hasFilters && (
            <button
              type="button"
              onClick={handleClearFilters}
              className="h-10 px-2 text-sm text-stone-500 hover:text-stone-700"
            >
              {t("pages.moneyTransactions.filter.clear", "Clear")}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
