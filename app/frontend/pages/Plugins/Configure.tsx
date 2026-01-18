import { Head, usePage, router, Link } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Toaster } from "@/components/ui/sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

interface FieldDefinition {
  name: string;
  label: string;
  type: "text" | "password" | "number" | "date" | "email";
  required: boolean;
  placeholder?: string;
  description?: string;
}

interface Plugin {
  plugin_name: string;
  plugin_version: string;
  plugin_description: string;
  enabled: boolean;
  configured: boolean;
}

interface PageProps {
  plugin: Plugin;
  credentials: Record<string, string>;
  settings: Record<string, string | number>;
  credential_fields: FieldDefinition[];
  setting_fields: FieldDefinition[];
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

// Build Zod schema from field definitions
function buildSchema(fields: FieldDefinition[]) {
  const shape: Record<string, z.ZodTypeAny> = {};

  fields.forEach((field) => {
    let fieldSchema: z.ZodTypeAny;

    switch (field.type) {
      case "number":
        fieldSchema = z.coerce.number().optional();
        break;
      case "date":
        fieldSchema = z.string().optional();
        break;
      case "email":
        fieldSchema = field.required
          ? z.string().email()
          : z.string().email().optional().or(z.literal(""));
        break;
      default:
        fieldSchema = field.required
          ? z.string().min(1, `${field.label} is required`)
          : z.string().optional();
    }

    shape[field.name] = fieldSchema;
  });

  return z.object(shape);
}

function CredentialsForm({
  fields,
  defaultValues,
  pluginName,
}: {
  fields: FieldDefinition[];
  defaultValues: Record<string, string>;
  pluginName: string;
}) {
  const { t } = useTranslation();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const schema = buildSchema(fields);
  type FormData = z.infer<typeof schema>;

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: Object.fromEntries(
      fields.map((f) => [f.name, ""])
    ) as FormData,
  });

  const onSubmit = (data: FormData) => {
    setIsSubmitting(true);
    router.patch(
      `/plugins/${pluginName}/update_credentials`,
      { credentials: data as Record<string, string> },
      {
        preserveScroll: true,
        onFinish: () => setIsSubmitting(false),
      }
    );
  };

  const hasCredentials = Object.values(defaultValues).some(
    (v) => v && v !== ""
  );

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      {hasCredentials && (
        <div className="p-3 bg-stone-50 rounded-lg text-sm text-stone-600">
          {t("pages.plugins.configuration.credentialsMasked")}
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {fields.map((field) => (
          <div key={field.name} className="space-y-1.5">
            <Label
              htmlFor={`cred-${field.name}`}
              className="text-sm font-medium text-stone-700"
            >
              {field.label}
              {field.required && <span className="text-red-500 ml-1">*</span>}
            </Label>
            <Input
              id={`cred-${field.name}`}
              type={field.type}
              placeholder={
                field.placeholder ||
                (hasCredentials ? defaultValues[field.name] : "")
              }
              {...register(field.name)}
              className={`bg-stone-50 ${
                errors[field.name] ? "border-red-500" : ""
              }`}
            />
            {field.description && (
              <p className="text-xs text-stone-500">{field.description}</p>
            )}
            {errors[field.name] && (
              <p className="text-xs text-red-500">
                {errors[field.name]?.message as string}
              </p>
            )}
          </div>
        ))}
      </div>

      <div className="flex items-center gap-3 pt-2">
        <Button
          type="submit"
          disabled={isSubmitting}
          className="bg-stone-900 hover:bg-stone-800"
        >
          {isSubmitting
            ? t("common.saving")
            : t("pages.plugins.configuration.saveCredentials")}
        </Button>

        {hasCredentials && (
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button type="button" variant="outline" className="text-red-600">
                {t("pages.plugins.configuration.clearCredentials")}
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>
                  {t("pages.plugins.configuration.clearCredentials")}
                </AlertDialogTitle>
                <AlertDialogDescription>
                  {t("pages.plugins.configuration.clearCredentialsConfirm")}
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>{t("common.cancel")}</AlertDialogCancel>
                <AlertDialogAction
                  onClick={() => {
                    router.delete(`/plugins/${pluginName}/clear_credentials`, {
                      preserveScroll: true,
                    });
                  }}
                  className="bg-red-600 hover:bg-red-700"
                >
                  {t("pages.plugins.configuration.clearCredentials")}
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        )}
      </div>
    </form>
  );
}

function SettingsForm({
  fields,
  defaultValues,
  pluginName,
}: {
  fields: FieldDefinition[];
  defaultValues: Record<string, string | number>;
  pluginName: string;
}) {
  const { t } = useTranslation();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const schema = buildSchema(fields);
  type FormData = z.infer<typeof schema>;

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: defaultValues as FormData,
  });

  const onSubmit = (data: FormData) => {
    setIsSubmitting(true);
    router.patch(
      `/plugins/${pluginName}/update_settings`,
      { settings: data as Record<string, string | number> },
      {
        preserveScroll: true,
        onFinish: () => setIsSubmitting(false),
      }
    );
  };

  if (fields.length === 0) {
    return (
      <p className="text-sm text-stone-500 py-4">
        This plugin has no configurable settings.
      </p>
    );
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {fields.map((field) => (
          <div key={field.name} className="space-y-1.5">
            <Label
              htmlFor={`setting-${field.name}`}
              className="text-sm font-medium text-stone-700"
            >
              {field.label}
              {field.required && <span className="text-red-500 ml-1">*</span>}
            </Label>
            <Input
              id={`setting-${field.name}`}
              type={field.type}
              placeholder={field.placeholder}
              {...register(field.name)}
              className={`bg-stone-50 ${
                errors[field.name] ? "border-red-500" : ""
              }`}
            />
            {field.description && (
              <p className="text-xs text-stone-500">{field.description}</p>
            )}
            {errors[field.name] && (
              <p className="text-xs text-red-500">
                {errors[field.name]?.message as string}
              </p>
            )}
          </div>
        ))}
      </div>

      <div className="pt-2">
        <Button
          type="submit"
          disabled={isSubmitting}
          className="bg-stone-900 hover:bg-stone-800"
        >
          {isSubmitting
            ? t("common.saving")
            : t("pages.plugins.configuration.saveSettings")}
        </Button>
      </div>
    </form>
  );
}

export default function PluginsConfigure() {
  const {
    plugin,
    credentials,
    settings,
    credential_fields,
    setting_fields,
    flash,
  } = usePage<PageProps>().props;
  const { t } = useTranslation();

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
      <Head
        title={t("pages.plugins.configuration.title", {
          name: plugin.plugin_name,
        })}
      />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
        {/* Header */}
        <div className="mb-6 sm:mb-8">
          <Link
            href="/plugins"
            className="inline-flex items-center gap-1 text-sm text-stone-500 hover:text-stone-700 mb-4"
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
            {t("pages.plugins.configuration.backToPlugins")}
          </Link>
          <div className="flex items-center gap-3 mb-2">
            <h1 className="text-2xl font-semibold text-stone-900">
              {t("pages.plugins.configuration.title", {
                name: plugin.plugin_name,
              })}
            </h1>
            <span className="text-xs text-stone-500 bg-stone-100 px-2 py-0.5 rounded">
              v{plugin.plugin_version}
            </span>
          </div>
          <p className="text-stone-500">{plugin.plugin_description}</p>
        </div>

        <div className="max-w-2xl space-y-6">
          {/* Credentials Section - only show if plugin has credential fields */}
          {credential_fields.length > 0 && (
            <div className="bg-white rounded-xl border border-stone-200 p-6">
              <h3 className="font-semibold text-stone-900 mb-1">
                {t("pages.plugins.configuration.credentialsSection")}
              </h3>
              <p className="text-sm text-stone-500 mb-4">
                {t("pages.plugins.configuration.credentialsDescription")}
              </p>
              <CredentialsForm
                fields={credential_fields}
                defaultValues={credentials}
                pluginName={plugin.plugin_name}
              />
            </div>
          )}

          {/* Settings Section */}
          <div className="bg-white rounded-xl border border-stone-200 p-6">
            <h3 className="font-semibold text-stone-900 mb-1">
              {t("pages.plugins.configuration.settingsSection")}
            </h3>
            <p className="text-sm text-stone-500 mb-4">
              {t("pages.plugins.configuration.settingsDescription")}
            </p>
            <SettingsForm
              fields={setting_fields}
              defaultValues={settings}
              pluginName={plugin.plugin_name}
            />
          </div>
        </div>
      </div>
    </>
  );
}
