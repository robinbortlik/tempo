class BankAccountSerializer
  include Alba::Resource

  attributes :id, :name, :bank_name, :bank_account, :bank_swift, :iban, :is_default

  class ForSelect
    include Alba::Resource

    attributes :id, :name

    attribute :iban_hint do |account|
      account.iban.present? ? "...#{account.iban.last(4)}" : nil
    end
  end
end
