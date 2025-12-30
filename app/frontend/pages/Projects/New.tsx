import { Head, usePage, router } from "@inertiajs/react";
import { useEffect } from "react";
import { toast } from "sonner";
import { Toaster } from "@/components/ui/sonner";
import ProjectForm from "./Form";

interface Project {
  id: number | null;
  name: string;
  client_id: number | null;
  hourly_rate: number | null;
  active: boolean;
}

interface Client {
  id: number;
  name: string;
  hourly_rate: number | null;
  currency: string | null;
}

interface PageProps {
  project: Project;
  clients: Client[];
  preselected_client_id: number | null;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function NewProject() {
  const { project, clients, preselected_client_id, flash } =
    usePage<PageProps>().props;

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  return (
    <>
      <Head title="New Project" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-6">
          <button
            onClick={() => router.visit("/projects")}
            className="flex items-center gap-1 text-sm text-stone-500 hover:text-stone-700 mb-4"
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
                d="M15 19l-7-7 7-7"
              />
            </svg>
            Back to Projects
          </button>
          <h1 className="text-2xl font-semibold text-stone-900">New Project</h1>
          <p className="text-stone-500 mt-1">Add a new project to track time</p>
        </div>

        <ProjectForm
          project={project}
          clients={clients}
          preselectedClientId={preselected_client_id}
        />
      </div>
    </>
  );
}
