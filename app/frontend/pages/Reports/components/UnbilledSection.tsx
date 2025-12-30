import { ProjectGroup } from "./ProjectGroup";

interface Entry {
  id: number;
  date: string;
  hours: number;
  description: string | null;
  calculated_amount: number;
}

interface Project {
  id: number;
  name: string;
  effective_hourly_rate: number;
}

interface ProjectGroupData {
  project: Project;
  entries: Entry[];
  total_hours: number;
  total_amount: number;
}

interface UnbilledSectionProps {
  projectGroups: ProjectGroupData[];
  totalHours: number;
  totalAmount: number;
  currency: string;
}

export function UnbilledSection({
  projectGroups,
  currency,
}: UnbilledSectionProps) {
  if (projectGroups.length === 0) {
    return null;
  }

  return (
    <section className="mb-8">
      <h2 className="text-lg font-semibold text-stone-900 mb-4 flex items-center gap-2">
        <span className="w-2 h-2 bg-amber-500 rounded-full" />
        Unbilled Work
      </h2>
      <div className="bg-white border border-stone-200 rounded-xl overflow-hidden">
        {projectGroups.map((group, index) => (
          <div
            key={group.project.id}
            className={index < projectGroups.length - 1 ? "border-b border-stone-100" : ""}
          >
            <ProjectGroup
              project={group.project}
              entries={group.entries}
              totalHours={group.total_hours}
              totalAmount={group.total_amount}
              currency={currency}
              defaultOpen={true}
            />
          </div>
        ))}
      </div>
    </section>
  );
}
