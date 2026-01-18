import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import i18n from "@/lib/i18n";
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
import { formatCurrency } from "@/components/CurrencyDisplay";
import LineItemEditor from "./components/LineItemEditor";
import LineItemDisplay from "./components/LineItemDisplay";

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
  status: "draft" | "final" | "paid";
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
  client_address: string | null;
  client_email: string | null;
  client_vat_id: string | null;
  client_company_registration: string | null;
  client_default_vat_rate: number | null;
  client_locale: string;
  paid_at: string | null;
  main_currency_amount: number | null;
  main_currency: string | null;
}

interface Settings {
  company_name: string | null;
  address: string | null;
  email: string | null;
  phone: string | null;
  vat_id: string | null;
  company_registration: string | null;
  invoice_message: string | null;
  logo_url: string | null;
}

interface BankAccount {
  id: number;
  name: string;
  bank_name: string | null;
  bank_account: string | null;
  bank_swift: string | null;
  iban: string;
  is_default: boolean;
}

interface QrCode {
  data_url: string;
  format: "epc" | "spayd";
}

interface PageProps {
  invoice: Invoice;
  line_items: LineItem[];
  settings: Settings;
  bank_account: BankAccount | null;
  qr_code: QrCode | null;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

function formatDate(dateString: string, locale: string = "en"): string {
  const date = new Date(dateString);
  const localeMap: Record<string, string> = { en: "en-US", cs: "cs-CZ" };
  const dateLocale = localeMap[locale] || "en-US";

  if (locale === "cs") {
    return date.toLocaleDateString(dateLocale, {
      day: "numeric",
      month: "numeric",
      year: "numeric",
    });
  }

  return date.toLocaleDateString(dateLocale, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function formatPeriod(
  start: string,
  end: string,
  locale: string = "en"
): string {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const localeMap: Record<string, string> = { en: "en-US", cs: "cs-CZ" };
  const dateLocale = localeMap[locale] || "en-US";

  if (locale === "cs") {
    // Czech format: "31. 12. – 30. 1. 2026"
    const startFormatted = startDate.toLocaleDateString(dateLocale, {
      day: "numeric",
      month: "numeric",
    });
    const endFormatted = endDate.toLocaleDateString(dateLocale, {
      day: "numeric",
      month: "numeric",
      year: "numeric",
    });
    return `${startFormatted} – ${endFormatted}`;
  }

  // English format: "Dec 31–Jan 30, 2026"
  const startMonth = startDate.toLocaleDateString(dateLocale, {
    month: "short",
  });
  const endMonth = endDate.toLocaleDateString(dateLocale, { month: "short" });
  const startDay = startDate.getDate();
  const endDay = endDate.getDate();
  const year = endDate.getFullYear();

  if (startMonth === endMonth) {
    return `${startMonth} ${startDay}\u2013${endDay}, ${year}`;
  }
  return `${startMonth} ${startDay}\u2013${endMonth} ${endDay}, ${year}`;
}

function StatusBadge({
  status,
  label,
}: {
  status: "draft" | "final" | "paid";
  label: string;
}) {
  if (status === "draft") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
        {label}
      </span>
    );
  }
  if (status === "paid") {
    return (
      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700">
        {label}
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">
      {label}
    </span>
  );
}

export default function InvoiceShow() {
  const { invoice, line_items, settings, bank_account, qr_code, flash } =
    usePage<PageProps>().props;
  const { t } = useTranslation();
  // Get translation function for client's locale (for invoice preview)
  const clientLocale = invoice.client_locale || "en";
  const tp = i18n.getFixedT(
    clientLocale,
    "translation",
    "pages.invoices.preview"
  );
  const [isFinalizing, setIsFinalizing] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isMarkingPaid, setIsMarkingPaid] = useState(false);
  const [paidDate, setPaidDate] = useState(
    new Date().toISOString().split("T")[0]
  );
  const [editingLineItemId, setEditingLineItemId] = useState<number | null>(
    null
  );
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

  const handleMarkAsPaid = () => {
    setIsMarkingPaid(true);
    router.post(
      `/invoices/${invoice.id}/mark_as_paid`,
      { paid_at: paidDate },
      {
        onFinish: () => setIsMarkingPaid(false),
      }
    );
  };

  const handleEditLineItem = (id: number) => {
    setEditingLineItemId(id);
  };

  const handleSaveLineItem = (
    id: number,
    data: { description: string; amount: number; vat_rate: number }
  ) => {
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

  const handleSaveNewLineItem = (data: {
    description: string;
    amount: number;
    vat_rate: number;
  }) => {
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
  const isFinal = invoice.status === "final";
  const isPaid = invoice.status === "paid";

  return (
    <>
      <Head title={`Invoice ${invoice.number}`} />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
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
            {t("common.backTo", { name: t("pages.invoices.title") })}
          </button>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <div className="flex items-center gap-3">
                <h1 className="text-2xl font-semibold text-stone-900 font-mono">
                  {invoice.number}
                </h1>
                <StatusBadge
                  status={invoice.status}
                  label={t(`pages.invoices.status.${invoice.status}`)}
                />
              </div>
              <p className="text-stone-500 mt-1">
                {invoice.client_name} {"\u00B7"}{" "}
                {formatPeriod(
                  invoice.period_start,
                  invoice.period_end,
                  i18n.language
                )}
                {isPaid && invoice.paid_at && (
                  <>
                    {" "}
                    {"\u00B7"}{" "}
                    {t("pages.invoices.paidOn", {
                      date: formatDate(invoice.paid_at, i18n.language),
                    })}
                  </>
                )}
              </p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
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
                  {t("pages.invoices.actions.downloadPdf")}
                </a>
              </Button>
              {isFinal && (
                <>
                  {/* Mark as Paid Dialog */}
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button className="px-4 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors">
                        {t("pages.invoices.actions.markAsPaid")}
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>
                          {t("pages.invoices.markAsPaid.title")}
                        </AlertDialogTitle>
                        <AlertDialogDescription>
                          {t("pages.invoices.markAsPaid.description")}
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <div className="py-4">
                        <label className="block text-sm font-medium text-stone-700 mb-1">
                          {t("pages.invoices.markAsPaid.dateLabel")}
                        </label>
                        <input
                          type="date"
                          value={paidDate}
                          onChange={(e) => setPaidDate(e.target.value)}
                          className="w-full px-3 py-2 border border-stone-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                      <AlertDialogFooter>
                        <AlertDialogCancel>
                          {t("common.cancel")}
                        </AlertDialogCancel>
                        <AlertDialogAction
                          onClick={handleMarkAsPaid}
                          disabled={isMarkingPaid}
                          className="bg-blue-600 hover:bg-blue-700"
                        >
                          {isMarkingPaid
                            ? t("pages.invoices.markAsPaid.marking")
                            : t("pages.invoices.markAsPaid.confirm")}
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </>
              )}
              {isDraft && (
                <>
                  <Button
                    variant="outline"
                    onClick={() => router.visit(`/invoices/${invoice.id}/edit`)}
                    className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
                  >
                    {t("common.edit")}
                  </Button>

                  {/* Finalize Dialog */}
                  <AlertDialog>
                    <AlertDialogTrigger asChild>
                      <Button className="px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors">
                        {t("pages.invoices.actions.markAsFinal")}
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>
                          {t("pages.invoices.finalize.title")}
                        </AlertDialogTitle>
                        <AlertDialogDescription>
                          {t("pages.invoices.finalize.description")}
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>
                          {t("common.cancel")}
                        </AlertDialogCancel>
                        <AlertDialogAction
                          onClick={handleFinalize}
                          disabled={isFinalizing}
                          className="bg-emerald-600 hover:bg-emerald-700"
                        >
                          {isFinalizing
                            ? t("common.finalizing")
                            : t("common.finalize")}
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
                        {t("common.delete")}
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent>
                      <AlertDialogHeader>
                        <AlertDialogTitle>
                          {t("pages.invoices.delete.title", {
                            number: invoice.number,
                          })}
                        </AlertDialogTitle>
                        <AlertDialogDescription>
                          {t("pages.invoices.delete.description")}
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel>
                          {t("common.cancel")}
                        </AlertDialogCancel>
                        <AlertDialogAction
                          onClick={handleDelete}
                          disabled={isDeleting}
                          className="bg-red-600 hover:bg-red-700"
                        >
                          {isDeleting
                            ? t("common.deleting")
                            : t("common.delete")}
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
        <div className="bg-white rounded-xl border border-stone-200 p-4 sm:p-6 lg:p-8 max-w-4xl">
          {/* Invoice Header */}
          <div className="text-right mb-8">
            <div className="w-48 h-0.5 bg-stone-900 ml-auto mb-3"></div>
            <p className="text-2xl font-semibold">
              <span className="text-stone-900">{tp("invoice")} </span>
              <span className="text-stone-500">{invoice.number}</span>
            </p>
            <p className="text-xs text-stone-500 uppercase tracking-wider mt-1">
              {tp("taxDocument")}
            </p>
          </div>

          {/* Supplier and Customer Section */}
          <div className="flex flex-col sm:flex-row gap-6 sm:gap-10 mb-10">
            {/* Supplier Column */}
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-5 h-0.5 bg-stone-900"></div>
                <span className="text-xs text-stone-500 uppercase tracking-wide">
                  {tp("supplier")}
                </span>
              </div>
              <p className="font-semibold text-stone-900 mb-1">
                {settings.company_name || tp("yourCompany")}
              </p>
              {settings.address && (
                <p className="text-sm text-stone-600 whitespace-pre-line mb-4">
                  {settings.address}
                </p>
              )}
              <table className="w-full text-sm">
                <tbody>
                  {settings.company_registration && (
                    <tr className="h-6">
                      <td className="text-stone-500">{tp("regNo")}</td>
                      <td className="text-right text-stone-900 font-medium">
                        {settings.company_registration}
                      </td>
                    </tr>
                  )}
                  {settings.vat_id && (
                    <tr className="h-6">
                      <td className="text-stone-500">{tp("vatId")}</td>
                      <td className="text-right text-stone-900 font-medium">
                        {settings.vat_id}
                      </td>
                    </tr>
                  )}
                  {bank_account?.bank_account && (
                    <tr className="h-6">
                      <td className="text-stone-500">{tp("bankAccount")}</td>
                      <td className="text-right text-stone-900 font-medium">
                        {bank_account.bank_account}
                      </td>
                    </tr>
                  )}
                  {bank_account?.iban && (
                    <tr className="h-6">
                      <td className="text-stone-500">{tp("iban")}</td>
                      <td className="text-right text-stone-900 font-medium">
                        {bank_account.iban}
                      </td>
                    </tr>
                  )}
                  {bank_account?.bank_swift && (
                    <tr className="h-6">
                      <td className="text-stone-500">{tp("swift")}</td>
                      <td className="text-right text-stone-900 font-medium">
                        {bank_account.bank_swift}
                      </td>
                    </tr>
                  )}
                  <tr className="h-6">
                    <td className="text-stone-500">{tp("reference")}</td>
                    <td className="text-right text-stone-900 font-medium">
                      {invoice.number}
                    </td>
                  </tr>
                  <tr className="h-6">
                    <td className="text-stone-500">{tp("paymentMethod")}</td>
                    <td className="text-right text-stone-900 font-medium">
                      {tp("bankTransfer")}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            {/* Customer Column */}
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-5 h-0.5 bg-stone-900"></div>
                <span className="text-xs text-stone-500 uppercase tracking-wide">
                  {tp("customer")}
                </span>
              </div>
              <p className="font-semibold text-stone-900 mb-1">
                {invoice.client_name}
              </p>
              {invoice.client_address && (
                <p className="text-sm text-stone-600 whitespace-pre-line mb-4">
                  {invoice.client_address}
                </p>
              )}
              <table className="w-full text-sm">
                <tbody>
                  {invoice.client_company_registration && (
                    <tr className="h-6">
                      <td className="text-stone-500">{tp("regNo")}</td>
                      <td className="text-right text-stone-900 font-medium">
                        {invoice.client_company_registration}
                      </td>
                    </tr>
                  )}
                  {invoice.client_vat_id && (
                    <tr className="h-6">
                      <td className="text-stone-500">{tp("vatId")}</td>
                      <td className="text-right text-stone-900 font-medium">
                        {invoice.client_vat_id}
                      </td>
                    </tr>
                  )}
                  <tr className="h-6">
                    <td className="text-stone-500">{tp("issuedOn")}</td>
                    <td className="text-right text-stone-900 font-medium">
                      {formatDate(invoice.issue_date, clientLocale)}
                    </td>
                  </tr>
                  <tr className="h-6">
                    <td className="text-stone-500">{tp("dueOn")}</td>
                    <td className="text-right text-stone-900 font-medium">
                      {formatDate(invoice.due_date, clientLocale)}
                    </td>
                  </tr>
                  <tr className="h-6">
                    <td className="text-stone-500">
                      {tp("dateOfTaxableSupply")}
                    </td>
                    <td className="text-right text-stone-900 font-medium">
                      {formatDate(invoice.issue_date, clientLocale)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          {/* Line Items */}
          <div className="mb-8 overflow-x-auto">
            <table className="w-full min-w-[500px]">
              <thead>
                <tr className="text-sm text-stone-500 border-b border-stone-200">
                  <th className="pb-3 font-medium text-left w-12"></th>
                  <th className="pb-3 font-medium text-left w-12"></th>
                  <th className="pb-3 font-medium text-left"></th>
                  <th className="pb-3 font-medium text-right w-16">
                    {tp("vat")}
                  </th>
                  <th className="pb-3 font-medium text-right w-24">
                    {tp("unitPrice")}
                  </th>
                  <th className="pb-3 font-medium text-right w-28">
                    {tp("totalWithoutVat")}
                  </th>
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
                        <td colSpan={isDraft ? 6 : 5} className="py-2">
                          <LineItemEditor
                            lineItem={item}
                            currency={invoice.currency}
                            defaultVatRate={invoice.client_default_vat_rate}
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
                      hoursUnit={tp("hoursUnit")}
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
                  {t("pages.invoices.lineItems.addLineItem")}
                </Button>
              </div>
            )}
          </div>

          {/* Totals */}
          <div className="flex justify-end">
            <dl className="w-72 text-sm">
              <div className="flex justify-between py-2 border-b border-stone-200">
                <dt className="text-stone-500">{tp("totalWithoutVat")}</dt>
                <dd className="tabular-nums text-stone-900">
                  {formatCurrency(invoice.subtotal, invoice.currency)}
                </dd>
              </div>
              {/* VAT breakdown by rate */}
              {Object.entries(invoice.vat_totals_by_rate || {})
                .filter(([rate, amount]) => parseFloat(rate) > 0 || amount > 0)
                .sort(([a], [b]) => parseFloat(b) - parseFloat(a))
                .map(([rate, amount]) => (
                  <div key={rate} className="flex justify-between py-2">
                    <dt className="text-stone-500">
                      {tp("vat")} {parseFloat(rate)} %
                    </dt>
                    <dd className="tabular-nums text-stone-900">
                      {formatCurrency(amount, invoice.currency)}
                    </dd>
                  </div>
                ))}
              {/* Show 0% VAT line only if all items are 0% */}
              {Object.keys(invoice.vat_totals_by_rate || {}).length === 0 ||
              (Object.keys(invoice.vat_totals_by_rate || {}).length === 1 &&
                Object.keys(invoice.vat_totals_by_rate)[0] === "0") ? (
                <div className="flex justify-between py-2">
                  <dt className="text-stone-500">{tp("vat")} 0 %</dt>
                  <dd className="tabular-nums text-stone-900">
                    {formatCurrency(0, invoice.currency)}
                  </dd>
                </div>
              ) : null}
              <div className="flex justify-end pt-3 border-t-2 border-stone-900">
                <dd className="tabular-nums font-bold text-lg text-stone-900">
                  {formatCurrency(invoice.grand_total, invoice.currency)}
                </dd>
              </div>
              {invoice.main_currency_amount !== null &&
                invoice.main_currency &&
                invoice.currency !== invoice.main_currency && (
                  <div
                    className="flex justify-end pt-2"
                    data-testid="converted-amount"
                  >
                    <dd className="tabular-nums text-sm text-stone-500">
                      {formatCurrency(
                        invoice.main_currency_amount,
                        invoice.main_currency
                      )}
                    </dd>
                  </div>
                )}
            </dl>
          </div>

          {/* Notes */}
          {invoice.notes && (
            <div className="mt-8 pt-8 border-t border-stone-200">
              <p className="text-sm font-medium text-stone-700 mb-2">
                {tp("notes")}
              </p>
              <p className="text-sm text-stone-500 whitespace-pre-line">
                {invoice.notes}
              </p>
            </div>
          )}

          {/* Footer - QR Code */}
          {qr_code && (
            <div className="mt-8 pt-6 border-t border-stone-200">
              <div>
                <img
                  src={qr_code.data_url}
                  alt={tp("qrAlt")}
                  className="w-[70px] h-[70px]"
                />
                <p className="text-[9px] text-stone-400 mt-1">
                  {tp("scanToPay")}
                </p>
              </div>
            </div>
          )}

          {/* Invoice Message */}
          {settings.invoice_message && (
            <div className="mt-8 pt-5 border-t border-stone-200">
              <p className="text-sm text-stone-500 whitespace-pre-line">
                {settings.invoice_message}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Remove Line Item Confirmation Dialog */}
      <AlertDialog
        open={lineItemToRemove !== null}
        onOpenChange={() => setLineItemToRemove(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {t("pages.invoices.lineItems.removeTitle")}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {t("pages.invoices.lineItems.removeDescription")}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setLineItemToRemove(null)}>
              {t("common.cancel")}
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmRemoveLineItem}
              className="bg-red-600 hover:bg-red-700"
            >
              {t("common.remove")}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
