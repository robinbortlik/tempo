import { router } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { useTranslation } from "react-i18next";
import i18n from "@/lib/i18n";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { InputWithAddon } from "@/components/ui/input-with-addon";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  formatCurrency,
  formatHours,
  getCurrencySymbol,
  isSymbolAfter,
} from "@/components/CurrencyDisplay";
import ProjectSelector from "./ProjectSelector";

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

interface WorkEntryRowProps {
  entry: WorkEntry;
  projects: ClientGroup[];
  onDelete: (id: number) => void;
  isFirst?: boolean;
  isLast?: boolean;
  showDate?: boolean;
}

function formatShortDate(
  dateStr: string,
  locale: string
): { isToday: boolean; isYesterday: boolean; formatted: string } {
  const date = new Date(dateStr);
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const localeMap: Record<string, string> = { en: "en-US", cs: "cs-CZ" };
  const dateLocale = localeMap[locale] || "en-US";

  const isToday = date.toDateString() === today.toDateString();
  const isYesterday = date.toDateString() === yesterday.toDateString();
  const formatted = date.toLocaleDateString(dateLocale, {
    month: "short",
    day: "numeric",
  });

  return { isToday, isYesterday, formatted };
}

export default function WorkEntryRow({
  entry,
  projects,
  onDelete,
  isFirst = false,
  isLast = false,
  showDate = false,
}: WorkEntryRowProps) {
  const { t } = useTranslation();
  const [isEditing, setIsEditing] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showRateOverride, setShowRateOverride] = useState(false);
  const [editData, setEditData] = useState({
    date: entry.date,
    project_id: entry.project_id.toString(),
    hours: entry.hours?.toString() || "",
    amount:
      entry.amount?.toString() ||
      (entry.entry_type === "time" && entry.calculated_amount
        ? entry.calculated_amount.toString()
        : ""),
    description: entry.description || "",
    hourly_rate: entry.hourly_rate?.toString() || "",
  });

  const isInvoiced = entry.status === "invoiced";
  const isTimeEntry = entry.entry_type === "time";

  // Get the selected project's client group
  const getSelectedClientGroup = (): ClientGroup | null => {
    if (!editData.project_id) return null;
    const pid = parseInt(editData.project_id);
    for (const group of projects) {
      const project = group.projects.find((p) => p.id === pid);
      if (project) return group;
    }
    return null;
  };

  const selectedClientGroup = getSelectedClientGroup();
  const selectedProjectRate = selectedClientGroup
    ? (selectedClientGroup.projects.find(
        (p) => p.id === parseInt(editData.project_id)
      )?.effective_hourly_rate ?? null)
    : null;
  const clientCurrency = selectedClientGroup?.client.currency;
  const selectedCurrency = getCurrencySymbol(clientCurrency);
  const currencyAfter = isSymbolAfter(clientCurrency);
  const hasCustomRate = editData.hourly_rate !== "";
  const displayRate = hasCustomRate
    ? parseFloat(editData.hourly_rate)
    : selectedProjectRate;

  const handleSave = (e: FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    router.patch(
      `/work_entries/${entry.id}`,
      {
        work_entry: {
          date: editData.date,
          project_id: parseInt(editData.project_id),
          description: editData.description,
          hours: editData.hours ? parseFloat(editData.hours) : null,
          amount: editData.amount ? parseFloat(editData.amount) : null,
          hourly_rate: editData.hours
            ? parseFloat(
                editData.hourly_rate || selectedProjectRate?.toString() || "0"
              )
            : null,
        },
      },
      {
        onSuccess: () => {
          setIsEditing(false);
          setShowRateOverride(false);
        },
        onFinish: () => {
          setIsSubmitting(false);
        },
      }
    );
  };

  const handleCancel = () => {
    setEditData({
      date: entry.date,
      project_id: entry.project_id.toString(),
      hours: entry.hours?.toString() || "",
      amount: entry.amount?.toString() || "",
      description: entry.description || "",
      hourly_rate: entry.hourly_rate?.toString() || "",
    });
    setIsEditing(false);
    setShowRateOverride(false);
  };

  // Validation: at least hours or amount must be provided
  const hasHours = editData.hours && parseFloat(editData.hours) > 0;
  const hasAmount = editData.amount && parseFloat(editData.amount) > 0;
  const isValid = hasHours || hasAmount;

  if (isEditing) {
    return (
      <form
        onSubmit={handleSave}
        className={`
          px-5 py-4 bg-amber-50/50 border border-amber-200/50 space-y-3
          ${isFirst ? "rounded-t-xl" : ""}
          ${isLast ? "rounded-b-xl" : ""}
        `}
        data-testid={`work-entry-row-${entry.id}`}
      >
        <div className="flex items-center gap-4">
          <div className="w-32">
            <input
              type="date"
              value={editData.date}
              onChange={(e) =>
                setEditData({ ...editData, date: e.target.value })
              }
              required
              className="w-full px-3 py-2 bg-white border border-stone-200 rounded-lg text-stone-900 text-sm focus:outline-none focus:ring-2 focus:ring-stone-900/10 focus:border-stone-400 transition-all"
            />
          </div>
          <div className="w-44">
            <ProjectSelector
              projects={projects}
              value={editData.project_id}
              onChange={(value) =>
                setEditData({ ...editData, project_id: value })
              }
              required
              className="w-full text-sm py-2"
            />
          </div>
          <div className="w-20">
            <Input
              type="number"
              step="0.25"
              min="0"
              max="24"
              value={editData.hours}
              onChange={(e) =>
                setEditData({ ...editData, hours: e.target.value })
              }
              className="w-full px-3 py-2 bg-white border-stone-200 rounded-lg text-stone-900 tabular-nums text-sm"
              placeholder="Hours"
            />
          </div>
          <div className="w-28">
            <InputWithAddon
              type="number"
              step="1"
              min="0"
              value={editData.amount}
              onChange={(e) =>
                setEditData({ ...editData, amount: e.target.value })
              }
              startAddon={currencyAfter ? undefined : selectedCurrency}
              endAddon={currencyAfter ? selectedCurrency : undefined}
              className="w-full px-3 py-2 bg-white border-stone-200 text-stone-900 tabular-nums text-sm"
              placeholder="500"
            />
          </div>
          <div className="flex-1">
            <Input
              type="text"
              value={editData.description}
              onChange={(e) =>
                setEditData({ ...editData, description: e.target.value })
              }
              className="w-full px-3 py-2 bg-white border-stone-200 rounded-lg text-stone-900 text-sm"
              placeholder="What did you work on?"
            />
          </div>
          <div className="flex items-center gap-2">
            <Button
              type="submit"
              disabled={isSubmitting || !isValid}
              className="px-4 py-2 bg-stone-900 text-white text-sm font-medium rounded-lg hover:bg-stone-800 transition-colors"
            >
              {isSubmitting ? "Saving..." : "Save"}
            </Button>
            <Button
              type="button"
              variant="outline"
              onClick={handleCancel}
              disabled={isSubmitting}
              className="px-4 py-2 border border-stone-200 text-stone-600 text-sm font-medium rounded-lg hover:bg-stone-50 transition-colors"
            >
              Cancel
            </Button>
          </div>
        </div>

        {hasHours && editData.project_id && (
          <Collapsible
            open={showRateOverride}
            onOpenChange={setShowRateOverride}
          >
            <CollapsibleTrigger className="flex items-center gap-2 text-sm text-stone-600 hover:text-stone-900 transition-colors cursor-pointer">
              <svg
                className={`w-4 h-4 transition-transform ${showRateOverride ? "rotate-90" : ""}`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M9 5l7 7-7 7"
                />
              </svg>
              <span>
                Rate: {selectedCurrency}
                {displayRate}/h
              </span>
            </CollapsibleTrigger>
            <CollapsibleContent className="pt-3">
              <div className="flex items-end gap-3">
                <div>
                  <label
                    htmlFor={`hourly_rate_${entry.id}`}
                    className="block text-sm font-medium text-stone-600 mb-1.5"
                  >
                    Hourly Rate
                  </label>
                  <InputWithAddon
                    id={`hourly_rate_${entry.id}`}
                    type="number"
                    step="1"
                    min="1"
                    required
                    value={
                      editData.hourly_rate ||
                      selectedProjectRate?.toString() ||
                      ""
                    }
                    onChange={(e) =>
                      setEditData({ ...editData, hourly_rate: e.target.value })
                    }
                    disabled={isInvoiced}
                    startAddon={currencyAfter ? undefined : selectedCurrency}
                    endAddon={currencyAfter ? selectedCurrency : undefined}
                    className="w-24 px-3 py-2 bg-white border-stone-200 tabular-nums text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                  />
                </div>
                {isInvoiced && (
                  <p className="text-xs text-stone-500 pb-2">
                    Rate locked on invoiced entries
                  </p>
                )}
              </div>
            </CollapsibleContent>
          </Collapsible>
        )}
      </form>
    );
  }

  return (
    <div
      className={`
        group/row relative
        transition-colors duration-150
        hover:bg-stone-50
        ${isInvoiced ? "bg-stone-50/50" : "bg-white"}
      `}
      data-testid={`work-entry-row-${entry.id}`}
    >
      {/* Desktop Layout */}
      <div className="hidden md:flex items-center px-4 py-3 gap-4">
        {/* Date (when showDate is true) */}
        {showDate && (
          <div className="w-16 shrink-0">
            <span className="text-sm font-medium text-stone-500 tabular-nums">
              {(() => {
                const { isToday, isYesterday, formatted } = formatShortDate(
                  entry.date,
                  i18n.language
                );
                if (isToday) return t("common.today");
                if (isYesterday) return t("common.yesterday");
                return formatted;
              })()}
            </span>
          </div>
        )}

        {/* Left section: Project and description */}
        <div className="flex-1 min-w-0 flex items-center gap-3">
          {/* Project info */}
          <div className="flex items-center gap-1.5 shrink-0">
            <span
              className={`text-xs font-medium uppercase tracking-wide ${isInvoiced ? "text-stone-400" : "text-stone-500"}`}
            >
              {entry.client_name}
            </span>
            <span
              className={`text-xs ${isInvoiced ? "text-stone-300" : "text-stone-400"}`}
            >
              /
            </span>
            <span
              className={`text-sm font-medium ${isInvoiced ? "text-stone-500" : "text-stone-700"}`}
            >
              {entry.project_name}
            </span>
          </div>

          {/* Description */}
          {entry.description && (
            <>
              <span className="text-stone-300">—</span>
              <span
                className={`text-sm truncate ${isInvoiced ? "text-stone-500" : "text-stone-600"}`}
              >
                {entry.description}
              </span>
            </>
          )}
        </div>

        {/* Right section: Hours, Rate, Total, Status, Actions */}
        <div className="flex items-center gap-4 shrink-0">
          {/* Calculation breakdown */}
          <div
            className={`flex items-center gap-2 text-sm tabular-nums ${isInvoiced ? "text-stone-500" : "text-stone-700"}`}
          >
            {isTimeEntry ? (
              <>
                <span className="font-semibold">
                  {formatHours(entry.hours)}
                  {t("common.hoursShort")}
                </span>
                <span className="text-stone-400">×</span>
                <span>
                  {formatCurrency(
                    entry.hourly_rate || 0,
                    entry.client_currency,
                    false
                  )}
                  /{t("common.hoursShort")}
                </span>
                <span className="text-stone-400">=</span>
                <span className="font-semibold min-w-[80px] text-right">
                  {formatCurrency(
                    entry.calculated_amount,
                    entry.client_currency,
                    false
                  )}
                </span>
              </>
            ) : (
              <span className="font-semibold">
                {formatCurrency(
                  entry.calculated_amount,
                  entry.client_currency,
                  false
                )}
              </span>
            )}
          </div>

          {/* Status badge - compact */}
          {isInvoiced ? (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium bg-emerald-50 text-emerald-700">
              <svg
                className="w-3 h-3"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M5 13l4 4L19 7"
                />
              </svg>
              {t("pages.workEntries.status.invoiced")}
            </span>
          ) : (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium bg-amber-50 text-amber-700">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              {t("pages.workEntries.status.unbilled")}
            </span>
          )}

          {/* Actions */}
          <div
            className={`
              flex items-center gap-0.5
              transition-opacity duration-150
              ${isInvoiced ? "opacity-0 pointer-events-none" : "opacity-0 group-hover/row:opacity-100"}
            `}
          >
            <button
              type="button"
              onClick={() => setIsEditing(true)}
              className="p-1.5 text-stone-400 hover:text-stone-700 hover:bg-stone-100 rounded transition-colors"
              title="Edit entry"
              data-testid={`edit-entry-${entry.id}`}
            >
              <svg
                className="w-3.5 h-3.5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10"
                />
              </svg>
            </button>
            <button
              type="button"
              onClick={() => onDelete(entry.id)}
              className="p-1.5 text-stone-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
              title="Delete entry"
              data-testid={`delete-entry-${entry.id}`}
            >
              <svg
                className="w-3.5 h-3.5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
                />
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Layout */}
      <div className="flex md:hidden flex-col px-4 py-3 gap-2">
        {/* Row 1: Project and description */}
        <div className="flex items-center justify-between gap-2">
          <div className="flex-1 min-w-0 flex items-center gap-2">
            {/* Project info */}
            <div className="flex items-center gap-1 shrink-0">
              <span
                className={`text-xs font-medium uppercase tracking-wide ${isInvoiced ? "text-stone-400" : "text-stone-500"}`}
              >
                {entry.client_name}
              </span>
              <span
                className={`text-xs ${isInvoiced ? "text-stone-300" : "text-stone-400"}`}
              >
                /
              </span>
              <span
                className={`text-sm font-medium ${isInvoiced ? "text-stone-500" : "text-stone-700"}`}
              >
                {entry.project_name}
              </span>
            </div>
          </div>

          {/* Actions - always visible on mobile for touch */}
          {!isInvoiced && (
            <div className="flex items-center gap-1 shrink-0">
              <button
                type="button"
                onClick={() => setIsEditing(true)}
                className="p-2.5 min-h-11 min-w-11 flex items-center justify-center text-stone-400 hover:text-stone-700 hover:bg-stone-100 rounded transition-colors"
                title="Edit entry"
                data-testid={`edit-entry-${entry.id}`}
              >
                <svg
                  className="w-4 h-4"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  strokeWidth={1.5}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10"
                  />
                </svg>
              </button>
              <button
                type="button"
                onClick={() => onDelete(entry.id)}
                className="p-2.5 min-h-11 min-w-11 flex items-center justify-center text-stone-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
                title="Delete entry"
                data-testid={`delete-entry-${entry.id}`}
              >
                <svg
                  className="w-4 h-4"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  strokeWidth={1.5}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
                  />
                </svg>
              </button>
            </div>
          )}
        </div>

        {/* Description on its own line if present */}
        {entry.description && (
          <p
            className={`text-sm truncate ${isInvoiced ? "text-stone-500" : "text-stone-600"}`}
          >
            {entry.description}
          </p>
        )}

        {/* Row 2: Date, hours/amount, status */}
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-3">
            {/* Date */}
            {showDate && (
              <span className="text-sm font-medium text-stone-500 tabular-nums">
                {formatShortDate(entry.date)}
              </span>
            )}

            {/* Hours and amount */}
            <div
              className={`flex items-center gap-1.5 text-sm tabular-nums ${isInvoiced ? "text-stone-500" : "text-stone-700"}`}
            >
              {isTimeEntry ? (
                <>
                  <span className="font-semibold">
                    {formatHours(entry.hours)}h
                  </span>
                  <span className="text-stone-400">=</span>
                  <span className="font-semibold">
                    {formatCurrency(
                      entry.calculated_amount,
                      entry.client_currency,
                      false
                    )}
                  </span>
                </>
              ) : (
                <span className="font-semibold">
                  {formatCurrency(
                    entry.calculated_amount,
                    entry.client_currency,
                    false
                  )}
                </span>
              )}
            </div>
          </div>

          {/* Status badge */}
          {isInvoiced ? (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium bg-emerald-50 text-emerald-700">
              <svg
                className="w-3 h-3"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M5 13l4 4L19 7"
                />
              </svg>
              Invoiced
            </span>
          ) : (
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium bg-amber-50 text-amber-700">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
              Unbilled
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
