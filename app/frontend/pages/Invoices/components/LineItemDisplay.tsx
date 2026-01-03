import { Button } from "@/components/ui/button";
import { formatCurrency } from "@/components/CurrencyDisplay";

interface LineItem {
  id?: number;
  line_type: "time_aggregate" | "fixed";
  description: string;
  quantity: number | null;
  unit_price: number | null;
  amount: number;
  vat_rate: number;
  vat_amount?: number;
  position: number;
  work_entry_ids?: number[];
}

interface LineItemDisplayProps {
  lineItem: LineItem;
  currency: string;
  isDraft: boolean;
  isFirst: boolean;
  isLast: boolean;
  onEdit: (id: number) => void;
  onRemove: (id: number) => void;
  onMoveUp: (id: number) => void;
  onMoveDown: (id: number) => void;
}

export default function LineItemDisplay({
  lineItem,
  currency,
  isDraft,
  isFirst,
  isLast,
  onEdit,
  onRemove,
  onMoveUp,
  onMoveDown,
}: LineItemDisplayProps) {
  const itemId = lineItem.id || 0;

  return (
    <tr className="border-b border-stone-100 last:border-b-0 group">
      {/* Quantity */}
      <td className="px-2 py-3 text-stone-900 font-medium w-12">
        {lineItem.line_type === "time_aggregate" && lineItem.quantity
          ? Math.round(lineItem.quantity)
          : ""}
      </td>
      {/* Unit */}
      <td className="px-2 py-3 text-stone-500 w-12">
        {lineItem.line_type === "time_aggregate" && lineItem.quantity
          ? "hrs"
          : ""}
      </td>
      {/* Description */}
      <td className="px-2 py-3 text-stone-700">
        {lineItem.description || "No description"}
      </td>
      {/* VAT */}
      <td className="px-2 py-3 text-right tabular-nums w-16 text-stone-500">
        {lineItem.vat_rate} %
      </td>
      {/* Unit Price */}
      <td className="px-2 py-3 text-right tabular-nums w-24 text-stone-500 whitespace-nowrap">
        {lineItem.line_type === "time_aggregate" && lineItem.unit_price
          ? formatCurrency(lineItem.unit_price, currency)
          : ""}
      </td>
      {/* Total w/o VAT */}
      <td className="px-2 py-3 text-right tabular-nums text-stone-900 font-medium w-28 whitespace-nowrap">
        {formatCurrency(lineItem.amount, currency)}
      </td>
      {isDraft && (
        <td className="px-2 py-3 w-36">
          <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => onMoveUp(itemId)}
              disabled={isFirst}
              className="h-7 w-7 p-0"
              aria-label="Move up"
              title="Move up"
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
                  d="M5 15l7-7 7 7"
                />
              </svg>
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => onMoveDown(itemId)}
              disabled={isLast}
              className="h-7 w-7 p-0"
              aria-label="Move down"
              title="Move down"
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
                  d="M19 9l-7 7-7-7"
                />
              </svg>
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => onEdit(itemId)}
              className="h-7 w-7 p-0"
              aria-label="Edit"
              title="Edit line item"
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
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
              </svg>
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => onRemove(itemId)}
              className="h-7 w-7 p-0 text-red-500 hover:text-red-700 hover:bg-red-50"
              aria-label="Remove"
              title="Remove line item"
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
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </Button>
          </div>
        </td>
      )}
    </tr>
  );
}
