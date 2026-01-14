import { Head, usePage, router, Link } from "@inertiajs/react";
import { useEffect } from "react";
import { useTranslation } from "react-i18next";
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

interface SyncHistory {
  id: number;
  status: string;
  started_at: string | null;
  completed_at: string | null;
  duration_formatted: string | null;
  records_processed: number;
  records_created: number;
  records_updated: number;
  error_message: string | null;
  successful: boolean;
}

interface Plugin {
  plugin_name: string;
  plugin_version: string;
  plugin_description: string;
  enabled: boolean;
  configured: boolean;
}

interface Stats {
  total_syncs: number;
  successful_syncs: number;
  failed_syncs: number;
  success_rate: number;
  average_duration: number | null;
  total_records_processed: number;
}

interface PageProps {
  plugin: Plugin;
  sync_histories: SyncHistory[];
  stats: Stats;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

function getStatusBadgeClass(status: string): string {
  switch (status) {
    case "completed":
      return "bg-green-100 text-green-700";
    case "failed":
      return "bg-red-100 text-red-700";
    case "running":
      return "bg-blue-100 text-blue-700";
    case "pending":
      return "bg-amber-100 text-amber-700";
    default:
      return "bg-stone-100 text-stone-600";
  }
}

function formatDate(dateString: string | null): string {
  if (!dateString) return "-";
  const date = new Date(dateString);
  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatDuration(seconds: number | null): string {
  if (!seconds) return "-";
  if (seconds < 60) return `${seconds.toFixed(1)}s`;
  const minutes = Math.floor(seconds / 60);
  const secs = Math.round(seconds % 60);
  return `${minutes}m ${secs}s`;
}

function StatCard({
  label,
  value,
  subValue,
}: {
  label: string;
  value: string | number;
  subValue?: string;
}) {
  return (
    <div className="bg-white rounded-xl border border-stone-200 p-4">
      <p className="text-sm text-stone-500 mb-1">{label}</p>
      <p className="text-2xl font-semibold text-stone-900">{value}</p>
      {subValue && <p className="text-xs text-stone-500 mt-1">{subValue}</p>}
    </div>
  );
}

export default function PluginsHistory() {
  const { plugin, sync_histories, stats, flash } = usePage<PageProps>().props;
  const { t } = useTranslation();

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleViewDetails = (syncId: number) => {
    router.visit(`/plugins/${plugin.plugin_name}/sync/${syncId}`);
  };

  return (
    <>
      <Head
        title={t("pages.plugins.history.title", { name: plugin.plugin_name })}
      />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
        {/* Header */}
        <div className="mb-6 sm:mb-8">
          <Link
            href="/plugins"
            className="inline-flex items-center gap-1 text-sm text-stone-500 hover:text-stone-700 mb-4"
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
            {t("pages.plugins.history.backToPlugins")}
          </Link>
          <h1 className="text-2xl font-semibold text-stone-900">
            {t("pages.plugins.history.title", { name: plugin.plugin_name })}
          </h1>
          <p className="text-stone-500 mt-1">
            {t("pages.plugins.history.subtitle")}
          </p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <StatCard
            label={t("pages.plugins.history.stats.totalSyncs")}
            value={stats.total_syncs}
            subValue={`${stats.successful_syncs} successful, ${stats.failed_syncs} failed`}
          />
          <StatCard
            label={t("pages.plugins.history.stats.successRate")}
            value={`${stats.success_rate.toFixed(1)}%`}
          />
          <StatCard
            label={t("pages.plugins.history.stats.averageDuration")}
            value={formatDuration(stats.average_duration)}
          />
          <StatCard
            label={t("pages.plugins.history.stats.recordsProcessed")}
            value={stats.total_records_processed.toLocaleString()}
          />
        </div>

        {/* History Table */}
        {sync_histories.length === 0 ? (
          <div className="bg-white rounded-xl border border-stone-200 p-8 text-center">
            <div className="w-12 h-12 mx-auto mb-4 bg-stone-100 rounded-lg flex items-center justify-center">
              <svg
                className="w-6 h-6 text-stone-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="1.5"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <h3 className="font-medium text-stone-900 mb-1">
              {t("pages.plugins.history.noHistory")}
            </h3>
            <p className="text-sm text-stone-500">
              {t("pages.plugins.history.noHistoryDescription")}
            </p>
          </div>
        ) : (
          <div className="bg-white rounded-xl border border-stone-200 overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="text-left text-sm text-stone-500 border-b border-stone-200">
                  <TableHead className="px-6 py-4 font-medium">
                    {t("pages.plugins.history.table.date")}
                  </TableHead>
                  <TableHead className="px-6 py-4 font-medium">
                    {t("pages.plugins.history.table.status")}
                  </TableHead>
                  <TableHead className="px-6 py-4 font-medium text-right">
                    {t("pages.plugins.history.table.duration")}
                  </TableHead>
                  <TableHead className="px-6 py-4 font-medium text-right">
                    {t("pages.plugins.history.table.records")}
                  </TableHead>
                  <TableHead className="hidden md:table-cell px-6 py-4 font-medium">
                    {t("pages.plugins.history.table.error")}
                  </TableHead>
                  <TableHead className="px-6 py-4 font-medium">
                    {t("pages.plugins.history.table.actions")}
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sync_histories.map((history) => (
                  <TableRow
                    key={history.id}
                    className="border-b border-stone-100 hover:bg-stone-50 transition-colors"
                  >
                    <TableCell className="px-6 py-4 text-stone-900">
                      {formatDate(history.started_at)}
                    </TableCell>
                    <TableCell className="px-6 py-4">
                      <span
                        className={`px-2 py-1 rounded text-xs font-medium ${getStatusBadgeClass(
                          history.status
                        )}`}
                      >
                        {history.status}
                      </span>
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right text-stone-600 tabular-nums">
                      {history.duration_formatted || "-"}
                    </TableCell>
                    <TableCell className="px-6 py-4 text-right">
                      <span className="text-stone-900 font-medium">
                        {history.records_processed}
                      </span>
                      {history.records_created > 0 && (
                        <span className="text-green-600 ml-2 text-sm">
                          +{history.records_created}
                        </span>
                      )}
                      {history.records_updated > 0 && (
                        <span className="text-blue-600 ml-1 text-sm">
                          ~{history.records_updated}
                        </span>
                      )}
                    </TableCell>
                    <TableCell className="hidden md:table-cell px-6 py-4 text-stone-500 max-w-xs truncate">
                      {history.error_message || "-"}
                    </TableCell>
                    <TableCell className="px-6 py-4">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleViewDetails(history.id)}
                        className="text-stone-600"
                      >
                        {t("pages.plugins.history.viewDetails")}
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>
    </>
  );
}
