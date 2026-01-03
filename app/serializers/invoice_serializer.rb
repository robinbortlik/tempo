class InvoiceSerializer
  include Alba::Resource

  # Full detail - for show page
  attributes :id, :number, :status, :issue_date, :due_date,
             :period_start, :period_end, :notes, :currency, :client_id

  attribute :total_hours do |invoice|
    invoice.total_hours&.to_f
  end

  attribute :total_amount do |invoice|
    invoice.total_amount&.to_f
  end

  attribute :subtotal do |invoice|
    invoice.subtotal.to_f
  end

  attribute :total_vat do |invoice|
    invoice.total_vat.to_f
  end

  attribute :grand_total do |invoice|
    invoice.grand_total.to_f
  end

  attribute :vat_totals_by_rate do |invoice|
    invoice.vat_totals_by_rate.transform_keys(&:to_f).transform_values(&:to_f)
  end

  attribute :client_name do |invoice|
    invoice.client.name
  end

  attribute :client_address do |invoice|
    invoice.client.address
  end

  attribute :client_email do |invoice|
    invoice.client.email
  end

  attribute :client_vat_id do |invoice|
    invoice.client.vat_id
  end

  attribute :client_company_registration do |invoice|
    invoice.client.company_registration
  end

  attribute :client_default_vat_rate do |invoice|
    invoice.client.default_vat_rate&.to_f
  end

  class List
    include Alba::Resource

    attributes :id, :number, :status, :issue_date, :due_date,
               :period_start, :period_end, :currency, :client_id

    attribute :total_hours do |invoice|
      invoice.total_hours&.to_f
    end

    attribute :total_amount do |invoice|
      invoice.total_amount&.to_f
    end

    attribute :client_name do |invoice|
      invoice.client.name
    end
  end

  class ProjectGroup
    include Alba::Resource

    attribute :project do |data|
      {
        id: data[:project].id,
        name: data[:project].name,
        effective_hourly_rate: data[:project].effective_hourly_rate&.to_f
      }
    end

    attribute :entries do |data|
      data[:entries].map do |entry|
        WorkEntrySerializer::ForInvoiceProjectGroup.new(entry).serializable_hash
      end
    end

    attribute :total_hours do |data|
      data[:entries].select(&:time?).sum { |e| e.hours || 0 }.to_f
    end

    attribute :total_amount do |data|
      data[:entries].sum { |e| e.calculated_amount || 0 }.to_f
    end
  end
end
