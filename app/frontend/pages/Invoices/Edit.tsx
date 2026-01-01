import { Head, usePage, router, useForm } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Toaster } from "@/components/ui/sonner";
import LineItemEditor from "./components/LineItemEditor";
import LineItemDisplay from "./components/LineItemDisplay";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

interface LineItem {
  id: number;
  line_type: "time_aggregate" | "fixed";
  description: string;
  quantity: number | null;
  unit_price: number | null;
  amount: number;
  vat_rate: number;
  vat_amount?: number;
  position: number;
  work_entry_ids: number[];
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
  subtotal: number;
  total_vat: number;
  grand_total: number;
  vat_totals_by_rate: Record<string, number>;
  currency: string;
  notes: string | null;
  client_id: number;
  client_name: string;
  client_default_vat_rate: number | null;
}

interface PageProps {
  invoice: Invoice;
  line_items: LineItem[];
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

function formatHours(hours: number): string {
  const numHours = Number(hours) || 0;
  return numHours % 1 === 0 ? numHours.toString() : numHours.toFixed(1);
}

export default function EditInvoice() {
  const { invoice, line_items, flash } = usePage<PageProps>().props;
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [editingLineItemId, setEditingLineItemId] = useState<number | null>(
    null
  );
  const [lineItemToRemove, setLineItemToRemove] = useState<number | null>(null);
  const [isAddingLineItem, setIsAddingLineItem] = useState(false);

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

  const handleEditLineItem = (id: number) => {
    setEditingLineItemId(id);
  };

  const handleSaveLineItem = (
    id: number,
    itemData: { description: string; amount: number; vat_rate: number }
  ) => {
    router.patch(
      `/invoices/${invoice.id}/line_items/${id}`,
      { line_item: itemData },
      {
        preserveScroll: true,
        onSuccess: () => {
          setEditingLineItemId(null);
          toast.success("Line item updated");
        },
        onError: () => {
          toast.error("Failed to update line item");
        },
      }
    );
  };

  const handleRemoveLineItem = (id: number) => {
    setLineItemToRemove(id);
  };

  const confirmRemoveLineItem = () => {
    if (lineItemToRemove === null) return;

    router.delete(`/invoices/${invoice.id}/line_items/${lineItemToRemove}`, {
      preserveScroll: true,
      onSuccess: () => {
        setLineItemToRemove(null);
        toast.success("Line item removed");
      },
      onError: () => {
        toast.error("Failed to remove line item");
      },
    });
  };

  const handleMoveLineItem = (id: number, direction: "up" | "down") => {
    router.patch(
      `/invoices/${invoice.id}/line_items/${id}/reorder`,
      { direction },
      {
        preserveScroll: true,
        onError: () => {
          toast.error("Failed to reorder line item");
        },
      }
    );
  };

  const handleAddLineItem = () => {
    setIsAddingLineItem(true);
  };

  const handleSaveNewLineItem = (itemData: {
    description: string;
    amount: number;
    vat_rate: number;
  }) => {
    router.post(
      `/invoices/${invoice.id}/line_items`,
      { line_item: { ...itemData, line_type: "fixed" } },
      {
        preserveScroll: true,
        onSuccess: () => {
          setIsAddingLineItem(false);
          toast.success("Line item added");
        },
        onError: () => {
          toast.error("Failed to add line item");
        },
      }
    );
  };

  // Calculate totals from line items
  const calculatedTotalHours = line_items
    .filter((item) => item.line_type === "time_aggregate")
    .reduce((sum, item) => sum + (item.quantity || 0), 0);

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

            {/* Right: Line Items */}
            <div className="col-span-2">
              <div className="bg-white rounded-xl border border-stone-200 p-6">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="font-semibold text-stone-900">
                    Invoice Line Items
                  </h3>
                  <div className="text-sm text-stone-500">
                    {calculatedTotalHours > 0 && (
                      <>
                        {formatHours(calculatedTotalHours)} hours{" "}
                        {"\u00B7"}{" "}
                      </>
                    )}
                    {formatCurrency(invoice.grand_total, invoice.currency)}
                  </div>
                </div>

                {/* Line Items */}
                <div className="border border-stone-200 rounded-lg overflow-hidden">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="text-left text-stone-500 bg-stone-50 border-b border-stone-200">
                        <th className="px-4 py-3 font-medium">Description</th>
                        <th className="px-4 py-3 font-medium text-right w-16">
                          Hours
                        </th>
                        <th className="px-4 py-3 font-medium text-right w-24">
                          Rate
                        </th>
                        <th className="px-4 py-3 font-medium text-right w-16">
                          VAT
                        </th>
                        <th className="px-4 py-3 font-medium text-right w-28">
                          Amount
                        </th>
                        <th className="px-4 py-3 font-medium w-36"></th>
                      </tr>
                    </thead>
                    <tbody>
                      {line_items.map((item, index) => {
                        const isEditing = editingLineItemId === item.id;
                        const isFirst = index === 0;
                        const isLast = index === line_items.length - 1;

                        if (isEditing) {
                          return (
                            <tr key={item.id}>
                              <td colSpan={6} className="py-2">
                                <LineItemEditor
                                  lineItem={item}
                                  currency={invoice.currency}
                                  defaultVatRate={
                                    invoice.client_default_vat_rate
                                  }
                                  onSave={(itemData) =>
                                    handleSaveLineItem(item.id, itemData)
                                  }
                                  onCancel={() => setEditingLineItemId(null)}
                                />
                              </td>
                            </tr>
                          );
                        }

                        return (
                          <LineItemDisplay
                            key={item.id}
                            lineItem={item}
                            currency={invoice.currency}
                            isDraft={true}
                            isFirst={isFirst}
                            isLast={isLast}
                            onEdit={handleEditLineItem}
                            onRemove={handleRemoveLineItem}
                            onMoveUp={(id) => handleMoveLineItem(id, "up")}
                            onMoveDown={(id) => handleMoveLineItem(id, "down")}
                          />
                        );
                      })}
                    </tbody>
                  </table>
                </div>

                {/* Add Line Item Form */}
                {isAddingLineItem && (
                  <div className="mt-4">
                    <LineItemEditor
                      lineItem={{
                        line_type: "fixed",
                        description: "",
                        quantity: null,
                        unit_price: null,
                        amount: 0,
                        vat_rate: invoice.client_default_vat_rate || 0,
                        position: line_items.length,
                      }}
                      currency={invoice.currency}
                      defaultVatRate={invoice.client_default_vat_rate}
                      onSave={handleSaveNewLineItem}
                      onCancel={() => setIsAddingLineItem(false)}
                    />
                  </div>
                )}

                {/* Add Line Item Button */}
                {!isAddingLineItem && (
                  <div className="mt-4">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={handleAddLineItem}
                      className="flex items-center gap-2 text-sm"
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
                          d="M12 4v16m8-8H4"
                        />
                      </svg>
                      Add Line Item
                    </Button>
                  </div>
                )}

                {/* Totals */}
                <div className="mt-6 pt-6 border-t border-stone-200">
                  <div className="flex justify-end">
                    <dl className="w-64 space-y-2 text-sm">
                      <div className="flex justify-between">
                        <dt className="text-stone-500">
                          Subtotal
                          {calculatedTotalHours > 0 &&
                            ` (${formatHours(calculatedTotalHours)} hrs)`}
                        </dt>
                        <dd className="tabular-nums text-stone-900">
                          {formatCurrency(invoice.subtotal, invoice.currency)}
                        </dd>
                      </div>
                      {/* VAT breakdown by rate */}
                      {Object.entries(invoice.vat_totals_by_rate || {})
                        .filter(
                          ([rate, amount]) => parseFloat(rate) > 0 || amount > 0
                        )
                        .sort(([a], [b]) => parseFloat(b) - parseFloat(a))
                        .map(([rate, amount]) => (
                          <div key={rate} className="flex justify-between">
                            <dt className="text-stone-500">
                              VAT {parseFloat(rate)}%
                            </dt>
                            <dd className="tabular-nums text-stone-900">
                              {formatCurrency(amount, invoice.currency)}
                            </dd>
                          </div>
                        ))}
                      {/* Show 0% VAT line only if all items are 0% */}
                      {Object.keys(invoice.vat_totals_by_rate || {}).length ===
                        0 ||
                      (Object.keys(invoice.vat_totals_by_rate || {}).length ===
                        1 &&
                        Object.keys(invoice.vat_totals_by_rate)[0] === "0") ? (
                        <div className="flex justify-between">
                          <dt className="text-stone-500">VAT (0%)</dt>
                          <dd className="tabular-nums text-stone-900">
                            {formatCurrency(0, invoice.currency)}
                          </dd>
                        </div>
                      ) : null}
                      <div className="flex justify-between pt-2 border-t border-stone-200">
                        <dt className="font-semibold text-stone-900">Total</dt>
                        <dd className="tabular-nums font-semibold text-stone-900">
                          {formatCurrency(
                            invoice.grand_total,
                            invoice.currency
                          )}
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

      {/* Remove Line Item Confirmation Dialog */}
      <AlertDialog
        open={lineItemToRemove !== null}
        onOpenChange={() => setLineItemToRemove(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remove Line Item?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove the line item from the invoice. Associated work
              entries will be unlinked and become unbilled again.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setLineItemToRemove(null)}>
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmRemoveLineItem}
              className="bg-red-600 hover:bg-red-700"
            >
              Remove
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
