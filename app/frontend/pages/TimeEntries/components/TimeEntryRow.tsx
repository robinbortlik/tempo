import { router } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import StatusBadge from "./StatusBadge";
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

interface TimeEntryRowProps {
  entry: TimeEntry;
  projects: ClientGroup[];
  onDelete: (id: number) => void;
}

function formatHours(hours: number): string {
  // Display whole numbers without decimal, otherwise show one decimal
  return hours % 1 === 0 ? `${Math.floor(hours)}h` : `${hours.toFixed(1)}h`;
}

export default function TimeEntryRow({
  entry,
  projects,
  onDelete,
}: TimeEntryRowProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [editData, setEditData] = useState({
    date: entry.date,
    project_id: entry.project_id.toString(),
    hours: entry.hours.toString(),
    description: entry.description || "",
  });

  const isInvoiced = entry.status === "invoiced";

  const handleSave = (e: FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    router.patch(
      `/time_entries/${entry.id}`,
      {
        time_entry: {
          date: editData.date,
          project_id: parseInt(editData.project_id),
          hours: parseFloat(editData.hours),
          description: editData.description,
        },
      },
      {
        onSuccess: () => {
          setIsEditing(false);
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
      hours: entry.hours.toString(),
      description: entry.description || "",
    });
    setIsEditing(false);
  };

  if (isEditing) {
    return (
      <form
        onSubmit={handleSave}
        className="flex items-center px-5 py-4 gap-4 bg-stone-50"
        data-testid={`time-entry-row-${entry.id}`}
      >
        <div className="w-32">
          <input
            type="date"
            value={editData.date}
            onChange={(e) => setEditData({ ...editData, date: e.target.value })}
            required
            className="w-full px-2 py-1.5 bg-white border border-stone-200 rounded-lg text-stone-900 text-sm"
          />
        </div>
        <div className="w-48">
          <ProjectSelector
            projects={projects}
            value={editData.project_id}
            onChange={(value) =>
              setEditData({ ...editData, project_id: value })
            }
            required
            className="w-full text-sm py-1.5"
          />
        </div>
        <div className="w-20">
          <Input
            type="number"
            step="0.25"
            min="0.25"
            max="24"
            value={editData.hours}
            onChange={(e) =>
              setEditData({ ...editData, hours: e.target.value })
            }
            required
            className="w-full px-2 py-1.5 bg-white border-stone-200 rounded-lg text-stone-900 tabular-nums text-sm"
          />
        </div>
        <div className="flex-1">
          <Input
            type="text"
            value={editData.description}
            onChange={(e) =>
              setEditData({ ...editData, description: e.target.value })
            }
            className="w-full px-2 py-1.5 bg-white border-stone-200 rounded-lg text-stone-900 text-sm"
            placeholder="Description"
          />
        </div>
        <div className="flex items-center gap-2">
          <Button
            type="submit"
            disabled={isSubmitting}
            className="px-3 py-1.5 bg-stone-900 text-white text-sm font-medium rounded-lg hover:bg-stone-800 transition-colors"
          >
            {isSubmitting ? "Saving..." : "Save"}
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={handleCancel}
            disabled={isSubmitting}
            className="px-3 py-1.5 border border-stone-200 text-stone-700 text-sm font-medium rounded-lg hover:bg-stone-50 transition-colors"
          >
            Cancel
          </Button>
        </div>
      </form>
    );
  }

  return (
    <div
      className={`flex items-center px-5 py-4 table-row ${isInvoiced ? "opacity-60" : ""}`}
      data-testid={`time-entry-row-${entry.id}`}
    >
      <div className="flex-1">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-stone-500">
            {entry.client_name}
          </span>
          <span className="text-stone-300">&rarr;</span>
          <span className="text-sm font-medium text-stone-700">
            {entry.project_name}
          </span>
        </div>
        {entry.description && (
          <p className="text-stone-900 mt-1">{entry.description}</p>
        )}
      </div>
      <div className="flex items-center gap-4">
        <StatusBadge status={entry.status} />
        <span className="text-lg font-semibold text-stone-900 tabular-nums w-16 text-right">
          {formatHours(entry.hours)}
        </span>
        {isInvoiced ? (
          <div className="w-20" />
        ) : (
          <div className="flex items-center gap-1">
            <button
              type="button"
              onClick={() => setIsEditing(true)}
              className="p-2 text-stone-400 hover:text-stone-600 hover:bg-stone-100 rounded-lg transition-colors"
              title="Edit entry"
              data-testid={`edit-entry-${entry.id}`}
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
                  d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
                />
              </svg>
            </button>
            <button
              type="button"
              onClick={() => onDelete(entry.id)}
              className="p-2 text-stone-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              title="Delete entry"
              data-testid={`delete-entry-${entry.id}`}
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
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
