import { router } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";

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
  id: number | null;
  date: string;
  hours: number | null;
  amount: number | null;
  entry_type: string;
  description: string;
  project_id: number | null;
  hourly_rate: number | null;
  status: "unbilled" | "invoiced";
  effective_hourly_rate: number | null;
}

interface WorkEntryFormProps {
  workEntry: WorkEntry;
  projects: ClientGroup[];
  preselectedProjectId?: number | null;
}

export default function WorkEntryForm({
  workEntry,
  projects,
  preselectedProjectId,
}: WorkEntryFormProps) {
  const today = new Date().toISOString().split("T")[0];
  const isEditing = workEntry.id !== null;

  const [formData, setFormData] = useState({
    date: workEntry.date || today,
    project_id: (preselectedProjectId || workEntry.project_id || "").toString(),
    hours: workEntry.hours?.toString() || "",
    amount: workEntry.amount?.toString() || "",
    description: workEntry.description || "",
    hourly_rate: workEntry.hourly_rate?.toString() || "",
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showRateOverride, setShowRateOverride] = useState(false);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    const entryData = {
      date: formData.date,
      project_id: parseInt(formData.project_id),
      description: formData.description,
      hours: formData.hours ? parseFloat(formData.hours) : null,
      amount: formData.amount ? parseFloat(formData.amount) : null,
      hourly_rate: formData.hourly_rate
        ? parseFloat(formData.hourly_rate)
        : null,
    };

    if (isEditing) {
      router.patch(
        `/work_entries/${workEntry.id}`,
        { work_entry: entryData },
        {
          onFinish: () => setIsSubmitting(false),
        }
      );
    } else {
      router.post(
        "/work_entries",
        { work_entry: entryData },
        {
          onFinish: () => setIsSubmitting(false),
        }
      );
    }
  };

  // Valid if date, project selected, and at least one of hours or amount is filled
  const hasHours = formData.hours && parseFloat(formData.hours) > 0;
  const hasAmount = formData.amount && parseFloat(formData.amount) > 0;
  const isValid =
    formData.date && formData.project_id && (hasHours || hasAmount);

  // Get the selected project's effective hourly rate
  const getSelectedProjectRate = (): number | null => {
    if (!formData.project_id) return null;
    const projectId = parseInt(formData.project_id);
    for (const group of projects) {
      const project = group.projects.find((p) => p.id === projectId);
      if (project) return project.effective_hourly_rate;
    }
    return null;
  };

  const selectedProjectRate = getSelectedProjectRate();
  const isInvoiced = workEntry.status === "invoiced";
  const hasCustomRate = formData.hourly_rate !== "";
  const displayRate = hasCustomRate
    ? parseFloat(formData.hourly_rate)
    : selectedProjectRate;

  return (
    <div className="bg-white rounded-xl border border-stone-200 p-6 max-w-2xl">
      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label
              htmlFor="date"
              className="block text-sm font-medium text-stone-700 mb-1.5"
            >
              Date <span className="text-red-500">*</span>
            </label>
            <input
              id="date"
              type="date"
              value={formData.date}
              onChange={(e) =>
                setFormData({ ...formData, date: e.target.value })
              }
              required
              className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg text-stone-900"
            />
          </div>

          <div>
            <label
              htmlFor="project"
              className="block text-sm font-medium text-stone-700 mb-1.5"
            >
              Project <span className="text-red-500">*</span>
            </label>
            <select
              id="project"
              value={formData.project_id}
              onChange={(e) =>
                setFormData({ ...formData, project_id: e.target.value })
              }
              required
              className="w-full px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg text-stone-900"
            >
              <option value="">Select a project</option>
              {projects.map((group) => (
                <optgroup key={group.client.id} label={group.client.name}>
                  {group.projects.map((project) => (
                    <option key={project.id} value={project.id}>
                      {project.name}
                    </option>
                  ))}
                </optgroup>
              ))}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label
              htmlFor="hours"
              className="block text-sm font-medium text-stone-700 mb-1.5"
            >
              Hours
            </label>
            <Input
              id="hours"
              type="number"
              step="0.25"
              min="0"
              max="24"
              value={formData.hours}
              onChange={(e) =>
                setFormData({ ...formData, hours: e.target.value })
              }
              className="w-full px-3 py-2 bg-stone-50 border-stone-200 rounded-lg text-stone-900 tabular-nums"
              placeholder="e.g., 8"
            />
            <p className="text-xs text-stone-500 mt-1">
              Fill hours for time-based entries
            </p>
          </div>

          <div>
            <label
              htmlFor="amount"
              className="block text-sm font-medium text-stone-700 mb-1.5"
            >
              Amount
            </label>
            <Input
              id="amount"
              type="number"
              step="0.01"
              min="0"
              value={formData.amount}
              onChange={(e) =>
                setFormData({ ...formData, amount: e.target.value })
              }
              className="w-full px-3 py-2 bg-stone-50 border-stone-200 rounded-lg text-stone-900 tabular-nums"
              placeholder="e.g., 500"
            />
            <p className="text-xs text-stone-500 mt-1">
              Fill amount for fixed-price entries (or to override calculated
              amount)
            </p>
          </div>
        </div>

        {hasHours && (
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
                Rate: ${displayRate}/h{" "}
                {hasCustomRate ? "(custom)" : "(from project)"}
              </span>
            </CollapsibleTrigger>
            <CollapsibleContent className="pt-3">
              <div>
                <label
                  htmlFor="hourly_rate"
                  className="block text-sm font-medium text-stone-700 mb-1.5"
                >
                  Hourly Rate Override
                </label>
                <Input
                  id="hourly_rate"
                  type="number"
                  step="0.01"
                  min="0"
                  value={formData.hourly_rate}
                  onChange={(e) =>
                    setFormData({ ...formData, hourly_rate: e.target.value })
                  }
                  disabled={isInvoiced}
                  className="w-full max-w-xs px-3 py-2 bg-stone-50 border-stone-200 rounded-lg text-stone-900 tabular-nums disabled:opacity-50 disabled:cursor-not-allowed"
                  placeholder={selectedProjectRate?.toString() || ""}
                />
                <p className="text-xs text-stone-500 mt-1">
                  {isInvoiced
                    ? "Rate cannot be changed on invoiced entries"
                    : "Clear this field to use the project rate"}
                </p>
              </div>
            </CollapsibleContent>
          </Collapsible>
        )}

        <p className="text-sm text-stone-600 bg-stone-50 p-3 rounded-lg">
          At least one of Hours or Amount must be filled. Hours only = time
          entry. Amount only = fixed entry. Both = time entry with custom
          pricing.
        </p>

        <div>
          <label
            htmlFor="description"
            className="block text-sm font-medium text-stone-700 mb-1.5"
          >
            Description
          </label>
          <Textarea
            id="description"
            value={formData.description}
            onChange={(e) =>
              setFormData({ ...formData, description: e.target.value })
            }
            rows={3}
            className="w-full px-3 py-2 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
            placeholder="What did you work on?"
          />
        </div>

        <div className="flex items-center gap-3 pt-4 border-t border-stone-200">
          <Button
            type="submit"
            disabled={!isValid || isSubmitting}
            className="px-6 py-2 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors disabled:opacity-50"
          >
            {isSubmitting
              ? isEditing
                ? "Saving..."
                : "Creating..."
              : isEditing
                ? "Save Changes"
                : "Create Entry"}
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => router.visit("/work_entries")}
            className="px-6 py-2 border border-stone-200 text-stone-600 font-medium rounded-lg hover:bg-stone-50 transition-colors"
          >
            Cancel
          </Button>
        </div>
      </form>
    </div>
  );
}
