import TimeEntryRow from "./TimeEntryRow";

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

interface TimeEntry {
  id: number;
  date: string;
  hours: number;
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
  entries: TimeEntry[];
}

interface DateGroupProps {
  group: DateGroupData;
  projects: ClientGroup[];
  onDeleteEntry: (id: number) => void;
}

function formatDateDisplay(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function formatTotalHours(hours: number): string {
  // Display whole numbers without decimal, otherwise show one decimal
  const formatted =
    hours % 1 === 0 ? Math.floor(hours).toString() : hours.toFixed(1);
  return `${formatted} ${hours === 1 ? "hour" : "hours"}`;
}

export default function DateGroup({
  group,
  projects,
  onDeleteEntry,
}: DateGroupProps) {
  return (
    <div>
      <div className="flex items-center gap-3 mb-3">
        <h3 className="font-semibold text-stone-900">{group.formatted_date}</h3>
        <span className="text-sm text-stone-500">
          {formatDateDisplay(group.date)}
        </span>
        <span className="text-sm text-stone-400">&middot;</span>
        <span className="text-sm font-medium text-stone-600">
          {formatTotalHours(group.total_hours)}
        </span>
      </div>
      <div className="bg-white rounded-xl border border-stone-200 divide-y divide-stone-100">
        {group.entries.map((entry) => (
          <TimeEntryRow
            key={entry.id}
            entry={entry}
            projects={projects}
            onDelete={onDeleteEntry}
          />
        ))}
      </div>
    </div>
  );
}
