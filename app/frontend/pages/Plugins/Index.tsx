import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Toaster } from "@/components/ui/sonner";

interface Plugin {
  plugin_name: string;
  plugin_version: string;
  plugin_description: string;
  enabled: boolean;
  configured: boolean;
  last_sync_at: string | null;
  last_sync_status: string | null;
  total_syncs: number;
  success_rate: number;
}

interface PageProps {
  plugins: Plugin[];
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

function getStatusBadgeClass(status: string | null): string {
  switch (status) {
    case "completed":
      return "bg-green-100 text-green-700";
    case "failed":
      return "bg-red-100 text-red-700";
    case "running":
      return "bg-blue-100 text-blue-700";
    default:
      return "bg-stone-100 text-stone-600";
  }
}

function formatDate(dateString: string | null): string {
  if (!dateString) return "-";
  const date = new Date(dateString);
  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function PluginsIndex() {
  const { plugins, flash } = usePage<PageProps>().props;
  const { t } = useTranslation();
  const [togglingPlugins, setTogglingPlugins] = useState<Set<string>>(
    new Set()
  );
  const [syncingPlugins, setSyncingPlugins] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const handleToggle = (plugin: Plugin) => {
    const action = plugin.enabled ? "disable" : "enable";
    setTogglingPlugins((prev) => new Set(prev).add(plugin.plugin_name));

    router.patch(
      `/plugins/${plugin.plugin_name}/${action}`,
      {},
      {
        preserveScroll: true,
        onFinish: () => {
          setTogglingPlugins((prev) => {
            const next = new Set(prev);
            next.delete(plugin.plugin_name);
            return next;
          });
        },
      }
    );
  };

  const handleSync = (plugin: Plugin) => {
    setSyncingPlugins((prev) => new Set(prev).add(plugin.plugin_name));

    router.post(
      `/plugins/${plugin.plugin_name}/sync`,
      {},
      {
        preserveScroll: true,
        onFinish: () => {
          setSyncingPlugins((prev) => {
            const next = new Set(prev);
            next.delete(plugin.plugin_name);
            return next;
          });
        },
      }
    );
  };

  const handleConfigure = (plugin: Plugin) => {
    router.visit(`/plugins/${plugin.plugin_name}/configure`);
  };

  return (
    <>
      <Head title={t("pages.plugins.title")} />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
        <div className="mb-6 sm:mb-8">
          <h1 className="text-2xl font-semibold text-stone-900">
            {t("pages.plugins.title")}
          </h1>
          <p className="text-stone-500 mt-1">{t("pages.plugins.subtitle")}</p>
        </div>

        {plugins.length === 0 ? (
          <div className="bg-white rounded-xl border border-stone-200 p-8 text-center">
            <div className="w-12 h-12 mx-auto mb-4 bg-stone-100 rounded-lg flex items-center justify-center">
              <svg
                className="w-6 h-6 text-stone-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="1.5"
                  d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                />
              </svg>
            </div>
            <h3 className="font-medium text-stone-900 mb-1">
              {t("pages.plugins.noPlugins")}
            </h3>
            <p className="text-sm text-stone-500">
              {t("pages.plugins.noPluginsDescription")}
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {plugins.map((plugin) => (
              <div
                key={plugin.plugin_name}
                className="bg-white rounded-xl border border-stone-200 p-6"
              >
                <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="font-semibold text-stone-900">
                        {plugin.plugin_name}
                      </h3>
                      <span className="text-xs text-stone-500 bg-stone-100 px-2 py-0.5 rounded">
                        v{plugin.plugin_version}
                      </span>
                      {plugin.configured ? (
                        <span className="text-xs text-green-600 bg-green-50 px-2 py-0.5 rounded">
                          {t("pages.plugins.configured")}
                        </span>
                      ) : (
                        <span className="text-xs text-amber-600 bg-amber-50 px-2 py-0.5 rounded">
                          {t("pages.plugins.notConfigured")}
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-stone-600 mb-3">
                      {plugin.plugin_description}
                    </p>

                    {/* Sync stats */}
                    <div className="flex flex-wrap items-center gap-4 text-sm">
                      <div className="flex items-center gap-2">
                        <span className="text-stone-500">
                          {t("pages.plugins.lastSync")}:
                        </span>
                        {plugin.last_sync_status && (
                          <span
                            className={`px-2 py-0.5 rounded text-xs font-medium ${getStatusBadgeClass(
                              plugin.last_sync_status
                            )}`}
                          >
                            {plugin.last_sync_status}
                          </span>
                        )}
                        <span className="text-stone-700">
                          {formatDate(plugin.last_sync_at)}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-stone-500">
                          {t("pages.plugins.totalSyncs")}:
                        </span>
                        <span className="text-stone-700 font-medium">
                          {plugin.total_syncs}
                        </span>
                      </div>
                      {plugin.total_syncs > 0 && (
                        <div className="flex items-center gap-2">
                          <span className="text-stone-500">
                            {t("pages.plugins.successRate")}:
                          </span>
                          <span className="text-stone-700 font-medium">
                            {plugin.success_rate.toFixed(1)}%
                          </span>
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    {/* Configure button */}
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleConfigure(plugin)}
                      className="text-stone-600"
                    >
                      {t("pages.plugins.configure")}
                    </Button>

                    {/* History button */}
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() =>
                        router.visit(`/plugins/${plugin.plugin_name}/history`)
                      }
                      className="text-stone-600"
                    >
                      {t("pages.plugins.viewHistory")}
                    </Button>

                    {/* Sync button */}
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleSync(plugin)}
                      disabled={
                        !plugin.enabled ||
                        !plugin.configured ||
                        syncingPlugins.has(plugin.plugin_name)
                      }
                      className="text-stone-600"
                    >
                      {syncingPlugins.has(plugin.plugin_name) ? (
                        <>
                          <svg
                            className="animate-spin -ml-1 mr-2 h-4 w-4"
                            fill="none"
                            viewBox="0 0 24 24"
                          >
                            <circle
                              className="opacity-25"
                              cx="12"
                              cy="12"
                              r="10"
                              stroke="currentColor"
                              strokeWidth="4"
                            />
                            <path
                              className="opacity-75"
                              fill="currentColor"
                              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                            />
                          </svg>
                          {t("pages.plugins.syncing")}
                        </>
                      ) : (
                        t("pages.plugins.syncNow")
                      )}
                    </Button>

                    {/* Enable/Disable toggle */}
                    <div className="flex items-center gap-2">
                      <Switch
                        checked={plugin.enabled}
                        onCheckedChange={() => handleToggle(plugin)}
                        disabled={togglingPlugins.has(plugin.plugin_name)}
                        aria-label={
                          plugin.enabled
                            ? t("pages.plugins.disable")
                            : t("pages.plugins.enable")
                        }
                      />
                      <span className="text-sm text-stone-600 min-w-[60px]">
                        {plugin.enabled
                          ? t("pages.plugins.enabled")
                          : t("pages.plugins.disabled")}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
