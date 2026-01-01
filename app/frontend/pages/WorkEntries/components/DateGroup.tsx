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
  const numHours = Number(hours) || 0;
  const formatted =
    numHours % 1 === 0 ? Math.floor(numHours).toString() : numHours.toFixed(1);
  return formatted;
}

function formatCurrency(amount: number): string {
  return amount.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
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
      <div className="flex items-center gap-4 mb-4">
        <div className="flex items-center gap-3">
          {/* Date pill */}
          <div
            className={`
              px-4 py-2 rounded-full text-sm font-semibold tracking-wide
              ${isToday ? "bg-stone-900 text-white" : isYesterday ? "bg-stone-200 text-stone-700" : "bg-stone-100 text-stone-600"}
            `}
          >
            {group.formatted_date}
          </div>
          <span className="text-sm text-stone-400 font-medium">
            {formatDateDisplay(group.date)}
          </span>
        </div>

        {/* Separator line */}
        <div className="flex-1 h-px bg-gradient-to-r from-stone-200 to-transparent" />

        {/* Hours and amount summary */}
        <div className="flex items-baseline gap-3 pr-2">
          <div className="flex items-baseline gap-1.5">
            <span className="text-2xl font-bold text-stone-900 tabular-nums tracking-tight">
              {formatTotalHours(group.total_hours)}
            </span>
            <span className="text-sm font-medium text-stone-400">
              {group.total_hours === 1 ? "hour" : "hours"}
            </span>
          </div>
          {group.total_amount > 0 && (
            <>
              <span className="text-stone-300">·</span>
              <span className="text-lg font-semibold text-stone-600 tabular-nums">
                {formatCurrency(group.total_amount)}
              </span>
            </>
          )}
        </div>
      </div>

      {/* Entries container */}
      <div className="relative">
        {/* Subtle left border accent */}
        <div
          className={`
            absolute left-0 top-3 bottom-3 w-1 rounded-full
            ${isToday ? "bg-stone-900" : "bg-stone-200"}
          `}
        />

        {/* Entries list */}
        <div className="ml-4 space-y-2">
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
    </div>
  );
}
