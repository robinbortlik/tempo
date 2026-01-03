import { Head, usePage, router } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Toaster } from "@/components/ui/sonner";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
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
import { formatCurrency, formatRate } from "@/components/CurrencyDisplay";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";

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
  share_token: string;
  sharing_enabled: boolean;
}

interface Project {
  id: number;
  name: string;
  hourly_rate: number | null;
  effective_hourly_rate: number;
  active: boolean;
  unbilled_hours: number;
}

interface Stats {
  total_hours: number;
  total_invoiced: number;
  unbilled_hours: number;
  unbilled_amount: number;
}

interface PageProps {
  client: Client;
  projects: Project[];
  stats: Stats;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

function getInitials(name: string): string {
  return name
    .split(" ")
    .map((word) => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function ClientShow() {
  const { client, projects, stats, flash } = usePage<PageProps>().props;
  const [isDeleting, setIsDeleting] = useState(false);
  const [copySuccess, setCopySuccess] = useState(false);
  const [sharingEnabled, setSharingEnabled] = useState(client.sharing_enabled);
  const [shareToken, setShareToken] = useState(client.share_token);
  const [isRegenerating, setIsRegenerating] = useState(false);

  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const shareUrl = `${window.location.origin}/reports/${shareToken}`;

  const handleCopyLink = async () => {
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopySuccess(true);
      toast.success("Link copied to clipboard");
      setTimeout(() => setCopySuccess(false), 2000);
    } catch {
      toast.error("Failed to copy link");
    }
  };

  const handleDelete = () => {
    setIsDeleting(true);
    router.delete(`/clients/${client.id}`, {
      onFinish: () => setIsDeleting(false),
    });
  };

  const handleToggleSharing = () => {
    const previousValue = sharingEnabled;
    setSharingEnabled(!sharingEnabled);
    router.patch(
      `/clients/${client.id}/toggle_sharing`,
      {},
      {
        preserveState: true,
        onSuccess: () => {
          toast.success(
            !previousValue
              ? "Report sharing enabled"
              : "Report sharing disabled"
          );
        },
        onError: () => {
          setSharingEnabled(previousValue);
          toast.error("Failed to update sharing status");
        },
      }
    );
  };

  const handleRegenerateToken = () => {
    setIsRegenerating(true);
    router.patch(
      `/clients/${client.id}/regenerate_share_token`,
      {},
      {
        preserveState: true,
        onSuccess: (page) => {
          const newClient = (page.props as unknown as PageProps).client;
          setShareToken(newClient.share_token);
          toast.success("Share link regenerated");
          setIsRegenerating(false);
        },
        onError: () => {
          toast.error("Failed to regenerate share link");
          setIsRegenerating(false);
        },
      }
    );
  };

  return (
    <>
      <Head title={client.name} />
      <Toaster position="top-right" />

      <div className="p-8">
        {/* Header */}
        <div className="mb-6">
          <button
            onClick={() => router.visit("/clients")}
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
            Back to Clients
          </button>
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 bg-stone-100 rounded-xl flex items-center justify-center text-stone-600 font-semibold text-lg">
                {getInitials(client.name)}
              </div>
              <div>
                <h1 className="text-2xl font-semibold text-stone-900">
                  {client.name}
                </h1>
                <p className="text-stone-500">
                  {client.email && `${client.email} \u00B7 `}
                  {formatRate(client.hourly_rate, client.currency)}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                onClick={() => router.visit(`/clients/${client.id}/edit`)}
                className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
              >
                Edit
              </Button>
              <Button
                onClick={() =>
                  router.visit(`/invoices/new?client_id=${client.id}`)
                }
                className="px-4 py-2 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
              >
                Create Invoice
              </Button>
            </div>
          </div>
        </div>

        {/* Share Link */}
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Switch
                id="sharing-toggle"
                checked={sharingEnabled}
                onCheckedChange={handleToggleSharing}
              />
              <Label
                htmlFor="sharing-toggle"
                className="text-sm font-medium text-amber-800 cursor-pointer"
              >
                Report Sharing
              </Label>
            </div>
            <div className="h-6 w-px bg-amber-300" />
            <div
              className={`flex items-center gap-3 ${!sharingEnabled ? "opacity-50 pointer-events-none" : ""}`}
            >
              <svg
                className="w-5 h-5 text-amber-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
                />
              </svg>
              <div>
                <p className="text-sm font-medium text-amber-800">
                  Client Report Portal
                </p>
                <p className="text-sm text-amber-600 font-mono truncate max-w-md">
                  {shareUrl}
                </p>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div
              className={
                !sharingEnabled ? "opacity-50 pointer-events-none" : ""
              }
            >
              <Button
                onClick={handleCopyLink}
                className="px-3 py-1.5 bg-amber-600 text-white text-sm font-medium rounded-lg hover:bg-amber-700 transition-colors"
              >
                {copySuccess ? "Copied!" : "Copy Link"}
              </Button>
            </div>
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button
                  variant="outline"
                  className="px-3 py-1.5 border border-amber-300 text-amber-700 text-sm font-medium rounded-lg hover:bg-amber-100 transition-colors"
                >
                  Regenerate Link
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Regenerate share link?</AlertDialogTitle>
                  <AlertDialogDescription>
                    This will create a new share link. The old link will stop
                    working immediately and anyone with the old link will no
                    longer be able to access reports.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                  <AlertDialogAction
                    onClick={handleRegenerateToken}
                    disabled={isRegenerating}
                    className="bg-amber-600 hover:bg-amber-700"
                  >
                    {isRegenerating ? "Regenerating..." : "Regenerate"}
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </div>
        </div>

        {/* Tabs */}
        <Tabs defaultValue="overview" className="w-full">
          <TabsList className="border-b border-stone-200 bg-transparent p-0 mb-6 w-full justify-start">
            <TabsTrigger
              value="overview"
              className="px-1 py-3 text-sm font-medium text-stone-500 hover:text-stone-700 border-b-2 border-transparent data-[state=active]:text-stone-900 data-[state=active]:border-stone-900 rounded-none bg-transparent"
            >
              Overview
            </TabsTrigger>
            <TabsTrigger
              value="projects"
              className="px-1 py-3 text-sm font-medium text-stone-500 hover:text-stone-700 border-b-2 border-transparent data-[state=active]:text-stone-900 data-[state=active]:border-stone-900 rounded-none bg-transparent ml-6"
            >
              Projects ({projects.length})
            </TabsTrigger>
            <TabsTrigger
              value="settings"
              className="px-1 py-3 text-sm font-medium text-stone-500 hover:text-stone-700 border-b-2 border-transparent data-[state=active]:text-stone-900 data-[state=active]:border-stone-900 rounded-none bg-transparent ml-6"
            >
              Settings
            </TabsTrigger>
          </TabsList>

          {/* Overview Tab */}
          <TabsContent value="overview" className="mt-0">
            {/* Stats */}
            <div className="grid grid-cols-4 gap-4 mb-8">
              <div className="bg-white rounded-xl border border-stone-200 p-4">
                <p className="text-sm text-stone-500">Total Hours</p>
                <p className="text-2xl font-semibold text-stone-900 tabular-nums mt-1">
                  {Math.round(stats.total_hours)}
                </p>
              </div>
              <div className="bg-white rounded-xl border border-stone-200 p-4">
                <p className="text-sm text-stone-500">Total Invoiced</p>
                <p className="text-2xl font-semibold text-stone-900 tabular-nums mt-1">
                  {formatCurrency(stats.total_invoiced, client.currency)}
                </p>
              </div>
              <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
                <p className="text-sm text-amber-700">Unbilled Hours</p>
                <p className="text-2xl font-semibold text-amber-900 tabular-nums mt-1">
                  {Math.round(stats.unbilled_hours)}
                </p>
              </div>
              <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
                <p className="text-sm text-amber-700">Unbilled Amount</p>
                <p className="text-2xl font-semibold text-amber-900 tabular-nums mt-1">
                  {formatCurrency(stats.unbilled_amount, client.currency)}
                </p>
              </div>
            </div>

            {/* Client Details */}
            <div className="grid grid-cols-2 gap-6">
              <div className="bg-white rounded-xl border border-stone-200 p-6">
                <h3 className="font-semibold text-stone-900 mb-4">
                  Contact Details
                </h3>
                <dl className="space-y-3 text-sm">
                  {client.contact_person && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">Contact Person</dt>
                      <dd className="text-stone-900">
                        {client.contact_person}
                      </dd>
                    </div>
                  )}
                  {client.email && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">Email</dt>
                      <dd className="text-stone-900">{client.email}</dd>
                    </div>
                  )}
                  {client.address && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">Address</dt>
                      <dd className="text-stone-900 text-right whitespace-pre-line">
                        {client.address}
                      </dd>
                    </div>
                  )}
                </dl>
              </div>
              <div className="bg-white rounded-xl border border-stone-200 p-6">
                <h3 className="font-semibold text-stone-900 mb-4">
                  Billing Details
                </h3>
                <dl className="space-y-3 text-sm">
                  {client.vat_id && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">VAT ID</dt>
                      <dd className="text-stone-900 font-mono">
                        {client.vat_id}
                      </dd>
                    </div>
                  )}
                  {client.company_registration && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">Company Registration</dt>
                      <dd className="text-stone-900 font-mono">
                        {client.company_registration}
                      </dd>
                    </div>
                  )}
                  {client.bank_details && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">Bank Details</dt>
                      <dd className="text-stone-900 text-right whitespace-pre-line">
                        {client.bank_details}
                      </dd>
                    </div>
                  )}
                  {client.payment_terms && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">Payment Terms</dt>
                      <dd className="text-stone-900">{client.payment_terms}</dd>
                    </div>
                  )}
                  {client.currency && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">Currency</dt>
                      <dd className="text-stone-900">{client.currency}</dd>
                    </div>
                  )}
                  {client.hourly_rate && (
                    <div className="flex justify-between">
                      <dt className="text-stone-500">Hourly Rate</dt>
                      <dd className="text-stone-900 font-medium">
                        {formatRate(client.hourly_rate, client.currency)}
                      </dd>
                    </div>
                  )}
                </dl>
              </div>
            </div>
          </TabsContent>

          {/* Projects Tab */}
          <TabsContent value="projects" className="mt-0">
            {projects.length === 0 ? (
              <div className="bg-white rounded-xl border border-stone-200 p-8 text-center">
                <p className="text-stone-500 mb-4">No projects yet.</p>
                <Button
                  onClick={() =>
                    router.visit(`/projects/new?client_id=${client.id}`)
                  }
                  className="px-4 py-2 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
                >
                  Add Project
                </Button>
              </div>
            ) : (
              <div className="bg-white rounded-xl border border-stone-200">
                <div className="divide-y divide-stone-100">
                  {projects.map((project) => (
                    <div
                      key={project.id}
                      className="px-6 py-4 flex items-center justify-between hover:bg-stone-50 cursor-pointer transition-colors"
                      onClick={() => router.visit(`/projects/${project.id}`)}
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
                              client.currency
                            )}
                            {project.hourly_rate && " (custom rate)"}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        {project.unbilled_hours > 0 ? (
                          <span className="text-amber-600 font-medium tabular-nums">
                            {Math.round(project.unbilled_hours)}h unbilled
                          </span>
                        ) : (
                          <span className="text-stone-400">
                            No unbilled hours
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </TabsContent>

          {/* Settings Tab */}
          <TabsContent value="settings" className="mt-0">
            <div className="bg-white rounded-xl border border-stone-200 p-6">
              <h3 className="font-semibold text-stone-900 mb-4">Danger Zone</h3>
              <p className="text-sm text-stone-500 mb-4">
                Deleting a client is permanent and cannot be undone. Clients
                with projects or invoices cannot be deleted.
              </p>
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <Button
                    variant="outline"
                    className="px-4 py-2 border border-red-200 text-red-600 font-medium rounded-lg hover:bg-red-50 transition-colors"
                  >
                    Delete Client
                  </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Delete {client.name}?</AlertDialogTitle>
                    <AlertDialogDescription>
                      This action cannot be undone. This will permanently delete
                      the client and all associated data.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                    <AlertDialogAction
                      onClick={handleDelete}
                      disabled={isDeleting}
                      className="bg-red-600 hover:bg-red-700"
                    >
                      {isDeleting ? "Deleting..." : "Delete"}
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </>
  );
}
