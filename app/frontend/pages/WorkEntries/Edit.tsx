import { Head, usePage, router } from "@inertiajs/react";
import { useEffect } from "react";
import { toast } from "sonner";
import { Toaster } from "@/components/ui/sonner";
import WorkEntryForm from "./Form";

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
}

interface PageProps {
  work_entry: WorkEntry;
  projects: ClientGroup[];
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function EditWorkEntry() {
  const { work_entry, projects, flash } = usePage<PageProps>().props;

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
      <Head title="Edit Work Entry" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-6">
          <button
            onClick={() => router.visit("/work_entries")}
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
            Back to Log Work
          </button>
          <h1 className="text-2xl font-semibold text-stone-900">
            Edit Work Entry
          </h1>
          <p className="text-stone-500 mt-1">Update your work entry details</p>
        </div>

        <WorkEntryForm workEntry={work_entry} projects={projects} />
      </div>
    </>
  );
}
