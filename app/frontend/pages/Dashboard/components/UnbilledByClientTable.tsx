import { router } from "@inertiajs/react";
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

interface UnbilledClient {
  id: number;
  name: string;
  currency: string;
  project_count: number;
  total_hours: number;
  total_amount: number;
  average_rate: number;
}

interface UnbilledByClientTableProps {
  data: UnbilledClient[];
}

const CURRENCY_SYMBOLS: Record<string, string> = {
  EUR: "\u20AC",
  USD: "$",
  GBP: "\u00A3",
  CZK: "K\u010D",
};

function formatCurrency(amount: number, currency: string): string {
  const symbol = CURRENCY_SYMBOLS[currency] || currency;
  return `${symbol}${amount.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  })}`;
}

export function UnbilledByClientTable({ data }: UnbilledByClientTableProps) {
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
        <CardTitle className="text-stone-900">Unbilled by Client</CardTitle>
        <Button
          variant="link"
          className="text-stone-900 hover:text-stone-700 font-medium p-0 h-auto"
          onClick={() => router.visit("/invoices/new")}
        >
          Create Invoice &rarr;
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        <Table>
          <TableHeader>
            <TableRow className="text-left text-sm text-stone-500 border-b border-stone-100">
              <TableHead className="px-6 py-3 font-medium">Client</TableHead>
              <TableHead className="px-6 py-3 font-medium text-right">
                Hours
              </TableHead>
              <TableHead className="px-6 py-3 font-medium text-right">
                Amount
              </TableHead>
              <TableHead className="px-6 py-3 font-medium text-right">
                Rate
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
                  No unbilled time entries
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
                      {client.project_count}{" "}
                      {client.project_count === 1 ? "project" : "projects"}
                    </div>
                  </TableCell>
                  <TableCell className="px-6 py-4 text-right tabular-nums text-stone-900">
                    {client.total_hours.toFixed(1)}
                  </TableCell>
                  <TableCell className="px-6 py-4 text-right tabular-nums font-medium text-stone-900">
                    {formatCurrency(client.total_amount, client.currency)}
                  </TableCell>
                  <TableCell className="px-6 py-4 text-right text-sm text-stone-500">
                    {formatCurrency(client.average_rate, client.currency)}/hr
                  </TableCell>
                  <TableCell className="px-6 py-4 text-right">
                    <Button
                      variant="link"
                      className="text-stone-900 hover:text-stone-700 font-medium p-0 h-auto"
                      onClick={(e) => handleCreateInvoice(e, client.id)}
                    >
                      Invoice
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
