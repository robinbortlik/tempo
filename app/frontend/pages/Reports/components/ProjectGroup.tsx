import { useState } from "react";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { formatCurrency } from "@/components/CurrencyDisplay";

interface Entry {
  id: number;
  date: string;
  hours: number;
  description: string | null;
  calculated_amount: number;
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

function formatHours(hours: number | string): string {
  // Convert to number if string (Rails may send as string)
  const numHours = typeof hours === "string" ? parseFloat(hours) : hours;
  // Remove trailing zeros: 8.0 -> 8, 8.5 -> 8.5
  return numHours % 1 === 0 ? numHours.toFixed(0) : numHours.toFixed(1);
}

export function ProjectGroup({
  project,
  entries,
  totalHours,
  totalAmount,
  currency,
  defaultOpen = true,
}: ProjectGroupProps) {
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
        <span className="text-sm text-stone-500">
          {formatHours(totalHours)}h &middot;{" "}
          {formatCurrency(totalAmount, currency)}
        </span>
      </CollapsibleTrigger>
      <CollapsibleContent className="print:!block print:!h-auto print:!overflow-visible">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
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
                  <td className="px-4 py-3 text-right tabular-nums text-stone-900 w-20">
                    {formatHours(entry.hours)}h
                  </td>
                  <td className="px-4 py-3 text-right tabular-nums text-stone-600 w-24">
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
