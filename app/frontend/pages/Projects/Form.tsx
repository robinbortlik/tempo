import { useForm, router } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { useTranslation } from "react-i18next";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { formatRate } from "@/components/CurrencyDisplay";

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
  hourly_rate: number | string | null;
  currency: string | null;
}

interface ProjectFormProps {
  project: Project;
  clients: Client[];
  preselectedClientId?: number | null;
  isEdit?: boolean;
}

export default function ProjectForm({
  project,
  clients,
  preselectedClientId,
  isEdit = false,
}: ProjectFormProps) {
  const { t } = useTranslation();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const initialClientId = project.client_id || preselectedClientId || null;

  const { data, setData } = useForm({
    name: project.name || "",
    client_id: initialClientId?.toString() || "",
    hourly_rate: project.hourly_rate?.toString() || "",
    active: project.active ?? true,
  });

  const selectedClient = clients.find(
    (c) => c.id.toString() === data.client_id
  );

  function handleSubmit(e: FormEvent) {
    e.preventDefault();

    const formData = {
      project: {
        name: data.name,
        client_id: data.client_id ? parseInt(data.client_id) : null,
        hourly_rate: data.hourly_rate ? parseFloat(data.hourly_rate) : null,
        active: data.active,
      },
    };

    setIsSubmitting(true);

    if (isEdit && project.id) {
      router.patch(`/projects/${project.id}`, formData, {
        onFinish: () => setIsSubmitting(false),
      });
    } else {
      router.post("/projects", formData, {
        onFinish: () => setIsSubmitting(false),
      });
    }
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-2xl space-y-8">
      {/* Project Details Section */}
      <div className="bg-white rounded-xl border border-stone-200 p-6">
        <h3 className="font-semibold text-stone-900 mb-6">
          {t("pages.projects.projectDetails")}
        </h3>
        <div className="space-y-4">
          <div>
            <Label
              htmlFor="name"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              {t("pages.projects.form.name")} *
            </Label>
            <Input
              id="name"
              type="text"
              value={data.name}
              onChange={(e) => setData("name", e.target.value)}
              required
              className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
              placeholder={t("pages.projects.form.namePlaceholder")}
            />
          </div>

          <div>
            <Label
              htmlFor="client_id"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              {t("pages.projects.form.client")} *
            </Label>
            <select
              id="client_id"
              value={data.client_id}
              onChange={(e) => setData("client_id", e.target.value)}
              required
              className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-stone-900"
            >
              <option value="">{t("pages.projects.form.selectClient")}</option>
              {clients.map((client) => (
                <option key={client.id} value={client.id}>
                  {client.name}
                  {client.hourly_rate &&
                    ` (${formatRate(client.hourly_rate, client.currency, false)})`}
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-2">
            <input
              id="active"
              type="checkbox"
              checked={data.active}
              onChange={(e) => setData("active", e.target.checked)}
              className="w-4 h-4 rounded border-stone-300 text-stone-900 focus:ring-stone-500"
            />
            <Label
              htmlFor="active"
              className="text-sm font-medium text-stone-600"
            >
              {t("pages.projects.form.activeProject")}
            </Label>
          </div>
        </div>
      </div>

      {/* Billing Details Section */}
      <div className="bg-white rounded-xl border border-stone-200 p-6">
        <h3 className="font-semibold text-stone-900 mb-6">
          {t("pages.projects.billingDetails")}
        </h3>
        <div className="space-y-4">
          <div>
            <Label
              htmlFor="hourly_rate"
              className="block text-sm font-medium text-stone-600 mb-1.5"
            >
              {t("pages.projects.form.customHourlyRate")}
            </Label>
            <Input
              id="hourly_rate"
              type="number"
              step="0.01"
              min="0"
              value={data.hourly_rate}
              onChange={(e) => setData("hourly_rate", e.target.value)}
              className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 tabular-nums"
              placeholder={
                selectedClient?.hourly_rate
                  ? `${t("pages.projects.form.client")}: ${formatRate(selectedClient.hourly_rate, selectedClient.currency, false)}`
                  : ""
              }
            />
            <p className="mt-1.5 text-sm text-stone-500">
              {selectedClient
                ? data.hourly_rate
                  ? t("pages.projects.rateHelp.custom", {
                      rate: formatRate(
                        selectedClient.hourly_rate,
                        selectedClient.currency,
                        false
                      ),
                    })
                  : t("pages.projects.rateHelp.default", {
                      rate: formatRate(
                        selectedClient.hourly_rate,
                        selectedClient.currency,
                        false
                      ),
                    })
                : t("pages.projects.rateHelp.selectFirst")}
            </p>
          </div>
        </div>
      </div>

      {/* Submit Button */}
      <div className="flex justify-end gap-3">
        <Button
          type="button"
          variant="outline"
          onClick={() =>
            router.visit(
              isEdit && project.id ? `/projects/${project.id}` : "/projects"
            )
          }
          className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
        >
          {t("common.cancel")}
        </Button>
        <Button
          type="submit"
          disabled={isSubmitting || !data.name || !data.client_id}
          className="px-6 py-2.5 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
        >
          {isSubmitting
            ? t("common.saving")
            : isEdit
              ? t("common.saveChanges")
              : t("pages.projects.createProject")}
        </Button>
      </div>
    </form>
  );
}
