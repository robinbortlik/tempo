import { useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { formatCurrency, formatHours } from "@/components/CurrencyDisplay";

interface Entry {
  id: number;
  date: string;
  hours: number;
  description: string | null;
  calculated_amount: number;
  entry_type: "time" | "fixed";
  amount: number | null;
}

interface Project {
  id: number;
  name: string;
  effective_hourly_rate: number;
}

interface ProjectGroupProps {
  project: Project;
  entries: Entry[];
  totalHours: number;
  totalAmount: number;
  currency: string;
  defaultOpen?: boolean;
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
}

export function ProjectGroup({
  project,
  entries,
  totalHours: _totalHours,
  totalAmount,
  currency,
  defaultOpen = true,
}: ProjectGroupProps) {
  const { t } = useTranslation();
  const [isOpen, setIsOpen] = useState(defaultOpen);

  return (
    <Collapsible
      open={isOpen}
      onOpenChange={setIsOpen}
      className="print:!block"
    >
      <CollapsibleTrigger className="w-full px-4 py-3 bg-stone-50 flex items-center justify-between hover:bg-stone-100 transition-colors cursor-pointer print:cursor-default print:hover:bg-stone-50">
        <div className="flex items-center gap-2">
          <svg
            className={`w-4 h-4 text-stone-400 transition-transform print:hidden ${isOpen ? "rotate-90" : ""}`}
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
          <span className="font-medium text-stone-700">{project.name}</span>
        </div>
        <span className="text-sm text-stone-500 whitespace-nowrap">
          {formatCurrency(totalAmount, currency)}
        </span>
      </CollapsibleTrigger>
      <CollapsibleContent className="print:!block print:!h-auto print:!overflow-visible">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs text-stone-400 border-b border-stone-100">
                <th className="px-4 pt-4 pb-2 font-medium">
                  {t("common.date")}
                </th>
                <th className="px-4 pt-4 pb-2 font-medium">
                  {t("common.description")}
                </th>
                <th className="px-4 pt-4 pb-2 font-medium text-right">
                  {t("common.hours")}
                </th>
                <th className="px-4 pt-4 pb-2 font-medium text-right">
                  {t("common.rate")}
                </th>
                <th className="px-4 pt-4 pb-2 font-medium text-right">
                  {t("common.amount")}
                </th>
              </tr>
            </thead>
            <tbody>
              {entries.map((entry, index) => (
                <tr
                  key={entry.id}
                  className={
                    index < entries.length - 1
                      ? "border-b border-stone-100"
                      : ""
                  }
                >
                  <td className="px-4 py-3 text-stone-500 w-24 whitespace-nowrap">
                    {formatDate(entry.date)}
                  </td>
                  <td className="px-4 py-3 text-stone-700">
                    {entry.description || "-"}
                  </td>
                  <td className="px-4 py-3 text-right tabular-nums text-stone-900 w-16 whitespace-nowrap">
                    {entry.entry_type === "time" ? (
                      <>{formatHours(entry.hours)}h</>
                    ) : (
                      <span className="text-stone-400">&mdash;</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-right tabular-nums text-stone-500 whitespace-nowrap">
                    {entry.entry_type === "time" &&
                    project.effective_hourly_rate > 0 ? (
                      <>
                        {formatCurrency(
                          project.effective_hourly_rate,
                          currency
                        )}
                      </>
                    ) : (
                      <span className="text-stone-300">&mdash;</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-right tabular-nums text-stone-600 whitespace-nowrap">
                    {formatCurrency(entry.calculated_amount, currency)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </CollapsibleContent>
    </Collapsible>
  );
}
