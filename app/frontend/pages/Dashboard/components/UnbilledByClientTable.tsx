import { router } from "@inertiajs/react";
import { useTranslation } from "react-i18next";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { formatCurrency } from "@/components/CurrencyDisplay";
import { MobileCard } from "@/components/MobileCard";

interface UnbilledClient {
  id: number;
  name: string;
  currency: string;
  project_count: number;
  total_hours: number;
  total_amount: number;
  project_rates: number[];
}

interface UnbilledByClientTableProps {
  data: UnbilledClient[];
}

function formatRates(rates: number[], currency: string): string {
  if (rates.length === 0) return "—";
  if (rates.length === 1) {
    return `${formatCurrency(rates[0], currency, false)}/hr`;
  }
  // Multiple rates: show range
  const min = rates[0];
  const max = rates[rates.length - 1];
  return `${formatCurrency(min, currency, false)}–${formatCurrency(max, currency, false)}/hr`;
}

export function UnbilledByClientTable({ data }: UnbilledByClientTableProps) {
  const { t } = useTranslation();

  const handleCreateInvoice = (e: React.MouseEvent, clientId: number) => {
    e.stopPropagation();
    router.visit(`/invoices/new?client_id=${clientId}`);
  };

  const handleRowClick = (clientId: number) => {
    router.visit(`/clients/${clientId}`);
  };

  return (
    <Card className="bg-white border-stone-200">
      <CardHeader className="flex flex-row items-center justify-between pb-4">
        <CardTitle className="text-stone-900">
          {t("pages.dashboard.unbilledByClient.title")}
        </CardTitle>
        <Button
          variant="link"
          className="text-stone-900 hover:text-stone-700 font-medium p-0 h-auto"
          onClick={() => router.visit("/invoices/new")}
        >
          {t("pages.dashboard.unbilledByClient.createInvoice")} &rarr;
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        {/* Mobile Card List */}
        <div className="block md:hidden p-4 space-y-3">
          {data.length === 0 ? (
            <p className="py-4 text-center text-stone-500">
              No unbilled time entries
            </p>
          ) : (
            data.map((client) => (
              <MobileCard
                key={client.id}
                title={client.name}
                subtitle={`${client.project_count} ${client.project_count === 1 ? "project" : "projects"}`}
                details={[
                  { label: "Hours", value: Math.round(client.total_hours).toString() },
                  { label: "Amount", value: formatCurrency(client.total_amount, client.currency, false) },
                  { label: "Rate", value: formatRates(client.project_rates, client.currency) },
                ]}
                onClick={() => handleRowClick(client.id)}
                action={
                  <Button
                    variant="link"
                    className="text-stone-900 hover:text-stone-700 font-medium p-0 h-auto min-h-11"
                    onClick={(e) => handleCreateInvoice(e, client.id)}
                  >
                    Invoice
                  </Button>
                }
              />
            ))
          )}
        </div>

        {/* Desktop Table */}
        <Table className="hidden md:table">
          <TableHeader>
            <TableRow className="text-left text-sm text-stone-500 border-b border-stone-100">
              <TableHead className="px-6 py-3 font-medium">
                {t("pages.clients.table.client")}
              </TableHead>
              <TableHead className="px-6 py-3 font-medium text-right">
                {t("common.hours")}
              </TableHead>
              <TableHead className="px-6 py-3 font-medium text-right">
                {t("common.amount")}
              </TableHead>
              <TableHead className="px-6 py-3 font-medium text-right">
                {t("common.rate")}
              </TableHead>
              <TableHead className="px-6 py-3"></TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.length === 0 ? (
              <TableRow>
                <TableCell
                  colSpan={5}
                  className="px-6 py-8 text-center text-stone-500"
                >
                  {t("pages.dashboard.unbilledByClient.noEntries")}
                </TableCell>
              </TableRow>
            ) : (
              data.map((client) => (
                <TableRow
                  key={client.id}
                  className="border-b border-stone-100 cursor-pointer hover:bg-stone-50 transition-colors"
                  onClick={() => handleRowClick(client.id)}
                >
                  <TableCell className="px-6 py-4">
                    <div className="font-medium text-stone-900">
                      {client.name}
                    </div>
                    <div className="text-sm text-stone-500">
                      {t("pages.projects.projectCount", {
                        count: client.project_count,
                      })}
                    </div>
                  </TableCell>
                  <TableCell className="px-6 py-4 text-right tabular-nums text-stone-900">
                    {Math.round(client.total_hours)}
                  </TableCell>
                  <TableCell className="px-6 py-4 text-right tabular-nums font-medium text-stone-900">
                    {formatCurrency(
                      client.total_amount,
                      client.currency,
                      false
                    )}
                  </TableCell>
                  <TableCell className="px-6 py-4 text-right text-sm text-stone-500 whitespace-nowrap">
                    {formatRates(client.project_rates, client.currency)}
                  </TableCell>
                  <TableCell className="px-6 py-4 text-right">
                    <Button
                      variant="link"
                      className="text-stone-900 hover:text-stone-700 font-medium p-0 h-auto"
                      onClick={(e) => handleCreateInvoice(e, client.id)}
                    >
                      {t("pages.dashboard.unbilledByClient.invoice")}
                    </Button>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
