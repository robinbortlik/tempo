import { ProjectGroup } from "./ProjectGroup";
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

interface ProjectGroupData {
  project: Project;
  entries: Entry[];
  total_hours: number;
  total_amount: number;
}

interface Invoice {
  id: number;
  number: string;
  issue_date: string;
  period_start: string;
  period_end: string;
  total_hours: number;
  total_amount: number;
}

interface InvoicedSectionProps {
  projectGroups: ProjectGroupData[];
  invoices: Invoice[];
  totalHours: number;
  totalAmount: number;
  currency: string;
}

function formatDateRange(start: string, end: string): string {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const startFormatted = startDate.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
  const endFormatted = endDate.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
  return `${startFormatted}\u2013${endFormatted}`;
}

function formatHours(hours: number | string): string {
  // Convert to number if string (Rails may send as string)
  const numHours = typeof hours === "string" ? parseFloat(hours) : hours;
  // Remove trailing zeros: 8.0 -> 8, 8.5 -> 8.5
  return numHours % 1 === 0 ? numHours.toFixed(0) : numHours.toFixed(1);
}

export function InvoicedSection({
  projectGroups,
  invoices,
  currency,
}: InvoicedSectionProps) {
  // Show nothing if there's no invoiced content
  if (projectGroups.length === 0 && invoices.length === 0) {
    return null;
  }

  return (
    <section className="mb-8">
      <h2 className="text-lg font-semibold text-stone-900 mb-4 flex items-center gap-2">
        <span className="w-2 h-2 bg-emerald-500 rounded-full" />
        Previously Invoiced
      </h2>

      {/* Invoice Summaries */}
      {invoices.length > 0 && (
        <div className="space-y-4 mb-4">
          {invoices.map((invoice) => (
            <div
              key={invoice.id}
              className="bg-white border border-stone-200 rounded-xl overflow-hidden"
            >
              <div className="px-4 py-3 bg-stone-50 flex items-center justify-between">
                <div>
                  <span className="font-medium text-stone-700">
                    Invoice #{invoice.number}
                  </span>
                  <span className="text-stone-400 mx-2">&middot;</span>
                  <span className="text-sm text-stone-500">
                    {formatDateRange(invoice.period_start, invoice.period_end)}
                  </span>
                </div>
                <span className="text-sm font-medium text-emerald-600">
                  {formatCurrency(invoice.total_amount, currency)}
                </span>
              </div>
              <div className="px-4 py-4 text-center text-stone-400 text-sm">
                {formatHours(invoice.total_hours)} hours
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Project Groups with Entries (optional, when showing entry details) */}
      {projectGroups.length > 0 && (
        <div className="bg-white border border-stone-200 rounded-xl overflow-hidden">
          {projectGroups.map((group, index) => (
            <div
              key={group.project.id}
              className={
                index < projectGroups.length - 1
                  ? "border-b border-stone-100"
                  : ""
              }
            >
              <ProjectGroup
                project={group.project}
                entries={group.entries}
                totalHours={group.total_hours}
                totalAmount={group.total_amount}
                currency={currency}
                defaultOpen={false}
              />
            </div>
          ))}
        </div>
      )}
    </section>
  );
}
