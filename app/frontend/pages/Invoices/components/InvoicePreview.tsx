import { formatCurrency } from "@/components/CurrencyDisplay";

export interface LineItem {
  id?: number;
  line_type: "time_aggregate" | "fixed";
  description: string;
  quantity: number | null;
  unit_price: number | null;
  amount: number;
  position: number;
  project_id?: number;
  project_name?: string;
  work_entry_ids?: number[];
}

interface InvoicePreviewProps {
  lineItems: LineItem[];
  totalHours: number;
  totalAmount: number;
  currency: string;
}

function formatHours(hours: number): string {
  const numHours = Number(hours) || 0;
  return numHours % 1 === 0 ? numHours.toString() : numHours.toFixed(1);
}

export default function InvoicePreview({
  lineItems,
  totalHours,
  totalAmount,
  currency,
}: InvoicePreviewProps) {
  if (lineItems.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-stone-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="font-semibold text-stone-900">Preview</h3>
        </div>
        <div className="text-center py-8 text-stone-500">
          <p>No unbilled work entries found for the selected period.</p>
          <p className="text-sm mt-2">
            Select a client and date range to preview entries.
          </p>
        </div>
      </div>
    );
  }

  // Group line items by project
  const groupedByProject = lineItems.reduce(
    (acc, item) => {
      const projectName = item.project_name || "Other";
      if (!acc[projectName]) {
        acc[projectName] = [];
      }
      acc[projectName].push(item);
      return acc;
    },
    {} as Record<string, LineItem[]>
  );

  return (
    <div className="bg-white rounded-xl border border-stone-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <h3 className="font-semibold text-stone-900">Preview</h3>
        <div className="text-sm text-stone-500">
          {totalHours > 0 && (
            <>
              {formatHours(totalHours)} hours {"\u00B7"}{" "}
            </>
          )}
          {formatCurrency(totalAmount, currency)}
        </div>
      </div>

      {/* Line items grouped by project */}
      <div className="border border-stone-200 rounded-lg overflow-hidden">
        {Object.entries(groupedByProject).map(
          ([projectName, items], groupIndex) => {
            const projectTotalHours = items
              .filter((item) => item.line_type === "time_aggregate")
              .reduce((sum, item) => sum + (item.quantity || 0), 0);
            const projectTotalAmount = items.reduce(
              (sum, item) => sum + item.amount,
              0
            );

            return (
              <div key={projectName}>
                <div
                  className={`px-4 py-3 bg-stone-50 flex items-center justify-between ${
                    groupIndex > 0 ? "border-t border-stone-200" : ""
                  }`}
                >
                  <span className="font-medium text-stone-700">
                    {projectName}
                  </span>
                  <span className="text-sm text-stone-500">
                    {projectTotalHours > 0 && (
                      <>
                        {formatHours(projectTotalHours)}h {"\u00B7"}{" "}
                      </>
                    )}
                    {formatCurrency(projectTotalAmount, currency)}
                  </span>
                </div>
                <table className="w-full text-sm">
                  <tbody>
                    {items.map((item, itemIndex) => (
                      <tr
                        key={item.id || itemIndex}
                        className={
                          itemIndex < items.length - 1
                            ? "border-b border-stone-100"
                            : ""
                        }
                      >
                        <td className="px-4 py-3 text-stone-700">
                          {item.description || "No description"}
                        </td>
                        {item.line_type === "time_aggregate" ? (
                          <>
                            <td className="px-4 py-3 text-right tabular-nums w-16 text-stone-600">
                              {formatHours(item.quantity || 0)}h
                            </td>
                            <td className="px-4 py-3 text-right tabular-nums w-24 text-stone-500">
                              {formatCurrency(item.unit_price || 0, currency)}/h
                            </td>
                          </>
                        ) : (
                          <>
                            <td className="px-4 py-3 text-right tabular-nums w-16 text-stone-400">
                              -
                            </td>
                            <td className="px-4 py-3 text-right tabular-nums w-24 text-stone-400">
                              -
                            </td>
                          </>
                        )}
                        <td className="px-4 py-3 text-right tabular-nums text-stone-900 font-medium w-28">
                          {formatCurrency(item.amount, currency)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            );
          }
        )}
      </div>

      {/* Totals */}
      <div className="mt-6 pt-6 border-t border-stone-200">
        <div className="flex justify-end">
          <dl className="w-64 space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-stone-500">
                Subtotal{totalHours > 0 && ` (${formatHours(totalHours)} hrs)`}
              </dt>
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
