import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Toaster } from "@/components/ui/sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import LineItemEditor from "./components/LineItemEditor";
import LineItemDisplay from "./components/LineItemDisplay";

interface LineItem {
  id: number;
  line_type: "time_aggregate" | "fixed";
  description: string;
  quantity: number | null;
  unit_price: number | null;
  amount: number;
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
  currency: string;
  notes: string | null;
  client_id: number;
  client_name: string;
  client_address: string | null;
  client_email: string | null;
  client_vat_id: string | null;
}

interface Settings {
  company_name: string | null;
  address: string | null;
  email: string | null;
  phone: string | null;
  vat_id: string | null;
  company_registration: string | null;
  bank_name: string | null;
  bank_account: string | null;
  bank_swift: string | null;
  logo_url: string | null;
}

interface PageProps {
  invoice: Invoice;
  line_items: LineItem[];
  settings: Settings;
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
    year: "numeric",
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

function formatHours(hours: number): string {
  const numHours = Number(hours) || 0;
  return numHours % 1 === 0 ? numHours.toString() : numHours.toFixed(1);
}

function StatusBadge({ status }: { status: "draft" | "final" }) {
  if (status === "draft") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
        Draft
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
      Final
    </span>
  );
}

export default function InvoiceShow() {
  const { invoice, line_items, settings, flash } = usePage<PageProps>().props;
  const [isFinalizing, setIsFinalizing] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [editingLineItemId, setEditingLineItemId] = useState<number | null>(null);
  const [lineItemToRemove, setLineItemToRemove] = useState<number | null>(null);
  const [isAddingLineItem, setIsAddingLineItem] = useState(false);

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleFinalize = () => {
    setIsFinalizing(true);
    router.post(
      `/invoices/${invoice.id}/finalize`,
      {},
      {
        onFinish: () => setIsFinalizing(false),
      }
    );
  };

  const handleDelete = () => {
    setIsDeleting(true);
    router.delete(`/invoices/${invoice.id}`, {
      onFinish: () => setIsDeleting(false),
    });
  };

  const handleEditLineItem = (id: number) => {
    setEditingLineItemId(id);
  };

  const handleSaveLineItem = (id: number, data: { description: string; amount: number }) => {
    router.patch(
      `/invoices/${invoice.id}/line_items/${id}`,
      { line_item: data },
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

  const handleSaveNewLineItem = (data: { description: string; amount: number }) => {
    router.post(
      `/invoices/${invoice.id}/line_items`,
      { line_item: { ...data, line_type: "fixed" } },
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

  const isDraft = invoice.status === "draft";

  // Calculate totals from line items
  const calculatedTotalHours = line_items
    .filter((item) => item.line_type === "time_aggregate")
    .reduce((sum, item) => sum + (item.quantity || 0), 0);
  const calculatedTotalAmount = line_items.reduce((sum, item) => sum + item.amount, 0);

  return (
    <>
      <Head title={`Invoice ${invoice.number}`} />
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
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-3">
                <h1 className="text-2xl font-semibold text-stone-900 font-mono">
                  {invoice.number}
                </h1>
                <StatusBadge status={invoice.status} />
              </div>
              <p className="text-stone-500 mt-1">
                {invoice.client_name} {"\u00B7"}{" "}
                {formatPeriod(invoice.period_start, invoice.period_end)}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                asChild
                className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors flex items-center gap-2"
              >
                <a href={`/invoices/${invoice.id}/pdf`} download>
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
                      d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                    />
                  </svg>
                  Download PDF
                </a>
              </Button>
              {isDraft && (
                <>
                  <Button
                    variant="outline"
                    onClick={() => router.visit(`/invoices/${invoice.id}/edit`)}
                    className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
                  >
                    Edit
                  </Button>

                  {/* Finalize Dialog */}
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button className="px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                        Mark as Final
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>Finalize Invoice?</AlertDialogTitle>
                        <AlertDialogDescription>
                          This will mark the invoice as final and lock all
                          associated work entries as invoiced. This action cannot
                          be undone.
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction
                          onClick={handleFinalize}
                          disabled={isFinalizing}
                          className="bg-emerald-600 hover:bg-emerald-700"
                        >
                          {isFinalizing ? "Finalizing..." : "Finalize"}
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>

                  {/* Delete Dialog */}
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button
                        variant="outline"
                        className="px-4 py-2 border border-red-200 text-red-600 font-medium rounded-lg hover:bg-red-50 transition-colors"
                      >
                        Delete
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>
                          Delete Invoice {invoice.number}?
                        </AlertDialogTitle>
                        <AlertDialogDescription>
                          This will permanently delete the invoice and unassociate
                          all work entries. The work entries will become unbilled
                          again.
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction
                          onClick={handleDelete}
                          disabled={isDeleting}
                          className="bg-red-600 hover:bg-red-700"
                        >
                          {isDeleting ? "Deleting..." : "Delete"}
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Invoice Preview */}
        <div className="bg-white rounded-xl border border-stone-200 p-8 max-w-4xl">
          {/* Header */}
          <div className="flex justify-between mb-8 pb-8 border-b border-stone-200">
            <div>
              <div className="w-12 h-12 bg-stone-900 rounded-lg flex items-center justify-center mb-4 overflow-hidden">
                {settings.logo_url ? (
                  <img
                    src={settings.logo_url}
                    alt="Company Logo"
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <svg
                    className="w-6 h-6 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                )}
              </div>
              <p className="font-semibold text-stone-900">
                {settings.company_name || "Your Company"}
              </p>
              {settings.address && (
                <p className="text-sm text-stone-500 whitespace-pre-line">
                  {settings.address}
                </p>
              )}
              {(settings.email || settings.phone) && (
                <p className="text-sm text-stone-500">
                  {[settings.email, settings.phone].filter(Boolean).join(" | ")}
                </p>
              )}
              {settings.vat_id && (
                <p className="text-sm text-stone-500">VAT: {settings.vat_id}</p>
              )}
            </div>
            <div className="text-right">
              <p className="text-3xl font-semibold text-stone-900 font-mono">
                INVOICE
              </p>
              <p className="text-lg font-mono text-stone-500 mt-1">
                #{invoice.number}
              </p>
              <dl className="mt-4 text-sm space-y-1">
                <div className="flex justify-end gap-4">
                  <dt className="text-stone-500">Issue Date:</dt>
                  <dd className="text-stone-900">
                    {formatDate(invoice.issue_date)}
                  </dd>
                </div>
                <div className="flex justify-end gap-4">
                  <dt className="text-stone-500">Due Date:</dt>
                  <dd className="text-stone-900">
                    {formatDate(invoice.due_date)}
                  </dd>
                </div>
                <div className="flex justify-end gap-4">
                  <dt className="text-stone-500">Period:</dt>
                  <dd className="text-stone-900">
                    {formatPeriod(invoice.period_start, invoice.period_end)}
                  </dd>
                </div>
              </dl>
            </div>
          </div>

          {/* Bill To */}
          <div className="mb-8">
            <p className="text-sm text-stone-500 mb-2">Bill To:</p>
            <p className="font-semibold text-stone-900">{invoice.client_name}</p>
            {invoice.client_address && (
              <p className="text-sm text-stone-500 whitespace-pre-line">
                {invoice.client_address}
              </p>
            )}
            {invoice.client_vat_id && (
              <p className="text-sm text-stone-500 mt-1">
                VAT: {invoice.client_vat_id}
              </p>
            )}
          </div>

          {/* Line Items */}
          <div className="mb-8">
            <table className="w-full">
              <thead>
                <tr className="text-left text-sm text-stone-500 border-b border-stone-200">
                  <th className="pb-3 font-medium">Description</th>
                  <th className="pb-3 font-medium text-right w-16">Hours</th>
                  <th className="pb-3 font-medium text-right w-24">Rate</th>
                  <th className="pb-3 font-medium text-right w-28">Amount</th>
                  {isDraft && <th className="pb-3 font-medium w-36"></th>}
                </tr>
              </thead>
              <tbody className="text-sm">
                {line_items.map((item, index) => {
                  const isEditing = editingLineItemId === item.id;
                  const isFirst = index === 0;
                  const isLast = index === line_items.length - 1;

                  if (isEditing) {
                    return (
                      <tr key={item.id}>
                        <td colSpan={isDraft ? 5 : 4} className="py-2">
                          <LineItemEditor
                            lineItem={item}
                            currency={invoice.currency}
                            onSave={(data) => handleSaveLineItem(item.id, data)}
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
                      isDraft={isDraft}
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
                    position: line_items.length,
                  }}
                  currency={invoice.currency}
                  onSave={handleSaveNewLineItem}
                  onCancel={() => setIsAddingLineItem(false)}
                />
              </div>
            )}

            {/* Add Line Item Button */}
            {isDraft && !isAddingLineItem && (
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
          </div>

          {/* Totals */}
          <div className="flex justify-end">
            <dl className="w-64 space-y-2 text-sm">
              <div className="flex justify-between">
                <dt className="text-stone-500">
                  Subtotal
                  {calculatedTotalHours > 0 && ` (${formatHours(calculatedTotalHours)} hrs)`}
                </dt>
                <dd className="tabular-nums text-stone-900">
                  {formatCurrency(calculatedTotalAmount, invoice.currency)}
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-stone-500">VAT (0%)</dt>
                <dd className="tabular-nums text-stone-900">
                  {formatCurrency(0, invoice.currency)}
                </dd>
              </div>
              <div className="flex justify-between pt-3 border-t border-stone-200 text-lg">
                <dt className="font-semibold text-stone-900">Total Due</dt>
                <dd className="tabular-nums font-semibold text-stone-900">
                  {formatCurrency(calculatedTotalAmount, invoice.currency)}
                </dd>
              </div>
            </dl>
          </div>

          {/* Notes */}
          {invoice.notes && (
            <div className="mt-8 pt-8 border-t border-stone-200">
              <p className="text-sm font-medium text-stone-700 mb-2">Notes</p>
              <p className="text-sm text-stone-500 whitespace-pre-line">
                {invoice.notes}
              </p>
            </div>
          )}

          {/* Footer */}
          <div className="mt-8 pt-8 border-t border-stone-200 text-sm text-stone-500">
            <p className="font-medium text-stone-700 mb-2">Payment Details</p>
            {(settings.bank_name || settings.bank_account || settings.bank_swift) && (
              <div className="grid grid-cols-3 gap-4 mb-4">
                {settings.bank_name && (
                  <div>
                    <p className="text-stone-500">Bank</p>
                    <p className="text-stone-900 font-medium">{settings.bank_name}</p>
                  </div>
                )}
                {settings.bank_account && (
                  <div>
                    <p className="text-stone-500">Account / IBAN</p>
                    <p className="text-stone-900 font-medium">{settings.bank_account}</p>
                  </div>
                )}
                {settings.bank_swift && (
                  <div>
                    <p className="text-stone-500">SWIFT / BIC</p>
                    <p className="text-stone-900 font-medium">{settings.bank_swift}</p>
                  </div>
                )}
              </div>
            )}
            <p>
              Please include invoice number{" "}
              <strong>#{invoice.number}</strong> in payment reference.
            </p>
          </div>
        </div>
      </div>

      {/* Remove Line Item Confirmation Dialog */}
      <AlertDialog open={lineItemToRemove !== null} onOpenChange={() => setLineItemToRemove(null)}>
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
