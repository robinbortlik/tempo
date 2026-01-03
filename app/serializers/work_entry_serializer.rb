class WorkEntrySerializer
  include Alba::Resource

  # Full detail - for list pages
  attributes :id, :date, :hours, :amount, :hourly_rate, :entry_type,
             :description, :status, :calculated_amount, :project_id

  attribute :project_name do |entry|
    entry.project.name
  end

  attribute :client_id do |entry|
    entry.project.client_id
  end

  attribute :client_name do |entry|
    entry.project.client.name
  end

  attribute :client_currency do |entry|
    entry.project.client.currency
  end

  class Recent
    include Alba::Resource

    attributes :id, :date, :hours, :amount, :entry_type, :description, :status, :calculated_amount

    attribute :project_name do |entry|
      entry.project.name
    end
  end

  class ForProjectShow
    include Alba::Resource

    attributes :id, :date, :hours, :description, :status

    attribute :calculated_amount do |entry|
      entry.calculated_amount.to_f
    end
  end

  class ForInvoice
    include Alba::Resource

    attributes :id, :date, :entry_type, :description, :project_id

    attribute :hours do |entry|
      entry.hours&.to_f
    end

    attribute :amount do |entry|
      entry.amount&.to_f
    end

    attribute :calculated_amount do |entry|
      entry.calculated_amount&.to_f
    end

    attribute :project_name do |entry|
      entry.project.name
    end

    attribute :effective_hourly_rate do |entry|
      entry.project.effective_hourly_rate&.to_f
    end
  end

  class ForInvoiceProjectGroup
    include Alba::Resource

    attributes :id, :date, :entry_type, :description

    attribute :hours do |entry|
      entry.hours&.to_f
    end

    attribute :amount do |entry|
      entry.amount&.to_f
    end

    attribute :calculated_amount do |entry|
      entry.calculated_amount&.to_f
    end
  end

  class GroupedByDate
    include Alba::Resource

    attribute :date do |data|
      data[:date]
    end

    attribute :formatted_date do |data|
      data[:formatted_date]
    end

    attribute :total_hours do |data|
      data[:entries].select(&:time?).sum { |e| e.hours || 0 }
    end

    attribute :total_amount do |data|
      data[:entries].sum { |e| e.calculated_amount || 0 }
    end

    attribute :entries do |data|
      data[:entries].map { |entry| WorkEntrySerializer.new(entry).serializable_hash }
    end
  end
end
