import { router } from "@inertiajs/react";
import { useTranslation } from "react-i18next";

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
  client_id: number | null;
  project_id: number | null;
  entry_type: string | null;
}

interface Period {
  year: number;
  month: number | null;
  available_years: number[];
}

interface FilterBarProps {
  clients: Client[];
  projects: ClientGroup[];
  filters: Filters;
  period: Period;
}

export default function FilterBar({
  clients,
  projects,
  filters,
  period,
}: FilterBarProps) {
  const { t } = useTranslation();

  const MONTHS = [
    t("months.jan"),
    t("months.feb"),
    t("months.mar"),
    t("months.apr"),
    t("months.may"),
    t("months.jun"),
    t("months.jul"),
    t("months.aug"),
    t("months.sep"),
    t("months.oct"),
    t("months.nov"),
    t("months.dec"),
  ];

  // Get projects for selected client (or all projects if no client selected)
  const availableProjects = filters.client_id
    ? projects.filter((g) => g.client.id === filters.client_id)
    : projects;

  const buildParams = (
    overrides: Record<string, string | number | null | undefined>
  ) => {
    const params: Record<string, string | number> = {};

    // Always include year
    const year = overrides.year !== undefined ? overrides.year : period.year;
    if (year) params.year = year;

    // Include month if set
    const month =
      overrides.month !== undefined ? overrides.month : period.month;
    if (month) params.month = month;

    // Include filters
    const clientId =
      overrides.client_id !== undefined
        ? overrides.client_id
        : filters.client_id;
    if (clientId) params.client_id = clientId;

    const projectId =
      overrides.project_id !== undefined
        ? overrides.project_id
        : filters.project_id;
    if (projectId) params.project_id = projectId;

    const entryType =
      overrides.entry_type !== undefined
        ? overrides.entry_type
        : filters.entry_type;
    if (entryType) params.entry_type = entryType as string;

    return params;
  };

  const handleYearChange = (newYear: number) => {
    router.get("/work_entries", buildParams({ year: newYear }), {
      preserveState: true,
      preserveScroll: true,
    });
  };

  const handleMonthChange = (newMonth: number | null) => {
    router.get("/work_entries", buildParams({ month: newMonth }), {
      preserveState: true,
      preserveScroll: true,
    });
  };

  const handleClientChange = (clientId: string) => {
    const newClientId = clientId ? parseInt(clientId, 10) : null;
    router.get(
      "/work_entries",
      buildParams({ client_id: newClientId, project_id: null }),
      {
        preserveState: true,
        preserveScroll: true,
      }
    );
  };

  const handleProjectChange = (projectId: string) => {
    const newProjectId = projectId ? parseInt(projectId, 10) : null;
    router.get("/work_entries", buildParams({ project_id: newProjectId }), {
      preserveState: true,
      preserveScroll: true,
    });
  };

  const handleEntryTypeChange = (entryType: string) => {
    router.get(
      "/work_entries",
      buildParams({ entry_type: entryType || null }),
      {
        preserveState: true,
        preserveScroll: true,
      }
    );
  };

  const handleClearFilters = () => {
    router.get("/work_entries", {}, { preserveState: true });
  };

  const hasFilters =
    filters.client_id || filters.project_id || filters.entry_type;

  return (
    <div className="bg-stone-100 px-4 sm:px-6 py-4">
      <div className="flex flex-col gap-4">
        {/* Year and Month Selector */}
        <div className="flex flex-wrap items-center gap-3">
          {/* Year Selector */}
          <select
            id="filter-year"
            value={period.year}
            onChange={(e) => handleYearChange(Number(e.target.value))}
            className="px-3 py-2 bg-white border border-stone-200 rounded-lg text-sm font-medium focus:outline-none focus:ring-2 focus:ring-stone-900 focus:border-transparent"
            aria-label={t("pages.workEntries.filter.year")}
          >
            {period.available_years.map((year) => (
              <option key={year} value={year}>
                {year}
              </option>
            ))}
          </select>

          {/* Month Selector */}
          <div className="flex flex-wrap gap-1 bg-stone-100 p-1 rounded-lg border border-stone-200">
            <button
              type="button"
              onClick={() => handleMonthChange(null)}
              className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                period.month === null
                  ? "bg-stone-900 text-white"
                  : "text-stone-500 hover:bg-white"
              }`}
            >
              {t("common.all")}
            </button>
            {MONTHS.map((month, index) => (
              <button
                type="button"
                key={month}
                onClick={() => handleMonthChange(index + 1)}
                className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
                  period.month === index + 1
                    ? "bg-stone-900 text-white"
                    : "text-stone-500 hover:bg-white"
                }`}
              >
                {month}
              </button>
            ))}
          </div>
        </div>

        {/* Other Filters */}
        <div className="flex flex-wrap gap-4 items-end">
          <div className="w-full sm:w-48">
            <label
              htmlFor="filter-client"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              {t("pages.workEntries.filter.client")}
            </label>
            <select
              id="filter-client"
              value={filters.client_id?.toString() || ""}
              onChange={(e) => handleClientChange(e.target.value)}
              className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
            >
              <option value="">
                {t("pages.workEntries.filter.allClients")}
              </option>
              {clients.map((client) => (
                <option key={client.id} value={client.id}>
                  {client.name}
                </option>
              ))}
            </select>
          </div>
          <div className="w-full sm:w-48">
            <label
              htmlFor="filter-project"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              {t("pages.workEntries.filter.project")}
            </label>
            <select
              id="filter-project"
              value={filters.project_id?.toString() || ""}
              onChange={(e) => handleProjectChange(e.target.value)}
              className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
            >
              <option value="">
                {t("pages.workEntries.filter.allProjects")}
              </option>
              {availableProjects.map((group) =>
                group.projects.map((project) => (
                  <option key={project.id} value={project.id}>
                    {group.client.name} &rarr; {project.name}
                  </option>
                ))
              )}
            </select>
          </div>
          <div className="w-full sm:w-36">
            <label
              htmlFor="filter-entry-type"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              {t("pages.workEntries.filter.entryType")}
            </label>
            <select
              id="filter-entry-type"
              value={filters.entry_type || ""}
              onChange={(e) => handleEntryTypeChange(e.target.value)}
              className="w-full h-10 px-3 bg-stone-50 border border-stone-200 rounded-lg text-sm text-stone-900"
            >
              <option value="">{t("pages.workEntries.filter.allTypes")}</option>
              <option value="time">{t("pages.workEntries.filter.time")}</option>
              <option value="fixed">
                {t("pages.workEntries.filter.fixed")}
              </option>
            </select>
          </div>
          {hasFilters && (
            <button
              type="button"
              onClick={handleClearFilters}
              className="h-10 px-2 text-sm text-stone-500 hover:text-stone-700"
            >
              {t("common.clear")}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
