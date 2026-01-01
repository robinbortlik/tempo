import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Toaster } from "@/components/ui/sonner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { formatCurrency, formatRate } from "@/components/CurrencyDisplay";

interface Project {
  id: number;
  name: string;
  client_id: number;
  client_name: string;
  client_currency: string | null;
  hourly_rate: number | null;
  effective_hourly_rate: number;
  active: boolean;
}

interface WorkEntry {
  id: number;
  date: string;
  hours: number;
  description: string | null;
  status: string;
  calculated_amount: number;
}

interface Stats {
  total_hours: number;
  unbilled_hours: number;
  unbilled_amount: number;
}

interface PageProps {
  project: Project;
  work_entries: WorkEntry[];
  stats: Stats;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export default function ProjectShow() {
  const { project, work_entries, stats, flash } = usePage<PageProps>().props;
  const [isDeleting, setIsDeleting] = useState(false);
  const [isToggling, setIsToggling] = useState(false);

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleDelete = () => {
    setIsDeleting(true);
    router.delete(`/projects/${project.id}`, {
      onFinish: () => setIsDeleting(false),
    });
  };

  const handleToggleActive = () => {
    setIsToggling(true);
    router.patch(
      `/projects/${project.id}/toggle_active`,
      {},
      {
        onFinish: () => setIsToggling(false),
      }
    );
  };

  return (
    <>
      <Head title={project.name} />
      <Toaster position="top-right" />

      <div className="p-8">
        {/* Header */}
        <div className="mb-6">
          <button
            onClick={() => router.visit("/projects")}
            className="flex items-center gap-1 text-sm text-stone-500 hover:text-stone-700 mb-4"
          >
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M15 19l-7-7 7-7"
              />
            </svg>
            Back to Projects
          </button>
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-4">
              <div
                className={`w-3 h-3 rounded-full ${project.active ? "bg-emerald-500" : "bg-stone-300"}`}
              />
              <div>
                <h1 className="text-2xl font-semibold text-stone-900">
                  {project.name}
                </h1>
                <p className="text-stone-500">
                  {project.client_name} {" \u00B7 "}
                  {formatRate(
                    project.effective_hourly_rate,
                    project.client_currency
                  )}
                  {project.hourly_rate && " (custom rate)"}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                onClick={handleToggleActive}
                disabled={isToggling}
                className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
              >
                {isToggling
                  ? "Updating..."
                  : project.active
                    ? "Deactivate"
                    : "Activate"}
              </Button>
              <Button
                variant="outline"
                onClick={() => router.visit(`/projects/${project.id}/edit`)}
                className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
              >
                Edit
              </Button>
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button
                    variant="outline"
                    className="px-4 py-2 border border-red-200 text-red-600 font-medium rounded-lg hover:bg-red-50 transition-colors"
                  >
                    Delete
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Delete {project.name}?</AlertDialogTitle>
                    <AlertDialogDescription>
                      This action cannot be undone. This will permanently delete
                      the project. Projects with invoiced time entries cannot be
                      deleted.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                    <AlertDialogAction
                      onClick={handleDelete}
                      disabled={isDeleting}
                      className="bg-red-600 hover:bg-red-700"
                    >
                      {isDeleting ? "Deleting..." : "Delete"}
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 mb-8">
          <div className="bg-white rounded-xl border border-stone-200 p-4">
            <p className="text-sm text-stone-500">Total Hours</p>
            <p className="text-2xl font-semibold text-stone-900 tabular-nums mt-1">
              {Math.round(stats.total_hours)}
            </p>
          </div>
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
            <p className="text-sm text-amber-700">Unbilled Hours</p>
            <p className="text-2xl font-semibold text-amber-900 tabular-nums mt-1">
              {Math.round(stats.unbilled_hours)}
            </p>
          </div>
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
            <p className="text-sm text-amber-700">Unbilled Amount</p>
            <p className="text-2xl font-semibold text-amber-900 tabular-nums mt-1">
              {formatCurrency(stats.unbilled_amount, project.client_currency)}
            </p>
          </div>
        </div>

        {/* Work Entries */}
        <div className="bg-white rounded-xl border border-stone-200">
          <div className="px-6 py-4 border-b border-stone-200">
            <h2 className="font-semibold text-stone-900">Work Entries</h2>
          </div>
          <Table>
            <TableHeader>
              <TableRow className="text-left text-sm text-stone-500 border-b border-stone-200">
                <TableHead className="px-6 py-4 font-medium">Date</TableHead>
                <TableHead className="px-6 py-4 font-medium">
                  Description
                </TableHead>
                <TableHead className="px-6 py-4 font-medium text-right">
                  Hours
                </TableHead>
                <TableHead className="px-6 py-4 font-medium text-right">
                  Amount
                </TableHead>
                <TableHead className="px-6 py-4 font-medium">Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {work_entries.length === 0 ? (
                <TableRow>
                  <TableCell
                    colSpan={5}
                    className="px-6 py-8 text-center text-stone-500"
                  >
                    No work entries yet.
                  </TableCell>
                </TableRow>
              ) : (
                work_entries.map((entry) => (
                  <TableRow
                    key={entry.id}
                    className="border-b border-stone-100"
                  >
                    <TableCell className="px-6 py-4 text-stone-600">
                      {formatDate(entry.date)}
                    </TableCell>
                    <TableCell className="px-6 py-4 text-stone-900">
                      {entry.description || (
                        <span className="text-stone-400">No description</span>
                      )}
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right tabular-nums text-stone-900">
                      {Math.round(entry.hours)}h
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right tabular-nums text-stone-900">
                      {formatCurrency(
                        entry.calculated_amount,
                        project.client_currency
                      )}
                    </TableCell>
                    <TableCell className="px-6 py-4">
                      <span
                        className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                          entry.status === "invoiced"
                            ? "bg-emerald-100 text-emerald-700"
                            : "bg-amber-100 text-amber-700"
                        }`}
                      >
                        {entry.status === "invoiced" ? "Invoiced" : "Unbilled"}
                      </span>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </div>
    </>
  );
}
