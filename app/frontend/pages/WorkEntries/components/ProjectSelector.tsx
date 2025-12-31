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

interface ProjectSelectorProps {
  projects: ClientGroup[];
  value: string;
  onChange: (value: string) => void;
  required?: boolean;
  className?: string;
  id?: string;
}

export default function ProjectSelector({
  projects,
  value,
  onChange,
  required = false,
  className = "",
  id,
}: ProjectSelectorProps) {
  return (
    <select
      id={id}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      required={required}
      className={`px-3 py-2 bg-stone-50 border border-stone-200 rounded-lg text-stone-900 ${className}`}
    >
      <option value="">Select a project</option>
      {projects.map((group) => (
        <optgroup key={group.client.id} label={group.client.name}>
          {group.projects.map((project) => (
            <option key={project.id} value={project.id}>
              {group.client.name} &rarr; {project.name}
            </option>
          ))}
        </optgroup>
      ))}
    </select>
  );
}
