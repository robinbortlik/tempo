class InvoiceLineItemSerializer
  include Alba::Resource

  attributes :id, :line_type, :description, :position

  attribute :quantity do |item|
    item.quantity&.to_f
  end

  attribute :unit_price do |item|
    item.unit_price&.to_f
  end

  attribute :amount do |item|
    item.amount.to_f
  end

  attribute :vat_rate do |item|
    item.vat_rate.to_f
  end

  attribute :vat_amount do |item|
    item.vat_amount.to_f
  end

  attribute :work_entry_ids do |item|
    item.work_entries.map(&:id)
  end
end
