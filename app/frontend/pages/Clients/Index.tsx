import { Head, usePage, router } from "@inertiajs/react";
import { useEffect } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Toaster } from "@/components/ui/sonner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

interface Client {
  id: number;
  name: string;
  email: string | null;
  currency: string | null;
  hourly_rate: number | null;
  unbilled_hours: number;
  unbilled_amount: number;
  projects_count: number;
}

interface PageProps {
  clients: Client[];
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

function getInitials(name: string): string {
  return name
    .split(" ")
    .map((word) => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

function formatCurrency(amount: number, currency: string | null): string {
  const symbols: Record<string, string> = {
    EUR: "\u20AC",
    USD: "$",
    GBP: "\u00A3",
    CZK: "K\u010D",
  };
  const symbol = currency ? symbols[currency] || currency : "";
  return `${symbol}${amount.toLocaleString()}`;
}

function formatRate(rate: number | null, currency: string | null): string {
  if (!rate) return "-";
  const symbols: Record<string, string> = {
    EUR: "\u20AC",
    USD: "$",
    GBP: "\u00A3",
    CZK: "K\u010D",
  };
  const symbol = currency ? symbols[currency] || currency : "";
  return `${symbol}${rate}/hr`;
}

export default function ClientsIndex() {
  const { clients, flash } = usePage<PageProps>().props;

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleRowClick = (clientId: number) => {
    router.visit(`/clients/${clientId}`);
  };

  return (
    <>
      <Head title="Clients" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-stone-900">Clients</h1>
            <p className="text-stone-500 mt-1">Manage your client relationships</p>
          </div>
          <Button
            onClick={() => router.visit("/clients/new")}
            className="flex items-center gap-2 px-4 py-2 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4" />
            </svg>
            Add Client
          </Button>
        </div>

        <div className="bg-white rounded-xl border border-stone-200">
          <Table>
            <TableHeader>
              <TableRow className="text-left text-sm text-stone-500 border-b border-stone-200">
                <TableHead className="px-6 py-4 font-medium">Client</TableHead>
                <TableHead className="px-6 py-4 font-medium">Currency</TableHead>
                <TableHead className="px-6 py-4 font-medium text-right">Rate</TableHead>
                <TableHead className="px-6 py-4 font-medium text-right">Unbilled</TableHead>
                <TableHead className="px-6 py-4 font-medium text-right">Projects</TableHead>
                <TableHead className="px-6 py-4"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {clients.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="px-6 py-8 text-center text-stone-500">
                    No clients yet. Add your first client to get started.
                  </TableCell>
                </TableRow>
              ) : (
                clients.map((client) => (
                  <TableRow
                    key={client.id}
                    className="border-b border-stone-100 cursor-pointer hover:bg-stone-50 transition-colors"
                    onClick={() => handleRowClick(client.id)}
                  >
                    <TableCell className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-stone-100 rounded-lg flex items-center justify-center text-stone-600 font-semibold">
                          {getInitials(client.name)}
                        </div>
                        <div>
                          <div className="font-medium text-stone-900">{client.name}</div>
                          {client.email && (
                            <div className="text-sm text-stone-500">{client.email}</div>
                          )}
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="px-6 py-4 text-stone-600">
                      {client.currency || "-"}
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right tabular-nums text-stone-900">
                      {formatRate(client.hourly_rate, client.currency)}
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right">
                      {client.unbilled_hours > 0 ? (
                        <>
                          <span className="tabular-nums font-medium text-amber-600">
                            {client.unbilled_hours}h
                          </span>
                          <span className="text-stone-400 ml-1">
                            {" \u00B7 "}
                            {formatCurrency(client.unbilled_amount, client.currency)}
                          </span>
                        </>
                      ) : (
                        <span className="text-stone-400">-</span>
                      )}
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right text-stone-600">
                      {client.projects_count}
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right">
                      <button className="p-2 text-stone-400 hover:text-stone-600 hover:bg-stone-100 rounded-lg transition-colors">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7" />
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
