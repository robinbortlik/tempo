import { Head, usePage, router } from "@inertiajs/react";
import { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Toaster } from "@/components/ui/sonner";
import { formatRate } from "@/components/CurrencyDisplay";

interface Client {
  id: number;
  name: string;
  currency: string | null;
}

interface Project {
  id: number;
  name: string;
  hourly_rate: number | null;
  effective_hourly_rate: number;
  active: boolean;
  unbilled_hours: number;
  time_entries_count: number;
}

interface ClientGroup {
  client: Client;
  projects: Project[];
}

interface PageProps {
  projects: ClientGroup[];
  clients: { id: number; name: string }[];
  selected_client_id: number | null;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function ProjectsIndex() {
  const { projects, flash } = usePage<PageProps>().props;
  const { t } = useTranslation();

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleProjectClick = (projectId: number) => {
    router.visit(`/projects/${projectId}`);
  };

  const totalProjects = projects.reduce(
    (sum, group) => sum + group.projects.length,
    0
  );

  return (
    <>
      <Head title={t("pages.projects.title")} />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-stone-900">
              {t("pages.projects.title")}
            </h1>
            <p className="text-stone-500 mt-1">
              {t("pages.projects.subtitle")}
            </p>
          </div>
          <Button
            onClick={() => router.visit("/projects/new")}
            className="flex items-center gap-2 px-4 py-2 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
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
                d="M12 4v16m8-8H4"
              />
            </svg>
            {t("pages.projects.addFirstProject")}
          </Button>
        </div>

        {totalProjects === 0 ? (
          <div className="bg-white rounded-xl border border-stone-200 p-8 text-center">
            <p className="text-stone-500 mb-4">
              {t("pages.projects.noProjects")}
            </p>
            <Button
              onClick={() => router.visit("/projects/new")}
              className="px-4 py-2 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
            >
              {t("pages.projects.addFirstProject")}
            </Button>
          </div>
        ) : (
          <div className="space-y-6">
            {projects.map((group) => (
              <div
                key={group.client.id}
                className="bg-white rounded-xl border border-stone-200"
              >
                {/* Client Header */}
                <div className="px-6 py-4 border-b border-stone-200 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <h2 className="font-semibold text-stone-900">
                      {group.client.name}
                    </h2>
                    <span className="text-sm text-stone-500">
                      {t("pages.projects.projectCount", {
                        count: group.projects.length,
                      })}
                    </span>
                  </div>
                  {group.client.currency && (
                    <span className="text-sm text-stone-500">
                      {group.client.currency}
                    </span>
                  )}
                </div>

                {/* Projects List */}
                <div className="divide-y divide-stone-100">
                  {group.projects.map((project) => (
                    <div
                      key={project.id}
                      className="px-6 py-4 flex items-center justify-between hover:bg-stone-50 cursor-pointer transition-colors"
                      onClick={() => handleProjectClick(project.id)}
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className={`w-2 h-2 rounded-full ${project.active ? "bg-emerald-500" : "bg-stone-300"}`}
                        />
                        <div>
                          <p className="font-medium text-stone-900">
                            {project.name}
                          </p>
                          <p className="text-sm text-stone-500">
                            {formatRate(
                              project.effective_hourly_rate,
                              group.client.currency
                            )}
                            {project.hourly_rate &&
                              ` ${t("pages.projects.customRate")}`}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-6">
                        <div className="text-right">
                          {project.unbilled_hours > 0 ? (
                            <span className="text-amber-600 font-medium tabular-nums">
                              {t("pages.clients.unbilledLabel", {
                                hours: Math.round(project.unbilled_hours),
                              })}
                            </span>
                          ) : (
                            <span className="text-stone-400">
                              {t("pages.clients.noUnbilledHours")}
                            </span>
                          )}
                        </div>
                        <div className="text-sm text-stone-500">
                          {t("pages.projects.entryCount", {
                            count: project.time_entries_count,
                          })}
                        </div>
                        <button className="p-2 text-stone-400 hover:text-stone-600 hover:bg-stone-100 rounded-lg transition-colors">
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
                              d="M9 5l7 7-7 7"
                            />
                          </svg>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
