import { Head, usePage, router } from "@inertiajs/react";
import { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Toaster } from "@/components/ui/sonner";
import ClientForm from "./Form";

interface Client {
  id: number;
  name: string;
  address: string | null;
  email: string | null;
  contact_person: string | null;
  vat_id: string | null;
  company_registration: string | null;
  bank_details: string | null;
  payment_terms: string | null;
  hourly_rate: number | null;
  currency: string | null;
  default_vat_rate: number | null;
  locale: string;
}

interface PageProps {
  client: Client;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function EditClient() {
  const { t } = useTranslation();
  const { client, flash } = usePage<PageProps>().props;

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
      <Head title={`${t("common.edit")} ${client.name}`} />
      <Toaster position="top-right" />

      <div className="p-4 sm:p-6 lg:p-8">
        <div className="mb-6">
          <button
            onClick={() => router.visit(`/clients/${client.id}`)}
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
            {t("common.backTo", { name: client.name })}
          </button>
          <h1 className="text-2xl font-semibold text-stone-900">
            {t("pages.clients.editClient")}
          </h1>
          <p className="text-stone-500 mt-1">{t("pages.clients.updateInfo")}</p>
        </div>

        <ClientForm client={client} isEdit />
      </div>
    </>
  );
}
