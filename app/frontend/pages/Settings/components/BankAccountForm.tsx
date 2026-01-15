import { useState } from "react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogCancel,
} from "@/components/ui/alert-dialog";
import type { BankAccount } from "./BankAccountsSection";

interface BankAccountFormProps {
  account: BankAccount | null;
  onClose: () => void;
  onSuccess: (accounts: BankAccount[]) => void;
}

export function BankAccountForm({
  account,
  onClose,
  onSuccess,
}: BankAccountFormProps) {
  const { t } = useTranslation();
  const isEditing = !!account;

  const [formData, setFormData] = useState({
    name: account?.name || "",
    bank_name: account?.bank_name || "",
    bank_account: account?.bank_account || "",
    bank_swift: account?.bank_swift || "",
    iban: account?.iban || "",
    is_default: account?.is_default || false,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (field: string, value: string | boolean) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next[field];
        return next;
      });
    }
  };

  const handleSubmit = async () => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = t("pages.settings.bankAccounts.form.nameRequired");
    }
    if (!formData.iban.trim()) {
      newErrors.iban = t("pages.settings.bankAccounts.form.ibanRequired");
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setIsSubmitting(true);
    try {
      const url = isEditing ? `/bank_accounts/${account.id}` : "/bank_accounts";
      const method = isEditing ? "PATCH" : "POST";

      const response = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token":
            document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
              ?.content || "",
        },
        body: JSON.stringify({ bank_account: formData }),
      });

      if (response.ok) {
        const data = await response.json();
        onSuccess(data.bank_accounts);
        toast.success(
          isEditing
            ? t("pages.settings.bankAccounts.updated")
            : t("pages.settings.bankAccounts.created")
        );
      } else {
        const data = await response.json();
        if (data.errors) {
          setErrors(data.errors);
        } else {
          toast.error(
            data.error || t("pages.settings.bankAccounts.saveFailed")
          );
        }
      }
    } catch {
      toast.error(t("pages.settings.bankAccounts.saveFailed"));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <AlertDialog open onOpenChange={(open) => !open && onClose()}>
      <AlertDialogContent className="max-w-md">
        <AlertDialogHeader>
          <AlertDialogTitle>
            {isEditing
              ? t("pages.settings.bankAccounts.editAccount")
              : t("pages.settings.bankAccounts.addAccount")}
          </AlertDialogTitle>
          <AlertDialogDescription>
            {t("pages.settings.bankAccounts.formDescription")}
          </AlertDialogDescription>
        </AlertDialogHeader>

        <div className="space-y-4 py-4">
          <div>
            <Label
              htmlFor="name"
              className="text-sm font-medium text-stone-600"
            >
              {t("pages.settings.bankAccounts.form.name")}
            </Label>
            <Input
              id="name"
              value={formData.name}
              onChange={(e) => handleChange("name", e.target.value)}
              className={`mt-1.5 ${errors.name ? "border-red-500" : ""}`}
            />
            {errors.name && (
              <p className="mt-1 text-sm text-red-600">{errors.name}</p>
            )}
          </div>

          <div>
            <Label
              htmlFor="bank_name"
              className="text-sm font-medium text-stone-600"
            >
              {t("pages.settings.bankAccounts.form.bankName")}
            </Label>
            <Input
              id="bank_name"
              value={formData.bank_name}
              onChange={(e) => handleChange("bank_name", e.target.value)}
              className="mt-1.5"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label
                htmlFor="bank_account"
                className="text-sm font-medium text-stone-600"
              >
                {t("pages.settings.bankAccounts.form.bankAccount")}
              </Label>
              <Input
                id="bank_account"
                value={formData.bank_account}
                onChange={(e) => handleChange("bank_account", e.target.value)}
                className="mt-1.5 font-mono"
              />
            </div>
            <div>
              <Label
                htmlFor="bank_swift"
                className="text-sm font-medium text-stone-600"
              >
                {t("pages.settings.bankAccounts.form.swift")}
              </Label>
              <Input
                id="bank_swift"
                value={formData.bank_swift}
                onChange={(e) => handleChange("bank_swift", e.target.value)}
                className="mt-1.5 font-mono"
              />
            </div>
          </div>

          <div>
            <Label
              htmlFor="iban"
              className="text-sm font-medium text-stone-600"
            >
              {t("pages.settings.bankAccounts.form.iban")}
            </Label>
            <Input
              id="iban"
              value={formData.iban}
              onChange={(e) => handleChange("iban", e.target.value)}
              className={`mt-1.5 font-mono ${errors.iban ? "border-red-500" : ""}`}
            />
            {errors.iban && (
              <p className="mt-1 text-sm text-red-600">{errors.iban}</p>
            )}
          </div>

          <div className="flex items-center justify-between pt-2">
            <div>
              <Label
                htmlFor="is_default"
                className="text-sm font-medium text-stone-600"
              >
                {t("pages.settings.bankAccounts.form.setAsDefault")}
              </Label>
              <p className="text-sm text-stone-500">
                {t("pages.settings.bankAccounts.form.defaultDescription")}
              </p>
            </div>
            <Switch
              id="is_default"
              checked={formData.is_default}
              onCheckedChange={(checked) => handleChange("is_default", checked)}
            />
          </div>
        </div>

        <AlertDialogFooter>
          <AlertDialogCancel disabled={isSubmitting}>
            {t("common.cancel")}
          </AlertDialogCancel>
          <Button onClick={handleSubmit} disabled={isSubmitting}>
            {isSubmitting
              ? t("common.saving")
              : isEditing
                ? t("common.save")
                : t("common.add")}
          </Button>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
