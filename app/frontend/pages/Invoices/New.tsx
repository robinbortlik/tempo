import { Head, usePage, router, useForm } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Toaster } from "@/components/ui/sonner";
import InvoicePreview, { LineItem } from "./components/InvoicePreview";

interface Client {
  id: number;
  name: string;
  currency: string;
  hourly_rate: number | null;
  has_unbilled_entries: boolean;
}

interface PreviewData {
  client: {
    id: number;
    name: string;
    currency: string;
  };
  period_start: string;
  period_end: string;
  issue_date: string;
  due_date: string;
  line_items: LineItem[];
  total_hours: number;
  total_amount: number;
  currency: string;
  work_entry_ids: number[];
}

interface PageProps {
  clients: Client[];
  preview: PreviewData | null;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

function getDefaultDates() {
  const today = new Date();
  const firstOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
  const lastOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);
  const dueDate = new Date(today);
  dueDate.setDate(dueDate.getDate() + 30);

  return {
    period_start: firstOfMonth.toISOString().split("T")[0],
    period_end: lastOfMonth.toISOString().split("T")[0],
    issue_date: today.toISOString().split("T")[0],
    due_date: dueDate.toISOString().split("T")[0],
  };
}

export default function NewInvoice() {
  const { clients, preview, flash } = usePage<PageProps>().props;
  const defaults = getDefaultDates();
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Get initial values from URL params or preview data
  const urlParams = new URLSearchParams(window.location.search);
  const initialClientId = urlParams.get("client_id") || "";
  const initialPeriodStart =
    urlParams.get("period_start") || defaults.period_start;
  const initialPeriodEnd = urlParams.get("period_end") || defaults.period_end;
  const initialIssueDate = urlParams.get("issue_date") || defaults.issue_date;
  const initialDueDate = urlParams.get("due_date") || defaults.due_date;

  const { data, setData } = useForm({
    client_id: initialClientId,
    period_start: initialPeriodStart,
    period_end: initialPeriodEnd,
    issue_date: initialIssueDate,
    due_date: initialDueDate,
    notes: "",
  });

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleClientChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setData("client_id", e.target.value);
    // Trigger preview fetch after state update
    setTimeout(() => {
      if (e.target.value && data.period_start && data.period_end) {
        const params = new URLSearchParams({
          client_id: e.target.value,
          period_start: data.period_start,
          period_end: data.period_end,
          issue_date: data.issue_date,
          due_date: data.due_date,
        });
        router.get(
          `/invoices/new?${params.toString()}`,
          {},
          { preserveState: true, preserveScroll: true }
        );
      }
    }, 0);
  };

  const handleDateChange =
    (field: "period_start" | "period_end" | "issue_date" | "due_date") =>
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setData(field, e.target.value);
      // Trigger preview fetch after state update
      setTimeout(() => {
        if (data.client_id && data.period_start && data.period_end) {
          const params = new URLSearchParams({
            client_id: data.client_id,
            period_start:
              field === "period_start" ? e.target.value : data.period_start,
            period_end:
              field === "period_end" ? e.target.value : data.period_end,
            issue_date:
              field === "issue_date" ? e.target.value : data.issue_date,
            due_date: field === "due_date" ? e.target.value : data.due_date,
          });
          router.get(
            `/invoices/new?${params.toString()}`,
            {},
            { preserveState: true, preserveScroll: true }
          );
        }
      }, 0);
    };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!data.client_id) {
      toast.error("Please select a client");
      return;
    }

    const lineItems = preview?.line_items || [];
    if (lineItems.length === 0) {
      toast.error("No unbilled entries found for the selected period");
      return;
    }

    setIsSubmitting(true);
    router.post(
      "/invoices",
      {
        invoice: {
          client_id: data.client_id,
          period_start: data.period_start,
          period_end: data.period_end,
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

  const selectedClient = clients.find(
    (c) => c.id.toString() === data.client_id
  );
  const lineItems = preview?.line_items || [];
  const hasLineItems = lineItems.length > 0;

  return (
    <>
      <Head title="New Invoice" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-6">
          <button
            onClick={() => router.visit("/invoices")}
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
            Back to Invoices
          </button>
          <h1 className="text-2xl font-semibold text-stone-900">New Invoice</h1>
          <p className="text-stone-500 mt-1">
            Create a new invoice from unbilled work entries
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
                    <Label
                      htmlFor="client_id"
                      className="block text-sm font-medium text-stone-600 mb-1.5"
                    >
                      Client
                    </Label>
                    <select
                      id="client_id"
                      value={data.client_id}
                      onChange={handleClientChange}
                      className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-stone-900 focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
                    >
                      <option value="">Select a client...</option>
                      {clients.map((client) => (
                        <option key={client.id} value={client.id}>
                          {client.name}
                          {client.has_unbilled_entries
                            ? " (has unbilled entries)"
                            : ""}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <Label
                        htmlFor="period_start"
                        className="block text-sm font-medium text-stone-600 mb-1.5"
                      >
                        From
                      </Label>
                      <input
                        type="date"
                        id="period_start"
                        value={data.period_start}
                        onChange={handleDateChange("period_start")}
                        className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-stone-900 focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
                      />
                    </div>
                    <div>
                      <Label
                        htmlFor="period_end"
                        className="block text-sm font-medium text-stone-600 mb-1.5"
                      >
                        To
                      </Label>
                      <input
                        type="date"
                        id="period_end"
                        value={data.period_end}
                        onChange={handleDateChange("period_end")}
                        className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-stone-900 focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500"
                      />
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
                      onChange={handleDateChange("issue_date")}
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
                      onChange={handleDateChange("due_date")}
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
                  type="submit"
                  disabled={isSubmitting || !data.client_id || !hasLineItems}
                  className="flex-1 py-2.5 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSubmitting ? "Creating..." : "Create Draft"}
                </Button>
              </div>
            </div>

            {/* Right: Preview */}
            <div className="col-span-2">
              <InvoicePreview
                lineItems={lineItems}
                totalHours={preview?.total_hours || 0}
                totalAmount={preview?.total_amount || 0}
                currency={
                  selectedClient?.currency || preview?.currency || "EUR"
                }
              />
            </div>
          </div>
        </form>
      </div>
    </>
  );
}
