import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";

interface LineItem {
  id?: number;
  line_type: "time_aggregate" | "fixed";
  description: string;
  quantity: number | null;
  unit_price: number | null;
  amount: number;
  vat_rate: number;
  position: number;
  work_entry_ids?: number[];
}

interface LineItemEditorProps {
  lineItem: LineItem;
  currency: string;
  defaultVatRate?: number | null;
  onSave: (data: {
    description: string;
    amount: number;
    vat_rate: number;
  }) => void;
  onCancel: () => void;
}

export default function LineItemEditor({
  lineItem,
  currency,
  defaultVatRate,
  onSave,
  onCancel,
}: LineItemEditorProps) {
  const [description, setDescription] = useState(lineItem.description);
  const [amount, setAmount] = useState(lineItem.amount);
  const [vatRate, setVatRate] = useState(
    lineItem.vat_rate ?? defaultVatRate ?? 0
  );
  const [errors, setErrors] = useState<{
    description?: string;
    amount?: string;
    vatRate?: string;
  }>({});

  const validate = () => {
    const newErrors: {
      description?: string;
      amount?: string;
      vatRate?: string;
    } = {};

    if (!description.trim()) {
      newErrors.description = "Description is required";
    }

    if (amount < 0) {
      newErrors.amount = "Amount must be non-negative";
    }

    if (vatRate < 0 || vatRate > 100) {
      newErrors.vatRate = "VAT rate must be between 0 and 100";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validate()) {
      onSave({ description: description.trim(), amount, vat_rate: vatRate });
    }
  };

  const currencySymbols: Record<string, string> = {
    EUR: "\u20AC",
    USD: "$",
    GBP: "\u00A3",
    CZK: "K\u010D",
  };
  const currencySymbol = currencySymbols[currency] || currency;

  return (
    <form
      onSubmit={handleSubmit}
      className="p-4 bg-stone-50 rounded-lg space-y-4"
    >
      <div>
        <Label
          htmlFor="edit-description"
          className="block text-sm font-medium text-stone-600 mb-1"
        >
          Description
        </Label>
        <Input
          id="edit-description"
          type="text"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className={`w-full ${errors.description ? "border-red-500" : ""}`}
          aria-describedby={
            errors.description ? "description-error" : undefined
          }
        />
        {errors.description && (
          <p id="description-error" className="mt-1 text-sm text-red-500">
            {errors.description}
          </p>
        )}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <Label
            htmlFor="edit-amount"
            className="block text-sm font-medium text-stone-600 mb-1"
          >
            Amount
          </Label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-500">
              {currencySymbol}
            </span>
            <Input
              id="edit-amount"
              type="number"
              step="0.01"
              min="0"
              value={amount}
              onChange={(e) => setAmount(parseFloat(e.target.value) || 0)}
              className={`w-full pl-8 ${errors.amount ? "border-red-500" : ""}`}
              aria-describedby={errors.amount ? "amount-error" : undefined}
            />
          </div>
          {errors.amount && (
            <p id="amount-error" className="mt-1 text-sm text-red-500">
              {errors.amount}
            </p>
          )}
        </div>

        <div>
          <Label
            htmlFor="edit-vat-rate"
            className="block text-sm font-medium text-stone-600 mb-1"
          >
            VAT Rate
          </Label>
          <div className="relative">
            <Input
              id="edit-vat-rate"
              type="number"
              step="0.01"
              min="0"
              max="100"
              value={vatRate}
              onChange={(e) => setVatRate(parseFloat(e.target.value) || 0)}
              className={`w-full pr-8 ${errors.vatRate ? "border-red-500" : ""}`}
              aria-describedby={errors.vatRate ? "vat-rate-error" : undefined}
            />
            <span className="absolute right-3 top-1/2 -translate-y-1/2 text-stone-500">
              %
            </span>
          </div>
          {errors.vatRate && (
            <p id="vat-rate-error" className="mt-1 text-sm text-red-500">
              {errors.vatRate}
            </p>
          )}
        </div>
      </div>

      <div className="flex justify-end gap-2 pt-2">
        <Button
          type="button"
          variant="outline"
          onClick={onCancel}
          className="px-4 py-2"
        >
          Cancel
        </Button>
        <Button
          type="submit"
          className="px-4 py-2 bg-stone-900 text-white hover:bg-stone-800"
        >
          Save
        </Button>
      </div>
    </form>
  );
}
