class SettingsSerializer
  include Alba::Resource

  attributes :id, :company_name, :address, :email, :phone, :vat_id,
             :company_registration, :invoice_message, :main_currency

  attribute :logo_url do |settings|
    if settings.logo?
      params[:url_helpers]&.url_for(settings.logo)
    end
  end

  class ForInvoice
    include Alba::Resource

    attributes :company_name, :address, :email, :phone, :vat_id,
               :company_registration, :invoice_message

    attribute :logo_url do |settings|
      if settings.logo?
        params[:url_helpers]&.url_for(settings.logo)
      end
    end
  end

  class ForReport
    include Alba::Resource

    attributes :company_name
  end
end
