import { Head, usePage, router, useForm } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Toaster } from "@/components/ui/sonner";

interface TimeEntry {
  id: number;
  date: string;
  hours: number;
  description: string;
  calculated_amount: number;
  project_id: number;
  project_name: string;
  effective_hourly_rate: number;
}

interface Invoice {
  id: number;
  number: string;
  status: "draft" | "final";
  issue_date: string;
  due_date: string;
  period_start: string;
  period_end: string;
  total_hours: number;
  total_amount: number;
  currency: string;
  notes: string | null;
  client_id: number;
  client_name: string;
}

interface PageProps {
  invoice: Invoice;
  time_entries: TimeEntry[];
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

function formatCurrency(amount: number, currency: string | null): string {
  const symbols: Record<string, string> = {
    EUR: "\u20AC",
    USD: "$",
    GBP: "\u00A3",
    CZK: "K\u010D",
  };
  const symbol = currency ? symbols[currency] || currency : "";
  return `${symbol}${amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
}

function formatPeriod(start: string, end: string): string {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const startMonth = startDate.toLocaleDateString("en-US", { month: "short" });
  const endMonth = endDate.toLocaleDateString("en-US", { month: "short" });
  const startDay = startDate.getDate();
  const endDay = endDate.getDate();
  const year = endDate.getFullYear();

  if (startMonth === endMonth) {
    return `${startMonth} ${startDay}\u2013${endDay}, ${year}`;
  }
  return `${startMonth} ${startDay}\u2013${endMonth} ${endDay}, ${year}`;
}

export default function EditInvoice() {
  const { invoice, time_entries, flash } = usePage<PageProps>().props;
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { data, setData } = useForm({
    issue_date: invoice.issue_date,
    due_date: invoice.due_date,
    notes: invoice.notes || "",
  });

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    router.patch(
      `/invoices/${invoice.id}`,
      {
        invoice: {
          issue_date: data.issue_date,
          due_date: data.due_date,
          notes: data.notes,
        },
      },
      {
        onFinish: () => setIsSubmitting(false),
      }
    );
  };

  // Group entries by project
  const entriesByProject = time_entries.reduce(
    (acc, entry) => {
      if (!acc[entry.project_name]) {
        acc[entry.project_name] = {
          entries: [],
          total_hours: 0,
          total_amount: 0,
        };
      }
      acc[entry.project_name].entries.push(entry);
      acc[entry.project_name].total_hours += entry.hours;
      acc[entry.project_name].total_amount += entry.calculated_amount;
      return acc;
    },
    {} as Record<
      string,
      { entries: TimeEntry[]; total_hours: number; total_amount: number }
    >
  );

  return (
    <>
      <Head title={`Edit Invoice ${invoice.number}`} />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-6">
          <button
            onClick={() => router.visit(`/invoices/${invoice.id}`)}
            className="flex items-center gap-1 text-sm text-stone-500 hover:text-stone-700 mb-4"
          >
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M15 19l-7-7 7-7"
              />
            </svg>
            Back to Invoice {invoice.number}
          </button>
          <h1 className="text-2xl font-semibold text-stone-900">
            Edit Invoice {invoice.number}
          </h1>
          <p className="text-stone-500 mt-1">
            {invoice.client_name} {"\u00B7"}{" "}
            {formatPeriod(invoice.period_start, invoice.period_end)}
          </p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="grid grid-cols-3 gap-8">
            {/* Left: Form */}
            <div className="col-span-1 space-y-6">
              <div className="bg-white rounded-xl border border-stone-200 p-6">
                <h3 className="font-semibold text-stone-900 mb-4">
                  Invoice Details
                </h3>
                <div className="space-y-4">
                  <div>
                    <Label className="block text-sm font-medium text-stone-600 mb-1.5">
                      Client
                    </Label>
                    <p className="px-3 py-2.5 bg-stone-100 border border-stone-200 rounded-lg text-stone-700">
                      {invoice.client_name}
                    </p>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <Label className="block text-sm font-medium text-stone-600 mb-1.5">
                        Period Start
                      </Label>
                      <p className="px-3 py-2.5 bg-stone-100 border border-stone-200 rounded-lg text-stone-700">
                        {invoice.period_start}
                      </p>
                    </div>
                    <div>
                      <Label className="block text-sm font-medium text-stone-600 mb-1.5">
                        Period End
                      </Label>
                      <p className="px-3 py-2.5 bg-stone-100 border border-stone-200 rounded-lg text-stone-700">
                        {invoice.period_end}
                      </p>
                    </div>
                  </div>

                  <div>
                    <Label
                      htmlFor="issue_date"
                      className="block text-sm font-medium text-stone-600 mb-1.5"
                    >
                      Issue Date
                    </Label>
                    <input
                      type="date"
                      id="issue_date"
                      value={data.issue_date}
                      onChange={(e) => setData("issue_date", e.target.value)}
                      className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-stone-900 focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
                    />
                  </div>

                  <div>
                    <Label
                      htmlFor="due_date"
                      className="block text-sm font-medium text-stone-600 mb-1.5"
                    >
                      Due Date
                    </Label>
                    <input
                      type="date"
                      id="due_date"
                      value={data.due_date}
                      onChange={(e) => setData("due_date", e.target.value)}
                      className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-stone-900 focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
                    />
                  </div>

                  <div>
                    <Label
                      htmlFor="notes"
                      className="block text-sm font-medium text-stone-600 mb-1.5"
                    >
                      Notes (optional)
                    </Label>
                    <Textarea
                      id="notes"
                      rows={3}
                      placeholder="Additional notes for the invoice..."
                      value={data.notes}
                      onChange={(e) => setData("notes", e.target.value)}
                      className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 placeholder:text-stone-400"
                    />
                  </div>
                </div>
              </div>

              <div className="flex gap-3">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => router.visit(`/invoices/${invoice.id}`)}
                  className="flex-1 py-2.5 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSubmitting ? "Saving..." : "Save Changes"}
                </Button>
              </div>
            </div>

            {/* Right: Preview */}
            <div className="col-span-2">
              <div className="bg-white rounded-xl border border-stone-200 p-6">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="font-semibold text-stone-900">
                    Invoice Entries
                  </h3>
                  <div className="text-sm text-stone-500">
                    {invoice.total_hours} hours {"\u00B7"}{" "}
                    {formatCurrency(invoice.total_amount, invoice.currency)}
                  </div>
                </div>

                {/* Entries grouped by project */}
                <div className="border border-stone-200 rounded-lg overflow-hidden">
                  {Object.entries(entriesByProject).map(
                    ([projectName, group], groupIndex) => (
                      <div key={projectName}>
                        <div
                          className={`px-4 py-3 bg-stone-50 flex items-center justify-between ${
                            groupIndex > 0 ? "border-t border-stone-200" : ""
                          }`}
                        >
                          <span className="font-medium text-stone-700">
                            {projectName}
                          </span>
                          <span className="text-sm text-stone-500">
                            {group.total_hours}h {"\u00B7"}{" "}
                            {formatCurrency(group.total_amount, invoice.currency)}
                          </span>
                        </div>
                        <table className="w-full text-sm">
                          <tbody>
                            {group.entries.map((entry, entryIndex) => (
                              <tr
                                key={entry.id}
                                className={
                                  entryIndex < group.entries.length - 1
                                    ? "border-b border-stone-100"
                                    : ""
                                }
                              >
                                <td className="px-4 py-3 text-stone-500 w-24">
                                  {formatDate(entry.date)}
                                </td>
                                <td className="px-4 py-3 text-stone-700">
                                  {entry.description || "No description"}
                                </td>
                                <td className="px-4 py-3 text-right tabular-nums w-16">
                                  {entry.hours}h
                                </td>
                                <td className="px-4 py-3 text-right tabular-nums text-stone-500 w-24">
                                  {formatCurrency(
                                    entry.calculated_amount,
                                    invoice.currency
                                  )}
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    )
                  )}
                </div>

                {/* Totals */}
                <div className="mt-6 pt-6 border-t border-stone-200">
                  <div className="flex justify-end">
                    <dl className="w-64 space-y-2 text-sm">
                      <div className="flex justify-between">
                        <dt className="text-stone-500">Subtotal</dt>
                        <dd className="tabular-nums text-stone-900">
                          {formatCurrency(invoice.total_amount, invoice.currency)}
                        </dd>
                      </div>
                      <div className="flex justify-between">
                        <dt className="text-stone-500">VAT (0%)</dt>
                        <dd className="tabular-nums text-stone-900">
                          {formatCurrency(0, invoice.currency)}
                        </dd>
                      </div>
                      <div className="flex justify-between pt-2 border-t border-stone-200">
                        <dt className="font-semibold text-stone-900">Total</dt>
                        <dd className="tabular-nums font-semibold text-stone-900">
                          {formatCurrency(invoice.total_amount, invoice.currency)}
                        </dd>
                      </div>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </>
  );
}
