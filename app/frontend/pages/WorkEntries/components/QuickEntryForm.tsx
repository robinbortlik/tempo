import { router } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
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

interface QuickEntryFormProps {
  projects: ClientGroup[];
}

export default function QuickEntryForm({ projects }: QuickEntryFormProps) {
  const today = new Date().toISOString().split("T")[0];
  const [date, setDate] = useState(today);
  const [projectId, setProjectId] = useState("");
  const [hours, setHours] = useState("");
  const [amount, setAmount] = useState("");
  const [description, setDescription] = useState("");
  const [hourlyRate, setHourlyRate] = useState("");
  const [showRateOverride, setShowRateOverride] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Get the selected project's effective hourly rate
  const getSelectedProjectRate = (): number | null => {
    if (!projectId) return null;
    const pid = parseInt(projectId);
    for (const group of projects) {
      const project = group.projects.find((p) => p.id === pid);
      if (project) return project.effective_hourly_rate;
    }
    return null;
  };

  const selectedProjectRate = getSelectedProjectRate();
  const hasCustomRate = hourlyRate !== "";
  const displayRate = hasCustomRate
    ? parseFloat(hourlyRate)
    : selectedProjectRate;

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    router.post(
      "/work_entries",
      {
        work_entry: {
          date,
          project_id: parseInt(projectId),
          description,
          hours: hours ? parseFloat(hours) : null,
          amount: amount ? parseFloat(amount) : null,
          hourly_rate: hours
            ? parseFloat(hourlyRate || selectedProjectRate?.toString() || "0")
            : null,
        },
      },
      {
        onSuccess: () => {
          // Reset form on success
          setDate(today);
          setProjectId("");
          setHours("");
          setAmount("");
          setDescription("");
          setHourlyRate("");
          setShowRateOverride(false);
        },
        onFinish: () => {
          setIsSubmitting(false);
        },
      }
    );
  };

  // Valid if date, project selected, and at least one of hours or amount is filled
  const hasHours = hours && parseFloat(hours) > 0;
  const hasAmount = amount && parseFloat(amount) > 0;
  const isValid = date && projectId && (hasHours || hasAmount);

  return (
    <div className="bg-white rounded-xl border border-stone-200 p-6 mb-6">
      <h3 className="font-semibold text-stone-900 mb-4">Quick Entry</h3>
      <form onSubmit={handleSubmit} className="space-y-3">
        <div className="flex items-end gap-4">
          <div className="w-40">
            <label
              htmlFor="Date"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              Date
            </label>
            <input
              id="Date"
              name="Date"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              required
              className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
            />
          </div>
          <div className="w-64">
            <label
              htmlFor="Project"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              Project
            </label>
            <ProjectSelector
              id="Project"
              projects={projects}
              value={projectId}
              onChange={setProjectId}
              required
              className="w-full h-10"
            />
          </div>
          <div className="w-24">
            <label
              htmlFor="Hours"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              Hours
            </label>
            <Input
              id="Hours"
              name="Hours"
              type="number"
              step="0.25"
              min="0"
              max="24"
              value={hours}
              onChange={(e) => setHours(e.target.value)}
              className="h-10 bg-stone-50 border-stone-200 rounded-lg tabular-nums"
              placeholder="8"
            />
          </div>
          <div className="w-28">
            <label
              htmlFor="Amount"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              Amount
            </label>
            <Input
              id="Amount"
              name="Amount"
              type="number"
              step="0.01"
              min="0"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="h-10 bg-stone-50 border-stone-200 rounded-lg tabular-nums"
              placeholder="$500"
            />
          </div>
          <div className="flex-1">
            <label
              htmlFor="Description"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              Description
            </label>
            <Input
              id="Description"
              name="Description"
              type="text"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="h-10 bg-stone-50 border-stone-200 rounded-lg"
              placeholder="What did you work on?"
            />
          </div>
          <Button
            type="submit"
            disabled={!isValid || isSubmitting}
            className="h-10 px-6 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors disabled:opacity-50"
          >
            {isSubmitting ? "Adding..." : "Add Entry"}
          </Button>
        </div>

        {hasHours && projectId && (
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
              <span>Rate: ${displayRate}/h</span>
            </CollapsibleTrigger>
            <CollapsibleContent className="pt-3">
              <div className="flex items-end gap-3">
                <div>
                  <label
                    htmlFor="hourly_rate"
                    className="block text-sm font-medium text-stone-600 mb-1.5"
                  >
                    Hourly Rate
                  </label>
                  <Input
                    id="hourly_rate"
                    type="number"
                    step="0.01"
                    min="0.01"
                    required
                    value={hourlyRate || selectedProjectRate?.toString() || ""}
                    onChange={(e) => setHourlyRate(e.target.value)}
                    className="w-32 h-10 bg-stone-50 border-stone-200 rounded-lg tabular-nums"
                  />
                </div>
              </div>
            </CollapsibleContent>
          </Collapsible>
        )}
      </form>
    </div>
  );
}
