import { useState } from "react";
import { useTranslation } from "react-i18next";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { BankAccountForm } from "./BankAccountForm";

export interface BankAccount {
  id: number;
  name: string;
  bank_name: string | null;
  bank_account: string | null;
  bank_swift: string | null;
  iban: string;
  is_default: boolean;
}

interface BankAccountsSectionProps {
  bankAccounts: BankAccount[];
  onBankAccountsChange: (accounts: BankAccount[]) => void;
}

function formatIban(iban: string): string {
  return iban.replace(/(.{4})/g, "$1 ").trim();
}

export function BankAccountsSection({
  bankAccounts,
  onBankAccountsChange,
}: BankAccountsSectionProps) {
  const { t } = useTranslation();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingAccount, setEditingAccount] = useState<BankAccount | null>(
    null
  );
  const [deleteConfirm, setDeleteConfirm] = useState<BankAccount | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleAdd = () => {
    setEditingAccount(null);
    setIsFormOpen(true);
  };

  const handleEdit = (account: BankAccount) => {
    setEditingAccount(account);
    setIsFormOpen(true);
  };

  const handleFormSuccess = (updatedAccounts: BankAccount[]) => {
    onBankAccountsChange(updatedAccounts);
    setIsFormOpen(false);
    setEditingAccount(null);
  };

  const handleDelete = async () => {
    if (!deleteConfirm) return;

    setIsDeleting(true);
    try {
      const response = await fetch(`/bank_accounts/${deleteConfirm.id}`, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token":
            document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
              ?.content || "",
        },
      });

      if (response.ok) {
        const data = await response.json();
        onBankAccountsChange(data.bank_accounts);
        toast.success(t("pages.settings.bankAccounts.deleted"));
      } else {
        const data = await response.json();
        toast.error(
          data.error || t("pages.settings.bankAccounts.deleteFailed")
        );
      }
    } catch {
      toast.error(t("pages.settings.bankAccounts.deleteFailed"));
    } finally {
      setIsDeleting(false);
      setDeleteConfirm(null);
    }
  };

  const canDelete = (account: BankAccount): boolean => {
    // Cannot delete if it's the sole default account
    if (account.is_default && bankAccounts.length === 1) {
      return false;
    }
    return true;
  };

  return (
    <div className="bg-white rounded-xl border border-stone-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <h3 className="font-semibold text-stone-900">
          {t("pages.settings.bankAccounts.title")}
        </h3>
        <Button type="button" variant="outline" size="sm" onClick={handleAdd}>
          {t("common.add")}
        </Button>
      </div>

      {bankAccounts.length === 0 ? (
        <p className="text-sm text-stone-500">
          {t("pages.settings.bankAccounts.noAccounts")}
        </p>
      ) : (
        <div className="space-y-4">
          {bankAccounts.map((account) => (
            <div
              key={account.id}
              className="border border-stone-200 rounded-lg p-4"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-medium text-stone-900">
                      {account.name}
                    </span>
                    {account.is_default && (
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-stone-100 text-stone-700">
                        {t("pages.settings.bankAccounts.default")}
                      </span>
                    )}
                  </div>
                  {account.bank_name && (
                    <p className="text-sm text-stone-600">
                      {account.bank_name}
                    </p>
                  )}
                  <p className="text-sm font-mono text-stone-500 mt-1">
                    {formatIban(account.iban)}
                  </p>
                </div>
                <div className="flex items-center gap-2 ml-4">
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => handleEdit(account)}
                  >
                    {t("common.edit")}
                  </Button>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setDeleteConfirm(account)}
                    disabled={!canDelete(account)}
                    className="text-red-600 hover:text-red-700 hover:bg-red-50"
                  >
                    {t("common.delete")}
                  </Button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {isFormOpen && (
        <BankAccountForm
          account={editingAccount}
          onClose={() => {
            setIsFormOpen(false);
            setEditingAccount(null);
          }}
          onSuccess={handleFormSuccess}
        />
      )}

      <ConfirmDialog
        open={!!deleteConfirm}
        onOpenChange={(open) => !open && setDeleteConfirm(null)}
        title={t("pages.settings.bankAccounts.deleteTitle")}
        description={t("pages.settings.bankAccounts.deleteDescription")}
        onConfirm={handleDelete}
        variant="destructive"
        loading={isDeleting}
      />
    </div>
  );
}
