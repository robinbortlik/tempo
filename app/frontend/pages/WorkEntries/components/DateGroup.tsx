import { formatCurrency } from "@/components/CurrencyDisplay";
import WorkEntryRow from "./WorkEntryRow";

interface Project {
  id: number;
  name: string;
  effective_hourly_rate: number;
}

interface Client {
  id: number;
  name: string;
  currency: string | null;
}

interface ClientGroup {
  client: Client;
  projects: Project[];
}

interface WorkEntry {
  id: number;
  date: string;
  hours: number | null;
  amount: number | null;
  hourly_rate: number | null;
  entry_type: "time" | "fixed";
  description: string | null;
  status: "unbilled" | "invoiced";
  calculated_amount: number;
  project_id: number;
  project_name: string;
  client_id: number;
  client_name: string;
  client_currency: string | null;
}

interface DateGroupData {
  date: string;
  formatted_date: string;
  total_hours: number;
  total_amount: number;
  entries: WorkEntry[];
}

interface DateGroupProps {
  group: DateGroupData;
  projects: ClientGroup[];
  onDeleteEntry: (id: number) => void;
}

function formatDateDisplay(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
}

function formatTotalHours(hours: number): string {
  return Math.round(Number(hours) || 0).toString();
}

export default function DateGroup({
  group,
  projects,
  onDeleteEntry,
}: DateGroupProps) {
  const isToday = group.formatted_date === "Today";
  const isYesterday = group.formatted_date === "Yesterday";

  return (
    <div className="group/dategroup">
      {/* Date Header */}
      <div className="flex items-center gap-3 px-4 py-2 bg-stone-50 border-b border-stone-100">
        <div className="flex items-center gap-2">
          <span
            className={`
              px-2.5 py-1 rounded-md text-xs font-semibold
              ${isToday ? "bg-stone-900 text-white" : isYesterday ? "bg-stone-300 text-stone-700" : "bg-stone-200 text-stone-600"}
            `}
          >
            {group.formatted_date}
          </span>
          <span className="text-xs text-stone-400">
            {formatDateDisplay(group.date)}
          </span>
        </div>

        <div className="flex-1" />

        {/* Day summary */}
        <div className="flex items-center gap-2 text-xs tabular-nums">
          <span className="font-semibold text-stone-700">
            {formatTotalHours(group.total_hours)}h
          </span>
          {group.total_amount > 0 && (
            <>
              <span className="text-stone-300">=</span>
              <span className="font-semibold text-stone-700">
                {formatCurrency(group.total_amount, group.entries[0]?.client_currency, false)}
              </span>
            </>
          )}
        </div>
      </div>

      {/* Entries list */}
      <div className="divide-y divide-stone-100">
        {group.entries.map((entry, index) => (
          <WorkEntryRow
            key={entry.id}
            entry={entry}
            projects={projects}
            onDelete={onDeleteEntry}
            isFirst={index === 0}
            isLast={index === group.entries.length - 1}
          />
        ))}
      </div>
    </div>
  );
}
