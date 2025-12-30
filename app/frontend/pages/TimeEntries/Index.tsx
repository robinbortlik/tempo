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

interface Filters {
  start_date: string | null;
  end_date: string | null;
  client_id: number | null;
  project_id: number | null;
}

interface PageProps {
  date_groups: DateGroupData[];
  projects: ClientGroup[];
  clients: { id: number; name: string }[];
  filters: Filters;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function TimeEntriesIndex() {
  const { date_groups, projects, clients, filters, flash } =
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
    router.delete(`/time_entries/${deleteEntryId}`, {
      onFinish: () => {
        setIsDeleting(false);
        setDeleteEntryId(null);
      },
    });
  };

  const totalEntries = date_groups.reduce(
    (sum, group) => sum + group.entries.length,
    0
  );

  return (
    <>
      <Head title="Time Entries" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-stone-900">
              Time Entries
            </h1>
            <p className="text-stone-500 mt-1">Track your work</p>
          </div>
        </div>

        <QuickEntryForm projects={projects} />

        <FilterBar clients={clients} projects={projects} filters={filters} />

        {totalEntries === 0 ? (
          <div className="bg-white rounded-xl border border-stone-200 p-8 text-center">
            <p className="text-stone-500">
              No time entries found. Add your first entry above.
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
            <AlertDialogTitle>Delete Time Entry?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the
              time entry.
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
