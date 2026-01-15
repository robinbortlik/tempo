class MoneyTransactionSerializer
  include Alba::Resource

  attributes :id, :transacted_on, :counterparty, :description, :currency,
             :transaction_type, :source, :reference, :external_id, :invoice_id

  attribute :amount do |transaction|
    transaction.amount.to_f
  end

  attribute :invoice_number do |transaction|
    transaction.invoice&.number
  end
end
