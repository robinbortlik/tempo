import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
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
import WorkEntryRow from "./components/WorkEntryRow";

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
  client_id: number | null;
  project_id: number | null;
  entry_type: string | null;
}

interface Period {
  year: number;
  month: number | null;
  available_years: number[];
}

interface PageProps {
  date_groups: DateGroupData[];
  projects: ClientGroup[];
  clients: { id: number; name: string }[];
  filters: Filters;
  period: Period;
  summary: Summary;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function WorkEntriesIndex() {
  const { date_groups, projects, clients, filters, period, summary, flash } =
    usePage<PageProps>().props;
  const { t } = useTranslation();
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
      <Head title={t("pages.workEntries.title")} />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
        <div className="mb-6 sm:mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-stone-900">
              {t("pages.workEntries.title")}
            </h1>
            <p className="text-stone-500 mt-1">
              {t("pages.workEntries.subtitle")}
            </p>
          </div>
        </div>

        <QuickEntryForm projects={projects} />

        {/* Data Section: Filters + Summary + Entries */}
        <div className="border border-stone-200 rounded-xl overflow-hidden">
          <FilterBar
            clients={clients}
            projects={projects}
            filters={filters}
            period={period}
          />

          {/* Summary Stats Bar */}
          {totalEntries > 0 && (
            <div className="bg-stone-50 border-t border-stone-200 px-4 sm:px-6 py-3">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-8">
                <div className="flex flex-wrap items-center gap-4 sm:gap-8">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-stone-500">
                      {t("pages.workEntries.summary.totalHours")}
                    </span>
                    <span className="text-lg font-bold text-stone-900 tabular-nums">
                      {Math.round(Number(summary.total_hours || 0))}h
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-stone-500">
                      {t("pages.workEntries.summary.totalAmount")}
                    </span>
                    <span className="text-lg font-bold text-stone-900 tabular-nums">
                      {formatCurrency(
                        Number(summary.total_amount || 0),
                        summaryCurrency,
                        false
                      )}
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-6 text-sm text-stone-500">
                  <span>
                    {t("pages.workEntries.summary.timeEntries", {
                      count: summary.time_entries_count || 0,
                    })}
                  </span>
                  <span>
                    {t("pages.workEntries.summary.fixedEntries", {
                      count: summary.fixed_entries_count || 0,
                    })}
                  </span>
                </div>
              </div>
            </div>
          )}

          {/* Entries List */}
          {totalEntries === 0 ? (
            <div className="bg-white border-t border-stone-200 p-8 text-center">
              <p className="text-stone-500">
                {t("pages.workEntries.noEntriesDescription")}
              </p>
            </div>
          ) : (
            <div className="bg-white border-t border-stone-200 divide-y divide-stone-100">
              {date_groups.flatMap((group) =>
                group.entries.map((entry) => (
                  <WorkEntryRow
                    key={entry.id}
                    entry={entry}
                    projects={projects}
                    onDelete={handleDeleteEntry}
                    showDate
                  />
                ))
              )}
            </div>
          )}
        </div>
      </div>

      <AlertDialog
        open={deleteEntryId !== null}
        onOpenChange={() => setDeleteEntryId(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {t("pages.workEntries.delete.title")}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {t("pages.workEntries.delete.description")}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isDeleting}>
              {t("common.cancel")}
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmDelete}
              disabled={isDeleting}
              className="bg-red-600 hover:bg-red-700 focus:ring-red-600"
            >
              {isDeleting ? t("common.deleting") : t("common.delete")}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
