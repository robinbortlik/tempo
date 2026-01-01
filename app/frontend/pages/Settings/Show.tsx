import { Head, useForm, usePage, router } from "@inertiajs/react";
import { FormEvent, useState, useRef, useEffect } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Toaster } from "@/components/ui/sonner";

interface Settings {
  id: number;
  company_name: string | null;
  address: string | null;
  email: string | null;
  phone: string | null;
  vat_id: string | null;
  company_registration: string | null;
  bank_name: string | null;
  bank_account: string | null;
  bank_swift: string | null;
  iban: string | null;
  invoice_message: string | null;
  logo_url: string | null;
}

interface PageProps {
  settings: Settings;
  flash: {
    alert?: string;
    notice?: string;
  };
  [key: string]: unknown;
}

export default function SettingsShow() {
  const { settings, flash } = usePage<PageProps>().props;
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [logoPreview, setLogoPreview] = useState<string | null>(
    settings.logo_url
  );
  const [emailError, setEmailError] = useState<string | null>(null);
  const [ibanError, setIbanError] = useState<string | null>(null);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const { data, setData } = useForm({
    company_name: settings.company_name || "",
    address: settings.address || "",
    email: settings.email || "",
    phone: settings.phone || "",
    vat_id: settings.vat_id || "",
    company_registration: settings.company_registration || "",
    bank_name: settings.bank_name || "",
    bank_account: settings.bank_account || "",
    bank_swift: settings.bank_swift || "",
    iban: settings.iban || "",
    invoice_message: settings.invoice_message || "",
    logo: null as File | null,
  });

  // Show toast notifications for flash messages
  useEffect(() => {
    if (flash.notice) {
      toast.success(flash.notice);
    }
    if (flash.alert) {
      toast.error(flash.alert);
    }
  }, [flash.notice, flash.alert]);

  const validateEmail = (email: string): boolean => {
    if (!email) return true; // Empty is valid (optional field)
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  const handleEmailChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setData("email", value);
    if (value && !validateEmail(value)) {
      setEmailError("Please enter a valid email address");
    } else {
      setEmailError(null);
    }
  };

  const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setData("logo", file);
      // Create preview URL
      const previewUrl = URL.createObjectURL(file);
      setLogoPreview(previewUrl);
    }
  };

  const handleUploadClick = () => {
    fileInputRef.current?.click();
  };

  function handleSubmit(e: FormEvent) {
    e.preventDefault();

    // Validate email before submit
    if (data.email && !validateEmail(data.email)) {
      setEmailError("Please enter a valid email address");
      return;
    }

    // Build FormData manually for file upload with PATCH method override
    const formData = new FormData();
    formData.append("_method", "patch");
    formData.append("setting[company_name]", data.company_name);
    formData.append("setting[address]", data.address);
    formData.append("setting[email]", data.email);
    formData.append("setting[phone]", data.phone);
    formData.append("setting[vat_id]", data.vat_id);
    formData.append("setting[company_registration]", data.company_registration);
    formData.append("setting[bank_name]", data.bank_name);
    formData.append("setting[bank_account]", data.bank_account);
    formData.append("setting[bank_swift]", data.bank_swift);
    formData.append("setting[iban]", data.iban);
    formData.append("setting[invoice_message]", data.invoice_message);
    if (data.logo) {
      formData.append("setting[logo]", data.logo);
    }

    setIsSubmitting(true);
    setIbanError(null);
    router.post("/settings", formData, {
      preserveScroll: true,
      onFinish: () => setIsSubmitting(false),
      onError: (errors) => {
        if (errors.iban) {
          setIbanError(errors.iban);
        }
      },
    });
  }

  return (
    <>
      <Head title="Settings" />
      <Toaster position="top-right" />

      <div className="p-8">
        <div className="mb-8">
          <h1 className="text-2xl font-semibold text-stone-900">Settings</h1>
          <p className="text-stone-500 mt-1">Configure your business details</p>
        </div>

        <form onSubmit={handleSubmit} className="max-w-2xl space-y-8">
          {/* Business Details Section */}
          <div className="bg-white rounded-xl border border-stone-200 p-6">
            <h3 className="font-semibold text-stone-900 mb-6">
              Business Details
            </h3>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label
                    htmlFor="company_name"
                    className="block text-sm font-medium text-stone-600 mb-1.5"
                  >
                    Company Name
                  </Label>
                  <Input
                    id="company_name"
                    type="text"
                    value={data.company_name}
                    onChange={(e) => setData("company_name", e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
                  />
                </div>
                <div>
                  <Label
                    htmlFor="email"
                    className="block text-sm font-medium text-stone-600 mb-1.5"
                  >
                    Email
                  </Label>
                  <Input
                    id="email"
                    type="email"
                    value={data.email}
                    onChange={handleEmailChange}
                    className={`w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 ${
                      emailError
                        ? "border-red-500 focus-visible:ring-red-500"
                        : ""
                    }`}
                  />
                  {emailError && (
                    <p className="mt-1 text-sm text-red-600">{emailError}</p>
                  )}
                </div>
              </div>

              <div>
                <Label
                  htmlFor="address"
                  className="block text-sm font-medium text-stone-600 mb-1.5"
                >
                  Address
                </Label>
                <Textarea
                  id="address"
                  rows={3}
                  value={data.address}
                  onChange={(e) => setData("address", e.target.value)}
                  className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label
                    htmlFor="phone"
                    className="block text-sm font-medium text-stone-600 mb-1.5"
                  >
                    Phone
                  </Label>
                  <Input
                    id="phone"
                    type="tel"
                    value={data.phone}
                    onChange={(e) => setData("phone", e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
                  />
                </div>
                <div>
                  <Label
                    htmlFor="vat_id"
                    className="block text-sm font-medium text-stone-600 mb-1.5"
                  >
                    VAT ID
                  </Label>
                  <Input
                    id="vat_id"
                    type="text"
                    value={data.vat_id}
                    onChange={(e) => setData("vat_id", e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 font-mono"
                  />
                </div>
              </div>

              <div>
                <Label
                  htmlFor="company_registration"
                  className="block text-sm font-medium text-stone-600 mb-1.5"
                >
                  Company Registration
                </Label>
                <Input
                  id="company_registration"
                  type="text"
                  value={data.company_registration}
                  onChange={(e) =>
                    setData("company_registration", e.target.value)
                  }
                  className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 font-mono"
                />
              </div>
            </div>
          </div>

          {/* Bank Details Section */}
          <div className="bg-white rounded-xl border border-stone-200 p-6">
            <h3 className="font-semibold text-stone-900 mb-6">Bank Details</h3>
            <div className="space-y-4">
              <div>
                <Label
                  htmlFor="bank_name"
                  className="block text-sm font-medium text-stone-600 mb-1.5"
                >
                  Bank Name
                </Label>
                <Input
                  id="bank_name"
                  type="text"
                  value={data.bank_name}
                  onChange={(e) => setData("bank_name", e.target.value)}
                  className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label
                    htmlFor="bank_account"
                    className="block text-sm font-medium text-stone-600 mb-1.5"
                  >
                    Bank Account
                  </Label>
                  <Input
                    id="bank_account"
                    type="text"
                    value={data.bank_account}
                    onChange={(e) => setData("bank_account", e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 font-mono"
                  />
                </div>
                <div>
                  <Label
                    htmlFor="bank_swift"
                    className="block text-sm font-medium text-stone-600 mb-1.5"
                  >
                    SWIFT/BIC
                  </Label>
                  <Input
                    id="bank_swift"
                    type="text"
                    value={data.bank_swift}
                    onChange={(e) => setData("bank_swift", e.target.value)}
                    className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 font-mono"
                  />
                </div>
              </div>

              <div>
                <Label
                  htmlFor="iban"
                  className="block text-sm font-medium text-stone-600 mb-1.5"
                >
                  IBAN
                </Label>
                <Input
                  id="iban"
                  type="text"
                  value={data.iban}
                  onChange={(e) => {
                    setData("iban", e.target.value);
                    setIbanError(null);
                  }}
                  className={`w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 font-mono ${
                    ibanError ? "border-red-500 focus-visible:ring-red-500" : ""
                  }`}
                />
                {ibanError && (
                  <p className="mt-1 text-sm text-red-600">{ibanError}</p>
                )}
              </div>
            </div>
          </div>

          {/* Invoice Settings Section */}
          <div className="bg-white rounded-xl border border-stone-200 p-6">
            <h3 className="font-semibold text-stone-900 mb-6">
              Invoice Settings
            </h3>
            <div className="space-y-4">
              <div>
                <Label
                  htmlFor="invoice_message"
                  className="block text-sm font-medium text-stone-600 mb-1.5"
                >
                  Invoice Message
                </Label>
                <Textarea
                  id="invoice_message"
                  rows={4}
                  maxLength={500}
                  value={data.invoice_message}
                  onChange={(e) => setData("invoice_message", e.target.value)}
                  placeholder="Custom message to display on all invoices"
                  className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
                />
                <p className="mt-1 text-sm text-stone-500">
                  {data.invoice_message.length}/500
                </p>
              </div>
            </div>
          </div>

          {/* Company Logo Section */}
          <div className="bg-white rounded-xl border border-stone-200 p-6">
            <h3 className="font-semibold text-stone-900 mb-6">Company Logo</h3>
            <div className="flex items-start gap-6">
              <div className="w-24 h-24 bg-stone-100 rounded-xl flex items-center justify-center overflow-hidden">
                {logoPreview ? (
                  <img
                    src={logoPreview}
                    alt="Company logo"
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <svg
                    className="w-8 h-8 text-stone-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="1.5"
                      d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                  </svg>
                )}
              </div>
              <div className="flex-1">
                <p className="text-sm text-stone-600 mb-3">
                  Upload your company logo to display on invoices. Recommended
                  size: 200x200px.
                </p>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleLogoChange}
                  className="hidden"
                />
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleUploadClick}
                  className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
                >
                  Upload Logo
                </Button>
              </div>
            </div>
          </div>

          {/* Submit Button */}
          <div className="flex justify-end">
            <Button
              type="submit"
              disabled={isSubmitting || !!emailError || !!ibanError}
              className="px-6 py-2.5 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
            >
              {isSubmitting ? "Saving..." : "Save Changes"}
            </Button>
          </div>
        </form>
      </div>
    </>
  );
}
