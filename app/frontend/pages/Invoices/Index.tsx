import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Toaster } from "@/components/ui/sonner";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { formatCurrency } from "@/components/CurrencyDisplay";

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
  currency: string;
  client_id: number;
  client_name: string;
  paid_at: string | null;
}

interface Client {
  id: number;
  name: string;
}

interface Filters {
  status: string | null;
  client_id: number | null;
  year: string | null;
}

interface PageProps {
  invoices: Invoice[];
  clients: Client[];
  filters: Filters;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
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

export default function InvoicesIndex() {
  const { invoices, filters, flash } = usePage<PageProps>().props;
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<string>(filters.status || "all");

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleRowClick = (invoiceId: number) => {
    router.visit(`/invoices/${invoiceId}`);
  };

  const handleTabChange = (value: string) => {
    setActiveTab(value);
    const params = new URLSearchParams();
    if (value !== "all") {
      params.set("status", value);
    }
    if (filters.client_id) {
      params.set("client_id", filters.client_id.toString());
    }
    if (filters.year) {
      params.set("year", filters.year);
    }
    const queryString = params.toString();
    router.visit(`/invoices${queryString ? `?${queryString}` : ""}`);
  };

  const draftCount = invoices.filter((inv) => inv.status === "draft").length;
  const finalCount = invoices.filter((inv) => inv.status === "final").length;
  const paidCount = invoices.filter((inv) => inv.status === "paid").length;

  return (
    <>
      <Head title={t("pages.invoices.title")} />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
        <div className="mb-6 sm:mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-stone-900">
              {t("pages.invoices.title")}
            </h1>
            <p className="text-stone-500 mt-1">
              {t("pages.invoices.subtitle")}
            </p>
          </div>
          <Button
            onClick={() => router.visit("/invoices/new")}
            className="flex items-center gap-2 px-4 py-2 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
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
            {t("pages.invoices.newInvoice")}
          </Button>
        </div>

        {/* Filter Tabs */}
        <Tabs
          value={activeTab}
          onValueChange={handleTabChange}
          className="mb-6"
        >
          <TabsList className="bg-transparent p-0 gap-2">
            <TabsTrigger
              value="all"
              className="px-4 py-2 text-sm font-medium rounded-lg data-[state=active]:bg-stone-900 data-[state=active]:text-white data-[state=inactive]:bg-white data-[state=inactive]:border data-[state=inactive]:border-stone-200 data-[state=inactive]:text-stone-600 data-[state=inactive]:hover:bg-stone-50"
            >
              {t("common.all")}
            </TabsTrigger>
            <TabsTrigger
              value="draft"
              className="px-4 py-2 text-sm font-medium rounded-lg data-[state=active]:bg-stone-900 data-[state=active]:text-white data-[state=inactive]:bg-white data-[state=inactive]:border data-[state=inactive]:border-stone-200 data-[state=inactive]:text-stone-600 data-[state=inactive]:hover:bg-stone-50"
            >
              {t("pages.invoices.status.draft")} ({draftCount})
            </TabsTrigger>
            <TabsTrigger
              value="final"
              className="px-4 py-2 text-sm font-medium rounded-lg data-[state=active]:bg-stone-900 data-[state=active]:text-white data-[state=inactive]:bg-white data-[state=inactive]:border data-[state=inactive]:border-stone-200 data-[state=inactive]:text-stone-600 data-[state=inactive]:hover:bg-stone-50"
            >
              {t("pages.invoices.status.final")} ({finalCount})
            </TabsTrigger>
            <TabsTrigger
              value="paid"
              className="px-4 py-2 text-sm font-medium rounded-lg data-[state=active]:bg-stone-900 data-[state=active]:text-white data-[state=inactive]:bg-white data-[state=inactive]:border data-[state=inactive]:border-stone-200 data-[state=inactive]:text-stone-600 data-[state=inactive]:hover:bg-stone-50"
            >
              {t("pages.invoices.status.paid")} ({paidCount})
            </TabsTrigger>
          </TabsList>
        </Tabs>

        <div className="bg-white rounded-xl border border-stone-200 overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow className="text-left text-sm text-stone-500 border-b border-stone-200">
                <TableHead className="px-6 py-4 font-medium">
                  {t("pages.invoices.table.number")}
                </TableHead>
                <TableHead className="px-6 py-4 font-medium">
                  {t("pages.invoices.table.client")}
                </TableHead>
                <TableHead className="hidden sm:table-cell px-6 py-4 font-medium">
                  {t("pages.invoices.form.periodStart")}
                </TableHead>
                <TableHead className="px-6 py-4 font-medium">
                  {t("common.status")}
                </TableHead>
                <TableHead className="px-6 py-4 font-medium text-right">
                  {t("common.amount")}
                </TableHead>
                <TableHead className="px-6 py-4"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {invoices.length === 0 ? (
                <TableRow>
                  <TableCell
                    colSpan={6}
                    className="px-6 py-8 text-center text-stone-500"
                  >
                    {t("pages.invoices.noInvoices")}
                  </TableCell>
                </TableRow>
              ) : (
                invoices.map((invoice) => (
                  <TableRow
                    key={invoice.id}
                    className="border-b border-stone-100 cursor-pointer hover:bg-stone-50 transition-colors"
                    onClick={() => handleRowClick(invoice.id)}
                  >
                    <TableCell className="px-6 py-4">
                      <span className="font-mono font-medium text-stone-900">
                        {invoice.number}
                      </span>
                    </TableCell>
                    <TableCell className="px-6 py-4 text-stone-700">
                      {invoice.client_name}
                    </TableCell>
                    <TableCell className="hidden sm:table-cell px-6 py-4 text-stone-500">
                      {formatPeriod(invoice.period_start, invoice.period_end)}
                    </TableCell>
                    <TableCell className="px-6 py-4">
                      <StatusBadge
                        status={invoice.status}
                        label={t(`pages.invoices.status.${invoice.status}`)}
                      />
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right tabular-nums font-medium text-stone-900">
                      {formatCurrency(invoice.total_amount, invoice.currency)}
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right">
                      <button className="p-2 text-stone-400 hover:text-stone-600 hover:bg-stone-100 rounded-lg transition-colors">
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
                            d="M9 5l7 7-7 7"
                          />
                        </svg>
                      </button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </div>
    </>
  );
}
