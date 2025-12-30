interface TimeEntry {
  id: number;
  date: string;
  hours: number;
  description: string;
  calculated_amount: number;
}

interface ProjectGroup {
  project: {
    id: number;
    name: string;
    effective_hourly_rate: number;
  };
  entries: TimeEntry[];
  total_hours: number;
  total_amount: number;
}

interface InvoicePreviewProps {
  projectGroups: ProjectGroup[];
  totalHours: number;
  totalAmount: number;
  currency: string;
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

export default function InvoicePreview({
  projectGroups,
  totalHours,
  totalAmount,
  currency,
}: InvoicePreviewProps) {
  if (projectGroups.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-stone-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-semibold text-stone-900">Preview</h3>
        </div>
        <div className="text-center py-8 text-stone-500">
          <p>No unbilled time entries found for the selected period.</p>
          <p className="text-sm mt-2">
            Select a client and date range to preview entries.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl border border-stone-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <h3 className="font-semibold text-stone-900">Preview</h3>
        <div className="text-sm text-stone-500">
          {totalHours} hours {"\u00B7"} {formatCurrency(totalAmount, currency)}
        </div>
      </div>

      {/* Entries grouped by project */}
      <div className="border border-stone-200 rounded-lg overflow-hidden">
        {projectGroups.map((group, groupIndex) => (
          <div key={group.project.id}>
            <div
              className={`px-4 py-3 bg-stone-50 flex items-center justify-between ${
                groupIndex > 0 ? "border-t border-stone-200" : ""
              }`}
            >
              <span className="font-medium text-stone-700">
                {group.project.name}
              </span>
              <span className="text-sm text-stone-500">
                {group.total_hours}h {"\u00B7"}{" "}
                {formatCurrency(group.total_amount, currency)}
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
                      {formatCurrency(entry.calculated_amount, currency)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ))}
      </div>

      {/* Totals */}
      <div className="mt-6 pt-6 border-t border-stone-200">
        <div className="flex justify-end">
          <dl className="w-64 space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-stone-500">Subtotal</dt>
              <dd className="tabular-nums text-stone-900">
                {formatCurrency(totalAmount, currency)}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-stone-500">VAT (0%)</dt>
              <dd className="tabular-nums text-stone-900">
                {formatCurrency(0, currency)}
              </dd>
            </div>
            <div className="flex justify-between pt-2 border-t border-stone-200">
              <dt className="font-semibold text-stone-900">Total</dt>
              <dd className="tabular-nums font-semibold text-stone-900">
                {formatCurrency(totalAmount, currency)}
              </dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
  );
}
