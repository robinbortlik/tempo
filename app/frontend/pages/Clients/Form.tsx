import { useForm, router } from "@inertiajs/react";
import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

interface Client {
  id: number | null;
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
}

interface ClientFormProps {
  client: Client;
  isEdit?: boolean;
}

export default function ClientForm({ client, isEdit = false }: ClientFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [emailError, setEmailError] = useState<string | null>(null);

  const { data, setData } = useForm({
    name: client.name || "",
    address: client.address || "",
    email: client.email || "",
    contact_person: client.contact_person || "",
    vat_id: client.vat_id || "",
    company_registration: client.company_registration || "",
    bank_details: client.bank_details || "",
    payment_terms: client.payment_terms || "",
    hourly_rate: client.hourly_rate?.toString() || "",
    currency: client.currency || "",
  });

  const validateEmail = (email: string): boolean => {
    if (!email) return true;
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

  function handleSubmit(e: FormEvent) {
    e.preventDefault();

    if (data.email && !validateEmail(data.email)) {
      setEmailError("Please enter a valid email address");
      return;
    }

    const formData = {
      client: {
        name: data.name,
        address: data.address,
        email: data.email,
        contact_person: data.contact_person,
        vat_id: data.vat_id,
        company_registration: data.company_registration,
        bank_details: data.bank_details,
        payment_terms: data.payment_terms,
        hourly_rate: data.hourly_rate ? parseFloat(data.hourly_rate) : null,
        currency: data.currency,
      },
    };

    setIsSubmitting(true);

    if (isEdit && client.id) {
      router.patch(`/clients/${client.id}`, formData, {
        onFinish: () => setIsSubmitting(false),
      });
    } else {
      router.post("/clients", formData, {
        onFinish: () => setIsSubmitting(false),
      });
    }
  }

  return (
    <form onSubmit={handleSubmit} className="max-w-2xl space-y-8">
      {/* Client Details Section */}
      <div className="bg-white rounded-xl border border-stone-200 p-6">
        <h3 className="font-semibold text-stone-900 mb-6">Client Details</h3>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="name" className="block text-sm font-medium text-stone-600 mb-1.5">
                Client Name *
              </Label>
              <Input
                id="name"
                type="text"
                value={data.name}
                onChange={(e) => setData("name", e.target.value)}
                required
                className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
              />
            </div>
            <div>
              <Label htmlFor="email" className="block text-sm font-medium text-stone-600 mb-1.5">
                Email
              </Label>
              <Input
                id="email"
                type="email"
                value={data.email}
                onChange={handleEmailChange}
                className={`w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 ${
                  emailError ? "border-red-500 focus-visible:ring-red-500" : ""
                }`}
              />
              {emailError && <p className="mt-1 text-sm text-red-600">{emailError}</p>}
            </div>
          </div>

          <div>
            <Label htmlFor="contact_person" className="block text-sm font-medium text-stone-600 mb-1.5">
              Contact Person
            </Label>
            <Input
              id="contact_person"
              type="text"
              value={data.contact_person}
              onChange={(e) => setData("contact_person", e.target.value)}
              className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900"
            />
          </div>

          <div>
            <Label htmlFor="address" className="block text-sm font-medium text-stone-600 mb-1.5">
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
              <Label htmlFor="vat_id" className="block text-sm font-medium text-stone-600 mb-1.5">
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
            <div>
              <Label htmlFor="company_registration" className="block text-sm font-medium text-stone-600 mb-1.5">
                Company Registration
              </Label>
              <Input
                id="company_registration"
                type="text"
                value={data.company_registration}
                onChange={(e) => setData("company_registration", e.target.value)}
                className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 font-mono"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Billing Details Section */}
      <div className="bg-white rounded-xl border border-stone-200 p-6">
        <h3 className="font-semibold text-stone-900 mb-6">Billing Details</h3>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="currency" className="block text-sm font-medium text-stone-600 mb-1.5">
                Currency
              </Label>
              <select
                id="currency"
                value={data.currency}
                onChange={(e) => setData("currency", e.target.value)}
                className="w-full px-3 py-2.5 bg-stone-50 border border-stone-200 rounded-lg text-stone-900"
              >
                <option value="">Select currency</option>
                <option value="EUR">EUR - Euro</option>
                <option value="USD">USD - US Dollar</option>
                <option value="GBP">GBP - British Pound</option>
                <option value="CZK">CZK - Czech Koruna</option>
              </select>
            </div>
            <div>
              <Label htmlFor="hourly_rate" className="block text-sm font-medium text-stone-600 mb-1.5">
                Hourly Rate
              </Label>
              <Input
                id="hourly_rate"
                type="number"
                step="0.01"
                min="0"
                value={data.hourly_rate}
                onChange={(e) => setData("hourly_rate", e.target.value)}
                className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 tabular-nums"
              />
            </div>
          </div>

          <div>
            <Label htmlFor="payment_terms" className="block text-sm font-medium text-stone-600 mb-1.5">
              Payment Terms
            </Label>
            <Input
              id="payment_terms"
              type="text"
              value={data.payment_terms}
              onChange={(e) => setData("payment_terms", e.target.value)}
              placeholder="e.g., Net 30 days"
              className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 placeholder:text-stone-400"
            />
          </div>

          <div>
            <Label htmlFor="bank_details" className="block text-sm font-medium text-stone-600 mb-1.5">
              Bank Details
            </Label>
            <Textarea
              id="bank_details"
              rows={3}
              value={data.bank_details}
              onChange={(e) => setData("bank_details", e.target.value)}
              placeholder="Bank name, account number, routing..."
              className="w-full px-3 py-2.5 bg-stone-50 border-stone-200 rounded-lg text-stone-900 placeholder:text-stone-400"
            />
          </div>
        </div>
      </div>

      {/* Submit Button */}
      <div className="flex justify-end gap-3">
        <Button
          type="button"
          variant="outline"
          onClick={() => router.visit(isEdit && client.id ? `/clients/${client.id}` : "/clients")}
          className="px-4 py-2 border border-stone-200 text-stone-700 font-medium rounded-lg hover:bg-stone-50 transition-colors"
        >
          Cancel
        </Button>
        <Button
          type="submit"
          disabled={isSubmitting || !!emailError || !data.name}
          className="px-6 py-2.5 bg-stone-900 text-white font-medium rounded-lg hover:bg-stone-800 transition-colors"
        >
          {isSubmitting ? "Saving..." : isEdit ? "Save Changes" : "Create Client"}
        </Button>
      </div>
    </form>
  );
}
