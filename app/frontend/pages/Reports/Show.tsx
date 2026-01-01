import React from "react";
import { router, usePage } from "@inertiajs/react";
import PublicLayout from "@/components/PublicLayout";
import { formatCurrency, formatHours } from "@/components/CurrencyDisplay";
import { UnbilledSection } from "./components/UnbilledSection";
import { InvoicedSection } from "./components/InvoicedSection";

interface Entry {
  id: number;
  date: string;
  hours: number;
  description: string | null;
  calculated_amount: number;
  entry_type: "time" | "fixed";
  amount: number | null;
}

interface WorkEntry {
  id: number;
  date: string;
  hours: number;
  description: string | null;
  calculated_amount: number;
  entry_type: "time" | "fixed";
  project_name: string;
}

interface LineItem {
  id: number;
  line_type: "time_aggregate" | "fixed";
  description: string;
  quantity: number | null;
  unit_price: number | null;
  amount: number;
  vat_rate: number;
  work_entries: WorkEntry[];
}

interface Project {
  id: number;
  name: string;
  effective_hourly_rate: number;
}

interface ProjectGroupData {
  project: Project;
  entries: Entry[];
  total_hours: number;
  total_amount: number;
}

interface Invoice {
  id: number;
  number: string;
  issue_date: string;
  period_start: string;
  period_end: string;
  total_hours: number;
  total_amount: number;
  line_items: LineItem[];
  subtotal: number;
  total_vat: number;
}

interface PageProps {
  client: {
    id: number;
    name: string;
    currency: string;
  };
  period: {
    year: number;
    month: number | null;
    available_years: number[];
  };
  unbilled: {
    project_groups: ProjectGroupData[];
    total_hours: number;
    total_amount: number;
  };
  invoiced: {
    project_groups: ProjectGroupData[];
    total_hours: number;
    total_amount: number;
    invoices: Invoice[];
  };
  settings: {
    company_name: string | null;
  };
  [key: string]: unknown;
}

const MONTHS = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

function ReportsShow() {
  const { client, period, unbilled, invoiced, settings } =
    usePage<PageProps>().props;

  // Get share_token from URL
  const pathParts = window.location.pathname.split("/");
  const shareToken = pathParts[pathParts.length - 1].split("?")[0];

  const handleYearChange = (newYear: number) => {
    router.get(
      `/reports/${shareToken}`,
      { year: newYear, month: period.month || undefined },
      { preserveState: true, preserveScroll: true }
    );
  };

  const handleMonthChange = (newMonth: number | null) => {
    router.get(
      `/reports/${shareToken}`,
      { year: period.year, month: newMonth || undefined },
      { preserveState: true, preserveScroll: true }
    );
  };

  const periodLabel = period.month
    ? `${MONTHS[period.month - 1]} ${period.year}`
    : `${period.year}`;

  return (
    <PublicLayout title={`Report - ${client.name}`}>
      {/* Print Styles */}
      <style>{`
        @media print {
          .no-print {
            display: none !important;
          }
          .print-expand [data-state] {
            display: block !important;
            height: auto !important;
            overflow: visible !important;
          }
          body {
            print-color-adjust: exact;
            -webkit-print-color-adjust: exact;
          }
        }
      `}</style>

      {/* Header */}
      <header className="border-b border-stone-200">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-6">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
            <div>
              <p className="text-sm text-stone-500">Time Report for</p>
              <h1 className="text-xl font-semibold text-stone-900">
                {client.name}
              </h1>
            </div>
            {settings.company_name && (
              <div className="text-left sm:text-right">
                <p className="text-sm text-stone-500">Prepared by</p>
                <p className="font-medium text-stone-900">
                  {settings.company_name}
                </p>
              </div>
            )}
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 sm:px-6 py-8 print-expand">
        {/* Period Filter */}
        <div className="flex flex-col sm:flex-row sm:items-center gap-3 mb-8 no-print">
          {/* Year Selector */}
          <select
            value={period.year}
            onChange={(e) => handleYearChange(Number(e.target.value))}
            className="px-3 py-2 bg-white border border-stone-200 rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-stone-900 focus:border-transparent"
          >
            {period.available_years.map((year) => (
              <option key={year} value={year}>
                {year}
              </option>
            ))}
          </select>

          {/* Month Selector */}
          <div className="flex flex-wrap gap-1 bg-stone-100 p-1 rounded-lg">
            <button
              onClick={() => handleMonthChange(null)}
              className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                period.month === null
                  ? "bg-stone-900 text-white"
                  : "text-stone-500 hover:bg-white"
              }`}
            >
              All
            </button>
            {MONTHS.map((month, index) => (
              <button
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

        {/* Period Label for Print */}
        <div className="hidden print:block mb-6">
          <p className="text-sm text-stone-500">
            Period:{" "}
            <span className="font-medium text-stone-900">{periodLabel}</span>
          </p>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
            <p className="text-sm text-amber-700 font-medium">Unbilled Hours</p>
            <p className="text-2xl font-semibold text-amber-900 tabular-nums mt-1">
              {formatHours(unbilled.total_hours)}
            </p>
          </div>
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
            <p className="text-sm text-amber-700 font-medium">
              Unbilled Amount
            </p>
            <p className="text-2xl font-semibold text-amber-900 tabular-nums mt-1 whitespace-nowrap">
              {formatCurrency(unbilled.total_amount, client.currency)}
            </p>
          </div>
          <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4">
            <p className="text-sm text-emerald-700 font-medium">
              Invoiced ({periodLabel})
            </p>
            <p className="text-2xl font-semibold text-emerald-900 tabular-nums mt-1 whitespace-nowrap">
              {formatCurrency(invoiced.total_amount, client.currency)}
            </p>
          </div>
        </div>

        {/* Unbilled Section */}
        <UnbilledSection
          projectGroups={unbilled.project_groups}
          totalHours={unbilled.total_hours}
          totalAmount={unbilled.total_amount}
          currency={client.currency}
        />

        {/* Invoiced Section */}
        <InvoicedSection
          invoices={invoiced.invoices}
          currency={client.currency}
          shareToken={shareToken}
        />

        {/* Empty State */}
        {unbilled.project_groups.length === 0 &&
          invoiced.invoices.length === 0 && (
            <div className="text-center py-12">
              <p className="text-stone-500">
                No time entries found for this period.
              </p>
            </div>
          )}
      </main>

      {/* Footer */}
      <footer className="border-t border-stone-200 mt-12 no-print">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-4 text-center text-sm text-stone-400">
          Generated by Tempo
        </div>
      </footer>
    </PublicLayout>
  );
}

// Use empty layout since PublicLayout handles everything
ReportsShow.layout = (page: React.ReactNode) => page;

export default ReportsShow;
