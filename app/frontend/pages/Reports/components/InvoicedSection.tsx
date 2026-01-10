import { useState } from "react";
import { useTranslation } from "react-i18next";
import { formatCurrency, formatHours } from "@/components/CurrencyDisplay";

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

interface InvoicedSectionProps {
  invoices: Invoice[];
  currency: string;
  shareToken: string;
}

function formatDateRange(start: string, end: string): string {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const startFormatted = startDate.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
  const endFormatted = endDate.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
  return `${startFormatted}\u2013${endFormatted}`;
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
}

function LineItemRow({ item, currency }: { item: LineItem; currency: string }) {
  const [isExpanded, setIsExpanded] = useState(false);
  // Only time_aggregate items can have expandable breakdowns
  const isExpandable =
    item.line_type === "time_aggregate" &&
    item.work_entries &&
    item.work_entries.length > 0;

  return (
    <>
      <tr className="border-b border-stone-100 last:border-0">
        <td className="py-3 text-stone-700">
          <div className="flex items-center gap-2">
            {isExpandable ? (
              <button
                onClick={() => setIsExpanded(!isExpanded)}
                className="flex items-center gap-1.5 hover:text-stone-900 cursor-pointer group"
              >
                <svg
                  className={`w-4 h-4 text-stone-400 group-hover:text-stone-600 transition-transform ${isExpanded ? "rotate-90" : ""}`}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M9 5l7 7-7 7"
                  />
                </svg>
                <span className="font-medium">{item.description}</span>
              </button>
            ) : (
              <span className="pl-6">{item.description}</span>
            )}
          </div>
        </td>
        <td className="py-3 text-right tabular-nums text-stone-600 whitespace-nowrap">
          {item.line_type === "time_aggregate" && item.quantity ? (
            `${formatHours(item.quantity)}h`
          ) : (
            <span className="text-stone-300">&mdash;</span>
          )}
        </td>
        <td className="py-3 text-right tabular-nums text-stone-600 whitespace-nowrap">
          {item.line_type === "time_aggregate" && item.unit_price ? (
            formatCurrency(item.unit_price, currency)
          ) : (
            <span className="text-stone-300">&mdash;</span>
          )}
        </td>
        <td className="py-3 text-right tabular-nums text-stone-500 whitespace-nowrap">
          {item.vat_rate}%
        </td>
        <td className="py-3 text-right tabular-nums text-stone-900 font-medium whitespace-nowrap">
          {formatCurrency(item.amount, currency)}
        </td>
      </tr>
      {/* Expanded Work Entries - only for time_aggregate items */}
      {isExpanded && isExpandable && (
        <>
          {item.work_entries.map((entry, index) => (
            <tr
              key={entry.id}
              className={
                index < item.work_entries.length - 1
                  ? "border-b border-stone-50"
                  : ""
              }
            >
              <td className="py-2 pl-7 text-stone-500">
                <div className="flex items-center gap-3">
                  <span className="text-xs text-stone-400 w-12">
                    {formatDate(entry.date)}
                  </span>
                  <span className="text-stone-600">
                    {entry.description || "-"}
                  </span>
                  <span className="text-xs text-stone-400">
                    {entry.project_name}
                  </span>
                </div>
              </td>
              <td className="py-2 text-right tabular-nums text-stone-500 whitespace-nowrap">
                {formatHours(entry.hours)}h
              </td>
              <td className="py-2 text-right whitespace-nowrap"></td>
              <td className="py-2 text-right whitespace-nowrap"></td>
              <td className="py-2 text-right tabular-nums text-stone-500 whitespace-nowrap">
                {formatCurrency(entry.calculated_amount, currency)}
              </td>
            </tr>
          ))}
        </>
      )}
    </>
  );
}

export function InvoicedSection({
  invoices,
  currency,
  shareToken,
}: InvoicedSectionProps) {
  const { t } = useTranslation();

  if (invoices.length === 0) {
    return null;
  }

  return (
    <section className="mb-8">
      <h2 className="text-lg font-semibold text-stone-900 mb-4 flex items-center gap-2">
        <span className="w-2 h-2 bg-emerald-500 rounded-full" />
        {t("pages.reports.previouslyInvoiced")}
      </h2>

      <div className="space-y-4">
        {invoices.map((invoice) => (
          <div
            key={invoice.id}
            className="bg-white border border-stone-200 rounded-xl overflow-hidden"
          >
            <div className="px-4 py-3 bg-stone-50 flex items-center justify-between border-b border-stone-100">
              <div className="flex items-center gap-3">
                <div>
                  <span className="font-medium text-stone-700">
                    {t("pages.reports.invoiceNumber", {
                      number: invoice.number,
                    })}
                  </span>
                  <span className="text-stone-300 mx-2">&middot;</span>
                  <span className="text-sm text-stone-500">
                    {formatDateRange(invoice.period_start, invoice.period_end)}
                  </span>
                </div>
                <a
                  href={`/reports/${shareToken}/invoices/${invoice.id}/pdf`}
                  download
                  className="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium text-stone-600 hover:text-stone-900 hover:bg-stone-100 rounded-md transition-colors"
                >
                  <svg
                    className="w-3.5 h-3.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                    />
                  </svg>
                  PDF
                </a>
              </div>
              <span className="text-sm font-semibold text-emerald-600 whitespace-nowrap">
                {formatCurrency(invoice.total_amount, currency)}
              </span>
            </div>
            {/* Line Items Table */}
            {invoice.line_items && invoice.line_items.length > 0 ? (
              <div className="px-4 py-3">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-left text-xs text-stone-400 border-b border-stone-100">
                      <th className="pb-2 font-medium">
                        {t("common.description")}
                      </th>
                      <th className="pb-2 font-medium text-right w-16">
                        {t("common.hours")}
                      </th>
                      <th className="pb-2 font-medium text-right w-28">
                        {t("common.rate")}
                      </th>
                      <th className="pb-2 font-medium text-right w-14">
                        {t("pages.invoices.lineItems.vat")}
                      </th>
                      <th className="pb-2 font-medium text-right w-32">
                        {t("common.amount")}
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {invoice.line_items.map((item) => (
                      <LineItemRow
                        key={item.id}
                        item={item}
                        currency={currency}
                      />
                    ))}
                  </tbody>
                </table>
                {/* Invoice Totals */}
                <div className="mt-4 pt-4 border-t border-stone-200 flex justify-end">
                  <div className="text-sm space-y-1.5 min-w-48">
                    <div className="flex justify-between gap-6 text-stone-500">
                      <span>{t("common.subtotal")}</span>
                      <span className="tabular-nums whitespace-nowrap">
                        {formatCurrency(invoice.subtotal, currency)}
                      </span>
                    </div>
                    {invoice.total_vat > 0 && (
                      <div className="flex justify-between gap-6 text-stone-500">
                        <span>{t("pages.invoices.lineItems.vat")}</span>
                        <span className="tabular-nums whitespace-nowrap">
                          {formatCurrency(invoice.total_vat, currency)}
                        </span>
                      </div>
                    )}
                    <div className="flex justify-between gap-6 font-semibold text-stone-900 pt-2 border-t border-stone-200">
                      <span>{t("common.total")}</span>
                      <span className="tabular-nums whitespace-nowrap">
                        {formatCurrency(invoice.total_amount, currency)}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="px-4 py-4 text-center text-stone-400 text-sm">
                {t("pages.reports.hoursCount", {
                  hours: formatHours(invoice.total_hours),
                })}
              </div>
            )}
          </div>
        ))}
      </div>
    </section>
  );
}
