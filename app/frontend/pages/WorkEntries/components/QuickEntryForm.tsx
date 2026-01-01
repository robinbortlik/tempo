import { router } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { InputWithAddon } from "@/components/ui/input-with-addon";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { getCurrencySymbol, isSymbolAfter } from "@/components/CurrencyDisplay";
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

  // Get the selected project's client group
  const getSelectedClientGroup = (): ClientGroup | null => {
    if (!projectId) return null;
    const pid = parseInt(projectId);
    for (const group of projects) {
      const project = group.projects.find((p) => p.id === pid);
      if (project) return group;
    }
    return null;
  };

  const selectedClientGroup = getSelectedClientGroup();
  const selectedProjectRate = selectedClientGroup
    ? (selectedClientGroup.projects.find((p) => p.id === parseInt(projectId))
        ?.effective_hourly_rate ?? null)
    : null;
  const clientCurrency = selectedClientGroup?.client.currency;
  const selectedCurrency = getCurrencySymbol(clientCurrency);
  const currencyAfter = isSymbolAfter(clientCurrency);
  const hasCustomRate = hourlyRate !== "";
  const displayRate = hasCustomRate
    ? parseFloat(hourlyRate)
    : selectedProjectRate;

  // Calculate amount from hours and rate (returns integer)
  const calculateAmount = (
    hoursValue: string,
    rateValue: number | null
  ): string => {
    const h = parseFloat(hoursValue);
    if (!isNaN(h) && h > 0 && rateValue && rateValue > 0) {
      return Math.round(h * rateValue).toString();
    }
    return "";
  };

  // Handle hours change - recalculate amount
  const handleHoursChange = (value: string) => {
    setHours(value);
    const rate = hasCustomRate ? parseFloat(hourlyRate) : selectedProjectRate;
    setAmount(calculateAmount(value, rate));
  };

  // Handle hourly rate change - recalculate amount
  const handleRateChange = (value: string) => {
    setHourlyRate(value);
    const rate = parseFloat(value);
    if (!isNaN(rate)) {
      setAmount(calculateAmount(hours, rate));
    }
  };

  // Handle project change - recalculate amount with new project's rate
  const handleProjectChange = (value: string) => {
    setProjectId(value);
    // Only recalculate if not using custom rate and hours are entered
    if (!hasCustomRate && hours) {
      const pid = parseInt(value);
      for (const group of projects) {
        const project = group.projects.find((p) => p.id === pid);
        if (project) {
          setAmount(calculateAmount(hours, project.effective_hourly_rate));
          break;
        }
      }
    }
  };

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
    <div className="bg-white rounded-xl border border-stone-200 border-l-4 border-l-emerald-500 p-6 mb-6">
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
              onChange={handleProjectChange}
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
              onChange={(e) => handleHoursChange(e.target.value)}
              className="h-10 bg-stone-50 border-stone-200 rounded-lg tabular-nums"
              placeholder="8"
            />
          </div>
          <div className="w-32">
            <label
              htmlFor="Amount"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              Amount
            </label>
            <InputWithAddon
              id="Amount"
              name="Amount"
              type="number"
              step="1"
              min="0"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              startAddon={currencyAfter ? undefined : selectedCurrency}
              endAddon={currencyAfter ? selectedCurrency : undefined}
              className="h-10 bg-stone-50 border-stone-200 tabular-nums"
              placeholder="500"
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
              <span>
                Rate: {selectedCurrency}
                {displayRate}/h
              </span>
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
                  <InputWithAddon
                    id="hourly_rate"
                    type="number"
                    step="1"
                    min="1"
                    required
                    value={hourlyRate || selectedProjectRate?.toString() || ""}
                    onChange={(e) => handleRateChange(e.target.value)}
                    startAddon={currencyAfter ? undefined : selectedCurrency}
                    endAddon={currencyAfter ? selectedCurrency : undefined}
                    className="w-24 h-10 bg-stone-50 border-stone-200 tabular-nums"
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
