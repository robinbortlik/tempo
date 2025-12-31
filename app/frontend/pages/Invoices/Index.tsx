import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
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
  client_id: number;
  client_name: string;
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

export default function InvoicesIndex() {
  const { invoices, filters, flash } = usePage<PageProps>().props;
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

  return (
    <>
      <Head title="Invoices" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-stone-900">Invoices</h1>
            <p className="text-stone-500 mt-1">Manage your invoices</p>
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
            New Invoice
          </Button>
        </div>

        {/* Filter Tabs */}
        <Tabs value={activeTab} onValueChange={handleTabChange} className="mb-6">
          <TabsList className="bg-transparent p-0 gap-2">
            <TabsTrigger
              value="all"
              className="px-4 py-2 text-sm font-medium rounded-lg data-[state=active]:bg-stone-900 data-[state=active]:text-white data-[state=inactive]:bg-white data-[state=inactive]:border data-[state=inactive]:border-stone-200 data-[state=inactive]:text-stone-600 data-[state=inactive]:hover:bg-stone-50"
            >
              All
            </TabsTrigger>
            <TabsTrigger
              value="draft"
              className="px-4 py-2 text-sm font-medium rounded-lg data-[state=active]:bg-stone-900 data-[state=active]:text-white data-[state=inactive]:bg-white data-[state=inactive]:border data-[state=inactive]:border-stone-200 data-[state=inactive]:text-stone-600 data-[state=inactive]:hover:bg-stone-50"
            >
              Draft ({draftCount})
            </TabsTrigger>
            <TabsTrigger
              value="final"
              className="px-4 py-2 text-sm font-medium rounded-lg data-[state=active]:bg-stone-900 data-[state=active]:text-white data-[state=inactive]:bg-white data-[state=inactive]:border data-[state=inactive]:border-stone-200 data-[state=inactive]:text-stone-600 data-[state=inactive]:hover:bg-stone-50"
            >
              Final ({finalCount})
            </TabsTrigger>
          </TabsList>
        </Tabs>

        <div className="bg-white rounded-xl border border-stone-200">
          <Table>
            <TableHeader>
              <TableRow className="text-left text-sm text-stone-500 border-b border-stone-200">
                <TableHead className="px-6 py-4 font-medium">Invoice</TableHead>
                <TableHead className="px-6 py-4 font-medium">Client</TableHead>
                <TableHead className="px-6 py-4 font-medium">Period</TableHead>
                <TableHead className="px-6 py-4 font-medium">Status</TableHead>
                <TableHead className="px-6 py-4 font-medium text-right">
                  Amount
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
                    No invoices yet. Create your first invoice to get started.
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
                    <TableCell className="px-6 py-4 text-stone-500">
                      {formatPeriod(invoice.period_start, invoice.period_end)}
                    </TableCell>
                    <TableCell className="px-6 py-4">
                      <StatusBadge status={invoice.status} />
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
