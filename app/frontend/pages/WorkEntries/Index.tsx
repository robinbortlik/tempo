import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Toaster } from "@/components/ui/sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { formatCurrency } from "@/components/CurrencyDisplay";
import QuickEntryForm from "./components/QuickEntryForm";
import FilterBar from "./components/FilterBar";
import DateGroup from "./components/DateGroup";

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

interface Summary {
  total_hours: number;
  total_amount: number;
  time_entries_count: number;
  fixed_entries_count: number;
}

interface Filters {
  start_date: string | null;
  end_date: string | null;
  client_id: number | null;
  project_id: number | null;
  entry_type: string | null;
}

interface PageProps {
  date_groups: DateGroupData[];
  projects: ClientGroup[];
  clients: { id: number; name: string }[];
  filters: Filters;
  summary: Summary;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function WorkEntriesIndex() {
  const { date_groups, projects, clients, filters, summary, flash } =
    usePage<PageProps>().props;
  const [deleteEntryId, setDeleteEntryId] = useState<number | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleDeleteEntry = (id: number) => {
    setDeleteEntryId(id);
  };

  const confirmDelete = () => {
    if (deleteEntryId === null) return;

    setIsDeleting(true);
    router.delete(`/work_entries/${deleteEntryId}`, {
      onFinish: () => {
        setIsDeleting(false);
        setDeleteEntryId(null);
      },
    });
  };

  // Get the currency to use for the summary - use filtered client's currency if available
  const getSummaryCurrency = (): string | null => {
    if (filters.client_id) {
      // Find the filtered client's currency from projects
      const clientGroup = projects.find(
        (group) => group.client.id === filters.client_id
      );
      return clientGroup?.client.currency || null;
    }
    // If no client filter, try to get currency from first entry
    const firstEntry = date_groups[0]?.entries[0];
    return firstEntry?.client_currency || null;
  };
  const summaryCurrency = getSummaryCurrency();

  const totalEntries = date_groups.reduce(
    (sum, group) => sum + group.entries.length,
    0
  );

  return (
    <>
      <Head title="Log Work" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-stone-900">Log Work</h1>
            <p className="text-stone-500 mt-1">
              Track your time and fixed-price work
            </p>
          </div>
        </div>

        <QuickEntryForm projects={projects} />

        <FilterBar clients={clients} projects={projects} filters={filters} />

        {/* Summary Stats Bar */}
        {totalEntries > 0 && (
          <div className="bg-stone-50 rounded-xl border border-stone-200 p-4 mb-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-8">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-stone-500">
                    Total Hours:
                  </span>
                  <span className="text-lg font-bold text-stone-900 tabular-nums">
                    {Number(summary.total_hours || 0).toFixed(1)}h
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-stone-500">
                    Total Amount:
                  </span>
                  <span className="text-lg font-bold text-stone-900 tabular-nums">
                    {formatCurrency(Number(summary.total_amount || 0), summaryCurrency, false)}
                  </span>
                </div>
              </div>
              <div className="flex items-center gap-6 text-sm text-stone-500">
                <span>
                  {summary.time_entries_count || 0} time{" "}
                  {(summary.time_entries_count || 0) === 1
                    ? "entry"
                    : "entries"}
                </span>
                <span>
                  {summary.fixed_entries_count || 0} fixed{" "}
                  {(summary.fixed_entries_count || 0) === 1
                    ? "entry"
                    : "entries"}
                </span>
              </div>
            </div>
          </div>
        )}

        {totalEntries === 0 ? (
          <div className="bg-white rounded-xl border border-stone-200 p-8 text-center">
            <p className="text-stone-500">
              No work entries found. Add your first entry above.
            </p>
          </div>
        ) : (
          <div className="space-y-6">
            {date_groups.map((group) => (
              <DateGroup
                key={group.date}
                group={group}
                projects={projects}
                onDeleteEntry={handleDeleteEntry}
              />
            ))}
          </div>
        )}
      </div>

      <AlertDialog
        open={deleteEntryId !== null}
        onOpenChange={() => setDeleteEntryId(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Work Entry?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the
              work entry.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isDeleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmDelete}
              disabled={isDeleting}
              className="bg-red-600 hover:bg-red-700 focus:ring-red-600"
            >
              {isDeleting ? "Deleting..." : "Delete"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
