import { router } from "@inertiajs/react";
import { useState } from "react";
import { Button } from "@/components/ui/button";

interface Client {
  id: number;
  name: string;
}

interface Project {
  id: number;
  name: string;
  effective_hourly_rate: number;
}

interface ClientGroup {
  client: {
    id: number;
    name: string;
    currency: string | null;
  };
  projects: Project[];
}

interface Filters {
  start_date: string | null;
  end_date: string | null;
  client_id: number | null;
  project_id: number | null;
  entry_type: string | null;
}

interface FilterBarProps {
  clients: Client[];
  projects: ClientGroup[];
  filters: Filters;
}

export default function FilterBar({
  clients,
  projects,
  filters,
}: FilterBarProps) {
  const [startDate, setStartDate] = useState(filters.start_date || "");
  const [endDate, setEndDate] = useState(filters.end_date || "");
  const [clientId, setClientId] = useState(filters.client_id?.toString() || "");
  const [projectId, setProjectId] = useState(
    filters.project_id?.toString() || ""
  );
  const [entryType, setEntryType] = useState(filters.entry_type || "");

  // Get projects for selected client (or all projects if no client selected)
  const availableProjects = clientId
    ? projects.filter((g) => g.client.id.toString() === clientId)
    : projects;

  const handleApplyFilters = () => {
    const params: Record<string, string> = {};
    if (startDate) params.start_date = startDate;
    if (endDate) params.end_date = endDate;
    if (clientId) params.client_id = clientId;
    if (projectId) params.project_id = projectId;
    if (entryType) params.entry_type = entryType;

    router.get("/work_entries", params, { preserveState: true });
  };

  const handleClearFilters = () => {
    setStartDate("");
    setEndDate("");
    setClientId("");
    setProjectId("");
    setEntryType("");
    router.get("/work_entries", {}, { preserveState: true });
  };

  const hasFilters = startDate || endDate || clientId || projectId || entryType;

  return (
    <div className="bg-stone-100 px-6 py-4">
      <div className="flex flex-wrap gap-4 items-end">
        <div className="w-40">
          <label
            htmlFor="filter-start-date"
            className="block text-sm font-medium text-stone-600 mb-1.5"
          >
            Start Date
          </label>
          <input
            id="filter-start-date"
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
          />
        </div>
        <div className="w-40">
          <label
            htmlFor="filter-end-date"
            className="block text-sm font-medium text-stone-600 mb-1.5"
          >
            End Date
          </label>
          <input
            id="filter-end-date"
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
            className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
          />
        </div>
        <div className="w-48">
          <label
            htmlFor="filter-client"
            className="block text-sm font-medium text-stone-600 mb-1.5"
          >
            Client
          </label>
          <select
            id="filter-client"
            value={clientId}
            onChange={(e) => {
              setClientId(e.target.value);
              setProjectId(""); // Reset project when client changes
            }}
            className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
          >
            <option value="">All Clients</option>
            {clients.map((client) => (
              <option key={client.id} value={client.id}>
                {client.name}
              </option>
            ))}
          </select>
        </div>
        <div className="w-48">
          <label
            htmlFor="filter-project"
            className="block text-sm font-medium text-stone-600 mb-1.5"
          >
            Project
          </label>
          <select
            id="filter-project"
            value={projectId}
            onChange={(e) => setProjectId(e.target.value)}
            className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
          >
            <option value="">All Projects</option>
            {availableProjects.map((group) =>
              group.projects.map((project) => (
                <option key={project.id} value={project.id}>
                  {group.client.name} &rarr; {project.name}
                </option>
              ))
            )}
          </select>
        </div>
        <div className="w-36">
          <label
            htmlFor="filter-entry-type"
            className="block text-sm font-medium text-stone-600 mb-1.5"
          >
            Entry Type
          </label>
          <select
            id="filter-entry-type"
            value={entryType}
            onChange={(e) => setEntryType(e.target.value)}
            className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
          >
            <option value="">All Types</option>
            <option value="time">Time</option>
            <option value="fixed">Fixed</option>
          </select>
        </div>
        <Button
          type="button"
          onClick={handleApplyFilters}
          className="h-10 px-4 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
        >
          Apply Filters
        </Button>
        {hasFilters && (
          <button
            type="button"
            onClick={handleClearFilters}
            className="h-10 px-2 text-sm text-stone-500 hover:text-stone-700"
          >
            Clear
          </button>
        )}
      </div>
    </div>
  );
}
