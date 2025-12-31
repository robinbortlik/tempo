import { router } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
  const [isSubmitting, setIsSubmitting] = useState(false);

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
      <form onSubmit={handleSubmit} className="flex items-end gap-4">
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
      </form>
    </div>
  );
}
