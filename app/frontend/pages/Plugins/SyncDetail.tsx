import { Head, usePage, Link } from "@inertiajs/react";
import { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Toaster } from "@/components/ui/sonner";

interface AuditEntry {
  id: number;
  auditable_type: string;
  auditable_id: number;
  action: string;
  source: string;
  changes_made: Record<string, { from: unknown; to: unknown } | unknown>;
  description: string;
  created_at: string;
}

interface SyncHistory {
  id: number;
  plugin_name: string;
  status: string;
  started_at: string | null;
  completed_at: string | null;
  duration: number | null;
  duration_formatted: string | null;
  records_processed: number;
  records_created: number;
  records_updated: number;
  error_message: string | null;
  successful: boolean;
  audit_entries: AuditEntry[];
}

interface Plugin {
  plugin_name: string;
  plugin_version: string;
  plugin_description: string;
}

interface PageProps {
  plugin: Plugin;
  sync_history: SyncHistory;
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

function getActionBadgeClass(action: string): string {
  switch (action) {
    case "create":
      return "bg-green-100 text-green-700";
    case "update":
      return "bg-blue-100 text-blue-700";
    case "destroy":
      return "bg-red-100 text-red-700";
    default:
      return "bg-stone-100 text-stone-600";
  }
}

function formatDateTime(dateString: string | null): string {
  if (!dateString) return "-";
  const date = new Date(dateString);
  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function formatTime(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleTimeString(undefined, {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function SummaryItem({
  label,
  value,
  className = "",
}: {
  label: string;
  value: string | number;
  className?: string;
}) {
  return (
    <div className="flex justify-between items-center py-2 border-b border-stone-100 last:border-0">
      <span className="text-stone-500">{label}</span>
      <span className={`font-medium ${className}`}>{value}</span>
    </div>
  );
}

function AuditEntryCard({ entry }: { entry: AuditEntry }) {
  const { t } = useTranslation();

  const actionLabel =
    entry.action === "create"
      ? t("pages.plugins.syncDetail.auditEntry.created")
      : entry.action === "update"
        ? t("pages.plugins.syncDetail.auditEntry.updated")
        : t("pages.plugins.syncDetail.auditEntry.destroyed");

  return (
    <div className="border border-stone-200 rounded-lg p-4">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <span
            className={`px-2 py-0.5 rounded text-xs font-medium ${getActionBadgeClass(
              entry.action
            )}`}
          >
            {actionLabel}
          </span>
          <span className="text-stone-900 font-medium">
            {entry.auditable_type} #{entry.auditable_id}
          </span>
        </div>
        <span className="text-xs text-stone-500">
          {formatTime(entry.created_at)}
        </span>
      </div>

      {entry.changes_made && Object.keys(entry.changes_made).length > 0 && (
        <div className="mt-2 text-sm">
          {Object.entries(entry.changes_made).map(([key, value]) => {
            if (key === "final_state") {
              // For destroy actions, show final state
              return (
                <div key={key} className="text-stone-500 text-xs mt-1">
                  Final state preserved
                </div>
              );
            }

            const change = value as { from: unknown; to: unknown };
            return (
              <div key={key} className="flex items-center gap-2 text-stone-600">
                <span className="font-mono text-xs bg-stone-100 px-1 rounded">
                  {key}
                </span>
                <span className="text-stone-400">:</span>
                <span className="text-red-600 line-through text-xs">
                  {String(change.from ?? "null")}
                </span>
                <span className="text-stone-400">-&gt;</span>
                <span className="text-green-600 text-xs">
                  {String(change.to ?? "null")}
                </span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default function PluginsSyncDetail() {
  const { plugin, sync_history, flash } = usePage<PageProps>().props;
  const { t } = useTranslation();

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  return (
    <>
      <Head title={t("pages.plugins.syncDetail.title")} />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
        {/* Header */}
        <div className="mb-6 sm:mb-8">
          <Link
            href={`/plugins/${plugin.plugin_name}/history`}
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
            {t("pages.plugins.syncDetail.backToHistory")}
          </Link>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-semibold text-stone-900">
              {t("pages.plugins.syncDetail.title")}
            </h1>
            <span
              className={`px-2 py-1 rounded text-sm font-medium ${getStatusBadgeClass(
                sync_history.status
              )}`}
            >
              {sync_history.status}
            </span>
          </div>
          <p className="text-stone-500 mt-1">
            {plugin.plugin_name} - Sync #{sync_history.id}
          </p>
        </div>

        <div className="max-w-3xl space-y-6">
          {/* Summary Section */}
          <div className="bg-white rounded-xl border border-stone-200 p-6">
            <h3 className="font-semibold text-stone-900 mb-4">
              {t("pages.plugins.syncDetail.summary")}
            </h3>

            <div className="space-y-1">
              <SummaryItem
                label={t("pages.plugins.syncDetail.startedAt")}
                value={formatDateTime(sync_history.started_at)}
              />
              <SummaryItem
                label={t("pages.plugins.syncDetail.completedAt")}
                value={formatDateTime(sync_history.completed_at)}
              />
              <SummaryItem
                label={t("pages.plugins.syncDetail.duration")}
                value={sync_history.duration_formatted || "-"}
              />
              <SummaryItem
                label={t("pages.plugins.syncDetail.recordsProcessed")}
                value={sync_history.records_processed}
              />
              <SummaryItem
                label={t("pages.plugins.syncDetail.recordsCreated")}
                value={sync_history.records_created}
                className="text-green-600"
              />
              <SummaryItem
                label={t("pages.plugins.syncDetail.recordsUpdated")}
                value={sync_history.records_updated}
                className="text-blue-600"
              />
            </div>

            {sync_history.error_message && (
              <div className="mt-4 p-3 bg-red-50 rounded-lg">
                <p className="text-sm font-medium text-red-800 mb-1">Error</p>
                <p className="text-sm text-red-700 font-mono">
                  {sync_history.error_message}
                </p>
              </div>
            )}
          </div>

          {/* Audit Trail Section */}
          <div className="bg-white rounded-xl border border-stone-200 p-6">
            <h3 className="font-semibold text-stone-900 mb-4">
              {t("pages.plugins.syncDetail.auditTrail")}
              {sync_history.audit_entries.length > 0 && (
                <span className="ml-2 text-sm font-normal text-stone-500">
                  ({sync_history.audit_entries.length} changes)
                </span>
              )}
            </h3>

            {sync_history.audit_entries.length === 0 ? (
              <p className="text-stone-500 text-sm py-4">
                {t("pages.plugins.syncDetail.noChanges")}
              </p>
            ) : (
              <div className="space-y-3">
                {sync_history.audit_entries.map((entry) => (
                  <AuditEntryCard key={entry.id} entry={entry} />
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
