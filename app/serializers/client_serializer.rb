class ClientSerializer
  include Alba::Resource

  # Full detail - for show/edit pages
  attributes :id, :name, :address, :email, :contact_person, :vat_id,
             :company_registration, :bank_details, :payment_terms,
             :hourly_rate, :currency, :default_vat_rate,
             :share_token, :sharing_enabled, :locale, :bank_account_id

  class List
    include Alba::Resource

    attributes :id, :name, :email, :currency, :hourly_rate

    attribute :unbilled_hours do |client|
      params[:unbilled_stats]&.dig(client.id, :hours) || 0
    end

    attribute :unbilled_amount do |client|
      params[:unbilled_stats]&.dig(client.id, :amount) || 0
    end

    attribute :projects_count do |client|
      client.projects.size
    end
  end

  # Empty is a simple PORO since Alba doesn't handle nil objects
  class Empty
    DEFAULTS = {
      id: nil,
      name: "",
      address: "",
      email: "",
      contact_person: "",
      vat_id: "",
      company_registration: "",
      bank_details: "",
      payment_terms: "",
      hourly_rate: nil,
      currency: "",
      default_vat_rate: nil,
      locale: "en",
      bank_account_id: nil
    }.freeze

    def self.to_h = DEFAULTS
    def self.serializable_hash = DEFAULTS
  end

  class ForFilter
    include Alba::Resource
    attributes :id, :name
  end

  class ForSelect
    include Alba::Resource
    attributes :id, :name, :hourly_rate, :currency
  end

  class ForInvoiceSelect
    include Alba::Resource
    attributes :id, :name, :currency, :hourly_rate

    attribute :default_vat_rate do |client|
      client.default_vat_rate&.to_f
    end

    attribute :has_unbilled_entries do |client|
      params[:unbilled_counts]&.dig(client.id).to_i > 0
    end
  end
end
